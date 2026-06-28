package main
import "core:fmt";
TcContext :: struct {
    in_function: bool,
    fn_ret_ty: Maybe(TypeId),
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
is_untyped :: proc(t: TypeId) -> bool {
    #partial switch get_type(t).kind {
    case .UntypedFloat: return true
    case .UntypedInteger: return true
    case: return false
    }
}
compare_and_reduce_numerics :: proc(l, r: TypeId) -> (TypeId,bool) {
    if l == r do return l, true

        lk := get_type(l).kind
        rk := get_type(r).kind

        l_untyped := lk == .UntypedInteger || lk == .UntypedFloat
        r_untyped := rk == .UntypedInteger || rk == .UntypedFloat

        // Both untyped — UntypedFloat dominates
        if l_untyped && r_untyped {
            if lk == .UntypedFloat || rk == .UntypedFloat {
                return intern_type(Type{kind = .UntypedFloat}), true
            }
            return l, true // both UntypedInteger, intern guarantees same ID, already caught above
        }

        // One untyped — typed wins only if compatible
        if l_untyped {
            if lk == .UntypedFloat && rk == .Integer do panic("type mismatch: float into integer")
                if lk == .UntypedInteger && rk == .Float  do panic("type mismatch: integer into float") // or allow? up to you
                    return r, true
        }
        if r_untyped {
            if rk == .UntypedFloat && lk == .Integer do panic("type mismatch: float into integer")
                if rk == .UntypedInteger && lk == .Float  do panic("type mismatch: integer into float")
                    return l, true
        }

        // Both typed, different IDs — mismatch
        panic("type mismatch")
}
compare_and_reduce_types :: proc(l, r: TypeId) -> (TypeId, bool) {
    if is_numeric(l) && is_numeric(r) {
        return compare_and_reduce_numerics(l, r);
    }
    fmt.println(get(l), get(r));
    fmt.println((l), (r));
    panic("impl");
}
can_binop :: proc(ty: TypeId) -> bool {
    if is_numeric(ty) do return true
        return false
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
        ty, ok := compare_and_reduce_types(expr_ty(expr.left), expr_ty(expr.right));
        propagate_type(ty, expr.left); // propagate, wtf?
        propagate_type(ty, expr.right);
        assert(ok)
        assert(can_binop(ty))
        get_ctx().expr_types[e] = ty
    }
    case FnCall: {
        tc_expr(tc, expr.target);
        ty := get_type(expr_ty(expr.target));
        assert(ty.kind == .Function)
        fargs := ty.fn.args;
        if len(fargs) != len(expr.args) {
            fmt.println(len(fargs), len(expr.args))
            panic("args count for function don't match");
        }
        for i in 0..<len(fargs) {
            panic("impl")
        }
        get_ctx().expr_types[e] = ty.fn.ret_ty
    }
    case: panic("impl tc expr")
    }
}

tc_stmt :: proc(tc: ^TcContext, s: StmtId) {
    #partial switch stmt in get_stmt(s) {
    case VarDec: {
        tc_expr(tc, stmt.value)
        resolved_ty := get_obj(get_ctx().stmt_objects[s]).type;
        // if vardec doesn't have a defined type then infer
        if resolved_ty == nil {
            // set to it's expression
            resolved_ty = expr_ty(stmt.value);
            // if it's untyped then get default type
            if is_untyped(resolved_ty.(TypeId)) {
                fmt.println("it's untyped")
                t := get_untyped_default(resolved_ty.(TypeId))
                fmt.println("got:", t, get(t));
                propagate_type(t, stmt.value)
            }
            // set obj type to expr type
            resolved_ty = expr_ty(stmt.value);
            fmt.println("setting vardec type to:", get_type(resolved_ty.(TypeId)))
            get_obj(get_ctx().stmt_objects[s]).type = resolved_ty;
        } else { // otherwise if the vardec has a specified type compare
            if t, ok := compare_and_reduce_types(resolved_ty.(TypeId), expr_ty(stmt.value)); ok {
                propagate_type(t, stmt.value)
            } else {
                panic("types don't match");
            }
        }
    }
    case Return: {
        if !tc.in_function {
            panic("return stmt not it a function");
        }
        // if it has a value
        if e, ok := stmt.expr.(ExprId); ok {
            tc_expr(tc, e);
            if tc.fn_ret_ty == nil { // if function expects no value
                panic("no return value expected");
            }
            // compare return expr type with fn return type
            ty, ok := compare_and_reduce_types(expr_ty(e), tc.fn_ret_ty.(TypeId));
            assert(ok);
            propagate_type(ty, e);
        // otherwise make sure function doesn't expect a value
        } else  {
            if tc.fn_ret_ty != nil {
                panic("return value expected");
            }
        }
    }
    case Assignment: {
        tc_expr(tc, stmt.target);
        tc_expr(tc, stmt.value);
        // target must have a type
        _, tyok := get_ctx().expr_types[stmt.target]; assert(tyok);
        t, ok := compare_and_reduce_types(expr_ty(stmt.target), expr_ty(stmt.value))
        assert(ok);
        propagate_type(t, stmt.value);

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
        fn, ok := get_ctx().item_objects[id]; assert(ok);
        type := get_type(get_obj(fn).type.(TypeId));
        assert(type.kind == .Function);
        new_tc := tc^;
        new_tc.in_function = true;
        new_tc.fn_ret_ty = type.fn.ret_ty;
        tc_block(&new_tc, i.block);

    }
    case: panic("impl")
    }
}
typecheck_module :: proc(ast: ^AST) {
    tc := TcContext{fn_ret_ty=nil, in_function=false}
    for i in ast.items {
        tc_item(&tc, i);
    }
}
