package main

// Inference for calls to generic functions: match each parameter's type
// against the type of the argument passed, record what every generic name
// stands for, then substitute those into the return type.
//
// Works on resolved TypeIds, so `$T` and a later plain `T` are the same
// thing as long as they share a name.

// The one place that knows how a generic param looks once resolved.
// ASSUMPTION: Type{kind=.Generic, name="T"}. Change this proc if yours differs.
generic_param_name :: proc(t: TypeId) -> (string, bool) {
    ty := get_type(t)
    if ty.kind == .Generic do return ty.name, true
    return "", false
}

// The one place that knows how a variadic param looks in a function type.
// Returns the element type (the `$T` of `..$T`).
// ASSUMPTION: fn type has `is_variadic: bool` and `variadic_ty: TypeId`
// (element type), and the variadic param is NOT in fn.args.
// Change this proc (and the writes in gen_subst) if yours differs.
fn_variadic_elem :: proc(ty: ^Type) -> (TypeId, bool) {
    if ty.fn.is_variadic do return ty.fn.variadic_ty, true
    return {}, false
}

// Does this type mention a generic param anywhere?
gen_has :: proc(t: TypeId) -> bool {
    ty := get_type(t)^ // copy: nothing here appends, but keep the habit
    #partial switch ty.kind {
    case .Generic:        return true
    case .Pointer:        return gen_has(ty.ptr)
    case .Slice:          return gen_has(ty.slice.type)
    case .FixedSizeArray: return gen_has(ty.fixed_size_array.type)
    case .Struct: {
        // only an instance with a generic arg (`Box(T)`) mentions one
        if ty.structure.is_instance {
            for a in ty.structure.args {
                if gen_has(a) do return true
            }
        }
    }
    case .Function: {
        for a in ty.fn.args {
            if gen_has(a.type) do return true
        }
        if v, ok := fn_variadic_elem(&ty); ok && gen_has(v) do return true
        return gen_has(ty.fn.ret_ty)
    }
    }
    return false
}

gen_bind :: proc(name: string, got: TypeId, bound: ^map[string]TypeId) -> (bool, string) {
    if get_type(got).kind == .Void {
        return false, "can't use a value of type void"
    }
    if prev, ok := bound[name]; ok {
        if types_equal(prev, got) do return true, ""
        return false, "type parameter was already inferred as a different type"
    }
    bound[name] = got
    return true, ""
}

// Walks the parameter type next to the argument's type. Concrete parts are
// skipped: the normal argument check handles those.
gen_unify :: proc(param, got: TypeId, bound: ^map[string]TypeId) -> (bool, string) {
    if name, ok := generic_param_name(param); ok {
        return gen_bind(name, got, bound)
    }
    if !gen_has(param) do return true, ""

    pt := get_type(param)^
    gt := get_type(got)^
    #partial switch pt.kind {
    case .Pointer: {
        if gt.kind != .Pointer do return false, "expected a pointer"
        return gen_unify(pt.ptr, gt.ptr, bound)
    }
    case .Slice: {
        if gt.kind != .Slice do return false, "expected a slice"
        return gen_unify(pt.slice.type, gt.slice.type, bound)
    }
    case .FixedSizeArray: {
        if gt.kind != .FixedSizeArray do return false, "expected a fixed size array"
        if gt.fixed_size_array.size != pt.fixed_size_array.size {
            return false, "array sizes don't match"
        }
        return gen_unify(pt.fixed_size_array.type, gt.fixed_size_array.type, bound)
    }
    case .Struct: {
        // gen_has said yes, so this is an instance like `Box(T)`
        if gt.kind != .Struct || !gt.structure.is_instance ||
           gt.structure.origin != pt.structure.origin {
            return false, "expected a different struct type"
        }
        for a, i in pt.structure.args {
            ok, msg := gen_unify(a, gt.structure.args[i], bound)
            if !ok do return false, msg
        }
        return true, ""
    }
    case .Function: {
        if gt.kind != .Function do return false, "expected a function"
        if len(gt.fn.args) != len(pt.fn.args) {
            return false, "function parameter counts don't match"
        }
        for a, i in pt.fn.args {
            ok, msg := gen_unify(a.type, gt.fn.args[i].type, bound)
            if !ok do return false, msg
        }
        pv, p_var := fn_variadic_elem(&pt)
        gv, g_var := fn_variadic_elem(&gt)
        if p_var != g_var do return false, "variadic parameters don't match"
        if p_var {
            ok, msg := gen_unify(pv, gv, bound)
            if !ok do return false, msg
        }
        return gen_unify(pt.fn.ret_ty, gt.fn.ret_ty, bound)
    }
    }
    return false, "types don't match"
}

