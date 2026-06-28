package main
import "core:fmt"
dump_context :: proc(ctx: ^Context) {
    fmt.println("==== CONTEXT DUMP ====")

    dump_types(ctx)
    dump_objects(ctx)
    dump_exprs(ctx)
    dump_stmts(ctx)
    dump_items(ctx)

    fmt.println("======================")
}
dump_types :: proc(ctx: ^Context) {
    fmt.println("\n-- TYPES --")

    for t, i in ctx.types {
        fmt.printf("[%d] %s\n", i, t.name)

        switch t.kind {
        case .Void: 
            fmt.println("    kind: Void")
        case .Invalid:
            fmt.println("    kind: Invalid")

        case .Integer, .Float, .Rune, .Byte, .UntypedInteger, .UntypedFloat:
            fmt.printf("    kind: %v\n", t.kind)

        case .Pointer:
            fmt.printf("    kind: Pointer -> %d (%s)\n",
                t.ptr,
                type_name(ctx, t.ptr),
            )

        case .Function:
            fmt.println("    kind: Function")
            fmt.println("    args:")

            for a in t.fn.args {
                fmt.printf("        %s : %s\n",
                    a.name,
                    type_name(ctx, a.type),
                )
            }

            fmt.printf("    ret: %s\n", type_name(ctx, t.fn.ret_ty))
        }
    }
}
dump_objects :: proc(ctx: ^Context) {
    fmt.println("\n-- OBJECTS --")

    for o, i in ctx.objs {
        fmt.printf("[%d] %s\n", i, o.name)

        if ty, ok := o.type.(TypeId); ok {
            fmt.printf("    type: %s (%d)\n",
                type_name(ctx, ty),
                ty,
            )
        } else {
            fmt.println("    type: <none>")
        }
    }
}
dump_exprs :: proc(ctx: ^Context) {
    fmt.println("\n-- EXPRS --")

    for id, ty in ctx.expr_types {
        fmt.printf("Expr %d -> type %s\n",
            id,
            type_name(ctx, ty),
        )

        if obj, ok := ctx.expr_objects[id]; ok {
            fmt.printf("    obj: %s (%d)\n",
                obj_name(ctx, obj),
                obj,
            )
        }
    }
}
dump_stmts :: proc(ctx: ^Context) {
    fmt.println("\n-- STMTS --")

    for id, obj in ctx.stmt_objects {
        fmt.printf("Stmt %d -> obj %s (%d)\n",
            id,
            obj_name(ctx, obj),
            obj,
        )
    }
}
dump_items :: proc(ctx: ^Context) {
    fmt.println("\n-- ITEMS --")

    for id, obj in ctx.item_objects {
        fmt.printf("Item %d -> obj %s (%d)\n",
            id,
            obj_name(ctx, obj),
            obj,
        )
    }
}
type_name :: proc(ctx: ^Context, id: TypeId) -> string {
    if id >= 0 && int(id) < len(ctx.types) {
        return ctx.types[id].name
    }
    return "<invalid-type>"
}

obj_name :: proc(ctx: ^Context, id: ObjId) -> string {
    if id >= 0 && int(id) < len(ctx.objs) {
        return ctx.objs[id].name
    }
    return "<invalid-obj>"
}
dump_context_brief :: proc(ctx: ^Context) {
    fmt.printf(
        "types=%d objs=%d exprs=%d stmts=%d items=%d\n",
        len(ctx.types),
        len(ctx.objs),
        len(ctx.expr_types),
        len(ctx.stmt_objects),
        len(ctx.item_objects),
    )
}
