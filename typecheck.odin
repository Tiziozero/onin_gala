package main
import "core:fmt";
TcContext :: struct {
    fn: Maybe(TypeId),
}
expr_ty :: proc(id: ExprId) -> TypeId {
    t, ok  := get_ctx().expr_types[id];
    if !ok {
        fmt.println(id, "has no type")
    }
    assert(ok);
    return t
}
is_numeric :: proc(t: TypeId) -> bool {
    #partial switch get_type(t).kind {
    case .UntypedFloat: return true
    case .UntypedInteger: return true
    case .Float: return true
    case .Integer: return true
    case: return false
    }
}
is_numeric_untyped :: proc(t: TypeId) -> bool {
    #partial switch get_type(t).kind {
    case .UntypedFloat: return true
    case .UntypedInteger: return true
    case: return false
    }
}
compare_and_reduce_numerics :: proc(l, r: TypeId) -> TypeId {
    if l == r do return l

    lk := get_type(l).kind
    rk := get_type(r).kind

    l_untyped := lk == .UntypedInteger || lk == .UntypedFloat
    r_untyped := rk == .UntypedInteger || rk == .UntypedFloat

    // Both untyped — UntypedFloat dominates
    if l_untyped && r_untyped {
        if lk == .UntypedFloat || rk == .UntypedFloat {
            return intern_type(Type{kind = .UntypedFloat})
        }
        return l // both UntypedInteger, intern guarantees same ID, already caught above
    }

    // One untyped — typed wins only if compatible
    if l_untyped {
        if lk == .UntypedFloat && rk == .Integer do panic("type mismatch: float into integer")
        if lk == .UntypedInteger && rk == .Float  do panic("type mismatch: integer into float") // or allow? up to you
        return r
    }
    if r_untyped {
        if rk == .UntypedFloat && lk == .Integer do panic("type mismatch: float into integer")
        if rk == .UntypedInteger && lk == .Float  do panic("type mismatch: integer into float")
        return l
    }

    // Both typed, different IDs — mismatch
    panic("type mismatch")
}
compare_and_reduce_types :: proc(l, r: TypeId) -> TypeId {
    if is_numeric(l) && is_numeric(r) {
        return compare_and_reduce_numerics(l, r);
    }
    fmt.println(get(l), get(r));
    fmt.println((l), (r));
    panic("impl");
}
tc_expr :: proc(tc: ^TcContext, e: ExprId) {
    fmt.println("tc expr:", e)

    switch expr in get(e) {
    case Symbol: {
        fmt.println("is a symbol")
        obj := get_ctx().expr_objects[e];
             get_ctx().expr_types[e] = get_obj(obj).type.(TypeId)
    }
    case Number: {
        fmt.println("is a number")
        // check if it's an untyped float or int
        for c in expr.text {
            if c == '.' {
                get_ctx().expr_types[e] = intern_type(Type{kind=.UntypedFloat})
                return
            }
        }
        get_ctx().expr_types[e] = intern_type(Type{kind=.UntypedInteger})
    }
    case Binop:{
        fmt.println("is a binop")
        tc_expr(tc, expr.left);
        tc_expr(tc, expr.right);
        ty := compare_and_reduce_types(expr_ty(expr.left), expr_ty(expr.right));
    }
    case: panic("impl tc expr")
    }
}
tc_stmt :: proc(tc: ^TcContext, s: StmtId) {
    switch stmt in get_stmt(s) {
    case VarDec: {
        tc_expr(tc, stmt.value)
    }
    case: panic("impl");
    }
}
tc_block :: proc(tc: ^TcContext, b: Block) {
    for s in b.stmts {
        tc_stmt(tc, s)
    }
}
tc_item :: proc(tc: ^TcContext, id: ItemId) {
    item := get_item(id)
    switch i in item {
    case FnDec: {
        prev_tc_fn := tc.fn;
        fn, ok := get_ctx().item_objects[id]; assert(ok);
        tc.fn = get_obj(fn).type;
        tc_block(tc, i.block);
        tc.fn = prev_tc_fn;
    }
    case: panic("impl")
    }
}
typecheck_module :: proc(ast: ^AST) {
    tc := TcContext{fn=nil}
    for i in ast.items {
        tc_item(&tc, i);
    }
}