// `t` with every generic param replaced by what was inferred for it.
// Types without generics come back unchanged (same id).
gen_subst :: proc(t: TypeId, bound: map[string]TypeId, call: ExprId) -> TypeId {
    if !gen_has(t) do return t

    if name, ok := generic_param_name(t); ok {
        b, found := bound[name]
        if !found {
            highlight_lines(get_span(call))
            gala_panicf("Can't infer type parameter \"%s\" from the arguments.", name)
        }
        return b
    }

    // copy first: interning below can move the type table
    ty := get_type(t)^
    #partial switch ty.kind {
    case .Pointer: {
        inner := gen_subst(ty.ptr, bound, call)
        return intern_type(Type{kind=.Pointer, ptr=inner})
    }
    case .Slice: {
        inner := gen_subst(ty.slice.type, bound, call)
        return intern_type(Type{kind=.Slice, slice={type=inner}})
    }
    case .FixedSizeArray: {
        inner := gen_subst(ty.fixed_size_array.type, bound, call)
        return intern_type(Type{kind=.FixedSizeArray,
            fixed_size_array={type=inner, size=ty.fixed_size_array.size}})
    }
    case .Struct: {
        // `Box(T)` -> `Box(i64)`
        args := make([]TypeId, len(ty.structure.args), allocator=get_ctx().allocator)
        for a, i in ty.structure.args {
            args[i] = gen_subst(a, bound, call)
        }
        return get_or_add_struct_instance(ty.structure.origin, args)
    }
    case .Function: {
        nt := ty
        args := make([]Arg, len(ty.fn.args), allocator=get_ctx().allocator)
        for a, i in ty.fn.args {
            args[i] = a
            args[i].type = gen_subst(a.type, bound, call)
        }
        nt.fn.args = args
        if v, ok := fn_variadic_elem(&ty); ok {
            nt.fn.variadic_ty = gen_subst(v, bound, call)
        }
        nt.fn.ret_ty = gen_subst(ty.fn.ret_ty, bound, call)
        nt.fn.is_generic = false
        return new_fn_type(nt)
    }
    }
    return t
}

// What each generic name stands for, from the arguments of this call.
// The arguments must already be type checked.
infer_generic_bindings :: proc(call: ExprId, args: [dynamic]FnCallArg, fn_tid: TypeId) -> map[string]TypeId {
    bound := make(map[string]TypeId, allocator=get_ctx().allocator)
    fn_ty := get_type(fn_tid)
    params := fn_ty.fn.args // slice header copy; the data doesn't move
    velem, is_variadic := fn_variadic_elem(fn_ty)

    // pass 0: typed arguments. pass 1: untyped literals for a bare `$T` that
    // is still unbound, which take their default type (i64 / f64). A literal
    // for an already-bound param adapts to it in the normal argument check.
    for pass in 0..<2 {
        for a, i in args {
            pi := i
            if len(a.name) > 0 {
                pi = -1
                for p, j in params {
                    if p.name == a.name {
                        pi = j
                        break
                    }
                }
            }
            // wrong names / too many args are reported by order_call_args
            if pi < 0 do continue

            ptype: TypeId
            pname: string
            if pi < len(params) {
                ptype = params[pi].type
                pname = params[pi].name
            } else if is_variadic && len(a.name) == 0 {
                // extra positional args all match the variadic element type
                ptype = velem
                pname = "variadic argument"
            } else {
                continue
            }

            t := expr_ty(a.expr)
            name, direct := generic_param_name(ptype)

            if is_untyped(t) && direct {
                if pass == 0 do continue
                if name in bound do continue
                if get_type(t).kind == .ZeroInit {
                    highlight_lines(get_span(a.expr))
                    gala_panicf("Can't infer \"%s\" from a zero initialiser.", name)
                }
                t = get_untyped_default(t)
            } else if pass == 1 {
                continue
            }

            ok, msg := gen_unify(ptype, t, &bound)
            if !ok {
                highlight_lines(get_span(a.expr))
                gala_panicf("Generic argument mismatch for parameter \"%s\": %s (expected %s got %s).",
                    pname, msg, tts(ptype), tts(t))
            }
        }
    }
    return bound
}

