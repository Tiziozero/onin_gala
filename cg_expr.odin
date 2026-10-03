package main

import "core:strings"
import "core:strconv"
import "core:mem"

// Boxes `val` (of concrete type `concrete_ty`) into an `any` value:
// { ptr, i64 } = { address of a spilled copy of val, typeid_of(concrete_ty) }.
// `any` is opaque — the callee only ever sees a rawptr + tag, never the
// value directly — so we always spill to get an address, even for values
// that would otherwise happily live in a register.
//
// Returns the boxed SSA value and its LLVM type string directly, rather
// than a TypeId for a boxed_ty to run back through ty_to_llvm_str: the ABI
// shape of a boxed `any` is a fixed, compile-time-known constant regardless
// of which TypeId a given `any` declaration resolves to, so there is
// nothing to look up here — no dependency on `any` being registered as a
// named type anywhere.
cg_box_any :: proc(c: ^CGCtx, val: string, concrete_ty: TypeId) -> (string, string) {
    concrete_ty_str := ty_to_llvm_str(c, concrete_ty)

    slot := new_tmp(c)
    cwritefln(c, "\t%s = alloca %s", slot, concrete_ty_str)
    cwritefln(c, "\tstore %s %s, ptr %s", concrete_ty_str, val, slot)

    v1 := new_tmp(c)
    v2 := new_tmp(c)
    cwritefln(c, "\t%s = insertvalue {{ ptr, i64 }} undef, ptr %s, 0", v1, slot)
    cwritefln(c, "\t%s = insertvalue {{ ptr, i64 }} %s, i64 %d, 1", v2, v1, typeid_of(concrete_ty))

    return v2, "{ ptr, i64 }"
}

// Function literals (lambdas) are lowered to ordinary, separate LLVM
// functions — a `define` can't be nested inside another function's body, so
// the lambda is generated into its own string builder and parked in
// c.lambdas; cg_module appends every parked definition after the regular
// items. The expression itself evaluates to the lambda's address
// (`@gala.lambda.N`), which is just a `ptr` — the same representation every
// other function value already has, so calling it through a variable, a
// struct field, an argument, or immediately all work unchanged.
//
// Lambdas don't capture (the resolver only lets the body see module-level
// names), so the body's scope is parented to the module's root scope rather
// than to whatever scope the lambda expression happens to sit in.
//
// They're emitted with `internal` linkage so the per-lambda names only have
// to be unique inside this module (each module is compiled to its own .o).
cg_fn_lit :: proc(c: ^CGCtx, id: ExprId, e: FnLit) -> CGExprRes {
    fn_type_id := expr_ty(id)
    name := aprintf(c, "gala.lambda.%d", next_tmp_index(c))

    lambda_b: strings.Builder
    strings.builder_init(&lambda_b, get_ctx().allocator)

    // everything the body generation mutates, saved so the enclosing
    // function carries on exactly where it left off
    saved_b := c.b
    saved_scope := c.scope
    saved_break := c.cur_break_label
    saved_continue := c.cur_continue_label

    // find the root (module) scope and keep a stable heap copy to parent to.
    // (maps are reference types, so the copy sees the same declarations.)
    root := &c.scope
    for root.parent != nil {
        root = root.parent
    }
    root_copy := new(CGScope, get_ctx().allocator)
    root_copy^ = root^

    c.b = &lambda_b
    c.scope = new_gcscope(root_copy)
    // a break/continue can't target a loop outside the lambda
    c.cur_break_label = ""
    c.cur_continue_label = ""

    cg_fn_definition(c, fn_type_id, name, e.block, internal = true)

    c.b = saved_b
    c.scope = saved_scope
    c.cur_break_label = saved_break
    c.cur_continue_label = saved_continue

    append(&c.lambdas, strings.to_string(lambda_b))

    return {kind=.Value, v=aprintf(c, "@%s", name), id=id}
}

