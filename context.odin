package main

Context :: struct {
    exprs:              [dynamic]Expr,
    stmts:              [dynamic]Stmt,
    items:              [dynamic]Item,
    types:              [dynamic]Type,
    objs :              [dynamic]Object,
    // refs
    expr_types:         map[ExprId]TypeId,
    expr_objects:       map[ExprId]ObjId,
    item_objects:       map[ItemId]ObjId,
    stmt_objects:       map[StmtId]ObjId,

    // for casts
    expr_cast_types:    map[ExprId]TypeId,

    base_mod:           ModuleScope,
}
new_stmt :: proc(stmt:=Stmt{}) -> StmtId {
    ctx := cast(^Context)context.user_ptr
    append(&ctx.stmts, stmt);
    return StmtId(len(ctx.stmts)-1)
}
new_expr :: proc(expr:=Expr{}) -> ExprId {
    ctx := cast(^Context)context.user_ptr
    append(&ctx.exprs, expr);
    return ExprId(len(ctx.exprs)-1)
}
new_item :: proc(item:=Item{}) -> ItemId {
    ctx := cast(^Context)context.user_ptr
    append(&ctx.items, item);
    return ItemId(len(ctx.items)-1)
}
get :: proc {
    get_expr,
    get_stmt,
    get_item,
    get_obj,
    get_type,
}
get_ctx :: proc() -> ^Context {
    return cast(^Context)context.user_ptr;
}
get_expr :: proc(id: ExprId) -> ^Expr {
    ctx := cast(^Context)context.user_ptr
    assert(int(id) < len(ctx.exprs));
    return &ctx.exprs[id]
}
get_stmt :: proc(id: StmtId) -> ^Stmt {
    ctx := cast(^Context)context.user_ptr
    assert(int(id) < len(ctx.stmts));
    return &ctx.stmts[id]
}
get_item :: proc(id: ItemId) -> ^Item {
    ctx := cast(^Context)context.user_ptr
    assert(int(id) < len(ctx.items));
    return &ctx.items[id]
}
get_type :: proc(id: TypeId) -> ^Type {
    ctx := cast(^Context)context.user_ptr
    assert(int(id) < len(ctx.types));
    return &ctx.types[id]
}
get_obj :: proc(id: ObjId) -> ^Object {
    ctx := cast(^Context)context.user_ptr
    assert(int(id) < len(ctx.objs));
    return &ctx.objs[id]
}
