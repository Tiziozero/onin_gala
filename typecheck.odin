package main

import "core:slice"
import "core:strings"

TcContext :: struct {
    in_function: bool,
    fn_ret_ty: Maybe(TypeId),
    in_loop: Maybe(StmtId),
    generic_items: ^[dynamic]ItemId,
    generic_exprs: ^[dynamic]ExprId,
}
// one concrete instantiation of a generic function
FnVersion :: struct {
    llvm_fn_name: string,   // filled in by codegen
    params:       []TypeId, // concrete param types (the version's identity)
    ret_ty:       TypeId,
    item:         ItemId,   // the clone made for this version
}

// which version of which function a call expr resolved to
FnVersionRef :: struct {
    fn:  TypeId, // function types aren't interned, so this is unique per function
    idx: int,    // index into get_type(fn).fn.versions
}
// Finds the version with exactly these concrete params, or adds it.
// Type ids are interned, so comparing ids is enough.
get_or_add_fn_version :: proc(fn_tid: TypeId, params: []TypeId, ret_ty: TypeId) -> (idx: int, added: bool) {
    // fetch fresh each time, nothing here holds a pointer across calls
    f := &get_type(fn_tid).fn

    search: for v, i in f.versions {
        if len(v.params) != len(params) do continue
        for p, j in v.params {
            if p != params[j] do continue search
        }
        return i, false
    }

    owned := make([]TypeId, len(params), get_ctx().allocator)
    copy(owned, params)
    append(&f.versions, FnVersion{params = owned, ret_ty = ret_ty})
    return len(f.versions) - 1, true
}
expr_ty :: proc(id: ExprId) -> TypeId {
    t, ok  := get_ctx().expr_types[id];
    if !ok {
        debugln(get(id))
        gala_panic(id, "has no type")
    }
    assert(ok);
    return t
}
// ---- type compatibility ----
// Identity is types_equal (types.odin). On top of that the only implicit
// things are: untyped literals, ZeroInit, and boxing into `any`.
//   assignable   a value of type `got` into a slot of type `expected`
//   unify_binop  the operand type of a binary operator

// ZeroInit can become any type that has a value to zero.
can_zero_init :: proc(k: TypeKind) -> bool {
    #partial switch k {
    case .Void, .Invalid, .UntypedInteger, .UntypedFloat, .Any: return false
    }
    return true
}

reduce_numerics :: proc(l, r: TypeId) -> (TypeId, bool, string) {
    if l == r do return l, true, ""

    lk := get_type(l).kind
    rk := get_type(r).kind

    l_untyped := is_numeric_untyped(l)
    r_untyped := is_numeric_untyped(r)

    // both untyped: UntypedFloat dominates
    if l_untyped && r_untyped {
        if lk == .UntypedFloat || rk == .UntypedFloat {
            return intern_type(Type{kind = .UntypedFloat}), true, ""
        }
        return intern_type(Type{kind = .UntypedInteger}), true, ""
    }

    // untyped on one side: it takes the typed side's type
    if l_untyped {
        if lk == .UntypedFloat && (is_integer(r) || is_byte_like(r)) {
            return TypeId(0), false, "type mismatch: float into integer"
        }
        return r, true, ""
    }
    if r_untyped {
        if rk == .UntypedFloat && (is_integer(l) || is_byte_like(l)) {
            return TypeId(0), false, "type mismatch: float into integer"
        }
        return l, true, ""
    }

    return TypeId(0), false, "type mismatch (different types)"
}

// pointer <-> pointer must be the same type; pointer <-> integer is offset
// math (result keeps the pointer's type, float offsets are rejected).
// Callers route here only when at least one side is a pointer.
reduce_pointers :: proc(l, r: TypeId) -> (TypeId, bool, string) {
    if l == r do return l, true, ""

    if is_pointer(l) && is_pointer(r) {
        if types_equal(l, r) do return l, true, ""
        return TypeId(0), false, "type mismatch: incompatible pointer types"
    }

    ptr, other := l, r
    if is_pointer(r) {
        ptr, other = r, l
    }
    if is_float(other) || get_type(other).kind == .UntypedFloat {
        return TypeId(0), false, "type mismatch: float offset into pointer"
    }
    if is_integer(other) || is_numeric_untyped(other) {
        return ptr, true, ""
    }
    return TypeId(0), false, "type mismatch: pointer with non-integer operand"
}

// Operand types of a binary operator.
unify_binop :: proc(l, r: TypeId) -> (TypeId, bool, string) {
    lk := get_type(l).kind
    rk := get_type(r).kind

    if lk == .ZeroInit || rk == .ZeroInit {
        return TypeId(0), false, "a zero initialiser can't be used in an expression"
    }
    if l == r do return l, true, ""

    if is_pointer(l) || is_pointer(r) do return reduce_pointers(l, r)
    if is_numeric(l) && is_numeric(r) do return reduce_numerics(l, r)

    if types_equal(l, r) do return l, true, ""
    if lk == .Function && rk == .Function {
        return TypeId(0), false, "function types don't match"
    }
    return TypeId(0), false, "types don't match"
}

