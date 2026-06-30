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

CGScope :: struct {
    vars : map[string]string,
    parent: ^CGScope,
}
new_gcscope :: proc(parent: ^CGScope) -> CGScope {
    s := CGScope{}
    s.vars = make(map[string]string);
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
    case: return "ptr"; // functions are just pointers
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
            return v;
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
        t := new_tmp(c)
        v := cgscope_get(&c.scope, e.name);
        cwritefln(c, "\t%s = load %s, ptr %s",
                            t, ty_to_llvm_str(c, expr_ty(id)), v);
        return {kind=.SingleRes,v=t};
    }
    case FnCall: {
        t := cg_fn_call_target(c, e.target);
        new_t := new_tmp(c);

        fn_ty := get_type(expr_ty(e.target));
        cwritefln(c, "\t%s = call %s %s()", new_t, ty_to_llvm_str(c, fn_ty.fn.ret_ty), t);
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
cg_stmt :: proc(c: ^CGCtx, id: StmtId) {
    #partial switch s in get_stmt(id) {
    /*
        %cond = icmp eq i32 %a, %b
        br i1 %cond, label %IfEqual, label %IfUnequal
       */
    case IfElse: {
        cond := reduce_expr_to_single_value(c, cg_expr(c, s.base_con));
        ty := get_type(expr_ty(s.base_con));
        assert(ty.kind == .Integer); // must be an integer
        c.tmp_id += 1;
        comp := aprintf(c, "%%cond%d", c.tmp_id)
        cwritefln(c, "\t%s = icmp ne %s %s, 0",
            comp, ty_to_llvm_str(c, expr_ty(s.base_con)), cond)
        base_block := aprintf(c, "base_block_label%d",c.tmp_id); 
        end_label := aprintf(c, "end_label%d",c.tmp_id); 

        cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", comp, base_block, end_label);

        { // base block
            cwritefln(c, "%s:", base_block);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement in s.base_block.stmts {
                cg_stmt(c, statement);
            }
            fmt.println("freeing scope", c.scope.vars);
            free_cgscope(&c.scope)
            fmt.println("freed scope");
            c.scope = old;
            cwritefln(c, "\tbr label %%%s", end_label);
        }

        cwritefln(c, "%s:", end_label);
    }
    case VarDec:{
        // get object
        obj := get_obj(get_ctx().stmt_objects[id]);
        // gen value
        value :=  reduce_expr_to_single_value(c, cg_expr(c, s.value));
        // write name to scope
        c.scope.vars[s.name] = aprintf(c, "%%%s", s.name);
        // allocate
        cwritefln(c, "\t%s = alloca %s",c.scope.vars[s.name], 
            ty_to_llvm_str(c, obj.type.(TypeId)));
        // init
        cwritefln(c, "\tstore %s %s, ptr %s", ty_to_llvm_str(c, obj.type.(TypeId)),
            value, c.scope.vars[s.name]);
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
            cwritefln(c, "\tstore %s %s, ptr %s",
                ty_to_llvm_str(c, expr_ty(s.target)), value,
                cgscope_get(&c.scope, e.name));
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
        name := new_tmp(c);
        // set to last value
        c.scope.vars[e.name] = name;
        return aprintf(c, "%s", name);
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
        cwrite(c, "() ");
        cwriteln(c, "{");
        // entry block
        cwriteln(c, "entry:");
        for s in i.block.stmts {
            cg_stmt(c, s);
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
    for s in b.stmts {
        if _, ok := get_stmt(s).(Return); ok {
            return true
        }
    }
    return false
}
check_fn :: proc(f: FnDec) -> bool {
    if !check_rets(f.block) {
        panic("function must return at all branches")
    }
    return true
}
cgscope_get :: proc(scope: ^CGScope, v: string) -> string {
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
            cgctx.scope.vars[s.name] = aprintf(&cgctx, "@%s", s.name);
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
