package main

import "core:os"
import "core:io"
import "core:fmt"
import "core:strings"
import "core:mem"
CGExprRes :: struct {
    id: ExprId,
    kind: enum {Invalid, Address, Value, Binop, Number, Struct, None},
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
    llvm_ty: map[TypeId]string,
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
    s.vars = make(map[string]CGObj, allocator=get_ctx().allocator);
    s.parent = parent
    return s;
}
free_cgscope :: proc(s: ^CGScope) {
    // delete(s.vars);
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

ty_to_llvm_str :: proc(c: ^CGCtx, id: TypeId) -> string {
    t, ok := c.llvm_ty[id];
    if ok { /*debugln("type found for:", id);*/ return t }
    ty := get_type(id)
    #partial switch ty.kind {
    case .UntypedInteger: fallthrough
    case .UntypedFloat: 
        dump_context(get_ctx())
        gala_panic("bug")
    case .Pointer: {
        s := fmt.aprintf("ptr", allocator=c.arena.block_allocator )
        c.llvm_ty[id]=s
        return s
    }
    case .Float: {
        c.llvm_ty[id]="double";
        return c.llvm_ty[id]
    }
    case .Integer: {
        c.llvm_ty[id]="i64";
        return c.llvm_ty[id]
    }
    case .Void: {
        c.llvm_ty[id]="void";
        return c.llvm_ty[id]
    }
    case .Byte: return "i8";
    case .Bool: return "i1";
    case .Function: return "ptr"; // functions are just pointers
    case .Struct: {
        if ty.name != "" {
            n := aprintf(c, "%%%s", ty.name);
            c.llvm_ty[id]=n;
            return c.llvm_ty[id]
        } else {
            debugln(ty);
            panic("impl")
        }
    }
    case .FixedSizeArray: {
            n := aprintf(c, "[%d x %s]", ty.fixed_size_array.size,
                   ty_to_llvm_str(c, ty.fixed_size_array.type));
            c.llvm_ty[id]=n;
            return c.llvm_ty[id]
    }
    case .Slice: {
        return "{ ptr, i64 }";
    }
    }
    debugln(ty);
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
// returns value
cg_fn_call_target :: proc(c: ^CGCtx, id: ExprId) -> string {
    #partial switch e in get(id) {
        case Symbol: {
            v := cgscope_get(&c.scope, e.name);
            return v.name;
        }
    }
    panic("no");
}
// Only decides on a single-instruction fast path. Returns ok=false when
// the pair needs the memory round-trip instead (structs, arrays, or any
// combo bitcast doesn't support).
ty_to_llvm_transmute_op :: proc(from_id, to_id: TypeId) -> (string, bool) {
    from := get_type(from_id)
    to := get_type(to_id)

    if from.kind == to.kind do return "", false // identical layout, no-op

    // int-family <-> Float, same width: true bit reinterpretation
    if is_int_kind(from.kind) && to.kind == .Float && bit_width_of(from.kind) == bit_width_of(to.kind) {
        return "bitcast", true
    }
    if from.kind == .Float && is_int_kind(to.kind) && bit_width_of(from.kind) == bit_width_of(to.kind) {
        return "bitcast", true
    }

    // Pointer <-> Integer: NOT bitcast-legal in LLVM. ptrtoint/inttoptr
    // are already the bit-preserving ops for equal widths.
    if from.kind == .Pointer && is_int_kind(to.kind) do return "ptrtoint", true
    if is_int_kind(from.kind) && to.kind == .Pointer do return "inttoptr", true

    // int-family <-> int-family, same width, different label (e.g. Integer <-> Byte
    // if you ever add a 64-bit byte-like kind): pure relabel, no instruction
    if is_int_kind(from.kind) && is_int_kind(to.kind) && bit_width_of(from.kind) == bit_width_of(to.kind) {
        return "", false
    }

    return "", false // signal "no fast path" — caller falls through to memory
}
cg_expr :: proc(c: ^CGCtx, id: ExprId) -> CGExprRes {
    span := get_span(id).span
    data := get_file_lines(get_ctx().current_file, span)
    cwritefln(c, "\t; cg_expr \"%s\"",
        string(get_ctx().files[get_ctx().current_file][span.start:span.end]))
    // in cg_expr:
    switch e in get_expr(id) {
    case Deref: {
        // rvalue: the pointer itself, already loaded
        ptr_val := cg_addr(c, e.expr);
        ptr_ty := get_type(expr_ty(e.expr))

        if ptr_ty.kind != .Pointer {
            panic("cannot dereference non-pointer type")
        }

        pointee_ty := ptr_ty.ptr
        pointee_llvm_ty := ty_to_llvm_str(c, pointee_ty)

        loaded := new_tmp(c);
        cwritefln(c, "\t%s = load %s, ptr %s", loaded, pointee_llvm_ty, ptr_val);

        return {
            kind = .Value,
            v = loaded,
        }
    }
    case Reference: {
        inner_ptr := cg_addr(c, e.expr)
        e_ty := expr_ty(e.expr);
        return {kind=.Value, v = inner_ptr}
    }
    case Transmute: {
        from_ty := expr_ty(e.target)
        to_ty := expr_ty(id)

        reduced, returns := reduce_expr_to_single_value(c, cg_expr(c, e.target))
        assert(returns)

        if op, ok := ty_to_llvm_transmute_op(from_ty, to_ty); ok {
            t := new_tmp(c)
            cwritefln(c, "\t%s = %s %s %s to %s", t, op,
                ty_to_llvm_str(c, from_ty), reduced, ty_to_llvm_str(c, to_ty))
            return {kind=.Value, v=t}
        }

        // General fallback: reinterpret through memory. Correct for ANY pair —
        // struct<->struct, struct<->array, scalar<->aggregate, whatever —
        // because store/load don't care about type, only bytes.
        slot := new_tmp(c)
        cwritefln(c, "\t%s = alloca %s", slot, ty_to_llvm_str(c, from_ty))
        cwritefln(c, "\tstore %s %s, ptr %s", ty_to_llvm_str(c, from_ty), reduced, slot)
        t := new_tmp(c)
        cwritefln(c, "\t%s = load %s, ptr %s", t, ty_to_llvm_str(c, to_ty), slot)
        return {kind=.Value, v=t}
    }
    case TakeSlice: {
        // compute length
        // gen ends
        start, sret := reduce_expr_to_single_value(c, cg_expr(c, e.start))
        assert(sret);
        end, eret := reduce_expr_to_single_value(c, cg_expr(c, e.end))
        assert(eret);

        // reduce both to int
        if get(expr_ty(e.start)).kind != .Integer {
            op, ok := ty_to_llvm_cast_op(expr_ty(e.start), integer_type());
            if !ok {
                // nothing?
            }
            t := new_tmp(c);
            cwritefln(c, "\t%s = %s %s %s to %s", t, op,
                ty_to_llvm_str(c, expr_ty(e.start)), start, ty_to_llvm_str(c, integer_type()));
            start = t
        }
        if get(expr_ty(e.end)).kind != .Integer {
            op, ok := ty_to_llvm_cast_op(expr_ty(e.end), integer_type());
            if !ok {
                // nothing?
            }
            t := new_tmp(c);
            cwritefln(c, "\t%s = %s %s %s to %s", t, op,
                ty_to_llvm_str(c, expr_ty(e.end)), end, ty_to_llvm_str(c, integer_type()));
            end = t
        }
        len_s := new_tmp(c);
        cwritefln(c, "\t%s = sub nsw nuw %s %s, %s",len_s,
            ty_to_llvm_str(c,integer_type()), end, start);

        llvm_int := ty_to_llvm_str(c, integer_type())
        // get ptr
        base_ptr, elem_ty := cg_data_ptr(c, e.target)
        elem_ptr := new_tmp(c)
        cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, %s %s",
            elem_ptr, elem_ty, base_ptr, llvm_int, start)

        v1 := new_tmp(c)
        v2 := new_tmp(c)
        cwritefln(c, "\t%s = insertvalue {{ ptr, %s }} undef, ptr %s, 0", v1, llvm_int, elem_ptr)
        cwritefln(c, "\t%s = insertvalue {{ ptr, %s }} %s, %s %s, 1", v2, llvm_int, v1, llvm_int, len_s)
        return {kind=.Value, v=v2}
    }
    // cg_expr's Index:
    case Index: {
        ptr := cg_elem_ptr(c, e.target, e.index)
        v := new_tmp(c)
        cwritefln(c, "\t%s = load %s, ptr %s", v, ty_to_llvm_str(c, expr_ty(id)), ptr)
        return {kind=.Value, v=v}
    }
    case FixedSizeArray: {
        assert(e.initialiser == nil);
        ty := ty_to_llvm_str(c, expr_ty(id));
        t := aprintf(c, "zeroinitializer");
        return {kind=.Value, v=t}
    }
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

        return {kind=.Value, v=t}
    }
    case StructLit: {
        ty := get_ctx().expr_resolution_types[id]
        fields := make([]string, len(get_type(ty).structure.fields), allocator=get_ctx().allocator)
        for f,k in get_type(ty).structure.fields {
            r, ok := reduce_expr_to_single_value(c, cg_expr(c, e.fields[f.name].expr));
            assert(ok);
            fields[k] = r
        }
        r: CGExprRes
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
        return {kind=.Value, v=t};
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
            debugln(get_type(operand_ty).kind)
            debugln(get_expr(id))
            panic("handle")
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
            return {kind=.Value,v=t};
        }
        case .Argument: {
            return {kind=.Value,v=v.name};
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
        args:=make([dynamic]string, allocator=get_ctx().allocator)
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
                    debugln(i, len(fn_ty.fn.args))
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
                    debugln(i, len(fn_ty.fn.args))
                    cwritef(c, ", ")
                }
            }
            cwriteln(c, ")");
            return {kind=.Value, v=new_t, id=id};
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
reduce_expr_to_single_value :: proc(c: ^CGCtx, e: CGExprRes) -> (string, bool) {
    switch e.kind {
    case .Address: {
        return e.v, true;
    }
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
    case .Value: {
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
    span := get_span(id).span
    data := get_file_lines(get_ctx().current_file, span)
    cwritefln(c, "\t; cg_stmt \"%s\"",
        string(get_ctx().files[get_ctx().current_file][span.start:span.end]))
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

        alt_cond_labels := make([dynamic]string, get_ctx().allocator)
        alt_body_labels := make([dynamic]string, get_ctx().allocator)
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
            tid := get_ctx().expr_resolution_types[v.id]
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
        target_ptr := cg_addr(c, s.target)
        cwritefln(c, "\tstore %s %s, ptr %s",
            ty_to_llvm_str(c, expr_ty(s.target)), value, target_ptr)
    }
    case:panic("impl");
    }
    cwriteln(c, "");
}
cg_can_assign_to :: proc(id: ExprId) -> bool {
    panic("impl");
}
// Resolves ANY indexable expression down to a pointer that already points at
// element 0, plus that element's LLVM type string. This is the one place
// that needs to know how array/slice/pointer differ — everything downstream
// (Index, TakeSlice, and later `for x in ...`) is a uniform single-index GEP
// off the result.
cg_data_ptr :: proc(c: ^CGCtx, id: ExprId) -> (ptr: string, elem_ty_str: string) {
    ty := get_type(expr_ty(id))
    cwritefln(c, "\t; cg_data_ptr expr tye: %s", tts(expr_ty(id)));
    #partial switch ty.kind {
    case .FixedSizeArray:
        // arrays are always addressable, never SSA values — get its address,
        // which (with opaque pointers) already IS "pointer to element 0"
        return cg_addr(c, id), ty_to_llvm_str(c, ty.fixed_size_array.type)

    case .Slice: {
        // slices are a small by-value {ptr, i64} — get the value however it
        // naturally arises (load, extractvalue, straight from TakeSlice,
        // a function return, whatever cg_expr already knows how to do) and
        // pull the data pointer straight out of it
        v, ok := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(ok)
        p := new_tmp(c)
        cwritefln(c, "\t%s = extractvalue {{ ptr, i64 }} %s, 0", p, v)
        return p, ty_to_llvm_str(c, ty.slice.type) // check your real field name
    }

    case .Pointer: {
        // already IS a pointer to element 0
        cwritefln(c, "\t; should load buf^");
        v, ok := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(ok)
        return v, ty_to_llvm_str(c, ty.ptr) // check your real field name
    }

    case: gala_panic("cg_data_ptr: not indexable")
    }
}

