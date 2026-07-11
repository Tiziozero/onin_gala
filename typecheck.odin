package main

TcContext :: struct {
    in_function: bool,
    fn_ret_ty: Maybe(TypeId),
}
expr_ty :: proc(id: ExprId) -> TypeId {
    t, ok  := get_ctx().expr_types[id];
    if !ok {
        debugln(id, "has no type")
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
compare_and_reduce_numerics :: proc(l, r: TypeId) -> (TypeId, bool, string) {
    if l == r do return l, true, ""
    lk := get_type(l).kind
    rk := get_type(r).kind
    l_untyped := lk == .UntypedInteger || lk == .UntypedFloat
    r_untyped := rk == .UntypedInteger || rk == .UntypedFloat

    // Both untyped — UntypedFloat dominates
    if l_untyped && r_untyped {
        if lk == .UntypedFloat || rk == .UntypedFloat {
            return intern_type(Type{kind = .UntypedFloat}), true, ""
        }
        return l, true, "" // both UntypedInteger, intern guarantees same ID, already caught above
    }

    // One untyped — typed wins only if compatible
    if l_untyped {
        if lk == .UntypedFloat && rk == .Integer {
            return TypeId(0), false, "type mismatch: float into integer"
        }
        if lk == .UntypedInteger && rk == .Float {
            return TypeId(0), false, "type mismatch: integer into float" // or allow? up to you
        }
        return r, true, ""
    }
    if r_untyped {
        if rk == .UntypedFloat && lk == .Integer {
            return TypeId(0), false, "type mismatch: float into integer"
        }
        if rk == .UntypedInteger && lk == .Float {
            return TypeId(0), false, "type mismatch: integer into float"
        }
        return l, true, ""
    }

    // Both typed, different IDs — mismatch
    return TypeId(0), false, "type mismatch"
}
compare_and_reduce_types :: proc(l, r: TypeId) -> (TypeId, bool, string) {
    if l == r do return l, true, ""
    if is_numeric(l) && is_numeric(r) {
        return compare_and_reduce_numerics(l, r);
    }
    debugln(get(l));
    debugln(get(r));
    debugln((l), (r));
    //dump_context(get_ctx());
    return 0, false, "types don't match"
}
can_binop :: proc(ty: TypeId) -> bool {
    if is_numeric(ty) do return true
        return false
}
can_cast_to :: proc(target_id, to_id: TypeId) -> bool {
    target := get_type(target_id);
    to := get_type(to_id);
    #partial switch target.kind {
    case .Integer: {
        #partial switch to.kind {
        case .Integer, .Float, .Byte, .Bool: return true;
        }
        return false
    }
    case .Float: {
        #partial switch to.kind {
        case .Integer, .Float: return true;
        }
        return false
    }
    case .Bool: {
    }
    }
    panic("impl")
}
tc_expr :: proc(tc: ^TcContext, e: ExprId) {
    debugln("tc expr:", e)

    switch expr in get(e) {
    case FieldAccess: {
        tc_expr(tc, expr.target);
        target_tid := expr_ty(expr.target);
        target_ty := get_type(target_tid);
        assert(target_ty.kind == .Struct);
        fields := target_ty.structure.fields;
        for f in fields {
            if f.name == expr.field {
                get_ctx().expr_types[e] = f.type;
                return; // ok
            }
        }
        highlight_lines(get_span(e).span);
        gala_panic("Field %s doesn't exist in type %s.", expr.field, target_ty.name);
    }
    case StructLit: {
        tid := get_ctx().expr_struct_types[e]
        s := get_type(tid)
        for sf in s.structure.fields {
            f := expr.fields[sf.name].expr
            tc_expr(tc, f);
            r, ok, err := compare_and_reduce_types(sf.type, expr_ty(f))
            if !ok {
                span := expr.fields[sf.name].span
                highlight_lines(span)
                gala_panic("Type error:", err);
            }
            propagate_type(r, f);
        }
        get_ctx().expr_types[e]=tid
    }
    case ZeroInit: {
        get_ctx().expr_types[e]=intern_type({kind=.ZeroInit})
    }
    case Cast: {
        tc_expr(tc, expr.target)
        to := get_ctx().expr_cast_types[e]
        if is_untyped(expr_ty(expr.target)) {
            t := get_untyped_default(expr_ty(expr.target));
            propagate_type(t, expr.target);
        }
        if !can_cast_to(expr_ty(expr.target), to) {
            highlight_lines(get_span(e).span);
            gala_panic("can't cast expression to desired type")
        }
        get_ctx().expr_types[e] = to
    }
    case Symbol: {
        debugln(e, "is a symbol", get(e))
        obj := get_ctx().expr_objects[e];
        get_ctx().expr_types[e] = get_obj(obj).type.(TypeId)
    }
    case Number: {
        debugln("is a number")
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
        debugln("is a binop")

        tc_expr(tc, expr.left);
        tc_expr(tc, expr.right);
        ty, ok, s := compare_and_reduce_types(expr_ty(expr.left), expr_ty(expr.right));
        if !ok {
            highlight_lines(get_span(e).span)
            gala_panic(s)
        }

        propagate_type(ty, expr.left); // propagate, wtf?
        propagate_type(ty, expr.right);

        #partial switch expr.kind {
        case .Addition:     fallthrough
        case .Subtraction:  fallthrough
        case .Multiply:     fallthrough
        case .Divide: {
            if !can_binop(ty) {
                highlight_lines(get_span(e).span);
                gala_panic("can't perform a binop on these two expressions");
            }
        }
        case:
            bool_ty, ok := get_ctx().base_mod.types["bool"]; assert(ok);
            ty = bool_ty;
        }
        get_ctx().expr_types[e] = ty
    }
    case FnCall: {
        tc_expr(tc, expr.target);
        ty := get_type(expr_ty(expr.target));
        assert(ty.kind == .Function)
        fargs := ty.fn.args;
        if len(fargs) != len(expr.args) {
            debugln(len(fargs), len(expr.args))
            gala_panic("args count for function don't match");
        }
        for i in 0..<len(fargs) {
            earg := expr.args[i];
            farg := fargs[i];
            tc_expr(tc, earg);
            r, ok, s := compare_and_reduce_types(farg.type, expr_ty(earg));
            if !ok {
                highlight_lines(get_span(e).span);
                gala_panic(s);
            }
            assert(r == farg.type); // should always match
            propagate_type(r, earg);
        }
        get_ctx().expr_types[e] = ty.fn.ret_ty
    }
    case: gala_panic("impl tc expr")
    }
}