cg_expr :: proc(c: ^CGCtx, id: ExprId) -> CGExprRes {
    span := get_span(id).span
    data := get_file_lines(get_ctx().current_file, span)
    switch e in get_expr(id) {
    case TypeIdOf: {
        // same resolution slot Sizeof uses for its type specifier
        tid := get_ctx().expr_resolution_types[id]
        return {kind=.Number, v=aprintf(c, "%d", tid)}
    }
    case UnNegative: {
        v, returns := reduce_expr_to_single_value(c, cg_expr(c, e.expr))
        assert(returns)

        t := expr_ty(e.expr)
        llvm_ty := ty_to_llvm_str(c, t)

        result := new_tmp(c)
        if is_float(t) {
            cwritefln(c, "\t%s = fneg %s %s", result, llvm_ty, v)
        } else {
            cwritefln(c, "\t%s = sub %s 0, %s", result, llvm_ty, v)
        }
        return {kind=.Value, v=result}
    }
    case UnNot: {
        v, returns := reduce_expr_to_single_value(c, cg_expr(c, e.expr))
        assert(returns)

        t := new_tmp(c)
        cwritefln(c, "\t%s = xor i1 %s, true", t, v)
        return {kind=.Value, v=t}
    }
    case BoolLitFalse: {
        return {kind=.Value, v="0"}
    }
    case BoolLitTrue: {
        return {kind=.Value, v="1"}
    }
    case Len: {
        inner, returns := reduce_expr_to_single_value(c, cg_expr(c, e.target));
        assert(returns);
        ty := get_type(expr_ty(e.target))
        #partial switch ty.kind {
        case .String, .Slice, .Struct: {
            t := new_tmp(c);
            cwritefln(c, "\t%s = extractvalue %s %s, 1",
                t, ty_to_llvm_str(c, expr_ty(e.target)), inner);
            return {kind=.Value, v=t};
        }
        case .FixedSizeArray: {
            v := aprintf(c, "%d", ty.fixed_size_array.size);
            return {kind=.Number, v=v}
        }
        case: {debugln(get(e.target), ty.kind); panic("can't take len of it.");}
        }
        panic("impl");
    }
    case Sizeof: {
        s := type_size(get_ctx().expr_resolution_types[id]);
        v := aprintf(c, "%d", s);
        return {kind=.Number, v=v}
    }
    case String: {
        r := c.strings[e.s] // global string thingy
        t := new_tmp(c);
        cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i64 0, i64 0",
            t, r.array_type, r.s);

        t1 := new_tmp(c);
        t2 := new_tmp(c);
        cwritefln(c, "\t%s = insertvalue {{ ptr, i64 }} undef, ptr %s, 0",
            t1, t)
        cwritefln(c, "\t%s = insertvalue {{ ptr, i64 }} %s, i64 %d, 1       ",
            t2, t1, r.len)
        return {kind=.Value, v=t2}
    }
    case Deref: {
        // NOTE: this must mirror cg_addr's Deref case in how it computes
        // the pointer's VALUE (cg_expr + reduce — NOT cg_addr, which would
        // ask for the address of e.expr, and e.expr is very often not an
        // addressable lvalue at all — e.g. `(ints + 0 * sizeof(i32))^`
        // has a Binop as e.expr, which has no address to take). Once we
        // have that pointer value, cg_expr additionally loads through it
        // (unlike cg_addr's Deref, which just returns the pointer value
        // itself as "the address").
        ptr_val, returns := reduce_expr_to_single_value(c, cg_expr(c, e.expr))
        assert(returns)
        ptr_ty := get_type(expr_ty(e.expr))

        if ptr_ty.kind != .Pointer {
            panic("cannot dereference non-pointer type")
        }

        pointee_ty := ptr_ty.ptr
        pointee_llvm_ty := ty_to_llvm_str(c, pointee_ty)

        loaded := new_tmp(c);
        cwritefln(c, "\t%s = load %s, ptr %s", loaded, pointee_llvm_ty, ptr_val);

        return {
            kind = .Value,
            v = loaded,
        }
    }
    case Reference: {
        inner_ptr := cg_addr(c, e.expr)
        e_ty := expr_ty(e.expr);
        return {kind=.Value, v = inner_ptr}
    }
    case Transmute: {
        from_ty := expr_ty(e.target)
        to_ty := expr_ty(id)
        reduced, returns := reduce_expr_to_single_value(c, cg_expr(c, e.target))
        assert(returns)

        op, result := ty_to_llvm_transmute_op(from_ty, to_ty)
        switch result {
        case .NoOp:
            return {kind=.Value, v=reduced}

        case .Instr:
            t := new_tmp(c)
            cwritefln(c, "\t%s = %s %s %s to %s", t, op,
                ty_to_llvm_str(c, from_ty), reduced, ty_to_llvm_str(c, to_ty))
            return {kind=.Value, v=t}

        case .Memory:
            slot := new_tmp(c)
            cwritefln(c, "\t%s = alloca %s", slot, ty_to_llvm_str(c, from_ty))
            cwritefln(c, "\tstore %s %s, ptr %s", ty_to_llvm_str(c, from_ty), reduced, slot)
            t := new_tmp(c)
            cwritefln(c, "\t%s = load %s, ptr %s", t, ty_to_llvm_str(c, to_ty), slot)
            return {kind=.Value, v=t}
        }
        panic("impl");
    }
    case TakeSlice: {
        start, sret := reduce_expr_to_single_value(c, cg_expr(c, e.start))
        assert(sret);
        end, eret := reduce_expr_to_single_value(c, cg_expr(c, e.end))
        assert(eret);

        if get(expr_ty(e.start)).kind != .UInt64 {
            op, ok := ty_to_llvm_cast_op(expr_ty(e.start), integer_type());
            if !ok {
                op = "bitcast"
            }
            t := new_tmp(c);
            cwritefln(c, "\t%s = %s %s %s to %s", t, op,
                ty_to_llvm_str(c, expr_ty(e.start)), start, ty_to_llvm_str(c, integer_type()));
            start = t
        }
        if get(expr_ty(e.end)).kind != .UInt64 {
            op, ok := ty_to_llvm_cast_op(expr_ty(e.end), integer_type());
            if !ok {
                op = "bitcast"
            }
            t := new_tmp(c);
            cwritefln(c, "\t%s = %s %s %s to %s", t, op,
                ty_to_llvm_str(c, expr_ty(e.end)), end, ty_to_llvm_str(c, integer_type()));
            end = t
        }
        len_s := new_tmp(c);
        cwritefln(c, "\t%s = sub nsw nuw %s %s, %s",len_s,
            ty_to_llvm_str(c,integer_type()), end, start);

        llvm_int := ty_to_llvm_str(c, integer_type())
        base_ptr, elem_ty := cg_data_ptr(c, e.target)
        elem_ptr := new_tmp(c)
        cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, %s %s",
            elem_ptr, elem_ty, base_ptr, llvm_int, start)

        v1 := new_tmp(c)
        v2 := new_tmp(c)
        cwritefln(c, "\t%s = insertvalue {{ ptr, %s }} undef, ptr %s, 0", v1, llvm_int, elem_ptr)
        cwritefln(c, "\t%s = insertvalue {{ ptr, %s }} %s, %s %s, 1", v2, llvm_int, v1, llvm_int, len_s)
        return {kind=.Value, v=v2}
    }
    case Index: {
        ptr := cg_elem_ptr(c, e.target, e.index)
        v := new_tmp(c)
        cwritefln(c, "\t%s = load %s, ptr %s", v, ty_to_llvm_str(c, expr_ty(id)), ptr)
        return {kind=.Value, v=v}
    }
    case FixedSizeArray: {
        // CHANGED: `{}` is all zeroes; otherwise start from zeroinitializer
        // and insertvalue each given element, so any elements past the end
        // of the initialiser stay zero.
        if len(e.initialiser) == 0 {
            return {kind=.Value, v="zeroinitializer"}
        }

        arr_ty := ty_to_llvm_str(c, expr_ty(id))
        elem_ty := ty_to_llvm_str(c, get_type(expr_ty(id)).fixed_size_array.type)

        acc := "zeroinitializer"
        for el, i in e.initialiser {
            v, returns := reduce_expr_to_single_value(c, cg_expr(c, el))
            assert(returns)
            t := new_tmp(c)
            cwritefln(c, "\t%s = insertvalue %s %s, %s %s, %d",
                t, arr_ty, acc, elem_ty, v, i)
            acc = t
        }
        return {kind=.Value, v=acc}
    }
    case FieldAccess: {
        r, ok := reduce_expr_to_single_value(c, cg_expr(c, e.target));
        assert(ok);

        target_ty := expr_ty(e.target)
        ty := get_type(target_ty)

        idx := -1
        for f, k in ty.structure.fields {
            if f.name == e.field {
                idx = k
                break
            }
        }
        assert(idx != -1)

        t := new_tmp(c)
        cwritefln(c, "\t%s = extractvalue %s %s, %d",
            t, ty_to_llvm_str(c, target_ty), r, idx)

        return {kind=.Value, v=t}
    }
    case StructLit: {
        ty := get_ctx().expr_resolution_types[id]
        fields := make([]string, len(get_type(ty).structure.fields), allocator=get_ctx().allocator)
        for f,k in get_type(ty).structure.fields {
            r, ok := reduce_expr_to_single_value(c, cg_expr(c, e.fields[f.name].expr));
            assert(ok);
            fields[k] = r
        }
        r: CGExprRes
        r.struct_lit.fields=fields
        r.id=id
        r.kind = .Struct
        return r;
    }
    case ZeroInit: {
        panic("impl");
    }
    case Cast: {
        target := cg_expr(c, e.target)
        target_ty := expr_ty(e.target);
        to_ty := expr_ty(id)
        op, ok := ty_to_llvm_cast_op(target_ty, to_ty);
        if !ok {
            return target
        }
        reduced_target, returns := reduce_expr_to_single_value(c, target);
        assert(returns);
        t := new_tmp(c);
        cwritefln(c, "\t%s = %s %s %s to %s", t, op,
            ty_to_llvm_str(c, target_ty), reduced_target, ty_to_llvm_str(c, to_ty));
        return {kind=.Value, v=t};
    }
    case Number: {
        if is_float(expr_ty(id)) {
            #partial switch get_type(expr_ty(id)).kind {
            case .Flt64: {
                f, ok := strconv.parse_f64(e.text)
                assert(ok)
                return {kind=.Number, v=llvm_double_const(f)}
            }
            case .Flt32: {
                f, ok := strconv.parse_f32(e.text)
                assert(ok)
                return {kind=.Number, v=llvm_float_const(f)}
            }
            case: panic("impl")
            }
        }

        n, ok := parse_integer_literal(e.text)
        assert(ok)

        return {kind=.Number, v=aprintf(c, "%d", n)}
    }
    case Binop: {
        left_ty := expr_ty(e.left)
        right_ty := expr_ty(e.right)

        left_is_ptr := is_pointer(left_ty)
        right_is_ptr := is_pointer(right_ty)

        // ---- pointer arithmetic / pointer comparison ----
        // Operands are always the same type in a Binop, so if either side is
        // a pointer, both are.
        if left_is_ptr || right_is_ptr {
            assert(left_is_ptr && right_is_ptr, "pointer binop requires both operands to be pointers")

            l_res := cg_expr(c, e.left)
            r_res := cg_expr(c, e.right)

            // A side may be a raw integer literal (e.g. the `1` in `ptr - 1`,
            // or `0` for a null check) that the type checker coerced onto a
            // pointer-typed operand without ever materializing an actual
            // pointer value. Number literals never went through cg_addr or a
            // load — .v is just plain decimal text — so `ptrtoint ptr %v` on
            // it is invalid IR (LLVM has no bare-integer ptr constant except
            // `null`). Feed those straight into the i64 math instead;
            // only reduce+ptrtoint values that are real pointers.
            to_i64 :: proc(c: ^CGCtx, res: CGExprRes) -> string {
                if res.kind == .Number {
                    return res.v
                }
                v, returns := reduce_expr_to_single_value(c, res)
                assert(returns)
                t := new_tmp(c)
                cwritefln(c, "\t%s = ptrtoint ptr %s to i64", t, v)
                return t
            }

            li := to_i64(c, l_res)
            ri := to_i64(c, r_res)

            #partial switch e.kind {
            case .Addition: {
                sum := new_tmp(c)
                cwritefln(c, "\t%s = add i64 %s, %s", sum, li, ri)
                t := new_tmp(c)
                cwritefln(c, "\t%s = inttoptr i64 %s to ptr", t, sum)
                return {kind=.Value, v=t}
            }
            case .Subtraction: {
                diff := new_tmp(c)
                cwritefln(c, "\t%s = sub i64 %s, %s", diff, li, ri)
                t := new_tmp(c)
                cwritefln(c, "\t%s = inttoptr i64 %s to ptr", t, diff)
                return {kind=.Value, v=t}
            }
            case .Equal, .NotEqual, .LessEqual, .GreaterEqual, .Less, .Greater: {
                op := ""
                #partial switch e.kind {
                case .Equal:        op = "icmp eq"
                case .NotEqual:     op = "icmp ne"
                case .LessEqual:    op = "icmp ule"
                case .GreaterEqual: op = "icmp uge"
                case .Less:         op = "icmp ult"
                case .Greater:      op = "icmp ugt"
                }
                return {kind=.Binop, v=aprintf(c, "%s i64 %s, %s", op, li, ri)}
            }
            case: gala_panic("unsupported pointer binary operation")
            }
        }

        l_v, returns_l := reduce_expr_to_single_value(c, cg_expr(c, e.left))
        assert(returns_l);
        r_v, returns_r := reduce_expr_to_single_value(c, cg_expr(c, e.right))
        assert(returns_r);

        operand_ty := left_ty
        op := ""
        if is_integer_signed(operand_ty) {
            #partial switch e.kind {
            case .Addition:     op = "add"
            case .Subtraction:  op = "sub"
            case .Multiply:     op = "mul"
            case .Divide:       op = "sdiv"
            case .Modulo:       op = "srem"
            case .Equal:        op = "icmp eq"
            case .NotEqual:     op = "icmp ne"
            case .LessEqual:    op = "icmp sle"
            case .GreaterEqual: op = "icmp sge"
            case .Less:         op = "icmp slt"
            case .Greater:      op = "icmp sgt"
            case .BitAnd:       op = "and"
            case .BitXor:       op = "xor"
            case .BitOr:        op = "or"
            case: panic("impl")
            }
        } else if is_integer_unsigned(operand_ty) {
            #partial switch e.kind {
            case .Addition:     op = "add"
            case .Subtraction:  op = "sub"
            case .Multiply:     op = "mul"
            case .Divide:       op = "udiv"
            case .Modulo:       op = "urem"
            case .Equal:        op = "icmp eq"
            case .NotEqual:     op = "icmp ne"
            case .LessEqual:    op = "icmp ule"
            case .GreaterEqual: op = "icmp uge"
            case .Less:         op = "icmp ult"
            case .Greater:      op = "icmp ugt"
            case .BitAnd:       op = "and"
            case .BitXor:       op = "xor"
            case .BitOr:        op = "or"
            case: panic("impl")
            }
        } else if is_float(operand_ty) {
            #partial switch e.kind {
            case .Addition:     op = "fadd"
            case .Subtraction:  op = "fsub"
            case .Multiply:     op = "fmul"
            case .Divide:       op = "fdiv"
            case .Equal:        op = "fcmp oeq"
            case .NotEqual:     op = "fcmp one"
            case .LessEqual:    op = "fcmp ole"
            case .GreaterEqual: op = "fcmp oge"
            case .Less:         op = "fcmp olt"
            case .Greater:      op = "fcmp ogt"
            case: panic("impl")
            }
        } else if get_type(operand_ty).kind == .Bool {
            #partial switch e.kind {
            case .Equal:
                op = "icmp eq"
            case .NotEqual:
                op = "icmp ne"
            case .LogicalAnd:
                op = "and"
            case .LogicalOr:
                op = "or"
            case:
                gala_panic("can't order booleans")
            }
        } else if get_type(operand_ty).kind == .Void {
            gala_panic("can't binop voids")
        } else {
            debugln(get_type(operand_ty).kind)
            debugln(get_expr(id))
            panic("handle")
        }

        return {kind=.Binop,
            v=aprintf(c, "%s %s %s, %s", op, ty_to_llvm_str(c, operand_ty), l_v, r_v)}
    }
    case Symbol: {
        v := cgscope_get(&c.scope, e.name);
        switch v.kind {
        case .Symbol: {
            return {kind=.Address, v=v.name}
        }
        case .Variable: {
            t := new_tmp(c)
            cwritefln(c, "\t%s = load %s, ptr %s",
                t, ty_to_llvm_str(c, expr_ty(id)), v.name);
            return {kind=.Value,v=t};
        }
        case .Argument: {
            return {kind=.Value,v=v.name};
        }
        case .Invalid: {
            gala_panic("invalid object");
        }
        }
        panic("impl");
    }
    case FnCall: {
        return cg_fn_call(c, id, e)
    }
    case FnLit: {
        return cg_fn_lit(c, id, e)
    }
    case: panic("impl");
    }
}