// Address of target[index]. Used by both cg_expr's Index (which loads
// afterward) and cg_addr's Index (which just returns this).
cg_elem_ptr :: proc(c: ^CGCtx, target: ExprId, index: ExprId) -> string {
    cwritefln(c, "\t; get_elem_ptr gens:");
    base_ptr, elem_ty := cg_data_ptr(c, target)
    idx_v, ok := reduce_expr_to_single_value(c, cg_expr(c, index)); assert(ok)
    idx_ty := ty_to_llvm_str(c, expr_ty(index))

    t := new_tmp(c)
    cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, %s %s",
        t, elem_ty, base_ptr, idx_ty, idx_v)
    return t
}
cg_addr :: proc(c: ^CGCtx, id: ExprId) -> string {
    span := get_span(id).span
    data := get_file_lines(get_ctx().current_file, span)
    cwritefln(c, "\t; cg_addr \"%s\"",
        string(get_ctx().files[get_ctx().current_file][span.start:span.end]))
    #partial switch e in get_expr(id) {
    case Symbol: {
        v := cgscope_get(&c.scope, e.name)
        if v.kind == .Variable do return v.name
        if v.kind == .Argument do return v.name

        panic("impl");
        // args aren't addressable — can't assign to a by-value param
        // can however if args is a ptr/array
    }
    case FieldAccess: {
        base_ptr := cg_addr(c, e.target)
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
    case Index: {
        cwritefln(c, "\t; for index addr, cg_elem_ptr");
        return cg_elem_ptr(c, e.target, e.index)
    }
    case Deref: {
        // generate expression, as that would already be a pointer, otherwise
        // dereferencing wouldn't make sense
        ptr_val, returns := reduce_expr_to_single_value(c, cg_expr(c, e.expr));
        assert(returns);
        ptr_ty := get_type(expr_ty(e.expr))

        if ptr_ty.kind != .Pointer {
            panic("cannot dereference non-pointer type")
        }
        t := new_tmp(c);

        /* cwritefln(c, "\t%s = load %s, ptr %s",
            t, ty_to_llvm_str(c, expr_ty(e.expr)), ptr_val)*/

        // return t;
        return ptr_val;
    }
    case: gala_panic("not an lvalue")
    }
}
gen_item :: proc(c: ^CGCtx, id: ItemId) {
    switch i in get_item(id) {
    case StructDec: {
        item := i;
        cwritef(c, "%%%s = ", i.name);
        cwrite(c, "type {")
        ty :=get_type(get_ctx().item_types[id])
        for f, i in ty.structure.fields {
            debugfln("for struct %s field %d (%s) type %s",
                item.name, i, f.name,
                ty_to_llvm_str(c,f.type));
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
                debugln(i, len(fn_ty.fn.args))
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
                debugln(i, len(fn_ty.fn.args))
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
    defer mem.dynamic_arena_free_all(&arena);
    cgctx.arena = &arena
    sb : strings.Builder
    strings.builder_init(&sb)
    defer strings.builder_destroy(&sb)
    cgctx.b = &sb
    cgctx.llvm_ty = make(map[TypeId]string, allocator=get_ctx().allocator);
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

    // print result
    debugln(strings.to_string(sb))

    // write
    dir_err := os.make_directory(".gala_build")
    if dir_err != io.Error.None {
        if dir_err != .Exist {
            gala_panic("Failed make .gala_build directory:", dir_err);
        }
    }
    e := os.write_entire_file_from_string(".gala_build/a.ll", strings.to_string(sb))
    if e != io.Error.None {
        gala_panic("Failed to write to file:", e);
    }
    
    {
        // compile llvm "llc -filetype=obj a.ll -o a.o"
        p, err := os.process_start({command={"llc", "-filetype=obj",
            ".gala_build/a.ll", "-o", ".gala_build/a.o"}});
        if err != .NONE {
            gala_panic("Failed to start clang process:", err);
        }
        p_state, werr := os.process_wait(p)
        if werr != .NONE {
            gala_panic("Failed to wait for clang process:", werr);
        }
        if p_state.exit_code != 0 {
            gala_panic("Failed to compile llvm ir. exit code:", p_state.exit_code);
        }
        debugln("clang exit code:", p_state.exit_code);
    }
    {
        // link ld a.o -o a.out
        /* ld \
        /usr/lib/crt1.o \
        /usr/lib/crti.o \
        a.o \
        -lc \
        /usr/lib/crtn.o */
        p, err := os.process_start({command={"ld",
            "-dynamic-linker", "/lib64/ld-linux-x86-64.so.2",
            "/usr/lib/crt1.o",
            "/usr/lib/crti.o",
            "-lc", 
            ".gala_build/a.o",
            "/usr/lib/crtn.o",
            "-o", "a.out",
        }});
        if err != .NONE {
            gala_panic("Failed to start link (ld) process:", err);
        }
        p_state, werr := os.process_wait(p)
        if werr != .NONE {
            gala_panic("Failed to wait for link (ld) process:", werr);
        }
        if p_state.exit_code != 0 {
            gala_panic("Failed to link machine code. exit code:", p_state.exit_code);
        }
        debugln("clang exit code:", p_state.exit_code);
    }
    
    {
        // run
        p, err := os.process_start({command={"./a.out"}});
        if err != .NONE {
            gala_panic("Failed to run compiled program:", err);
        }
        p_state, werr := os.process_wait(p)
        if werr != .NONE {
            gala_panic("Failed to wait program:", werr);
        }
        debugln     ("program exit code:", p_state.exit_code);
        gala_info   ("program exit code:", p_state.exit_code);
    }

}