// A value of type `got` into a slot of type `expected` (initialiser,
// assignment, argument, return, literal element). Returns the type to
// propagate into the value; for everything except `any` that is `expected`.
//   ZeroInit       -> any type with a value to zero (not `any`)
//   untyped number -> a typed numeric (float into integer is an error);
//                     an untyped integer may also become a pointer (`p = 0`)
//   anything       -> `any` (boxing); untyped numbers box as their default type
//   otherwise      -> types_equal. `any` never converts back implicitly.
assignable :: proc(expected, got: TypeId) -> (TypeId, bool, string) {
    ek := get_type(expected).kind
    gk := get_type(got).kind

    if gk == .ZeroInit {
        if !can_zero_init(ek) {
            return TypeId(0), false, "a zero initialiser needs a concrete type here"
        }
        return expected, true, ""
    }
    if expected == got do return expected, true, ""

    if ek == .Any {
        if gk == .Void {
            return TypeId(0), false, "can't use a value of type void"
        }
        if is_numeric_untyped(got) do return get_untyped_default(got), true, ""
        return got, true, ""
    }

    if is_numeric_untyped(got) {
        if is_numeric_typed(expected) {
            if gk == .UntypedFloat && !is_float(expected) {
                return TypeId(0), false, "type mismatch: float into integer"
            }
            return expected, true, ""
        }
        if gk == .UntypedInteger && is_pointer(expected) {
            return expected, true, ""
        }
    }

    if is_pointer(expected) != is_pointer(got) {
        return TypeId(0), false, "type mismatch: pointers and non-pointers don't convert implicitly (use cast)"
    }
    if types_equal(expected, got) do return expected, true, ""
    if ek == .Function && gk == .Function {
        return TypeId(0), false, "function types don't match"
    }
    return TypeId(0), false, "types don't match"
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
    case .Pointer: {
        // can't index through ^any or rawptr: there's no element type
        k := get_type(ty.ptr).kind
        if k == .Any || k == .Void {
            return TypeId(0), false
        }
        return ty.ptr, true
    }
    }
    return TypeId(0), false
}
can_reference :: proc(id: ExprId) -> bool {
    #partial switch e in get_expr(id) {
    case Symbol, Index, FieldAccess: {
        return true; // unless proven otherwise ig
    }
    }
    return false;
}
// things that can sit on the left of `=`
can_assign_to :: proc(id: ExprId) -> bool {
    #partial switch e in get_expr(id) {
    case Symbol, Index, FieldAccess, Deref: {
        return true
    }
    }
    return false
}
can_equal :: proc(id: TypeId, op: BinopKind) -> bool {
    t := get_type(id)

    if is_integer(id)   do return true
    if is_float(id)     do return true
    if is_byte_like(id) do return true

    #partial switch t.kind {
    case .Bool, .Pointer, .String:
        return true
    }

    if is_pointer(id) && (op == .Addition ||
        op==.Subtraction || op == .NotEqual || op == .Equal) {
        return true;
    }
    return false
}
can_order :: proc(id: TypeId) -> bool {
    return is_integer(id) || is_float(id) || is_byte_like(id) || is_pointer(id)
}
mark_arg :: proc(arg: ^FnCallArg, param_ty: TypeId, r: TypeId) {
    earg := arg.expr;
    if get(param_ty).kind == .Any {
        t := expr_ty(earg)
        if get_type(t).kind == .ZeroInit {
            highlight_lines(get_span(earg))
            gala_panic("Can't pass a zero initialiser as `any`: it has no type.")
        }
        // if it's untyped (because target is "any" or other valid untyped targets)
        if is_untyped(t) {
            propagate_type(get_untyped_default(t), earg)
        }
        arg.needs_boxing = true;
        arg.box_type = expr_ty(earg);
    } else {
        assert(r == param_ty); // should always match
        propagate_type(r, earg);
    }
}

// Function types whose parameter defaults have already been checked.
// tc_default_args is reached from several places (the module pre-pass, a
// FnLit, every call), so it must only do the work once per function.
default_args_done: map[TypeId]bool

// Type-checks the parameter defaults of a function type, so a bad default is
// reported at the declaration rather than at some far-away call site.
//
// A default is stored as a call to a hidden function (see make_default_thunk),
// and typing a call only needs the callee's signature, so this doesn't depend
// on globals having been typed yet.
//
// For `name := expr` parameters the type isn't written anywhere, so it is
// inferred here from the written expression (untyped literals take their
// default type, like a local `x := 1`), then patched into the parameter, the
// parameter's object (so the body sees it) and the hidden function's return
// type. This is why it has to run before anything that uses the function:
// typecheck_module runs it for module-level fns in a first pass, FnLit runs it
// before checking its body, and FnCall runs it on its callee.
tc_default_args :: proc(tc: ^TcContext, fn_type_id: TypeId) {
    if default_args_done[fn_type_id] do return
    default_args_done[fn_type_id] = true

    fn_ty := get_type(fn_type_id)
    for a, i in fn_ty.fn.args {
        def, has_default := a.default.(ExprId)
        if !has_default do continue

        if a.inferred {
            src := a.default_src.(ExprId)
            tc_expr(tc, src)

            t := expr_ty(src)
            // check these first: is_untyped() is true for ZeroInit too, and
            // there's no default type to give it
            kind := get_type(t).kind
            if kind == .ZeroInit || kind == .Void {
                highlight_lines(get_span(src))
                gala_panicf("Can't infer the type of parameter \"%s\" from its default value.", a.name)
            }
            if is_untyped(t) {
                t = get_untyped_default(t)
                propagate_type(t, src)
            }

            call := get_expr(def).(FnCall)
            thunk_obj := get_obj(get_ctx().expr_objects[call.target])
            get_ctx().types[thunk_obj.type.(TypeId)].fn.ret_ty = t
            get_ctx().types[fn_type_id].fn.args[i].type = t
            get_obj(a.obj).type = t

            // type the call only now that the hidden function returns `t`
            tc_expr(tc, def)
            continue
        }

        tc_expr(tc, def)
        _, ok, err := assignable(a.type, expr_ty(def))
        if !ok {
            highlight_lines(get_span(def))
            gala_panicf("Default value doesn't match the type of parameter \"%s\": %s (expected %s, got %s)",
                a.name, err, tts(a.type), tts(expr_ty(def)))
        }
    }
}

