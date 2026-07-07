package main

gala_panic :: proc(args: ..any) -> ! {
    fmt.println(..args)
    os.exit(1);
}
gala_panicf :: proc(f: string, args: ..any) -> ! {
    fmt.printfln(f, ..args)
    os.exit(1);
}

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
    file_name := "main.gala"
    data, err := os.read_entire_file(file_name, context.allocator)
    if err != io.Error.None {
        fmt.eprintln("Failed to read file")
        os.exit(1)
    }
    files[file_name] = string(data)
    defer delete(data)
    dyn_arena: mem.Dynamic_Arena
    mem.dynamic_arena_init(&dyn_arena)
    // create dynamic allocator with dynamic arena and use that, not the
    // arenas allocator
    context.temp_allocator = mem.dynamic_arena_allocator(&dyn_arena)  // ← this
    // destroy, not free
    defer mem.dynamic_arena_destroy(&dyn_arena)                        // ← prefer defer

    ctx := Context{}
    ctx.debug = true;
    ctx.items =         make([dynamic]Item, allocator=context.temp_allocator)
    ctx.exprs =         make([dynamic]Expr, allocator=context.temp_allocator)
    ctx.stmts =         make([dynamic]Stmt, allocator=context.temp_allocator)
    ctx.objs =          make([dynamic]Object, allocator=context.temp_allocator)
    ctx.types =         make([dynamic]Type, allocator=context.temp_allocator)
    ctx.expr_objects =  make(map[ExprId]ObjId)
    ctx.expr_types =    make(map[ExprId]TypeId)
    ctx.item_objects =    make(map[ItemId]ObjId)
    ctx.stmt_objects =    make(map[StmtId]ObjId)
    defer delete(ctx.expr_objects)
    defer delete(ctx.expr_types)
    defer delete(ctx.item_objects)
    defer delete(ctx.stmt_objects)

    ctx.current_file = file_name;
    context.user_ptr = &ctx

    tokens := lex_file(data)
    defer delete(tokens)
    ast := parse_tokens(file_name, tokens[:])
    // create base type first
    ctx.base_mod = new_module_scope();
    new_type(&ctx.base_mod, Type{name="int", kind=.Integer});
    new_type(&ctx.base_mod, Type{name="flt", kind=.Float});
    new_type(&ctx.base_mod, Type{name="void", kind=.Void});
    new_type(&ctx.base_mod, Type{name="bool", kind=.Bool});
    new_type(&ctx.base_mod, Type{name="byte", kind=.Byte});
    new_type(&ctx.base_mod, Type{name="rawptr", kind=.Pointer});
    resolve_module_ast(&ast)
    typecheck_module(&ast)
    cg_module(&ast)

    fmt.println("Finished parsing");
}