// Internal (Gala) variadics are lowered to an ordinary function whose last
// parameter is the `[]T` slice (fn.gala_abi_ty, named fn.variadic_name).
// Both the definition and every call site lower against this type, so the
// ABI code never needs to know about `..T`.
// Anything that isn't an internal variadic is returned unchanged.
lower_internal_variadic :: proc(fn_type_id: TypeId) -> TypeId {
    fn_ty := get_type(fn_type_id)
    if fn_ty.kind != .Function || !fn_ty.fn.is_variadic || fn_ty.fn.is_external {
        return fn_type_id
    }

    n_fixed := len(fn_ty.fn.args)
    args := make([]Arg, n_fixed + 1, allocator=get_ctx().allocator)
    copy(args, fn_ty.fn.args)
    args[n_fixed] = Arg{name=fn_ty.fn.variadic_name, type=fn_ty.fn.gala_abi_ty}

    lowered := Type{}
    lowered.kind = .Function
    lowered.fn = fn_ty.fn
    lowered.fn.args = args
    lowered.fn.is_variadic = false
    return new_fn_type(lowered)
}

// `any` is passed around as { ptr, i64 }: a pointer to a spilled copy of the
// value plus the TypeId of its concrete type (see cg_box_any).
is_any_type :: proc(t: TypeId) -> bool {
    return get_type(t).kind == .Any
}

