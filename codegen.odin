package main

import "core:os"
import "core:io"
import "core:fmt"
import "core:strings"
import "core:mem"
expr_result :: struct {
    id: ExprId,
    kind: enum {Invalid, SingleRes, Binop, Number, Struct, None},
    v: string,
    struct_lit: struct {
        fields: []string, // string of results
    }
}

CGCtx :: struct {
    arena: ^mem.Dynamic_Arena,
    b: ^strings.Builder,
    tmp_id: int,
    scope: CGScope,
}
CGObjectKind :: enum {
    Invalid,
    Argument,
    Variable,
    Symbol, // like functions
}
CGObj :: struct {
    kind: CGObjectKind,
    name: string
}
CGScope :: struct {
    vars : map[string]CGObj,
    parent: ^CGScope,
}
new_gcscope :: proc(parent: ^CGScope) -> CGScope {
    s := CGScope{}
    s.vars = make(map[string]CGObj);
    s.parent = parent
    return s;
}
free_cgscope :: proc(s: ^CGScope) {
    delete(s.vars);
}
cwritef :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintf(c.b, format, ..data)
}
cwrite :: proc(c: ^CGCtx, format: string) {
    fmt.sbprint(c.b, format)
}
cwriteln :: proc(c: ^CGCtx, format: string) {
    fmt.sbprintln(c.b, format);
}
cwritefln :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintfln(c.b, format, ..data);
}