// Puts a call's arguments into parameter order, for non-variadic callees.
// Positional arguments fill parameters from the left, `name = expr` ones fill
// the parameter with that name, and anything left over takes its default.
// The result has one entry per parameter and no names, so everything
// downstream (including codegen) sees an ordinary full-arity positional call.
order_call_args :: proc(id: ExprId, args: [dynamic]FnCallArg, params: []Arg) -> [dynamic]FnCallArg {
    ordered := make([dynamic]FnCallArg, len(params), allocator=get_ctx().allocator)
    filled := make([]bool, len(params), allocator=get_ctx().allocator)

    for a, i in args {
        idx := i
        if len(a.name) > 0 {
            idx = -1
            for p, j in params {
                if p.name == a.name {
                    idx = j
                    break
                }
            }
            if idx < 0 {
                highlight_lines(get_ctx().current_file, a.name_span)
                gala_panicf("Function has no parameter named \"%s\".", a.name)
            }
        } else if i >= len(params) {
            highlight_lines(get_span(id))
            gala_panicf("args count for function don't match (expected at most %d, got %d).",
                len(params), len(args))
        }
        // covers named-twice and a positional landing on a named one (`f(b=1, 2)`)
        if filled[idx] {
            if len(a.name) > 0 {
                highlight_lines(get_ctx().current_file, a.name_span)
            } else {
                highlight_lines(get_span(a.expr))
            }
            gala_panicf("Parameter \"%s\" is given more than once.", params[idx].name)
        }
        ordered[idx] = a
        ordered[idx].name = ""
        filled[idx] = true
    }

    for p, i in params {
        if filled[i] do continue
        def, has_default := p.default.(ExprId)
        if !has_default {
            highlight_lines(get_span(id))
            gala_panicf("Missing argument \"%s\" (it has no default value).", p.name)
        }
        ordered[i] = FnCallArg{expr = def}
    }
    return ordered
}