// Evaluates one call argument for a parameter of type `param_ty`.
// If the parameter is `any` and the argument isn't already an `any`, the
// value is boxed. If the typechecker marked the arg (needs_boxing), its
// box_type is taken as the concrete type; otherwise the concrete type is
// the argument expression's own type.
cg_call_arg_value :: proc(c: ^CGCtx, a: FnCallArg, param_ty: TypeId) -> string {
    r, returns := reduce_expr_to_single_value(c, cg_expr(c, a.expr))
    assert(returns)

    concrete_ty := expr_ty(a.expr)
    should_box := is_any_type(param_ty) && !is_any_type(concrete_ty)
    if a.needs_boxing {
        concrete_ty = a.box_type
        should_box = true
    }

    if should_box {
        boxed, _ := cg_box_any(c, r, concrete_ty)
        return boxed
    }
    return r
}

// Packs the variadic tail of a call into a `{ ptr, i64 }` slice value:
// the elements are stored into a stack array and the slice points at it.
// With no extra arguments the slice is { null, 0 }.
// For `..any` every element is boxed first, so the array is [n x { ptr, i64 }].
cg_pack_variadic_slice :: proc(c: ^CGCtx, tail: []FnCallArg, elem_ty: TypeId) -> string {
    llvm_int := ty_to_llvm_str(c, integer_type())
    elem_str := "{ ptr, i64 }" if is_any_type(elem_ty) else ty_to_llvm_str(c, elem_ty)
    n := len(tail)

    base := "null"
    if n > 0 {
        arr_ty := aprintf(c, "[%d x %s]", n, elem_str)
        base = new_tmp(c)
        cwritefln(c, "\t%s = alloca %s", base, arr_ty)
        for a, i in tail {
            v := cg_call_arg_value(c, a, elem_ty)
            p := new_tmp(c)
            cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i64 0, i64 %d",
                p, arr_ty, base, i)
            cwritefln(c, "\tstore %s %s, ptr %s", elem_str, v, p)
        }
    }

    v1 := new_tmp(c)
    v2 := new_tmp(c)
    cwritefln(c, "\t%s = insertvalue {{ ptr, %s }} undef, ptr %s, 0", v1, llvm_int, base)
    cwritefln(c, "\t%s = insertvalue {{ ptr, %s }} %s, %s %d, 1", v2, llvm_int, v1, llvm_int, n)
    return v2
}