llvm_ty: map[TypeId]string
ty_to_llvm_str :: proc(c: ^CGCtx, id: TypeId) -> string {
    t, ok := llvm_ty[id];
    if ok { fmt.println("type found for:", id); return t }
    ty := get_type(id)
    #partial switch ty.kind {
    case .UntypedInteger: fallthrough
    case .UntypedFloat: 
        dump_context(get_ctx())
        gala_panic("bug")
    case .Pointer: {
        s := fmt.aprintf("ptr", allocator=c.arena.block_allocator )
        llvm_ty[id]=s
        return s
    }
    case .Float: {
        llvm_ty[id]="double";
        return llvm_ty[id]
    }
    case .Integer: {
        llvm_ty[id]="i64";
        return llvm_ty[id]
    }
    case .Void: {
        llvm_ty[id]="void";
        return llvm_ty[id]
    }
    case .Bool: return "i1";
    case .Function: return "ptr"; // functions are just pointers
    case .Struct: {
        if ty.name != "" {
            n := aprintf(c, "%%%s", ty.name);
            llvm_ty[id]=n;
            return llvm_ty[id]
        } else {
            debugln(ty);
            panic("impl")
        }
    }
    }
    panic("impl")
}
// eg "%t1"
new_tmp::proc(c: ^CGCtx) -> string {
    c.tmp_id += 1;
    return fmt.aprintf("%%t%d",c.tmp_id, allocator=c.arena.block_allocator);
}
aprintf :: proc(c: ^CGCtx, format: string, data: ..any) -> string {
    res := fmt.aprintf(format, ..data, allocator=c.arena.block_allocator)
    return res
}
ssa_names: map[string]string;
// returns value
cg_fn_call_target :: proc(c: ^CGCtx, id: ExprId) -> string {
    #partial switch e in get(id) {
        case Symbol: {
            v := cgscope_get(&c.scope, e.name);
            return v.name;
        }
    }
    gala_panic("no");
}
cg_expr :: proc(c: ^CGCtx, id: ExprId) -> expr_result {
    switch e in get_expr(id) {
    case FieldAccess: {
        r, ok := reduce_expr_to_single_value(c, cg_expr(c, e.target));
        assert(ok);

        target_ty := expr_ty(e.target)
        ty := get_type(target_ty)

        idx := -1
        for f, k in ty.structure.fields {
            if f.name == e.field {
                idx = k
                break
            }
        }
        assert(idx != -1)

        t := new_tmp(c)
        cwritefln(c, "\t%s = extractvalue %s %s, %d",
            t, ty_to_llvm_str(c, target_ty), r, idx)

        return {kind=.SingleRes, v=t}
    }
    case StructLit: {
        ty := get_ctx().expr_struct_types[id]
        fields := make([]string, len(get_type(ty).structure.fields), allocator=get_ctx().allocator)
        for f,k in get_type(ty).structure.fields {
            r, ok := reduce_expr_to_single_value(c, cg_expr(c, e.fields[f.name].expr));
            assert(ok);
            fields[k] = r
        }
        r: expr_result
        r.struct_lit.fields=fields
        r.id=id
        r.kind = .Struct
        return r;
    }
    case ZeroInit: {
        gala_panic("impl");
    }
    case Cast: {
        target := cg_expr(c, e.target)
        target_ty := expr_ty(e.target);
        to_ty := expr_ty(id)
        op, ok := ty_to_llvm_cast_op(target_ty, to_ty);
        if !ok {
            return target
        }
        reduced_target, returns := reduce_expr_to_single_value(c, target);
        assert(returns);
        t := new_tmp(c);
        cwritefln(c, "\t%s = %s %s %s to %s", t, op,
            ty_to_llvm_str(c, target_ty), reduced_target, ty_to_llvm_str(c, to_ty));
        return {kind=.SingleRes, v=t};
    }

    case Number: {
        return {kind=.Number, v=e.text};
    }
    case Binop: {
        l_v, returns_l := reduce_expr_to_single_value(c, cg_expr(c, e.left))
        assert(returns_l);
        r_v, returns_r := reduce_expr_to_single_value(c, cg_expr(c, e.right))
        assert(returns_r);

        // Use the OPERAND type, not expr_ty(id) — comparisons return Bool
        // but the instruction needs the type of the things being compared.
        operand_ty := expr_ty(e.left)

        op := ""
        if get_type(operand_ty).kind == .Integer {
            switch e.kind {
            case .Addition:     op = "add"
            case .Subtraction:  op = "sub"
            case .Multiply:     op = "mul"
            case .Divide:       op = "sdiv" // signed div; use udiv if you track unsigned types
            case .Equal:        op = "icmp eq"
            case .NotEqual:     op = "icmp ne"
            case .LessEqual:    op = "icmp sle"
            case .GreaterEqual: op = "icmp sge"
            case: gala_panic("impl")
            }
        } else if get_type(operand_ty).kind == .Float {
            switch e.kind {
            case .Addition:     op = "fadd"
            case .Subtraction:  op = "fsub"
            case .Multiply:     op = "fmul"
            case .Divide:       op = "fdiv"
            case .Equal:        op = "fcmp oeq"
            case .NotEqual:     op = "fcmp one"
            case .LessEqual:    op = "fcmp ole"
            case .GreaterEqual: op = "fcmp oge"
            case: gala_panic("impl")
            }
        } else if get_type(operand_ty).kind == .Void {
            dump_context(get_ctx())
            gala_panic("can't binop voids")
        } else {
            fmt.println(get_type(operand_ty).kind)
            fmt.println(get_expr(id))
            gala_panic("handle")
        }

        return {kind=.Binop,
            v=aprintf(c, "%s %s %s, %s", op, ty_to_llvm_str(c, operand_ty), l_v, r_v)}
    }
    case Symbol: {
        // v := cgscope_get(&c.scope, e.name);
        v := cgscope_get(&c.scope, e.name);
        switch v.kind {
        case .Variable: fallthrough
        case .Symbol: {
            t := new_tmp(c)
            cwritefln(c, "\t%s = load %s, ptr %s",
                t, ty_to_llvm_str(c, expr_ty(id)), v.name);
            return {kind=.SingleRes,v=t};
        }
        case .Argument: {
            return {kind=.SingleRes,v=v.name};
        }
        case .Invalid: {
            gala_panic("invalid object");
        }
        }
        gala_panic("impl");
    }
    case FnCall: {
        t := cg_fn_call_target(c, e.target);
        fn_ty := get_type(expr_ty(e.target));
        //gen args
        args:=make([dynamic]string)
        for a, i in e.args {
            r, returns := reduce_expr_to_single_value(c, cg_expr(c, a));
            assert(returns);
            v := aprintf(c, "%s %s", ty_to_llvm_str(c, expr_ty(a)), r);
               append(&args, v);
        }

        if get(fn_ty.fn.ret_ty).kind == .Void {
            cwritef(c, "\tcall %s %s", ty_to_llvm_str(c, fn_ty.fn.ret_ty), t);
            cwrite(c, "(");
            for a, i in args {
                cwritef(c, "%s", a);
                if i < len(args) - 1 {
                    fmt.println(i, len(fn_ty.fn.args))
                    cwritef(c, ", ")
                }
            }
            cwriteln(c, ")");
            return {kind=.None, id=id}
        } else {
            new_t := new_tmp(c);
            cwritef(c, "\t%s = call %s %s", new_t, ty_to_llvm_str(c, fn_ty.fn.ret_ty), t);
            cwrite(c, "(");
            for a, i in args {
                cwritef(c, "%s", a);
                if i < len(args) - 1 {
                    fmt.println(i, len(fn_ty.fn.args))
                    cwritef(c, ", ")
                }
            }
            cwriteln(c, ")");
            return {kind=.SingleRes, v=new_t, id=id};
        }
    }
    case: gala_panic("impl");
    }
}
bit_width_of :: proc(k: TypeKind) -> int {
    #partial switch k {
    case .Bool:   return 1
    case .Byte:   return 8
    case .Rune:   return 32
    case .Integer: return 64
    case .Float:  return 64 // double
    case: gala_panic("bit_width_of: not a scalar numeric kind")
    }
}

