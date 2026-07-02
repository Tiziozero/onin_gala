package main

import "core:os"
import "core:io"
import "core:fmt"
import "core:strings"
import "core:mem"

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
        panic("bug")
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
    panic("no");
}
cg_expr :: proc(c: ^CGCtx, id: ExprId) -> expr_result {
    #partial switch e in get_expr(id) {
    case Number: {
        return {kind=.Number, v=e.text};
    }
    case Binop: {
        l_v := reduce_expr_to_single_value(c, cg_expr(c, e.left))
        r_v := reduce_expr_to_single_value(c, cg_expr(c, e.right))

        // Use the OPERAND type, not expr_ty(id) — comparisons return Bool
        // but the instruction needs the type of the things being compared.
        operand_ty := expr_ty(e.left)

        op := ""
        if get_type(operand_ty).kind == .Integer {
            #partial switch e.kind {
            case .Addition:     op = "add"
            case .Subtraction:  op = "sub"
            case .Multiply:     op = "mul"
            case .Divide:       op = "sdiv" // signed div; use udiv if you track unsigned types
            case .Equal:        op = "icmp eq"
            case .NotEqual:     op = "icmp ne"
            case .LessEqual:    op = "icmp sle"
            case .GreaterEqual: op = "icmp sge"
            case: panic("impl")
            }
        } else if get_type(operand_ty).kind == .Float {
            #partial switch e.kind {
            case .Addition:     op = "fadd"
            case .Subtraction:  op = "fsub"
            case .Multiply:     op = "fmul"
            case .Divide:       op = "fdiv"
            case .Equal:        op = "fcmp oeq"
            case .NotEqual:     op = "fcmp one"
            case .LessEqual:    op = "fcmp ole"
            case .GreaterEqual: op = "fcmp oge"
            case: panic("impl")
            }
        } else if get_type(operand_ty).kind == .Void {
            dump_context(get_ctx())
            panic("can't binop voids")
        } else {
            fmt.println(get_type(operand_ty).kind)
            fmt.println(get_expr(id))
            panic("handle")
        }

        return {kind=.Binop,
            v=aprintf(c, "%s %s %s, %s", op, ty_to_llvm_str(c, operand_ty), l_v, r_v)}
    }
    case Symbol: {
        // v := cgscope_get(&c.scope, e.name);
        v := cgscope_get(&c.scope, e.name);
        #partial switch v.kind {
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
            panic("invalid object");
        }
        }
        panic("impl");
    }
    case FnCall: {
        t := cg_fn_call_target(c, e.target);
        fn_ty := get_type(expr_ty(e.target));
        new_t := new_tmp(c);
        //gen args
        args:=make([dynamic]string)
        for a, i in e.args {
            r := reduce_expr_to_single_value(c, cg_expr(c, a));
            v := aprintf(c, "%s %s", ty_to_llvm_str(c, expr_ty(a)), r);
               append(&args, v);
        }

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
        return {kind=.SingleRes, v=new_t};
    }
    case: panic("impl");
    }
}
cg_expr_old :: proc(c: ^CGCtx, id: ExprId) -> expr_result {
    #partial switch e in get_expr(id) {
    case Number: {
        return {kind=.Number, v=e.text};
    }
    case Binop: {
        ty := expr_ty(id);
        l_v := reduce_expr_to_single_value(c, cg_expr(c, e.left))
        r_v := reduce_expr_to_single_value(c, cg_expr(c, e.right))
        // get op kind
        op := ""
        if get_type(expr_ty(id)).kind == .Integer {
            #partial switch e.kind {
            case .Addition: op = "add"
            case .Subtraction: op = "sub"
            case: panic("impl")
            }
        } else if get_type(expr_ty(id)).kind == .Float {
            #partial switch e.kind {
            case .Addition: op = "fadd"
            case .Subtraction: op = "fsub"
            case: panic("impl")
            }
        } else if get_type(expr_ty(id)).kind == .Void {
            dump_context(get_ctx())
            panic("can't binop voids");
        } else {
            fmt.println(get_type(expr_ty(id)).kind)
            fmt.println(get_expr(id))
            panic("handle");
        }
        return {kind=.Binop,
            v=aprintf(c, "%s %s %s, %s", op, ty_to_llvm_str(c, ty), l_v, r_v)};
    }
    case Symbol: {
        // v := cgscope_get(&c.scope, e.name);
        v := cgscope_get(&c.scope, e.name);
        #partial switch v.kind {
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
            panic("invalid object");
        }
        }
        panic("impl");
    }
    case FnCall: {
        t := cg_fn_call_target(c, e.target);
        new_t := new_tmp(c);

        fn_ty := get_type(expr_ty(e.target));
        cwritef(c, "\t%s = call %s %s", new_t, ty_to_llvm_str(c, fn_ty.fn.ret_ty), t);
        cwrite(c, "(");
        for a, i in e.args {
            r := reduce_expr_to_single_value(c, cg_expr(c, a));
            cwritef(c, "%s %s", ty_to_llvm_str(c, expr_ty(a)), r);
            if i < len(fn_ty.fn.args) - 1 {
                fmt.println(i, len(fn_ty.fn.args))
                cwritef(c, ", ")
            }
        }
        cwriteln(c, ")");
        return {kind=.SingleRes, v=new_t};
    }
    case: panic("impl");
    }
}