// Call to an internal variadic: fixed args are evaluated as usual, the tail
// is packed into a slice, and the result is a plain non-variadic call
// against the lowered type.
cg_fn_call_internal_variadic :: proc(c: ^CGCtx, id: ExprId, e: FnCall, target: string) -> CGExprRes {
    fn_type_id := expr_ty(e.target)
    fn_ty := get_type(fn_type_id)
    lowered_id := lower_internal_variadic(fn_type_id)
    sig := cg_abi_lower_signature(c, lowered_id, .SysV)

    n_fixed := len(fn_ty.fn.args)
    assert(len(e.args) >= n_fixed, "not enough arguments for variadic call")

    // SSA values for every lowered parameter: fixed args, then the slice
    values := make([dynamic]string, allocator=get_ctx().allocator)
    for k in 0 ..< n_fixed {
        append(&values, cg_call_arg_value(c, e.args[k], sig.args[k].orig_type))
    }
    append(&values, cg_pack_variadic_slice(c, e.args[n_fixed:], fn_ty.fn.variadic_ty))
    assert(len(values) == len(sig.args))

    call_args := make([dynamic]string, allocator=get_ctx().allocator)

    sret_slot := ""
    if sig.ret.mode == .Indirect {
        sret_slot = new_tmp(c)
        cwritefln(c, "\t%s = alloca %s", sret_slot, ty_to_llvm_str(c, sig.ret.orig_type))
        append(&call_args, aprintf(c, "ptr sret(%s) align %d %s",
            ty_to_llvm_str(c, sig.ret.orig_type), sig.ret.sret_align, sret_slot))
    }

    for al, k in sig.args {
        r := values[k]
        arg_ty_str := ty_to_llvm_str(c, al.orig_type)

        switch al.mode {
        case .ByVal: {
            slot := new_tmp(c)
            cwritefln(c, "\t%s = alloca %s", slot, arg_ty_str)
            cwritefln(c, "\tstore %s %s, ptr %s", arg_ty_str, r, slot)
            append(&call_args, aprintf(c, "ptr byval(%s) align %d %s", arg_ty_str, al.byval_align, slot))
        }
        case .Direct: {
            if al.needs_coercion {
                slot := new_tmp(c)
                cwritefln(c, "\t%s = alloca %s", slot, arg_ty_str)
                cwritefln(c, "\tstore %s %s, ptr %s", arg_ty_str, r, slot)
                coerced := new_tmp(c)
                cwritefln(c, "\t%s = load %s, ptr %s", coerced, al.coerced_type, slot)
                append(&call_args, aprintf(c, "%s %s", al.coerced_type, coerced))
            } else {
                append(&call_args, aprintf(c, "%s %s", al.coerced_type, r))
            }
        }
        }
    }

    write_call_args := proc(c: ^CGCtx, call_args: [dynamic]string) {
        cwrite(c, "(")
        for a, i in call_args {
            cwritef(c, "%s", a)
            if i < len(call_args) - 1 {
                cwritef(c, ", ")
            }
        }
        cwriteln(c, ")")
    }

    if sig.ret.mode == .Indirect {
        cwritef(c, "\tcall void %s", target)
        write_call_args(c, call_args)

        loaded := new_tmp(c)
        cwritefln(c, "\t%s = load %s, ptr %s", loaded, ty_to_llvm_str(c, sig.ret.orig_type), sret_slot)
        return {kind=.Value, v=loaded, id=id}
    } else if sig.ret.coerced_type == "void" {
        cwritef(c, "\tcall void %s", target)
        write_call_args(c, call_args)
        return {kind=.None, id=id}
    } else {
        new_t := new_tmp(c)
        cwritef(c, "\t%s = call %s %s", new_t, sig.ret.coerced_type, target)
        write_call_args(c, call_args)

        if sig.ret.needs_coercion {
            real_ty_str := ty_to_llvm_str(c, sig.ret.orig_type)
            slot := new_tmp(c)
            cwritefln(c, "\t%s = alloca %s", slot, real_ty_str)
            cwritefln(c, "\tstore %s %s, ptr %s", sig.ret.coerced_type, new_t, slot)
            loaded := new_tmp(c)
            cwritefln(c, "\t%s = load %s, ptr %s", loaded, real_ty_str, slot)
            return {kind=.Value, v=loaded, id=id}
        }
        return {kind=.Value, v=new_t, id=id}
    }
}