is_signed :: proc(k: TypeKind) -> bool {
    #partial switch k {
    case .Integer: return true
    case .Byte, .Rune, .Bool: return false
    case: gala_panic("is_signed: not an integer-ish kind")
    }
}

is_int_kind :: proc(k: TypeKind) -> bool {
    return k == .Integer || k == .Byte || k == .Rune || k == .Bool
}

// Returns the LLVM instruction mnemonic needed to convert `target` -> `to`.
// Assumes can_cast_to(target_id, to_id) has already been checked and is true;
// gala_panics on invalid pairs so a mismatch between the two tables is caught loudly.
ty_to_llvm_cast_op :: proc(target_id, to_id: TypeId) -> (string, bool) {
    target := get_type(target_id)
    to := get_type(to_id)

    if target.kind == to.kind {
        // same kind: Pointer->Pointer (bitcast, or no-op with opaque ptrs),
        // otherwise truly identical, no instruction needed
        #partial switch target.kind {
        case .Pointer: return "bitcast", true // safe even if often a no-op with opaque ptrs
        case: return "", false // identity — caller should skip emitting anything
        }
    }

    tk, ok := target.kind, to.kind

    // --- int-family -> int-family (includes Bool/Byte/Rune/Integer combos) ---
    if is_int_kind(tk) && is_int_kind(ok) {
        from_w := bit_width_of(tk)
        to_w   := bit_width_of(ok)
        if from_w < to_w {
            return is_signed(tk) ? "sext" : "zext", true
        } else if from_w > to_w {
            return "trunc", true
        }
        return "", false // same width, different kind label (e.g. Byte <-> Bool at same width) — bitcast-free no-op
    }

    // --- int-family -> Float ---
    if is_int_kind(tk) && ok == .Float {
        return is_signed(tk) ? "sitofp" : "uitofp", true
    }

    // --- Float -> int-family ---
    if tk == .Float && is_int_kind(ok) {
        return is_signed(ok) ? "fptosi" : "fptoui", true
    }

    // --- Float -> Float (different width, if you ever add f32) ---
    if tk == .Float && ok == .Float {
        return "", false // no change
    }

    // --- Pointer <-> Integer ---
    if tk == .Pointer && is_int_kind(ok) {
        return "ptrtoint", true
    }
    if is_int_kind(tk) && ok == .Pointer {
        return "inttoptr", true
    }

    gala_panic("ty_to_llvm_cast_op: no cast op for this pair — check can_cast_to table")
}

