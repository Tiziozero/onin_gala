package main

import "core:fmt"
import "core:strings"
import "core:mem"

CGCtx :: struct {
    arena: mem.Dynamic_Arena,
    b: strings.Builder,
}

cwrite :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintf(&c.b, format, data);
}
cwriteln :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintfln(&c.b, format, data);
}
ty_to_llv_str :: proc(c: ^CGCtx, id: TypeId) -> string {
    ty := get_type(id)
    #partial switch ty.kind {
    case .UntypedInteger: fallthrough
    case .UntypedFloat: 
        panic("bug")
    case .Pointer: {
        return fmt.aprintf("ptr", allocator=c.arena.block_allocator )
    }
    case: {
        return fmt.aprintf("%s", ty.name, allocator=c.arena.block_allocator )
    }
    }
    panic("impl")
}
gen_item :: proc(c: ^CGCtx, id: ItemId) {
    switch i in get_item(id) {
    case FnDec: {
        objid :=get_ctx().item_objects[id] 
        obj := get_ctx().objs[objid]
        cwrite(c, "define");
        cwrite(c, "%s", ty_to_llv_str(c, obj.type));
    }
    case: panic("impl")
    }
}
cg_ast :: proc(c: ^CGCtx, ast: AST) {
    for id in ast.items {
        gen_item(c, id)
    }
}
cg_module :: proc(ast: AST) {
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
}