tc_stmt :: proc(tc: ^TcContext, s: StmtId) {
    switch stmt in get_stmt(s) {
    case ExprId: tc_expr(tc, stmt);
    case IfElse: {
        tc_expr(tc, stmt.base_con);
        // make it numeric
        if get_type(expr_ty(stmt.base_con)).kind != .Bool {
            debugln(get_type(expr_ty(stmt.base_con)))
            gala_panic("not a bool?");
        }
        tc_block(tc, stmt.base_block);
        for a in stmt.alt {
            tc_expr(tc, a.cond);
            // make it numeric
            if get_type(expr_ty(a.cond)).kind != .Bool {
                debugln(get_type(expr_ty(a.cond)))
                gala_panic("not a bool?");
            }
            tc_block(tc, a.block);
        }
        if stmt.has_else_block {
            tc_block(tc, stmt.else_block);
        }
    }
    case VarDec: {
        tc_expr(tc, stmt.value)
        resolved_ty := get_obj(get_ctx().stmt_objects[s]).type;
        // if vardec doesn't have a defined type then infer
        if resolved_ty == nil {
            // set to it's expression
            resolved_ty = expr_ty(stmt.value);
            // if it's untyped then get default type
            if is_untyped(resolved_ty.(TypeId)) {
                debugln("it's untyped")
                t := get_untyped_default(resolved_ty.(TypeId))
                debugln("got:", t, get(t));
                propagate_type(t, stmt.value)
            } else if get(resolved_ty.(TypeId)).kind == .ZeroInit {
                highlight_lines(get_span(s).span);
                gala_panic("can't have zero initialiser here. Type required");
            }
            // set obj type to expr type
            resolved_ty = expr_ty(stmt.value);
            debugln("setting vardec type to:", get_type(resolved_ty.(TypeId)))
            get_obj(get_ctx().stmt_objects[s]).type = resolved_ty;
        } else { // otherwise if the vardec has a specified type compare
            expected_type := resolved_ty.(TypeId)
            if t, ok, s := compare_and_reduce_types(expected_type, expr_ty(stmt.value)); ok {
                propagate_type(t, stmt.value)
            } else {
                gala_panic("types don't match");
            }
        }
    }
    case Return: {
        if !tc.in_function {
            gala_panic("return stmt not it a function");
        }
        // if it has a value
        if e, ok := stmt.expr.(ExprId); ok {
            tc_expr(tc, e);
            if tc.fn_ret_ty == nil { // if function expects no value
                gala_panic("no return value expected");
            }
            // compare return expr type with fn return type
            ty, ok, s := compare_and_reduce_types(expr_ty(e), tc.fn_ret_ty.(TypeId));
            if !ok {
                highlight_lines(get_span(e).span);
                gala_panic(s);
            }
            propagate_type(ty, e);
        // otherwise make sure function doesn't expect a value
        } else  {
            if tc.fn_ret_ty != nil {
                if get_type(tc.fn_ret_ty.(TypeId)).kind == .Void {
                    // returning voiud
                } else { // not in function
                    gala_panic("return value expected");
                }
            }
        }
    }
    case Assignment: {
        tc_expr(tc, stmt.target);
        tc_expr(tc, stmt.value);
        // target must have a type
        _, tyok := get_ctx().expr_types[stmt.target]; assert(tyok);
        t, ok, err := compare_and_reduce_types(expr_ty(stmt.target), expr_ty(stmt.value))
        if !ok {
            highlight_lines(get_span(s).span);
            gala_panic(err);
        }
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
    case StructDec: {
        // ok?
    }
    case ExternFnDec: {
        // ok ig?
    }
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
propagate_type :: proc(ty: TypeId, expr: ExprId) {
    debugln("propagating:", get_type(ty), "to", get_expr(expr));
    switch e in get_expr(expr) {
    case FieldAccess: {
        return // already typed
    }
    case StructLit: {
        return // already has type
    }
    case ZeroInit: {
    }
    case Cast: { // should have a fixed type
        return
    }
    case Binop: {
        propagate_type(ty, e.left)
        propagate_type(ty, e.right)
    }
    case Number: {
    }
    case Symbol: { // should have a fixed type
        return
    }
    case FnCall: { // should have a fixed type
        return
    }
    case: panic("impl");
    }
    // set to all
    get_ctx().expr_types[expr] = ty;
}
