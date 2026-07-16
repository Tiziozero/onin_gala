package main

import "core:slice"
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
    case .C_Integer: return true
    case .Byte: return true
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
        if lk == .UntypedFloat && rk == .C_Integer {
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
        if rk == .UntypedFloat && lk == .C_Integer {
            return TypeId(0), false, "type mismatch: float into integer"
        }
        if rk == .UntypedInteger && lk == .Float {
            return TypeId(0), false, "type mismatch: integer into float"
        }
        return l, true, ""
    }

    // Both typed, different IDs — mismatch
    return TypeId(0), false, "type mismatch (different types)"
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
type_size :: proc(t: TypeId) -> int {
    ty := get_type(t)
    #partial switch ty.kind {
    case .C_Integer, .Integer, .Float, .Pointer: return 8
    case .Rune: return 4
    case .Byte, .Bool: return 1
    case .FixedSizeArray:
        return ty.fixed_size_array.size * type_size(ty.fixed_size_array.type)
    case .Slice:
        return 16 // { ptr, i64 } per ty_to_llvm_str
    case .Struct:
        // naive sum — see caveat below
        total := 0
        for f in ty.structure.fields {
            total += type_size(f.type)
        }
        return total
    }
    panic("impl")
}
can_transmute_to :: proc(target_id, to_id: TypeId) -> bool {
    if type_size(target_id) != type_size(to_id) {
        return false
    }
    return true
}
can_cast_to :: proc(target_id, to_id: TypeId) -> bool {
    target := get_type(target_id);
    to := get_type(to_id);

    if is_int_kind(target.kind) {
        #partial switch to.kind {
        case .C_Integer, .Integer, .Float, .Byte, .Bool, .Rune, .Pointer: return true
        }
        return false
    }

    #partial switch target.kind {
    case .Float: {
        #partial switch to.kind {
        case .C_Integer, .Integer, .Float, .Byte, .Rune: return true;
        }
        return false
    }
    case .Pointer: {
        #partial switch to.kind {
        case .Pointer, .C_Integer, .Integer: return true
        }
        return false
    }
    }

    // Struct, Slice, FixedSizeArray, Function, Void, ZeroInit, Untyped*, Invalid:
    // no single-instruction cast exists for these. Array/slice->pointer decay,
    // struct field extraction, etc. happen elsewhere, not here.
    debugln(target)
    debugln(to)
    panic("impl")
}
is_array_type :: proc(t: TypeId) -> bool {
    #partial switch get_type(t).kind {
    case .FixedSizeArray: return true
    case .Slice, .String: return true
    }
    return false
}
can_index :: proc(t: TypeId) -> bool {
    #partial switch get_type(t).kind {
    case .C_Integer, .Integer: return true
    }
    return false
}
get_array_base_type :: proc(t: TypeId) -> (TypeId, bool) {
    ty := get_type(t)
    #partial switch ty.kind {
    case .FixedSizeArray: {
        return ty.fixed_size_array.type, true
    }
    case .Slice: {
        return ty.slice.type, true
    }
    case .String: return byte_type(), true
    }
    panic("can't index")
}
can_reference :: proc(id: ExprId) -> bool {
    #partial switch e in get_expr(id) {
    case Symbol, Index, FieldAccess: {
        return true; // unless proven otherwise ig
    }
    }
    return false;
}
can_compare :: proc(ty: Type) -> bool {
    #partial switch ty.kind {
    case .C_Integer, .Integer:
        return true;

    case .Float:
        return true;

    case .Rune:
        return true;

    case .Byte:
        return true;

    case .Bool:
        return true; // only for == and != ideally

    case .Pointer:
        return true; // only equality ideally

    case:
        return false;
    }
}
tc_expr :: proc(tc: ^TcContext, id: ExprId) {
    switch e in get_expr(id) {
    case UnNot: {
        tc_expr(tc, e.expr);
        if get(expr_ty(e.expr)).kind != .Bool {
            highlight_lines(get_span_expr(id).span);
            gala_panic("Expr type must be bools.");
        }
        get_ctx().expr_types[id] = ty_from_name("bool")
    }
    case BoolLitFalse, BoolLitTrue: {
        get_ctx().expr_types[id] = ty_from_name("bool")
    }
    case String: {
        get_ctx().expr_types[id] = intern_type({kind=.String})
    }
    case Deref: {
        tc_expr(tc, e.expr);
        t := expr_ty(e.expr);
        if get(t).kind != .Pointer {
            highlight_lines(get_span_expr(id).span);
            gala_panic("Can't dereference expression if type %s.", tts(t));
        }
        if get_type(get_type(t).ptr).kind == .Void {
            highlight_lines(get_span_expr(id).span);
            gala_panic("Can't dereference expression if type %s.", tts(t));
        }
        get_ctx().expr_types[id] = get_type(t).ptr;
    }
    case Reference: {
        tc_expr(tc, e.expr);
        if !can_reference(e.expr) {
            highlight_lines(get_span_expr(id).span);
            gala_panic("Can't reference expression.");
        }
        t := Type{ kind=.Pointer, ptr=expr_ty(e.expr)}
        get_ctx().expr_types[id] = intern_type(t);
    }
    case TakeSlice: {
        tc_expr(tc, e.target)
        target_ty := expr_ty(e.target)

        if !is_array_type(target_ty) {
            gala_panic("can't index type:", tts(target_ty))
        }

        tc_expr(tc, e.start)
        s_ty := expr_ty(e.start)
        tc_expr(tc, e.end)
        e_ty := expr_ty(e.end)


        if is_untyped(s_ty) {
            if get(s_ty).kind == .UntypedInteger {
                s_ty = integer_type()
                get_ctx().expr_types[e.start] = s_ty
            } else {
                gala_panic("array index must be an integer")
            }
        }
        if is_untyped(e_ty) {
            if get(e_ty).kind == .UntypedInteger {
                e_ty = integer_type()
                get_ctx().expr_types[e.end] = e_ty
            } else {
                gala_panic("array index must be an integer")
            }
        }

        if !can_index(s_ty) {
            gala_panic("can't use type:", get_type(s_ty), "to index an array")
        }
        if !can_index(e_ty) {
            gala_panic("can't use type:", get_type(e_ty), "to index an array")
        }

        ty, ok := get_array_base_type(target_ty)
        assert(ok)
        slice_t := Type {
            kind=.Slice,
            slice={type=ty},
        }
        tid := intern_type(slice_t);
        get_ctx().expr_types[id] = tid
    }
    case Index: {
        tc_expr(tc, e.target)
        target_ty := expr_ty(e.target)

        if !is_array_type(target_ty) {
            gala_panic("can't index type:", tts(target_ty))
        }

        tc_expr(tc, e.index)
        i_ty := expr_ty(e.index)

        if is_untyped(i_ty) {
            if get(i_ty).kind == .UntypedInteger {
                i_ty = integer_type()
                get_ctx().expr_types[e.index] = i_ty
            } else {
                gala_panic("array index must be an integer")
            }
        }

        if !can_index(i_ty) {
            gala_panic("can't use type:", get_type(i_ty), "to index an array")
        }

        ty, ok := get_array_base_type(target_ty)
        assert(ok)

        get_ctx().expr_types[id] = ty
    }
    case FixedSizeArray: {
        t := Type{};
        t.kind = .FixedSizeArray
        t.fixed_size_array.type = get_ctx().expr_resolution_types[id]
        t.fixed_size_array.size = e.size;
        tid := intern_type(t);
        get_ctx().expr_types[id] = tid;
    }
    case FieldAccess: {
        tc_expr(tc, e.target);
        target_tid := expr_ty(e.target);
        target_ty := get_type(target_tid);
        assert(target_ty.kind == .Struct);
        fields := target_ty.structure.fields;
        for f in fields {
            if f.name == e.field {
                get_ctx().expr_types[id] = f.type;
                return; // ok
            }
        }
        highlight_lines(get_span(id).span);
        gala_panic("Field %s doesn't exist in type %s.", e.field, target_ty.name);
    }
    case StructLit: {
        tid := get_ctx().expr_resolution_types[id]
        s := get_type(tid)
        for sf in s.structure.fields {
            f := e.fields[sf.name].expr
            tc_expr(tc, f);
            r, ok, err := compare_and_reduce_types(sf.type, expr_ty(f))
            if !ok {
                span := e.fields[sf.name].span
                highlight_lines(span)
                gala_panic("Type error:", err);
            }
            propagate_type(r, f);
        }
        get_ctx().expr_types[id]=tid
    }
    case ZeroInit: {
        get_ctx().expr_types[id]=intern_type({kind=.ZeroInit})
    }
    case Transmute: {
        tc_expr(tc, e.target)
        to := get_ctx().expr_resolution_types[id]
        if is_untyped(expr_ty(e.target)) {
            t := get_untyped_default(expr_ty(e.target));
            propagate_type(t, e.target);
        }
        if !can_transmute_to(expr_ty(e.target), to) {
            highlight_lines(get_span(id).span);
            debugln("target:", tts(expr_ty(e.target)), "to:", tts(to));
            gala_panic("can't transmute expression to desired type")
        }
        get_ctx().expr_types[id] = to
    }
    case Cast: {
        tc_expr(tc, e.target)
        to := get_ctx().expr_resolution_types[id]
        if is_untyped(expr_ty(e.target)) {
            t := get_untyped_default(expr_ty(e.target));
            propagate_type(t, e.target);
        }
        if !can_cast_to(expr_ty(e.target), to) {
            highlight_lines(get_span(id).span);
            debugln(get(expr_ty(e.target)).kind, get(to).kind);
            gala_panic("can't cast expression to desired type")
        }
        get_ctx().expr_types[id] = to
    }
    case Symbol: {
        debugln(e, "is a symbol", get_expr(id))
        obj := get_ctx().expr_objects[id];
        get_ctx().expr_types[id] = get_obj(obj).type.(TypeId)
    }
    case Number: {
        debugln("is a number")
        // check if it's an untyped float or int
        for c in e.text {
            if c == '.' {
                get_ctx().expr_types[id] = intern_type(Type{kind=.UntypedFloat})
                return
            }
        }
        get_ctx().expr_types[id] = intern_type(Type{kind=.UntypedInteger})
    }
    case Len: {
        tc_expr(tc, e.target);
        if get(expr_ty(e.target)).kind != .Slice &&
                get(expr_ty(e.target)).kind != .String &&
                get(expr_ty(e.target)).kind != .FixedSizeArray {
            highlight_lines(get_span_expr(id).span);
            gala_panicf("Can not take len of expression of type %s.",
                tts(expr_ty(e.target)));
        }
        get_ctx().expr_types[id] = integer_type()
    }
    case Sizeof: {
        get_ctx().expr_types[id] = intern_type({kind=.UntypedInteger})
    }
    case Binop: {
        tc_expr(tc, e.left);
        tc_expr(tc, e.right);

        left_ty  := expr_ty(e.left);
        right_ty := expr_ty(e.right);

        ty, ok, s := compare_and_reduce_types(left_ty, right_ty);
        if !ok {
            highlight_lines(get_span(id).span)
            gala_panic(s)
        }
        if is_untyped(ty) {
            ty = get_untyped_default(ty);
        }
        propagate_type(ty, e.left);
        propagate_type(ty, e.right);

        switch e.kind {
        case .Addition, .Subtraction, .Multiply, .Divide: {
            if !can_binop(ty) {
                highlight_lines(get_span(id).span);
                gala_panic("can't perform a binop on these two expressions");
            }

            propagate_type(ty, e.left);
            propagate_type(ty, e.right);

            get_ctx().expr_types[id] = ty;
        }

        case .Equal, .NotEqual, .LessEqual, .GreaterEqual: {
            // force operands to resolve first
            propagate_type(ty, e.left);
            propagate_type(ty, e.right);

            if !can_compare(get_type(ty)^) {
                highlight_lines(get_span(id).span);
                gala_panic("can't compare these two expressions");
            }

            
            bool_ty := ty_from_name("bool");

            get_ctx().expr_types[id] = bool_ty;
        }
        }
    }
    case FnCall: {
        tc_expr(tc, e.target);
        ty := get_type(expr_ty(e.target));
        assert(ty.kind == .Function)
        fargs := ty.fn.args;
        debugln("fn ty:",expr_ty(e.target), ty, )
        debugln("expr:", get(e.target));
        debugln("expr sym:", get(get_ctx().expr_objects[e.target]));
        if ty.fn.is_variadic {
            if len(e.args) < len(fargs) {
                highlight_lines(get_span(id).span);
                gala_panicf("args count for function don't match (expected at least %d, got %d).",
                    len(fargs), len(e.args));
            }
        } else {
            if len(fargs) != len(e.args) {
                highlight_lines(get_span(id).span);
                gala_panicf("args count for function don't match (expected %d, got %d).",
                    len(fargs), len(e.args));
            }
        }
        for a in e.args {
            tc_expr(tc, a);
            /* if is_untyped(expr_ty(a)) {
                get_ctx().expr_types[a] = get_untyped_default(expr_ty(a))
            } */
        }
        for i in 0..<len(fargs) {
            earg := e.args[i];
            farg := fargs[i];
            r, ok, s := compare_and_reduce_types(farg.type, expr_ty(earg));
            if !ok {
                debugln(ty.fn);
                highlight_lines(get_span(earg).span);
                gala_panicf("Type Mismatch: %s (expected %s, got %s)",
                    s, tts(farg.type), tts(expr_ty(earg)));
            }
            assert(r == farg.type); // should always match
            propagate_type(r, earg);
        }
        // default for rest
        for i in len(fargs)..<len(e.args) {
            a := e.args[i]
            if is_untyped(expr_ty(a)) {
                get_ctx().expr_types[a] = get_untyped_default(expr_ty(a))
            }
        }
        get_ctx().expr_types[id] = ty.fn.ret_ty
    }
    case: gala_panic("impl tc expr")
    }
}

