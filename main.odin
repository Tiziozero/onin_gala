package main

gala_panic :: proc(args: ..any) -> ! {
    fmt.println(..args)
    os.exit(1);
}
gala_panicf :: proc(f: string, args: ..any) -> ! {
    fmt.printfln(f, ..args)
    os.exit(1);
}

import "core:mem/virtual"
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
    ctx := Context{}
    context.user_ptr = &ctx
    // init ctx
    // arena
    dyn_arena: virtual.Arena
    aerr := virtual.arena_init_growing(&dyn_arena)
    assert(aerr == virtual.Allocator_Error.None);
    defer virtual.arena_destroy(&dyn_arena)
    // create dynamic allocator with dynamic arena and use that, not the
    // arenas allocator
    // context.temp_allocator = mem.panic_allocator()
    get_ctx().allocator = virtual.arena_allocator(&dyn_arena)

    ctx.debug = true;
    ctx.items =         make([dynamic]Item, allocator=get_ctx().allocator)
    ctx.exprs =         make([dynamic]Expr, allocator=get_ctx().allocator)
    ctx.stmts =         make([dynamic]Stmt, allocator=get_ctx().allocator)
    ctx.objs =          make([dynamic]Object, allocator=get_ctx().allocator)
    ctx.types =         make([dynamic]Type, allocator=get_ctx().allocator)


    // refs
    // expr_types:         map[ExprId]TypeId,
    // expr_objects:       map[ExprId]ObjId,

    // item_types:         map[ItemId]TypeId,
    // item_objects:       map[ItemId]ObjId,

    // stmt_objects:       map[StmtId]ObjId,
    // stmt_types:         map[StmtId]TypeId,

    ctx.expr_types =                make(map[ExprId]TypeId, allocator=get_ctx().allocator)
    ctx.expr_objects =              make(map[ExprId]ObjId, allocator=get_ctx().allocator)

    ctx.item_types =                make(map[ItemId]TypeId, allocator=get_ctx().allocator)
    ctx.item_objects =              make(map[ItemId]ObjId, allocator=get_ctx().allocator)

    ctx.stmt_objects =              make(map[StmtId]ObjId, allocator=get_ctx().allocator)
    ctx.stmt_types =                make(map[StmtId]TypeId, allocator=get_ctx().allocator)
    ctx.expr_resolution_types =     make(map[ExprId]TypeId, allocator=get_ctx().allocator)


    ctx.spans.exprs =       make(map[ExprId]struct{file_name: string, span: Span},
                                            allocator=get_ctx().allocator)
    ctx.spans.items =       make(map[ItemId]struct{file_name: string, span: Span},
                                            allocator=get_ctx().allocator)
    ctx.spans.stmts =       make(map[StmtId]struct{file_name: string, span: Span},
                                            allocator=get_ctx().allocator)
    ctx.spans.objs_decs =   make(map[ObjId]struct{file_name: string, span: Span},
                                            allocator=get_ctx().allocator)
    get_ctx().files = make(map[string]string, allocator=get_ctx().allocator);

    // create base type first
    ctx.base_mod = new_module_scope();
    new_type(&ctx.base_mod, Type{name="int", kind=.Integer});
    new_type(&ctx.base_mod, Type{name="flt", kind=.Float});
    new_type(&ctx.base_mod, Type{name="void", kind=.Void});
    new_type(&ctx.base_mod, Type{name="bool", kind=.Bool});
    new_type(&ctx.base_mod, Type{name="byte", kind=.Byte});
    new_type(&ctx.base_mod, Type{name="rawptr", kind=.Pointer, ptr=void_type()});


    // parse main
    file_name := "main.gala"
    data, err := os.read_entire_file(file_name, context.allocator)
    if err != io.Error.None {
        fmt.eprintln("Failed to read file")
        os.exit(1)
    }
    defer delete(data)
    get_ctx().files[file_name] = cast(string)data


    ctx.current_file = file_name;

    tokens := lex_file(data)
    defer delete(tokens)

    ast := parse_tokens(file_name, tokens[:])
    resolve_module_ast(&ast)
    typecheck_module(&ast)
    cg_module(&ast)
    free_all(context.temp_allocator);

    fmt.println("Finished parsing");
}