tc_expr :: proc(tc: ^TcContext, id: ExprId) {
    switch e in get_expr(id) {
    case TypeIdOf: {
        _, syntactic := e.t.(TypeSpecifier)
        if !syntactic && !e.names_type {
            ex := e.expr.(ExprId)
            tc_expr(tc, ex)
            t := expr_ty(ex)
            if get_type(t).kind == .ZeroInit {
                highlight_lines(get_span(ex))
                gala_panic("Can't take the type_id of a zero initialiser: it has no type.")
            }
            // type_id(1) is i64, like `x := 1`
            if is_untyped(t) {
                t = get_untyped_default(t)
                propagate_type(t, ex)
            }
            // codegen reads the id from here, same as for the type form
            get_ctx().expr_resolution_types[id] = t
        }
        get_ctx().expr_types[id] = intern_type(Type{kind=.UntypedInteger})
    }
    case UnNegative: {
        tc_expr(tc, e.expr);
        t := expr_ty(e.expr)
        if !is_numeric(t) {
            highlight_lines(get_span_expr(id));
            gala_panic("Can't negate a non-numeric expression.");
        }
        get_ctx().expr_types[id] = t
    }
    case UnNot: {
        tc_expr(tc, e.expr);
        if get(expr_ty(e.expr)).kind != .Bool {
            highlight_lines(get_span_expr(id));
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
            highlight_lines(get_span_expr(id));
            gala_panicf("Can't dereference expression of type %s.", tts(t));
        }
        if get_type(get_type(t).ptr).kind == .Void {
            highlight_lines(get_span_expr(id));
            gala_panicf("Can't dereference expression of type %s.", tts(t));
        }
        get_ctx().expr_types[id] = get_type(t).ptr;
    }
    case Reference: {
        tc_expr(tc, e.expr);
        if !can_reference(e.expr) {
            highlight_lines(get_span_expr(id));
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

        if !e.empty_start {
            tc_expr(tc, e.start)
            s_ty := expr_ty(e.start)

            if is_untyped(s_ty) {
                if get(s_ty).kind == .UntypedInteger {
                    s_ty = integer_type()
                    propagate_type(s_ty, e.start)
                } else {
                    gala_panic("array index must be an integer")
                }
            }

            if !is_valid_index_type(s_ty) {
                highlight_lines(get_span(id))
                gala_panic("can't use type:", tts(s_ty), "to index an array")
            }
        }
        if !e.empty_end {
            tc_expr(tc, e.end)
            e_ty := expr_ty(e.end)
            if is_untyped(e_ty) {
                if get(e_ty).kind == .UntypedInteger {
                    e_ty = integer_type()
                    propagate_type(e_ty, e.end)
                } else {
                    gala_panic("array index must be an integer")
                }
            }
            if !is_valid_index_type(e_ty) {
                highlight_lines(get_span(id))
                gala_panic("can't use type:", tts(e_ty), "to index an array")
            }
        }

        ty, ok := get_array_base_type(target_ty)
        if !ok {
            highlight_lines(get_span(e.target));
            gala_panic("Can't get index:", tts(target_ty))
        }
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

        if !can_be_index(target_ty) {
            gala_panic("can't index type:", tts(target_ty))
        }

        tc_expr(tc, e.index)
        i_ty := expr_ty(e.index)

        if is_untyped(i_ty) {
            if get(i_ty).kind == .UntypedInteger {
                i_ty = integer_type()
                propagate_type(i_ty, e.index)
            } else {
                gala_panic("array index must be an integer")
            }
        }

        if !is_valid_index_type(i_ty) {
            highlight_lines(get_span(id))
            gala_panic("can't use type:", tts(i_ty), "to index an array")
        }

        ty, ok := get_array_base_type(target_ty)
        if !ok {
            highlight_lines(get_span(e.target));
            gala_panic("Can't get index:", tts(target_ty))
        }
        if get(ty).kind == .Void || get(ty).kind == .Any {
            highlight_lines(get_span(e.target));
            gala_panic("Can't index with base:", tts(target_ty))
        }

        get_ctx().expr_types[id] = ty
    }
    case FixedSizeArray: {
        // CHANGED: check every initialiser element against the element type
        elem_ty := get_ctx().expr_resolution_types[id]

        for el in e.initialiser {
            tc_expr(tc, el)
            r, ok, err := assignable(elem_ty, expr_ty(el))
            if !ok {
                highlight_lines(get_span(el))
                gala_panic("Type error:", err)
            }
            propagate_type(r, el)
        }

        t := Type{};
        t.kind = .FixedSizeArray
        t.fixed_size_array.type = elem_ty
        t.fixed_size_array.size = e.size;
        tid := intern_type(t);
        get_ctx().expr_types[id] = tid;
    }
    case FieldAccess: {
        tc_expr(tc, e.target);
        target_tid := expr_ty(e.target);
        target_ty := get_type(target_tid);
        if target_ty.kind != .Struct {
            highlight_lines(get_span(id));
            gala_panic("can't access field of object of type:", tts(target_tid))
        }
        fields := target_ty.structure.fields;
        for f in fields {
            if f.name == e.field {
                get_ctx().expr_types[id] = f.type;
                return; // ok
            }
        }
        highlight_lines(get_span(id));
        gala_panicf("Field %s doesn't exist in type %s.", e.field, target_ty.name);
    }
    case StructLit: {
        tid := get_ctx().expr_resolution_types[id]
        s := get_type(tid)
        for sf in s.structure.fields {
            f := e.fields[sf.name].expr
            tc_expr(tc, f);
            r, ok, err := assignable(sf.type, expr_ty(f))
            if !ok {
                span := e.fields[sf.name].span
                highlight_lines(get_ctx().current_file, span)
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
            highlight_lines(get_span(id));
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
            highlight_lines(get_span(id));
            debugln(get(expr_ty(e.target)).kind, get(to).kind);
            gala_panic("can't cast expression to desired type")
        }
        get_ctx().expr_types[id] = to
    }
    case Symbol: {
        obj := get_ctx().expr_objects[id];
        // a global declared with `:=` has no type until its own initialiser
        // has been checked, so using one before that (a later global, or
        // itself) lands here with a nil type.
        t, has_type := get_obj(obj).type.(TypeId)
        if !has_type {
            highlight_lines(get_span(id))
            gala_panicf("\"%s\" is used before its type is known (a global's initialiser can only use globals declared before it).", e.name)
        }
        get_ctx().expr_types[id] = t
    }
    case Number: {
        // untyped float if it has a '.', otherwise untyped int (decimal, 0x.., 0b..)
        if is_float_literal(e.text) {
            get_ctx().expr_types[id] = intern_type(Type{kind=.UntypedFloat})
            return
        }
        get_ctx().expr_types[id] = intern_type(Type{kind=.UntypedInteger})
    }
    case Len: {
        tc_expr(tc, e.target);
        if get(expr_ty(e.target)).kind != .Slice &&
                get(expr_ty(e.target)).kind != .String &&
                get(expr_ty(e.target)).kind != .FixedSizeArray {
            highlight_lines(get_span_expr(id));
            gala_panicf("Can not take len of expression of type %s.",
                tts(expr_ty(e.target)));
        }
        get_ctx().expr_types[id] = intern_type({kind=.UntypedInteger});
    }
    case Sizeof: {
        get_ctx().expr_types[id] = intern_type({kind=.UntypedInteger})
    }
    case Binop: {
        tc_expr(tc, e.left);
        tc_expr(tc, e.right);

        left_ty  := expr_ty(e.left);
        right_ty := expr_ty(e.right);

        ty, ok, s := unify_binop(left_ty, right_ty);
        if !ok {
            highlight_lines(get_span(id))
            gala_panic(s, tts(left_ty), "vs", tts(right_ty))
        }
        /*if is_untyped(ty) {
            ty = get_untyped_default(ty);
        }*/
        propagate_type(ty, e.left);
        propagate_type(ty, e.right);

        switch e.kind {
        case .Addition, .Subtraction, .Multiply, .Divide, .Modulo: {
            // pointer arithmetic: `ptr +- int`, `int + ptr`, `ptr - ptr`.
            // not `ptr + ptr` and not `int - ptr`.
            if is_pointer(right_ty) {
                bad := false
                if is_pointer(left_ty) {
                    bad = e.kind == .Addition
                } else {
                    bad = e.kind != .Addition
                }
                if bad {
                    highlight_lines(get_span(id))
                    gala_panic("invalid pointer arithmetic.")
                }
            }
            if !can_binop(ty, e.kind) {
                highlight_lines(get_span(id));
                gala_panicf("can't perform a binop on these two expressions. (%s)", tts(ty));
            }
            if e.kind == .Modulo {
                k := get(ty).kind
                // untyped integers (`7 % 3`) are fine; they get a concrete
                // integer type later when they're propagated into a slot
                if !is_int_kind(k) && k != .UntypedInteger {
                    debugln(tts(ty))
                    highlight_lines(get_span(id))
                    gala_panic("can't take modulo of non-integer numbers.")
                }
            }

            propagate_type(ty, e.left);
            propagate_type(ty, e.right);
            check_binop_post :: proc(id: ExprId, ty: TypeId, op: BinopKind) -> bool {
                #partial switch e in get(id) {
                case Binop:
                    return can_binop(ty, e.kind) &&
                        check_binop_post(e.left, ty, e.kind) &&
                        check_binop_post(e.right, ty, e.kind)
                }
                return true
            }
            if !check_binop_post(id, ty, e.kind) { // check post
                highlight_lines(get_span(id))
                gala_panic("can't binop expr types.");
            }

            get_ctx().expr_types[id] = ty;
        }
        case .NotEqual, .Equal: {
            if is_untyped(ty) {
                ty = get_untyped_default(ty);
                // force operands to resolve first
                propagate_type(ty, e.left);
                propagate_type(ty, e.right);
            }

            if !can_equal(ty, e.kind) {
                highlight_lines(get_span(id));
                gala_panic("can't compare these two expressions");
            }
            check_binop_post :: proc(id: ExprId, ty: TypeId, op: BinopKind) -> bool {
                #partial switch e in get(id) {
                case Binop:
                    return can_equal(ty, e.kind) &&
                        check_binop_post(e.left, ty, e.kind) &&
                        check_binop_post(e.right, ty, e.kind)
                }
                return true
            }
            if !check_binop_post(id, ty, e.kind) { // check post
                highlight_lines(get_span(id))
                gala_panic("can't binop expr types.");
            }


            bool_ty := ty_from_name("bool");
            get_ctx().expr_types[id] = bool_ty;
        }
        case .LessEqual, .GreaterEqual, .Less, .Greater: {
            if is_untyped(ty) {
                ty = get_untyped_default(ty);
            }
            propagate_type(ty, e.left);
            propagate_type(ty, e.right);

            if !can_order(ty) {
                highlight_lines(get_span(id));
                gala_panic("can't order these two expressions");
            }
            check_binop_post :: proc(id: ExprId, ty: TypeId, op: BinopKind) -> bool {
                #partial switch e in get(id) {
                case Binop:
                    return can_order(ty) &&
                        check_binop_post(e.left, ty, e.kind) &&
                        check_binop_post(e.right, ty, e.kind)
                }
                return true
            }
            if !check_binop_post(id, ty, e.kind) { // check post
                highlight_lines(get_span(id))
                gala_panic("can't binop expr types.");
            }

            bool_ty := ty_from_name("bool");
            get_ctx().expr_types[id] = bool_ty;
        }
        case .BitAnd, .BitOr, .BitXor, .ShiftLeft, .ShiftRight: {
            if is_untyped(ty) {
                ty = get_untyped_default(ty)
            }
            propagate_type(ty, e.left);
            propagate_type(ty, e.right);

            if !is_integer(ty) && !is_byte_like(ty) {
                highlight_lines(get_span(id));
                gala_panic("bitwise operators require integer or byte operands");
            }

            get_ctx().expr_types[id] = ty;
        }
        case .LogicalAnd, .LogicalOr: {
            if get_type(ty).kind != .Bool {
                highlight_lines(get_span(id));
                gala_panic("logical operators require boolean operands");
            }
            propagate_type(ty, e.left);
            propagate_type(ty, e.right);
            get_ctx().expr_types[id] = ty;
        }
        }
    }
    case FnCall: {
        tc_expr(tc, e.target);
        fn_tid := expr_ty(e.target)
        if get_type(fn_tid).kind != .Function {
            highlight_lines(get_span(e.target))
            gala_panicf("Can't call a value of type %s.", tts(fn_tid))
        }

        // Read the signature only now: typing can intern types, which may move
        // the type table and leave an earlier pointer dangling.
        ty := get_type(fn_tid);
        fargs := ty.fn.args;
        declared_var_ty := ty.fn.variadic_ty
        is_variadic := ty.fn.is_variadic
        is_generic := ty.fn.is_generic
        declared_ret := ty.fn.ret_ty   // copied: substitution below can intern types

        // make sure inferred parameter types are known before reading them
        tc_default_args(tc, fn_tid)

        has_named := false
        for a in e.args {
            if len(a.name) > 0 do has_named = true
        }

        for a in e.args {
            tc_expr(tc, a.expr);
        }

        call_args := e.args
        if is_variadic {
            // defaults and variadics can't be combined (see parse_args_dec),
            // so every fixed parameter has to be passed positionally
            if has_named {
                highlight_lines(get_span(id));
                gala_panic("Named arguments can't be used when calling a variadic function.")
            }
            if len(e.args) < len(fargs) {
                highlight_lines(get_span(id));
                gala_panicf("args count for function don't match (expected at least %d, got %d).",
                    len(fargs), len(e.args));
            }
        } else {
            // reorder named args and fill in defaults, then write the
            // full-arity call back (`e` is a copy of the union payload)
            call_args = order_call_args(id, e.args, fargs)
            new_call := e
            new_call.args = call_args
            get_ctx().exprs[id] = Expr(new_call)
        }

        // Concrete parameter types for this call, the variadic element type and
        // the return type. Generic: inferred from the arguments, then the
        // matching version is found or created.
        param_tys := make([]TypeId, len(fargs), context.temp_allocator)
        ret_ty: TypeId
        var_ty: TypeId

        if !is_generic {
            for farg, i in fargs do param_tys[i] = farg.type
            var_ty = declared_var_ty
            ret_ty = declared_ret
        } else {
            bound := infer_generic_bindings(id, call_args, fn_tid)
            for farg, i in fargs {
                param_tys[i] = gen_subst(farg.type, bound, id)
            }
            if is_variadic {
                var_ty = gen_subst(declared_var_ty, bound, id)
            }
            ret_ty = gen_subst(declared_ret, bound, id)

            // the variadic element is part of the version key (goes last)
            key_tys := param_tys
            if is_variadic {
                key_tys = make([]TypeId, len(param_tys) + 1, context.temp_allocator)
                copy(key_tys, param_tys)
                key_tys[len(param_tys)] = var_ty
            }
            idx, added := get_or_add_fn_version(fn_tid, key_tys, ret_ty)
            if added {
                debugln("NEW VARIATION FOR GENERIC FUNCRTION!")
                MAX_GENERIC_VERSIONS :: 64
                if len(get_type(fn_tid).fn.versions) > MAX_GENERIC_VERSIONS {
                    highlight_lines(get_span(id))
                    gala_panic("Generic instantiation limit reached; this looks like infinite recursion (e.g. f<T> instantiating f<^T>).")
                }
            }
            get_ctx().expr_fn_version[id] = FnVersionRef{fn = fn_tid, idx = idx}
        }

        for i in 0..<len(fargs) {
            earg := call_args[i].expr;
            expected := param_tys[i]
            r, ok, s := assignable(expected, expr_ty(earg));
            if !ok {
                debugln(get(expected));
                highlight_lines(get_span(earg));
                gala_panicf("Type Mismatch: %s (expected %s, got %s)",
                    s, tts(expected), tts(expr_ty(earg)));
            }
            mark_arg(&call_args[i], expected, r);
        }

        // variadic tail, checked against the concrete element type
        if is_variadic do for i in len(fargs)..<len(call_args) {
            earg := call_args[i].expr;
            r, ok, err := assignable(var_ty, expr_ty(earg));
            if !ok {
                highlight_lines(get_span(earg));
                gala_panicf("Type Mismatch: %s (expected %s, got %s)",
                    err, tts(var_ty), tts(expr_ty(earg)));
            }
            mark_arg(&call_args[i], var_ty, r);
        }

        get_ctx().expr_types[id] = ret_ty
    }
    case FnLit: {
        // the resolver already built the fn type from the signature.
        tid := get_ctx().expr_resolution_types[id]
        assert(get_type(tid).kind == .Function)

        if get_type(tid).fn.is_generic {
            append(tc.generic_exprs, id);
            return
        }

        // validate parameter defaults before anything can call this literal
        tc_default_args(tc, tid)

        // body is checked like a FnDec body: fresh function context, and the
        // enclosing loop must not be visible (no break/continue across it).
        // (type fetched after tc_default_args, which may have grown the table)
        new_tc := tc^
        new_tc.in_function = true
        new_tc.fn_ret_ty = get_type(tid).fn.ret_ty
        new_tc.in_loop = nil
        tc_block(&new_tc, e.block)

        get_ctx().expr_types[id] = tid
    }
    case: panic("impl tc expr")
    }
}
is_iterable :: proc(id: TypeId) -> bool {
    t := get_type(id)
    #partial switch t.kind {
    case .Slice, .String, .FixedSizeArray: return true
    }
    return false
}
get_iterale_base_type :: proc(id: TypeId) -> TypeId {
    t := get_type(id);
    #partial switch t.kind {
    case .String: return ty_from_name("byte");
    case .FixedSizeArray: return t.fixed_size_array.type;
    case .Slice: return t.slice.type;
    }
    debugln(tts(id))
    panic("No base type.")
}
tc_stmt :: proc(tc: ^TcContext, s: StmtId) {
    switch stmt in get_stmt(s) {
    case ForLoop: {
        last_loop := tc.in_loop; // break/continue etc
        tc.in_loop = s;
        oid := get_ctx().stmt_objects[s];
        tc_expr(tc, stmt.expr);
        if !is_iterable(expr_ty(stmt.expr)) {
            highlight_lines(get_span(stmt.expr));
            gala_panic("can't iterate over", tts(expr_ty(stmt.expr)));
        }
        ty := get_iterale_base_type(expr_ty(stmt.expr))
        o := get_obj(oid)
        o.type = ty;
        tc_block(tc, stmt.block);
        tc.in_loop = last_loop;
    }
    case BreakStmt, ContinueStmt: {
        lid /* loop id */ := tc.in_loop;
        if lid == nil {
            highlight_lines(get_span(s));
            gala_panic("break/continue outside of a loop");
        }
        get_ctx().break_lables[s] = lid.(StmtId);
    }
    case WhileLoop: {
        last_loop := tc.in_loop;
        tc.in_loop = s;
        tc_expr(tc, stmt.cond);
        if is_untyped(expr_ty(stmt.cond)) {
            t := get_untyped_default(expr_ty(stmt.cond));
            propagate_type(t, stmt.cond);
        }
        if get_type(expr_ty(stmt.cond)).kind != .Bool {
            highlight_lines(get_span(stmt.cond));
            gala_panic("Expression is not of type boolean.");
        }
        tc_block(tc, stmt.block);
        tc.in_loop = last_loop;
    }
    case ExprId: tc_expr(tc, stmt);
    case IfElse: {
        // no in_loop change: break/continue inside an if/else target the
        // enclosing loop
        tc_expr(tc, stmt.base_con);
        // make it numeric
        if get_type(expr_ty(stmt.base_con)).kind != .Bool {
            highlight_lines(get_span(stmt.base_con))
            gala_panic("not a bool.");
        }
        tc_block(tc, stmt.base_block);
        for a in stmt.alt {
            tc_expr(tc, a.cond);
            // make it numeric
            if get_type(expr_ty(a.cond)).kind != .Bool {
                highlight_lines(get_span(a.cond))
                gala_panic("not a bool.");
            }
            tc_block(tc, a.block);
        }
        if stmt.has_else_block {
            tc_block(tc, stmt.else_block);
        }
    }
    case VarDec: {
        tc_expr(tc, stmt.value)
        oid := get_ctx().stmt_objects[s]
        declared := get_obj(oid).type
        // if vardec doesn't have a defined type then infer
        if declared == nil {
            t := expr_ty(stmt.value)
            // check these first: is_untyped() is true for ZeroInit too, and
            // there's no default type to give it
            #partial switch get_type(t).kind {
            case .ZeroInit: {
                highlight_lines(get_span(s));
                gala_panic("can't have zero initialiser here. Type required");
            }
            case .Void: {
                highlight_lines(get_span(s));
                gala_panic("can't declare a variable from an expression with no value.");
            }
            }
            // if it's untyped then get default type
            if is_untyped(t) {
                propagate_type(get_untyped_default(t), stmt.value)
            }
            get_obj(oid).type = expr_ty(stmt.value);
        } else { // otherwise if the vardec has a specified type compare
            expected := declared.(TypeId)
            r, ok, err := assignable(expected, expr_ty(stmt.value))
            if !ok {
                highlight_lines(get_span(s))
                gala_panicf("types don't match (%s vs %s): %s",
                    tts(expected), tts(expr_ty(stmt.value)), err)
            }
            propagate_type(r, stmt.value)
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
            expected := tc.fn_ret_ty.(TypeId)
            ty, cok, err := assignable(expected, expr_ty(e));
            if !cok {
                highlight_lines(get_span(e));
                gala_panicf("Return type mismatch: %s (expected %s, got %s)",
                    err, tts(expected), tts(expr_ty(e)));
            }
            propagate_type(ty, e);
        // otherwise make sure function doesn't expect a value
        } else  {
            if tc.fn_ret_ty != nil {
                if get_type(tc.fn_ret_ty.(TypeId)).kind == .Void {
                    // returning void - ok
                } else { // not in function
                    gala_panic("return value expected");
                }
            }
        }
    }
    case Assignment: {
        tc_expr(tc, stmt.target);
        tc_expr(tc, stmt.value);
        if !can_assign_to(stmt.target) {
            highlight_lines(get_span(stmt.target));
            gala_panic("Can't assign to this expression.");
        }
        // target must have a type
        _, tyok := get_ctx().expr_types[stmt.target]; assert(tyok);
        t, ok, err := assignable(expr_ty(stmt.target), expr_ty(stmt.value))
        if !ok {
            highlight_lines(get_span(s));
            debugln(tts(expr_ty(stmt.target)), tts(expr_ty(stmt.value)));
            gala_panic("Assignment error.", err);
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
// Same rules as a local VarDec: `:=` infers the type from the initialiser
// (untyped literals take their default type), `name: T = value` checks the
// initialiser against T. The result is written into the global's object so
// every later use (in functions or in later globals) sees a concrete type.
tc_global_var_dec :: proc(tc: ^TcContext, id: ItemId) {
    gd, gok := get_item(id).(GlobalVarDec); assert(gok)
    oid, ok := get_ctx().item_objects[id]; assert(ok)
    span := get_ctx().spans.items[id].span

    tc_expr(tc, gd.value)

    resolved_ty := get_obj(oid).type
    if resolved_ty == nil {
        t := expr_ty(gd.value)
        // before is_untyped(): that's true for ZeroInit too
        #partial switch get_type(t).kind {
        case .ZeroInit: {
            highlight_lines(get_ctx().current_file, span)
            gala_panic("can't have zero initialiser here. Type required")
        }
        case .Void: {
            highlight_lines(get_ctx().current_file, span)
            gala_panic("can't declare a global from an expression with no value.")
        }
        }
        if is_untyped(t) {
            propagate_type(get_untyped_default(t), gd.value)
        }
        get_obj(oid).type = expr_ty(gd.value)
    } else {
        expected := resolved_ty.(TypeId)
        t, cok, err := assignable(expected, expr_ty(gd.value))
        if !cok {
            highlight_lines(get_ctx().current_file, span)
            gala_panicf("types don't match (%s vs %s): %s",
                tts(expected), tts(expr_ty(gd.value)), err)
        }
        propagate_type(t, gd.value)
    }
}
tc_item :: proc(tc: ^TcContext, id: ItemId) {
    item := get_item(id)
    switch i in item {
    case Import: {} // ok
    case StructDec: {
        // ok?
    }
    case ExternFnDec: {
        // ok ig?
    }
    case GlobalVarDec: {
        // already checked in typecheck_module's global pass
    }
    case FnDec: {
        fn, ok := get_ctx().item_objects[id]; assert(ok);
        type := get_type(get_obj(fn).type.(TypeId));
        assert(type.kind == .Function);
        if type.fn.is_generic {
            append(tc.generic_items, id);
        } else {
            new_tc := tc^;
            new_tc.in_function = true;
            new_tc.fn_ret_ty = type.fn.ret_ty;
            tc_block(&new_tc, i.block);
        }
    }
    case: panic("impl")
    }
}
// "f" + params [f64, ^i32] -> "f.f64.p_i32"; only [A-Za-z0-9_] survive, LLVM-safe
mangle_version :: proc(base: string, params: []TypeId, idx: int) -> string {
    b: strings.Builder
    strings.builder_init(&b, get_ctx().allocator)
    strings.write_string(&b, base)
    for p in params {
        strings.write_byte(&b, '.')
        for r in tts(p) {
            switch {
            case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '_':
                strings.write_rune(&b, r)
            case r == '^': strings.write_string(&b, "p_")
            case r == '[': strings.write_string(&b, "a_")
            case r == ']': // dropped
            case: strings.write_byte(&b, '_')
            }
        }
    }
    // names are for readability only; the index is what makes them unique
    strings.write_string(&b, ".v")
    strings.write_int(&b, idx)
    return strings.to_string(b)
}
typecheck_module :: proc(ast: ^AST, mid: ModId, file: string) {
    generic_items := make([dynamic]ItemId, allocator=get_ctx().allocator);
    generic_exprs := make([dynamic]ExprId, allocator=get_ctx().allocator);
    tc := TcContext{
        fn_ret_ty=nil,
        in_function=false,
        generic_items=&generic_items,
        generic_exprs=&generic_exprs,
    }

    // First pass: globals, in declaration order, before any function body.
    // A `:=` global only gets its type here, and functions may use globals
    // declared further down the file, so all of them must be typed before
    // the first body is checked. A global initialiser that calls a function
    // gets that function's parameter defaults checked on demand (FnCall).
    for i in ast.items {
        if _, is_global := get_item(i).(GlobalVarDec); is_global {
            tc_global_var_dec(&tc, i)
        }
    }

    // Second pass: check parameter defaults of every module-level function
    // (extern ones included) before any body is checked, so inferred
    // parameter types and hidden-function return types exist by the time a
    // call needs them. Runs after the globals so an inferred default
    // (`fn f(x := SOME_GLOBAL)`) can use them.
    for i in ast.items {
        #partial switch _ in get_item(i) {
        case FnDec, ExternFnDec: {
            fn_obj, ok := get_ctx().item_objects[i]; assert(ok);
            tc_default_args(&tc, get_obj(fn_obj).type.(TypeId))
        }
        }
    }

    // Third pass: bodies, including the hidden default-value functions, whose
    // `return <expr>;` is where the written default expression is checked.
    for i in ast.items {
        tc_item(&tc, i);
    }

    // Generic bodies aren't checked here: other modules may still add
    // versions of them. Hand them to typecheck_generics along with their
    // owner, and take the generic originals out of this module (only their
    // clones get emitted).
    for g in generic_items {
        append(&get_ctx().generic_items, g)
        get_ctx().generic_owner[g] = GenericOwner{ast = ast, mod = mid, file = file}
    }
    kept := make([dynamic]ItemId, allocator=get_ctx().allocator)
    for i in ast.items {
        if slice.contains(generic_items[:], i) {
            continue
        }
        append(&kept, i)
    }
    ast.items = kept
}

// Instantiates every requested version of every generic function, across
// all modules. Run once, after all modules are type-checked. A clone is
// resolved and checked in its owner's scope and added to the owner's
// items, so the owner's object file defines it and importers call it like
// any other function. Checking a clone can request more versions (of this
// or another generic), hence the loop.
typecheck_generics :: proc() {
    c := get_ctx()

    // clones are never generic, so these stay empty
    scratch_items := make([dynamic]ItemId, allocator=c.allocator)
    scratch_exprs := make([dynamic]ExprId, allocator=c.allocator)
    tc := TcContext{
        generic_items=&scratch_items,
        generic_exprs=&scratch_exprs,
    }

    prev_file := c.current_file
    prev_mod  := c.current_module_id

    progress := true
    for progress {
        progress = false
        for g in c.generic_items {
            owner := c.generic_owner[g]
            fn_tid := get_obj(c.item_objects[g]).type.(TypeId)

            for c.generic_done[g] < len(get_type(fn_tid).fn.versions) {
                idx := c.generic_done[g]
                c.generic_done[g] += 1

                // names and spans must resolve in the owner's module
                c.current_file = owner.file
                c.current_module_id = owner.mod

                iid := clone_item(g)
                // unique name per version, kept on the version too
                fd := c.items[iid].(FnDec)
                fd.name = mangle_version(fd.name, get_type(fn_tid).fn.versions[idx].params, idx)
                c.items[iid] = Item(fd)
                get_type(fn_tid).fn.versions[idx].llvm_fn_name = fd.name

                // fetched fresh each time: cloning/resolving appends to the tables
                get_type(fn_tid).fn.versions[idx].item = iid
                v := get_type(fn_tid).fn.versions[idx]

                append(&owner.ast.items, iid)
                resolve_generic_clone(g, iid, v)
                c.obj_modules[c.item_objects[iid]] = owner.mod

                tc_item(&tc, iid)
                progress = true
            }
        }
    }

    c.current_file = prev_file
    c.current_module_id = prev_mod

    retarget_generic_calls()
}

// Points every generic call at its clone, so codegen sees a plain call.
retarget_generic_calls :: proc() {
    for call_id, ref in get_ctx().expr_fn_version {
        v := get_type(ref.fn).fn.versions[ref.idx]
        if v.llvm_fn_name == "" do continue

        call := get_expr(call_id).(FnCall)
        oid := get_ctx().item_objects[v.item]
        get_ctx().expr_objects[call.target] = oid
        get_ctx().expr_types[call.target] = get_obj(oid).type.(TypeId)

        // codegen resolves callees by name, so rename the symbol too
        if sym, ok := get_expr(call.target).(Symbol); ok {
            sym.name = get_obj(oid).name
            get_ctx().exprs[call.target] = Expr(sym)
        }
    }
}
propagate_type :: proc(ty: TypeId, expr: ExprId) {
    switch e in get_expr(expr) {
    case TypeIdOf: {
    }
    case UnNegative: {
        propagate_type(ty, e.expr);
    }
    case UnNot: {
        return // bool
    }
    case BoolLitFalse, BoolLitTrue: return // already typed
    case Len: {
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
        t, ok := get_ctx().expr_types[expr];
        if ok {
            if !is_untyped(t) do return // skip if it's been assigned a type
        }
        if e.kind == .Modulo && !is_int_kind(get(ty).kind) && !is_untyped(ty) {
            highlight_lines(get_span(expr))
            gala_panicf("can't take modulo of non-integer numbers (result used as %s).", tts(ty))
        }
        // else propagate and set self
        propagate_type(ty, e.left)
        propagate_type(ty, e.right)
    }
    case Number: {
        t := expr_ty(expr);
        if !is_untyped(t) do return // skip if it's been assigned a type
    }
    case Symbol: { // should have a fixed type
        return
    }
    case FnCall: { // should have a fixed type
        return
    }
    case FnLit: { // fixed fn type from its signature
        return
    }
    case: panic("impl");
    }
    // set to all
    get_ctx().expr_types[expr] = ty;
}