// some expressions (fn calls with void returns) don't return so are invalid
reduce_expr_to_single_value :: proc(c: ^CGCtx, e: expr_result) -> (string, bool) {
    switch e.kind {
    case .Struct: {
        lit := get_expr(e.id).(StructLit)
        tid := expr_ty(e.id)
        ty := get_type(tid);
        ty_str := ty_to_llvm_str(c, tid)

        cur := "undef"   // starting aggregate — a literal LLVM keyword, not a register
        i := 0;
        for field in ty.structure.fields {
            f := lit.fields[field.name]
            fv, returns := reduce_expr_to_single_value(c, cg_expr(c, f.expr))
            assert(returns)
            next := new_tmp(c)
            cwritefln(c, "\t%s = insertvalue %s %s, %s %s, %d",
                next, ty_str, cur, ty_to_llvm_str(c, expr_ty(f.expr)), fv, i)
            cur = next
            i+=1;
        }
        return cur, true
    }
    case .Invalid: gala_panic("invalid")
    case .None: return "", false
    case .SingleRes: {
        return e.v, true
    }
    case .Number: {
        return e.v, true
    }
    case .Binop: {
        t := new_tmp(c)
        cwritefln(c, "\t%s = %s", t, e.v);
        return t, true
    }
    }
    gala_panic("impl");
}
stmt_ends_block :: proc(stmt: StmtId) -> bool {
    switch s in get(stmt) {
    case IfElse: {
        has_all_returns := s.has_else_block
        if !check_rets(s.base_block) do has_all_returns = false;
        for a in s.alt {
            if !check_rets(a.block) do has_all_returns = false;
        }
        if s.has_else_block {
            if !check_rets(s.else_block) do has_all_returns = false;
        }
        return has_all_returns
    }
    case Return: return true
    case VarDec: return false
    case Assignment: return false
    case ExprId: return false;
    case: gala_panic("impl");
    }
    gala_panic("impl");
}
cg_stmt :: proc(c: ^CGCtx, id: StmtId) {
    switch s in get_stmt(id) {
    case ExprId:
        reduce_expr_to_single_value(c, cg_expr(c, s));
    case IfElse: {
        c.tmp_id += 1;
        id_suffix := c.tmp_id
        end_label := aprintf(c, "end_label%d", id_suffix);

        // Precompute all labels we'll need up front so branch targets
        // can reference "the next check" before that block is emitted.
        base_block := aprintf(c, "base_block_label%d", id_suffix);

        alt_cond_labels := make([dynamic]string, c.arena.block_allocator)
        alt_body_labels := make([dynamic]string, c.arena.block_allocator)
        for _, i in s.alt {
            append(&alt_cond_labels, aprintf(c, "alt_cond_label%d_%d", id_suffix, i))
            append(&alt_body_labels, aprintf(c, "alt_block_label%d_%d", id_suffix, i))
        }
        has_else := s.has_else_block;
        else_label := aprintf(c, "else_block_label%d", id_suffix);

        // what to jump to if the base condition is false
        next_after_base := end_label
        if len(s.alt) > 0 {
            next_after_base = alt_cond_labels[0]
        } else if has_else {
            next_after_base = else_label
        }

        // --- base condition ---
        {
            cond, returns := reduce_expr_to_single_value(c, cg_expr(c, s.base_con));
            assert(returns);
            ty := get_type(expr_ty(s.base_con));
            assert(ty.kind == .Bool);
            cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", cond, base_block, next_after_base);

            cwritefln(c, "%s:", base_block);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in s.base_block.stmts {
                cg_stmt(c, statement);
                if stmt_ends_block(statement) && i != len(s.base_block.stmts) - 1 {
                    gala_panic("nothing past will be executed");
                }
            }
            free_cgscope(&c.scope)
            c.scope = old;
            if !check_rets(s.base_block) {
                cwritefln(c, "\tbr label %%%s", end_label);
            }
        }

        // --- else-if chain ---
        for a, i in s.alt {
            next := end_label
            if i < len(s.alt) - 1 {
                next = alt_cond_labels[i + 1]
            } else if has_else {
                next = else_label
            }

            cwritefln(c, "%s:", alt_cond_labels[i]);
            cond, returns := reduce_expr_to_single_value(c, cg_expr(c, a.cond));
            assert(returns);
            ty := get_type(expr_ty(a.cond));
            assert(ty.kind == .Bool);
            cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", cond, alt_body_labels[i], next);

            cwritefln(c, "%s:", alt_body_labels[i]);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in a.block.stmts {
                cg_stmt(c, statement);
                if stmt_ends_block(statement) && i != len(s.base_block.stmts) - 1 {
                    gala_panic("nothing past will be executed");
                }
            }
            free_cgscope(&c.scope)
            c.scope = old;
            if !check_rets(a.block) {
                cwritefln(c, "\tbr label %%%s", end_label);
            }
        }

        // --- else ---
        if has_else {
            cwritefln(c, "%s:", else_label);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in s.else_block.stmts {
                cg_stmt(c, statement);
                if stmt_ends_block(statement) && i != len(s.base_block.stmts) - 1 {
                    gala_panic("nothing past will be executed");
                }
            }
            free_cgscope(&c.scope)
            c.scope = old;
            if !check_rets(s.else_block) {
                cwritefln(c, "\tbr label %%%s", end_label);
            }
        }

        has_all_returns := has_else
        if !check_rets(s.base_block) do has_all_returns = false;
        for a in s.alt {
            if !check_rets(a.block) do has_all_returns = false;
        }
        if has_else {
            if !check_rets(s.else_block) do has_all_returns = false;
        }
        // returns in every branch, so never needs end label
        if !has_all_returns {
            cwritefln(c, "%s:", end_label);
        }
    }
    case VarDec:{
        // get object
        obj := get_obj(get_ctx().stmt_objects[id]);
        // gen value
        v := cg_expr(c, s.value)
        // write name to scope
        c.scope.vars[s.name] = {.Variable, aprintf(c, "%%%s", s.name)};
        name := c.scope.vars[s.name].name
        if true {
            value, returns :=  reduce_expr_to_single_value(c, v);
            assert(returns);
            // allocate
            cwritefln(c, "\t%s = alloca %s", name,
                ty_to_llvm_str(c, obj.type.(TypeId)));
            // init
            cwritefln(c, "\tstore %s %s, ptr %s", ty_to_llvm_str(c, obj.type.(TypeId)),
                value, name);
        } else {
            cwritefln(c, "\t%s = alloca %s",name, 
                ty_to_llvm_str(c, obj.type.(TypeId)));
            tid := get_ctx().expr_struct_types[v.id]
            ty := get_type(tid);
            for v, i in v.struct_lit.fields {
                // load
                // %y_addr = getelementptr inbounds %Vec2, %Vec2* %ptr, i32 0, i32 1
                t := new_tmp(c)
                llvm_t := ty_to_llvm_str(c, tid)
                cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i32 0, i32 %d",
                            t, llvm_t, name, i)
                // store
                // store float 3.0, float* %y_addr
                field_ty := ty_to_llvm_str(c, ty.structure.fields[i].type);
                cwritefln(c, "\tstore %s %s, ptr %s",
                            field_ty, v, t)
            }
        }
    }
    case Return: {
        if e, ok := s.expr.(ExprId); ok {
            r, returns := reduce_expr_to_single_value(c, cg_expr(c, e));
            assert(returns);
            cwritefln(c, "\tret %s %s", ty_to_llvm_str(c, expr_ty(e)), r)
        } else {
            cwriteln(c, "\tret void")
        }
    }
    case Assignment: {
        value, returns := reduce_expr_to_single_value(c, cg_expr(c, s.value))
        assert(returns)
        target_ptr := cg_lvalue(c, s.target)
        cwritefln(c, "\tstore %s %s, ptr %s",
            ty_to_llvm_str(c, expr_ty(s.target)), value, target_ptr)
    }
    case:panic("impl");
    }
}
cg_lvalue :: proc(c: ^CGCtx, id: ExprId) -> string {
    #partial switch e in get_expr(id) {
    case Symbol: {
        v := cgscope_get(&c.scope, e.name)
        assert(v.kind == .Variable) // args aren't addressable — can't assign to a by-value param
        return v.name
    }
    case FieldAccess: {
        base_ptr := cg_lvalue(c, e.target) // recurse — handles a.b.c chains
        base_ty := expr_ty(e.target)
        ty := get_type(base_ty)

        idx := -1
        for f, k in ty.structure.fields {
            if f.name == e.field {
                idx = k
                break
            }
        }
        assert(idx != -1)

        t := new_tmp(c)
        cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i32 0, i32 %d",
            t, ty_to_llvm_str(c, base_ty), base_ptr, idx)
        return t
    }
    case: gala_panic("not an lvalue")
    }
}
gen_item :: proc(c: ^CGCtx, id: ItemId) {
    switch i in get_item(id) {
    case StructDec: {
        cwritef(c, "%%%s = ", i.name);
        cwrite(c, "type {")
        ty :=get_type(get_ctx().item_types[id])
        for f, i in ty.structure.fields {
            fmt.printfln("%s", ty_to_llvm_str(c,f.type));
            cwritef(c, "%s", ty_to_llvm_str(c,f.type));
            if i != len(get_type(get_ctx().item_types[id]).structure.fields) -1 {
                cwrite(c, ",");
            }
        }
        cwriteln(c, "}")
    }
    case ExternFnDec: {
        // get type
        objid :=get_ctx().item_objects[id]
        obj := get_ctx().objs[objid]
        fn_ty := get_type(obj.type.(TypeId))

        // write
        cwrite(c, "declare ");
        // write return type
        cwritef(c, "%s ", ty_to_llvm_str(c, fn_ty.fn.ret_ty));
        // write name
        cwritef(c, "@%s ", obj.name);
        // write args
        cwrite(c, "(");
        for a, i in fn_ty.fn.args {
            // write name to scope
            c.scope.vars[a.name] = {.Argument, aprintf(c, "%%%s", a.name)};
            cwritef(c, "%s %s", ty_to_llvm_str(c, a.type), c.scope.vars[a.name].name);
            if i < len(fn_ty.fn.args) - 1 {
                fmt.println(i, len(fn_ty.fn.args))
                cwritef(c, ", ")
            }
        }
        cwriteln(c, ")");
    }
    case FnDec: {
        // double check type is a function
        assert(check_fn(i));
        // new scope
        old_scope := c.scope
        new_cg_scope := new_gcscope(&old_scope);
        c.scope = new_cg_scope

        // get type
        objid :=get_ctx().item_objects[id]
        obj := get_ctx().objs[objid]
        fn_ty := get_type(obj.type.(TypeId))

        // write
        cwrite(c, "define ");
        // write return type
        cwritef(c, "%s ", ty_to_llvm_str(c, fn_ty.fn.ret_ty));
        // write name
        cwritef(c, "@%s ", obj.name);
        // write args
        cwrite(c, "(");
        for a, i in fn_ty.fn.args {
            // write name to scope
            c.scope.vars[a.name] = {.Argument, aprintf(c, "%%%s", a.name)};
            cwritef(c, "%s %s", ty_to_llvm_str(c, a.type), c.scope.vars[a.name].name);
            if i < len(fn_ty.fn.args) - 1 {
                fmt.println(i, len(fn_ty.fn.args))
                cwritef(c, ", ")
            }
        }
        cwrite(c, ") ");
        cwriteln(c, "{");
        // entry block
        cwriteln(c, "entry:");
        for statement, index in i.block.stmts {
            cg_stmt(c, statement);
            if stmt_ends_block(statement) && index != len(i.block.stmts) - 1 {
                gala_panic("nothing past will be executed");
            }
        }
        cwriteln(c, "}");
        // reset scope
        c.scope = old_scope
    }
    case: panic("impl")
    }
}
cg_ast :: proc(c: ^CGCtx, ast: ^AST) {
    for id in ast.items {
        gen_item(c, id)
    }
}
check_rets :: proc(b: Block) -> bool {
    last := b.stmts[len(b.stmts)-1];
    return stmt_ends_block(last); // check if last statement ends block
}
check_fn :: proc(f: FnDec) -> bool {
    if !check_rets(f.block) {
        gala_panic("function must return at all branches")
    }
    return true
}
cgscope_get :: proc(scope: ^CGScope, v: string) -> CGObj {
    s := scope
    for s != nil {
        n, ok := s.vars[v];
        if ok do return n
        s = s.parent
    }
    gala_panic("doesn't exist")
}
cg_module :: proc(ast: ^AST) {
    cgctx := CGCtx{}
    arena : mem.Dynamic_Arena;
    mem.dynamic_arena_init(&arena)
    cgctx.arena = &arena
    sb : strings.Builder
    strings.builder_init(&sb)
    cgctx.b = &sb
    cgctx.scope = new_gcscope(nil);


    // boilerplate + garbage
    fmt.sbprintfln(cgctx.b, "; target info")
    fmt.sbprintfln(cgctx.b, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"");
    fmt.sbprintfln(cgctx.b, "target triple = \"x86_64-pc-linux-gnu\"")
    for i in ast.items {
        switch s in get_item(i) {
        case StructDec: {}
        case FnDec: { 
            // declare first;
            // it's a function , so use "@main" instead of "%main"
            cgctx.scope.vars[s.name] = {.Symbol, aprintf(&cgctx, "@%s", s.name)};
        }
        case ExternFnDec: { 
            // declare first;
            // it's a function , so use "@main" instead of "%main"
            cgctx.scope.vars[s.name] = {.Symbol, aprintf(&cgctx, "@%s", s.name)};
        }
        }
    }
    // gen
    cg_ast(&cgctx, ast)
    // print resuly
    fmt.println(strings.to_string(sb))
    // write
    e := os.write_entire_file_from_string("a.ll", strings.to_string(sb))
    assert(e == io.Error.None)
    
    // compile llvm
    p, err := os.process_start({command={"clang", "-o", "a.out", "a.ll"}});
    assert(err == .NONE);
    p_state, werr := os.process_wait(p)
    assert(err == .NONE);
    assert(p_state.exit_code == 0);
    fmt.println("clang exit code:", p_state.exit_code);
    
    // run
    p, err = os.process_start({command={"./a.out"}});
    assert(err == .NONE);
    p_state, werr = os.process_wait(p)
    assert(err == .NONE);
    fmt.println("program exit code:", p_state.exit_code);

}
