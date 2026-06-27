package main

import "core:math/rand"
import "core:math"
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
}
new_gcscope :: proc(parent: ^CGScope) -> CGScope {
    s := CGScope{}
    s.vars = make(map[string]string);
    return s;
}
free_cgscope :: proc(s: ^CGScope) {
    free(&s.vars);
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
ty_to_llv_str :: proc(c: ^CGCtx, id: TypeId) -> string {
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
    case: {
        fmt.println("ty name:", ty.name, ty.kind);
        s := fmt.aprintf("%s", ty.name, allocator=c.arena.block_allocator )
        llvm_ty[id]=s
        return s
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
cg_expr :: proc(c: ^CGCtx, id: ExprId) -> string {
    #partial switch e in get_expr(id) {
    case Number: {
        return e.text;
        // ty := expr_ty(id);
        // tmp := new_tmp(c);
        // cwritefln(c, "\t%t  = %s %s", tmp, ty_to_llv_str(c, ty), e.text);
        // return tmp
    }
    case Binop: {
        ty := expr_ty(id);
        l := cg_expr(c, e.left);
        r := cg_expr(c, e.right);
        tmp := new_tmp(c)
        op := ""
        #partial switch e.kind {
        case .Addition: op = "add"
        case .Subtraction: op = "sub"
        case: panic("impl")
        }
        // -> "    %t = add i32 4, %t2"
        cwritefln(c, "\t%s = %s %s %s, %s", tmp, op, ty_to_llv_str(c, ty), l, r);
        return tmp
    }
    case Symbol: {
        t := new_tmp(c);
        cwritefln(c, "\t%s = load %s, ptr %%%s", t, ty_to_llv_str(c, expr_ty(id)), e.name);
        return t;
    }
    case: panic("impl");
    }
}
old_cg_stmt :: proc(c: ^CGCtx, id: StmtId) {
    #partial switch s in get_stmt(id) {
    case VarDec:{
        obj := get_ctx().stmt_objects[id];
        // allocate/declare
        cwritefln(c, "\t%%%s = alloca %s", s.name, ty_to_llv_str(c, get_obj(obj).type.(TypeId)))
        // init
        v := cg_expr(c, s.value);
        cwritefln(c, "\tstore %s %s, ptr %%%s", ty_to_llv_str(c, expr_ty(s.value)), v, s.name)
    }
    case Return: {
        if e, ok := s.expr.(ExprId); ok {
            t := cg_expr(c, e);
            cwritefln(c, "\tret %s %s", ty_to_llv_str(c, expr_ty(e)), t)
        } else {
            cwriteln(c, "\tret void")
        }
    }
    case:panic("impl");
    }
}
cg_stmt :: proc(c: ^CGCtx, id: StmtId) {
    #partial switch s in get_stmt(id) {
    case VarDec:{
        obj := get_ctx().stmt_objects[id];
        // init
         sname := new_tmp(c);
        v := cg_expr(c, s.value);
        cwritefln(c, "\t%%%s = %s %s", sname, ty_to_llv_str(c, expr_ty(s.value)), v)
        c.scope.vars[s.name]=sname;
    }
    case Return: {
        if e, ok := s.expr.(ExprId); ok {
            t := cg_expr(c, e);
            cwritefln(c, "\tret %s %s", ty_to_llv_str(c, expr_ty(e)), t)
        } else {
            cwriteln(c, "\tret void")
        }
    }
    case Assignment: {
    }
    case:panic("impl");
    }
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
        if fn_ty.fn.ret_ty != nil {
            cwritef(c, "%s ", ty_to_llv_str(c, fn_ty.fn.ret_ty.(TypeId)));
        } else {
            cwrite(c,"void ");
        }
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



    fmt.sbprintfln(cgctx.b, "; target info")
    fmt.sbprintfln(cgctx.b, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"");
    fmt.sbprintfln(cgctx.b, "target triple = \"x86_64-pc-linux-gnu\"")

    fmt.sbprintfln(cgctx.b, "; external functions (declare, not define)")
    fmt.sbprintfln(cgctx.b, "declare i32 @printf(ptr, ...)")
    fmt.sbprintfln(cgctx.b, "declare ptr @malloc(i64)")
    fmt.sbprintfln(cgctx.b, "declare void @free(ptr)")
    cg_ast(&cgctx, ast)
    fmt.println(strings.to_string(sb))
    e := os.write_entire_file_from_string("a.ll", strings.to_string(sb))
    assert(e == io.Error.None)
    p, err := os.process_start({command={"clang", "-o", "a.out", "a.ll"}});
    assert(err == .NONE);
    p_state, werr := os.process_wait(p)
    assert(err == .NONE);
    fmt.println("clang exit code:", p_state.exit_code);
    
    p, err = os.process_start({command={"./a.out"}});
    assert(err == .NONE);
    p_state, werr = os.process_wait(p)
    assert(err == .NONE);
    fmt.println("program exit code:", p_state.exit_code);

}