reduce_expr_to_single_value :: proc(c: ^CGCtx, e: expr_result) -> string {
    switch e.kind {
    case .Invalid: panic("invalid")
    case .SingleRes: {
        return e.v
    }
    case .Number: {
        return e.v
    }
    case .Binop: {
        t := new_tmp(c)
        cwritefln(c, "\t%s = %s", t, e.v);
        return t
    }
    }
    panic("impl");
}
expr_result :: struct {
    kind: enum {Invalid, SingleRes,Binop,Number},
    v: string,
}
stmt_ends_block :: proc(stmt: StmtId) -> bool {
    #partial switch s in get(stmt) {
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
    case: panic("impl");
    }
    panic("impl");
}
cg_stmt :: proc(c: ^CGCtx, id: StmtId) {
    #partial switch s in get_stmt(id) {
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
            cond := reduce_expr_to_single_value(c, cg_expr(c, s.base_con));
            ty := get_type(expr_ty(s.base_con));
            assert(ty.kind == .Bool);
            cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", cond, base_block, next_after_base);

            cwritefln(c, "%s:", base_block);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in s.base_block.stmts {
                cg_stmt(c, statement);
                if stmt_ends_block(statement) && i != len(s.base_block.stmts) - 1 {
                    panic("nothing past will be executed");
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
            cond := reduce_expr_to_single_value(c, cg_expr(c, a.cond));
            ty := get_type(expr_ty(a.cond));
            assert(ty.kind == .Bool);
            cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", cond, alt_body_labels[i], next);

            cwritefln(c, "%s:", alt_body_labels[i]);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in a.block.stmts {
                cg_stmt(c, statement);
                if stmt_ends_block(statement) && i != len(s.base_block.stmts) - 1 {
                    panic("nothing past will be executed");
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
                    panic("nothing past will be executed");
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
        value :=  reduce_expr_to_single_value(c, cg_expr(c, s.value));
        // write name to scope
        c.scope.vars[s.name] = {.Variable, aprintf(c, "%%%s", s.name)};
        // allocate
        cwritefln(c, "\t%s = alloca %s",c.scope.vars[s.name].name, 
            ty_to_llvm_str(c, obj.type.(TypeId)));
        // init
        cwritefln(c, "\tstore %s %s, ptr %s", ty_to_llvm_str(c, obj.type.(TypeId)),
            value, c.scope.vars[s.name].name);
    }
    case Return: {
        if e, ok := s.expr.(ExprId); ok {
            r := reduce_expr_to_single_value(c, cg_expr(c, e));
            cwritefln(c, "\tret %s %s", ty_to_llvm_str(c, expr_ty(e)), r)
        } else {
            cwriteln(c, "\tret void")
        }
    }
    case Assignment: {
        #partial switch e in get_expr(s.target) {
        case Symbol: {
            value :=  reduce_expr_to_single_value(c, cg_expr(c, s.value));
            t := cgscope_get(&c.scope, e.name);
            assert(t.kind == .Variable);
            cwritefln(c, "\tstore %s %s, ptr %s",
                ty_to_llvm_str(c, expr_ty(s.target)), value,
                t.name);
        }
        case: panic("impl");
        }
    }
    case:panic("impl");
    }
}
cg_lvalue :: proc(c: ^CGCtx, id: ExprId) -> string {
    #partial switch e in get_expr(id) {
    case Symbol: {
        panic("impl");
    }
    case: panic("impl")
    }
    panic("impl")
}
gen_item :: proc(c: ^CGCtx, id: ItemId) {
    switch i in get_item(id) {
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
                panic("nothing past will be executed");
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
        panic("function must return at all branches")
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
    panic("doesn't exist")
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

    fmt.sbprintfln(cgctx.b, "; external functions (declare, not define)")
    fmt.sbprintfln(cgctx.b, "declare i32 @printf(ptr, ...)")
    fmt.sbprintfln(cgctx.b, "declare ptr @malloc(i64)")
    fmt.sbprintfln(cgctx.b, "declare void @free(ptr)")
    for i in ast.items {
        switch s in get_item(i) {
        case FnDec: { 
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
