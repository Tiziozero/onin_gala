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
cg_expr :: proc(c: ^CGCtx, id: ExprId) -> CGExprRes {
    span := get_span(id).span
    data := get_file_lines(get_ctx().current_file, span)
    // cwritefln(c, "\t; cg_expr \"%s\"",
        // string(get_ctx().files[get_ctx().current_file][span.start:span.end]))
    // in cg_expr:
    switch e in get_expr(id) {
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
        /*
           ; 1. decay the global array into a plain ptr
           %str.ptr = getelementptr inbounds [6 x i8], ptr @tstring1, i64 0, i64 0

           ; 2. build the {ptr, i64} value piece by piece
           %tmp0 = insertvalue { ptr, i64 } undef, ptr %str.ptr, 0
           %tmp1 = insertvalue { ptr, i64 } %tmp0, i64 5, 1

           ; 3. store the fully-built struct value into the alloca
           store { ptr, i64 } %tmp1, ptr %s
         */
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
        // returns t2 with the slice
        return {kind=.Value, v=t2}
    }
    case Deref: {
        // rvalue: the pointer itself, already loaded
        ptr_val := cg_addr(c, e.expr);
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
            // identical bit layout, different label — no instruction, reuse the value
            return {kind=.Value, v=reduced}

        case .Instr:
            t := new_tmp(c)
            cwritefln(c, "\t%s = %s %s %s to %s", t, op,
                ty_to_llvm_str(c, from_ty), reduced, ty_to_llvm_str(c, to_ty))
            return {kind=.Value, v=t}

        case .Memory:
            // General fallback: reinterpret through memory. Correct for ANY pair —
            // struct<->struct, struct<->array, scalar<->aggregate, whatever —
            // because store/load don't care about type, only bytes.
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
        // compute length
        // gen ends
        start, sret := reduce_expr_to_single_value(c, cg_expr(c, e.start))
        assert(sret);
        end, eret := reduce_expr_to_single_value(c, cg_expr(c, e.end))
        assert(eret);

        // reduce both to int
        if get(expr_ty(e.start)).kind != .UInt64 {
            op, ok := ty_to_llvm_cast_op(expr_ty(e.start), integer_type());
            if !ok {
                op = "bitcast"
                // nothing?
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
                // nothing?
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
        // get ptr
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
    // cg_expr's Index:
    case Index: {
        ptr := cg_elem_ptr(c, e.target, e.index)
        v := new_tmp(c)
        cwritefln(c, "\t%s = load %s, ptr %s", v, ty_to_llvm_str(c, expr_ty(id)), ptr)
        return {kind=.Value, v=v}
    }
    case FixedSizeArray: {
        assert(e.initialiser == nil);
        ty := ty_to_llvm_str(c, expr_ty(id));
        t := aprintf(c, "zeroinitializer");
        return {kind=.Value, v=t}
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
        l_v, returns_l := reduce_expr_to_single_value(c, cg_expr(c, e.left))
        assert(returns_l);
        r_v, returns_r := reduce_expr_to_single_value(c, cg_expr(c, e.right))
        assert(returns_r);

        operand_ty := expr_ty(e.left)
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
        case .Variable, .Symbol: {
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
    case: panic("impl");
    }
}


cg_fn_call :: proc(c: ^CGCtx, id: ExprId, e: FnCall) -> CGExprRes {
    // Every call — internal Gala function or extern C function alike —
    // goes through cg_abi_lower_signature. See abi_sysv.odin.
    t := cg_fn_call_target(c, e.target);
    fn_type_id := expr_ty(e.target)
    fn_ty := get_type(fn_type_id);
    sig := cg_abi_lower_signature(c, fn_type_id, .SysV)

    call_args := make([dynamic]string, allocator=get_ctx().allocator)

    // sret slot, if the return value is passed indirectly, comes first
    sret_slot := ""
    if sig.ret.mode == .Indirect {
        sret_slot = new_tmp(c)
        cwritefln(c, "\t%s = alloca %s", sret_slot, ty_to_llvm_str(c, sig.ret.orig_type))
        append(&call_args, aprintf(c, "ptr sret(%s) align %d %s",
            ty_to_llvm_str(c, sig.ret.orig_type), sig.ret.sret_align, sret_slot))
    }

    // A gala (non-extern) variadic function's trailing parameter is a
    // real, single Slice(elem_type) parameter, not C-style "...". The
    // caller still writes individual trailing expressions though (e.g.
    // `print_i32(fmt, 1, 2, 3)`), so those need collecting into an
    // actual runtime slice value — handled in the block below, after
    // this loop only walks the real fixed params.
    is_gala_variadic :=
        !fn_ty.fn.is_variadic &&
        len(fn_ty.fn.args) > 0 &&
        fn_ty.fn.args[len(fn_ty.fn.args)-1].is_variadic

    // The count of TRUE fixed parameters — i.e. excluding the trailing
    // declared slot that stands in for "the rest": for an extern C
    // variadic that's the `any`-typed placeholder param
    // (fn_ty.fn.is_variadic), for a gala variadic it's the
    // Slice(elem_type) param (is_gala_variadic). sig.args still has an
    // ABI-lowered entry for that placeholder slot too (lowered as if it
    // were a real `any`/slice parameter, giving `{ ptr, i64 }`) — that
    // entry must never be consulted for what the caller actually passes
    // past this point, only for fixed params before it.
    fixed_arg_count := len(e.args)
    if fn_ty.fn.is_variadic || is_gala_variadic {
        fixed_arg_count = len(fn_ty.fn.args) - 1
    }

    for k in 0 ..< len(e.args) {
        if is_gala_variadic && k >= fixed_arg_count {
            break // handled by the slice-packing block below instead
        }

        a := e.args[k]
        r, returns := reduce_expr_to_single_value(c, cg_expr(c, a.expr));
        assert(returns);

        // default: the value/type computed normally, straight from the
        // expression itself — this is also what a trailing extern C
        // variadic argument uses (see below), since sig.args has no
        // meaningful entry for "the Nth trailing vararg", only for the
        // one placeholder slot standing in for all of them.
        arg_val := r
        arg_ty_str := ty_to_llvm_str(c, expr_ty(a.expr))

        // target param slot is `any` — box {data ptr, typeid} instead
        // of passing the raw concrete value. box_type/needs_boxing
        // were set by the typechecker's FnCall case.
        if a.needs_boxing {
            arg_val, arg_ty_str = cg_box_any(c, r, a.box_type)
        }

        if k >= fixed_arg_count {
            // Trailing extern C variadic argument: pass using the
            // expression's own type — NOT sig.args[k]'s lowering, which
            // (past the fixed params) only describes the trailing `any`
            // placeholder parameter's shape, not what's actually here.
            append(&call_args, aprintf(c, "%s %s", arg_ty_str, arg_val))
            continue
        }

        al := sig.args[k]
        switch al.mode {
        case .ByVal: {
            arg_ty_str := ty_to_llvm_str(c, al.orig_type)
            slot := new_tmp(c)
            cwritefln(c, "\t%s = alloca %s", slot, arg_ty_str)
            cwritefln(c, "\tstore %s %s, ptr %s", arg_ty_str, arg_val, slot)
            append(&call_args, aprintf(c, "ptr byval(%s) align %d %s", arg_ty_str, al.byval_align, slot))
        }
        case .Direct: {
            if al.needs_coercion {
                arg_ty_str := ty_to_llvm_str(c, al.orig_type)
                slot := new_tmp(c)
                cwritefln(c, "\t%s = alloca %s", slot, arg_ty_str)
                cwritefln(c, "\tstore %s %s, ptr %s", arg_ty_str, arg_val, slot)
                coerced := new_tmp(c)
                cwritefln(c, "\t%s = load %s, ptr %s", coerced, al.coerced_type, slot)
                append(&call_args, aprintf(c, "%s %s", al.coerced_type, coerced))
            } else {
                append(&call_args, aprintf(c, "%s %s", al.coerced_type, arg_val))
            }
        }
        }
    }

    // Pack the trailing call-site expressions into the real
    // Slice(elem_type) value the gala callee actually expects.
    if is_gala_variadic {
        elem_ty := get_type(fn_ty.fn.args[len(fn_ty.fn.args)-1].type).slice.type
        elem_ty_str := ty_to_llvm_str(c, elem_ty)
        n := len(e.args) - fixed_arg_count

        data_ptr := "null"
        if n > 0 {
            arr_ty_str := aprintf(c, "[%d x %s]", n, elem_ty_str)
            arr_slot := new_tmp(c)
            cwritefln(c, "\t%s = alloca %s", arr_slot, arr_ty_str)

            for k in 0 ..< n {
                a := e.args[fixed_arg_count + k]
                v, returns := reduce_expr_to_single_value(c, cg_expr(c, a.expr))
                assert(returns)
                elem_ptr := new_tmp(c)
                cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i64 0, i64 %d",
                    elem_ptr, arr_ty_str, arr_slot, k)
                cwritefln(c, "\tstore %s %s, ptr %s", elem_ty_str, v, elem_ptr)
            }

            decayed := new_tmp(c)
            cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i64 0, i64 0",
                decayed, arr_ty_str, arr_slot)
            data_ptr = decayed
        }

        v1 := new_tmp(c)
        v2 := new_tmp(c)
        cwritefln(c, "\t%s = insertvalue {{ ptr, i64 }} undef, ptr %s, 0", v1, data_ptr)
        cwritefln(c, "\t%s = insertvalue {{ ptr, i64 }} %s, i64 %d, 1", v2, v1, n)

        append(&call_args, aprintf(c, "{ ptr, i64 } %s", v2))
    }

    // For variadic calls, LLVM needs the full parameter TYPE list
    // (fixed args, ABI-lowered) between the callee's return type and
    // the "..." before the actual argument list. Only the TRUE fixed
    // prefix goes here — sig.args[fixed_arg_count:] is the placeholder
    // slot's own lowering and must never appear in this list, or LLVM
    // sees a phantom fixed `{ ptr, i64 }` parameter that was never
    // actually declared.
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
        return {kind=.Value, v=new_t, id=id};
    }
}
