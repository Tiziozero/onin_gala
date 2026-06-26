package main

import "core:os"
import "core:io"
import "core:fmt"
import "core:strings"
import "core:mem"

CGCtx :: struct {
    arena: mem.Dynamic_Arena,
    b: strings.Builder,
}

cwritef :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintf(&c.b, format, ..data)
}
cwrite :: proc(c: ^CGCtx, format: string) {
    fmt.sbprint(&c.b, format)
}
cwriteln :: proc(c: ^CGCtx, format: string) {
    fmt.sbprintln(&c.b, format);
}
cwritefln :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintfln(&c.b, format, ..data);
}
llvm_ty: map[TypeId]string
ty_to_llv_str :: proc(c: ^CGCtx, id: TypeId) -> string {
    t, ok := llvm_ty[id];
    if ok { fmt.println("type found for:", id); return t }
    fmt.println("no type for:", id);
    ty := get_type(id)
    #partial switch ty.kind {
    case .UntypedInteger: fallthrough
    case .UntypedFloat: 
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
_tmp_ssa_intex := 0
new_tmp::proc(c: ^CGCtx) -> string {
    _tmp_ssa_intex += 1;
    return fmt.aprintf("t%d",_tmp_ssa_intex, allocator=c.arena.block_allocator);
}
// returns value
cg_expr :: proc(c: ^CGCtx, id: ExprId) -> string {
    panic("impl expr")
}
cg_stmt :: proc(c: ^CGCtx, id: StmtId) {
    #partial switch s in get_stmt(id) {
    case VarDec:{
        obj := get_ctx().stmt_objects[id];
        // allocate/declare
        cwritefln(c, "%%%s = alloca %s", s.name, ty_to_llv_str(c, get_obj(obj).type.(TypeId)))
        // init
        v := cg_expr(c, s.value);
        cwritefln(c, "store %s %s, ptr %%%s", ty_to_llv_str(c, expr_ty(s.value)), v, s.name)
        panic("impl");
    }
    case:panic("impl");
    }
}
gen_item :: proc(c: ^CGCtx, id: ItemId) {
    switch i in get_item(id) {
    case FnDec: {
        objid :=get_ctx().item_objects[id]
        obj := get_ctx().objs[objid]
        fn_ty := get_type(obj.type.(TypeId))
        cwrite(c, "define ");
        if fn_ty.fn.ret_ty != nil {
            cwritef(c, "%s ", ty_to_llv_str(c, fn_ty.fn.ret_ty.(TypeId)));
        } else {
            cwrite(c,"void ");
        }
        cwritef(c, "@%s ", obj.name);
        cwrite(c, "() ");
        cwriteln(c, "{");
        cwriteln(c, "entry:");
        for s in i.block.stmts {
            cg_stmt(c, s);
        }
        cwriteln(c, "}");
    }
    case: panic("impl")
    }
}
cg_ast :: proc(c: ^CGCtx, ast: ^AST) {
    for id in ast.items {
        gen_item(c, id)
    }
}
cg_module :: proc(ast: ^AST) {
    cgctx := CGCtx{}
    mem.dynamic_arena_init(&cgctx.arena)
    strings.builder_init(&cgctx.b)
    fmt.sbprintfln(&cgctx.b, "; target info")
    fmt.sbprintfln(&cgctx.b, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"");
    fmt.sbprintfln(&cgctx.b, "target triple = \"x86_64-pc-linux-gnu\"")

    fmt.sbprintfln(&cgctx.b, "; external functions (declare, not define)")
    fmt.sbprintfln(&cgctx.b, "declare i32 @printf(ptr, ...)")
    fmt.sbprintfln(&cgctx.b, "declare ptr @malloc(i64)")
    fmt.sbprintfln(&cgctx.b, "declare void @free(ptr)")
    cg_ast(&cgctx, ast)
    fmt.println(strings.to_string(cgctx.b))
    e := os.write_entire_file_from_string("a.ll", strings.to_string(cgctx.b))
    assert(e == io.Error.None)
}