cg_fn_call :: proc(c: ^CGCtx, id: ExprId, e: FnCall) -> CGExprRes {
    t := cg_fn_call_target(c, e.target)
    fn_type_id := expr_ty(e.target)
    fn_ty := get_type(fn_type_id)

    // internal (Gala) variadics: pack the tail into a slice and call the
    // lowered, non-variadic form. Extern C variadics continue below.
    if fn_ty.fn.is_variadic && !fn_ty.fn.is_external {
        return cg_fn_call_internal_variadic(c, id, e, t)
    }

    sig := cg_abi_lower_signature(c, fn_type_id, .SysV)

    call_args := make([dynamic]string, allocator=get_ctx().allocator)

    sret_slot := ""
    if sig.ret.mode == .Indirect {
        sret_slot = new_tmp(c)
        cwritefln(c, "\t%s = alloca %s", sret_slot, ty_to_llvm_str(c, sig.ret.orig_type))
        append(&call_args, aprintf(c, "ptr sret(%s) align %d %s",
            ty_to_llvm_str(c, sig.ret.orig_type), sig.ret.sret_align, sret_slot))
    }

    // Only the true fixed prefix goes through sig.args — the trailing
    // C-variadic placeholder slot in fn_ty.fn.args (and its corresponding
    // sig.args entry) is never a real argument to lower here.
    fixed_arg_count := len(e.args)
    if fn_ty.fn.is_variadic { // get fixed args from fn signature
        fixed_arg_count = len(fn_ty.fn.args)
    }

    // ---- fixed params ----
    for k in 0 ..< fixed_arg_count {
        a := e.args[k]
        al := sig.args[k]
        // boxes into `any` when the parameter is `any`
        r := cg_call_arg_value(c, a, al.orig_type)
        arg_ty_str := ty_to_llvm_str(c, al.orig_type)

        switch al.mode {
        case .ByVal: {
            slot := new_tmp(c)
            cwritefln(c, "\t%s = alloca %s", slot, arg_ty_str)
            cwritefln(c, "\tstore %s %s, ptr %s", arg_ty_str, r, slot)
            append(&call_args, aprintf(c, "ptr byval(%s) align %d %s", arg_ty_str, al.byval_align, slot))
        }
        case .Direct: {
            if al.needs_coercion {
                slot := new_tmp(c)
                cwritefln(c, "\t%s = alloca %s", slot, arg_ty_str)
                cwritefln(c, "\tstore %s %s, ptr %s", arg_ty_str, r, slot)
                coerced := new_tmp(c)
                cwritefln(c, "\t%s = load %s, ptr %s", coerced, al.coerced_type, slot)
                append(&call_args, aprintf(c, "%s %s", al.coerced_type, coerced))
            } else {
                append(&call_args, aprintf(c, "%s %s", al.coerced_type, r))
            }
        }
        }
    }

    // ---- trailing C-variadic arguments ----
    // Each gets C's default argument promotions applied (see
    // c_variadic_promote), never the boxing or slice-packing that a Gala
    // `..T` tail would need — there is no such tail here, only extern
    // `...`.
    if fn_ty.fn.is_variadic && fn_ty.fn.is_external { // and is external
        for k in fixed_arg_count ..< len(e.args) {
            a := e.args[k]
            v, returns := reduce_expr_to_single_value(c, cg_expr(c, a.expr))
            assert(returns)

            promoted_v, promoted_ty_str := cg_variadic_promote(c, v, expr_ty(a.expr))
            append(&call_args, aprintf(c, "%s %s", promoted_ty_str, promoted_v))
        }
    }

    // LLVM requires the full fixed-parameter TYPE list between the
    // callee's return type and "..." for a variadic call site.
    variadic_prefix := ""
    if fn_ty.fn.is_variadic {
        vb: strings.Builder
        strings.builder_init(&vb, get_ctx().allocator)
        strings.write_string(&vb, "(")
        if sig.ret.mode == .Indirect {
            strings.write_string(&vb, aprintf(c, "ptr sret(%s), ", ty_to_llvm_str(c, sig.ret.orig_type)))
        }
        for al in sig.args[:fixed_arg_count] {
            if al.mode == .ByVal {
                strings.write_string(&vb, aprintf(c, "ptr byval(%s) align %d",
                    ty_to_llvm_str(c, al.orig_type), al.byval_align))
            } else {
                strings.write_string(&vb, al.coerced_type)
            }
            strings.write_string(&vb, ", ")
        }
        strings.write_string(&vb, "...)")
        variadic_prefix = strings.to_string(vb)
    }

    write_call_args := proc(c: ^CGCtx, call_args: [dynamic]string) {
        cwrite(c, "(")
        for a, i in call_args {
            cwritef(c, "%s", a)
            if i < len(call_args) - 1 {
                cwritef(c, ", ")
            }
        }
        cwriteln(c, ")")
    }

    if sig.ret.mode == .Indirect {
        cwritef(c, "\tcall void ")
        if fn_ty.fn.is_variadic { cwritef(c, "%s", variadic_prefix) }
        cwritef(c, "%s", t)
        write_call_args(c, call_args)

        loaded := new_tmp(c)
        cwritefln(c, "\t%s = load %s, ptr %s", loaded, ty_to_llvm_str(c, sig.ret.orig_type), sret_slot)
        return {kind=.Value, v=loaded, id=id}
    } else if sig.ret.coerced_type == "void" {
        cwritef(c, "\tcall void ")
        if fn_ty.fn.is_variadic { cwritef(c, "%s", variadic_prefix) }
        cwritef(c, "%s", t)
        write_call_args(c, call_args)
        return {kind=.None, id=id}
    } else {
        new_t := new_tmp(c)
        cwritef(c, "\t%s = call %s ", new_t, sig.ret.coerced_type)
        if fn_ty.fn.is_variadic { cwritef(c, "%s", variadic_prefix) }
        cwritef(c, "%s", t)
        write_call_args(c, call_args)

        if sig.ret.needs_coercion {
            real_ty_str := ty_to_llvm_str(c, sig.ret.orig_type)
            slot := new_tmp(c)
            cwritefln(c, "\t%s = alloca %s", slot, real_ty_str)
            cwritefln(c, "\tstore %s %s, ptr %s", sig.ret.coerced_type, new_t, slot)
            loaded := new_tmp(c)
            cwritefln(c, "\t%s = load %s, ptr %s", loaded, real_ty_str, slot)
            return {kind=.Value, v=loaded, id=id}
        }
        return {kind=.Value, v=new_t, id=id}
    }
}
// Emits the C-variadic default-argument-promotion conversion for an
// already-reduced value `v` of static type `type_id`, if one applies.
// Pure passthrough (same value, same type string) otherwise.
cg_variadic_promote :: proc(c: ^CGCtx, v: string, type_id: TypeId) -> (string, string) {
    promotion, promoted_ty_str := c_variadic_promote(type_id)
    orig_ty_str := ty_to_llvm_str(c, type_id)

    instr := ""
    switch promotion {
    case .None:            return v, orig_ty_str
    case .FloatToDouble:   instr = "fpext"
    case .ZeroExtendToInt: instr = "zext"
    case .SignExtendToInt: instr = "sext"
    }

    t := new_tmp(c)
    cwritefln(c, "\t%s = %s %s %s to %s", t, instr, orig_ty_str, v, promoted_ty_str)
    return t, promoted_ty_str
}