// The return type of a call to a generic function: its declared return type
// with the inferred types substituted in. Call after the arguments have been
// type checked.
infer_ty_from_generic_fn_call :: proc(call: ExprId, args: [dynamic]FnCallArg, fn_tid: TypeId) -> TypeId {
    bound := infer_generic_bindings(call, args, fn_tid)
    ret := get_type(fn_tid).fn.ret_ty
    return gen_subst(ret, bound, call)
}
// The concrete fn type for this call: params, variadic element and return
// type all substituted with what was inferred.
instantiate_generic_fn_type :: proc(call: ExprId, args: [dynamic]FnCallArg, fn_tid: TypeId) -> TypeId {
    bound := infer_generic_bindings(call, args, fn_tid)
    return gen_subst(fn_tid, bound, call)
}

// `Box{1, 2}` / `Map{a, b, ...}`: the instance a literal of a generic struct
// makes, inferred from the types of its values (so no `Box(i64){..}`).
// `tmpl_id` is the generic struct itself. The values must already be type
// checked. Same two passes as infer_generic_bindings: typed values first,
// then untyped literals for a bare `$T` that is still unbound (default type).
// Any other untyped value (`0` for a pointer field, `{}`) adapts to its field
// later, in the normal field check.
infer_struct_lit_type :: proc(id: ExprId, tmpl_id: TypeId, lit: StructLit) -> TypeId {
    tmpl := get_type(tmpl_id)^ // copy: unify and instancing can append types
    bound := make(map[string]TypeId, allocator=get_ctx().allocator)

    for pass in 0..<2 {
        for sf in tmpl.structure.fields {
            val := lit.fields[sf.name]
            t := expr_ty(val.expr)
            name, direct := generic_param_name(sf.type)

            if is_untyped(t) {
                if pass == 0 || !direct do continue
                if name in bound do continue
                if get_type(t).kind == .ZeroInit {
                    highlight_lines(get_ctx().current_file, val.span)
                    gala_panicf("Can't infer \"%s\" from a zero initialiser.", name)
                }
                t = get_untyped_default(t)
            } else if pass == 1 {
                continue
            }

            ok, msg := gen_unify(sf.type, t, &bound)
            if !ok {
                highlight_lines(get_ctx().current_file, val.span)
                gala_panicf("Generic field mismatch for \"%s\": %s (expected %s got %s).",
                    sf.name, msg, tts(sf.type), tts(t))
            }
        }
    }

    args := make([]TypeId, len(tmpl.structure.generic_names), allocator=get_ctx().allocator)
    for n, i in tmpl.structure.generic_names {
        b, found := bound[n]
        if !found {
            highlight_lines(get_span(id))
            gala_panicf("Can't infer type parameter \"%s\" of \"%s\" from the literal, write %s(...){...} instead.",
                n, tmpl.name, tmpl.name)
        }
        args[i] = b
    }
    return get_or_add_struct_instance(tmpl_id, args)
}
