package main

import "core:mem"
import "core:fmt"
import "core:os"
import "core:io"
ExprId :: distinct u32
StmtId :: distinct u32
ItemId :: distinct u32
TypeId :: distinct u32
ObjId  :: distinct u32


main :: proc() {
    data, err := os.read_entire_file("main.gala", context.allocator)
    if err != io.Error.None {
        fmt.eprintln("Failed to read file")
        os.exit(1)
    }
    defer delete(data)
    dyn_arena: mem.Dynamic_Arena
    mem.dynamic_arena_init(&dyn_arena)
    // create dynamic allocator with dynamic arena and use that, not the
    // arenas allocator
    context.temp_allocator = mem.dynamic_arena_allocator(&dyn_arena)  // ← this
    // destroy, not free
    defer mem.dynamic_arena_destroy(&dyn_arena)                        // ← prefer defer

    ctx := Context{}
    ctx.items =         make([dynamic]Item, allocator=context.temp_allocator)
    ctx.exprs =         make([dynamic]Expr, allocator=context.temp_allocator)
    ctx.stmts =         make([dynamic]Stmt, allocator=context.temp_allocator)
    ctx.objs =          make([dynamic]Object, allocator=context.temp_allocator)
    ctx.types =         make([dynamic]Type, allocator=context.temp_allocator)
    ctx.expr_objects =  make(map[ExprId]ObjId)
    ctx.expr_types =    make(map[ExprId]TypeId)
    defer delete(ctx.expr_objects)
    defer delete(ctx.expr_types)
    context.user_ptr = &ctx

    tokens := lex_file(data)
    defer delete(tokens)
    ast := parse_tokens(tokens[:])
    resolve_module_ast(&ast)
    typecheck_module(&ast)

    fmt.println("Finished parsing");
}