tc_stmt :: proc(tc: ^TcContext, s: StmtId) {
    switch stmt in get_stmt(s) {
    case WhileLoop: {
        tc_expr(tc, stmt.cond);
        if is_untyped(expr_ty(stmt.cond)) {
            t := get_untyped_default(expr_ty(stmt.cond));
            propagate_type(t, stmt.cond);
        }
        if get_type(expr_ty(stmt.cond)).kind != .Bool {
            highlight_lines(get_span(stmt.cond).span);
            gala_panic("Expression is not of type boolean.");
        }
        tc_block(tc, stmt.block);
    }
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
            sid := s;
            if t, ok, s := compare_and_reduce_types(expected_type, expr_ty(stmt.value)); ok {
                propagate_type(t, stmt.value)
            } else {
                highlight_lines(get_span(sid).span)
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
        debugln(type)
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
    case UnNot: {
        return // bool
    }
    case BoolLitFalse, BoolLitTrue: return // already typed
    case Len: {
        return // always an int
    }
    // just porpatae as they're untyped int by default
    case Sizeof: {
    }
    case String:  {
        return; // once a string, always a string (for now at least)
    }
    case Reference: {
        return; // should be typed, no?
    }
    case Deref: {
        return; // should be typed, no?
    }
    case TakeSlice: {
        return // already typed
    }
    case Index: {
        return // already typed
    }
    case FixedSizeArray: {
        return // already typed
    }
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
    case Transmute: {
        return // already should have a type
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
