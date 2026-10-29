// cg_abi.odin
package main

import "core:fmt"

// ============================================================================
// Unified ABI layer.
//
// Every function definition, declaration, and call goes through
// cg_abi_lower_signature instead of branching on `is_external`. AbiKind lets
// a distinct calling convention be added later without touching call sites;
// for now BOTH .None and .SysV use the same SysV x86-64 lowering (internal
// Gala-to-Gala calls get full SysV treatment too). To change that, give .None
// its own branch inside cg_abi_lower_signature.
// ============================================================================

AbiKind :: enum {
    None,
    SysV,
}

AbiClass :: enum {
    NoClass,
    Integer,
    Sse,
    Memory,
}

AbiEightbyte :: struct {
    class: AbiClass,
    llvm_type: string,
    hi: int, // end offset (from struct start) of the last real data byte

    f32_count: int,
    f16_count: int,
    only_f32: bool,
    // a double lives in this eightbyte (only mixes with floats via unions)
    has_double: bool,
}

// Result of classifying an aggregate (struct / fixed array / union) for
// argument/return purposes. Scalars and slice-likes are handled directly in
// lower_abi_value and never go through this.
AbiClassified :: struct {
    is_memory:      bool,
    eightbytes:     [2]AbiEightbyte,
    num_eightbytes: int, // 0 if is_memory, else 1 or 2
    size:           int,
    align:          int,
}

merge_abi_class :: proc(a, b: AbiClass) -> AbiClass {
    if a == b do return a
    if a == .NoClass do return b
    if b == .NoClass do return a
    if a == .Memory || b == .Memory do return .Memory
    if a == .Integer || b == .Integer do return .Integer
    return .Sse
}

scalar_abi_class :: proc(k: TypeKind) -> AbiClass {
    #partial switch k {
    case .Flt64, .Flt32, .Flt16:
        return .Sse
    case:
        // ints, Byte, Rune, Bool, Pointer, Function — and Flt_8, which is
        // lowered as a plain i8 (see scalar_llvm_str) and so travels in an
        // integer register.
        return .Integer
    }
}

// Naive sequential (no field reordering) struct layout — natural C-style
// alignment, no explicit #packed support. Good enough for classification.
type_align_of :: proc(type_id: TypeId) -> int {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .UInt64, .Int64, .Flt64, .Pointer, .Function:
        return 8
    case .UInt32, .Int32, .Flt32, .Rune:
        return 4
    case .UInt16, .Int16, .Flt16:
        return 2
    case .UInt_8, .Int_8, .Flt_8, .Byte, .Bool:
        return 1
    case .Slice, .String, .Any:
        // `any` is boxed as { ptr, i64 }, same header shape as a slice/string.
        return 8
    case .FixedSizeArray:
        return type_align_of(ty.fixed_size_array.type)
    case .Struct:
        a := 1
        for f in ty.structure.fields {
            fa := type_align_of(f.type)
            if fa > a do a = fa
        }
        return a
    case .Union:
        a := 1
        for f in ty.union_fields {
            fa := type_align_of(f.type)
            if fa > a do a = fa
        }
        return a
    case:
        gala_panic("type_align_of: unhandled kind", ty.kind)
    }
    return 1
}

// Offsets of each field of a struct, laid out sequentially with natural
// alignment padding (no reordering).
struct_field_offsets :: proc(type_id: TypeId) -> []int {
    ty := get_type(type_id)
    assert(ty.kind == .Struct)
    offsets := make([]int, len(ty.structure.fields), allocator = context.temp_allocator)
    off := 0
    for f, i in ty.structure.fields {
        fa := type_align_of(f.type)
        if off % fa != 0 {
            off += fa - (off % fa)
        }
        offsets[i] = off
        off += type_size(f.type)
    }
    return offsets
}

// Walks a (possibly nested) type and merges its scalar leaves into the
// eightbyte buckets covering [base_offset .. base_offset+size). Only ever
// called on types whose total containing aggregate is <=16 bytes, so the
// two-element `eb` array is always in bounds.
classify_into_eightbytes :: proc(type_id: TypeId, base_offset: int, eb: ^[2]AbiEightbyte) {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .Struct: {
        offsets := struct_field_offsets(type_id)
        for f, i in ty.structure.fields {
            classify_into_eightbytes(f.type, base_offset + offsets[i], eb)
        }
    }
    case .Union: {
        // All members overlap at base_offset. Classify each into a scratch
        // buffer and combine there (float counts via max, since overlapping
        // members don't add up), then add that into `eb`.
        merged: [2]AbiEightbyte
        for f in ty.union_fields {
            tmp: [2]AbiEightbyte
            classify_into_eightbytes(f.type, base_offset, &tmp)
            for i in 0 ..< 2 {
                merged[i].class      = merge_abi_class(merged[i].class, tmp[i].class)
                merged[i].hi         = max(merged[i].hi, tmp[i].hi)
                merged[i].f32_count  = max(merged[i].f32_count, tmp[i].f32_count)
                merged[i].f16_count  = max(merged[i].f16_count, tmp[i].f16_count)
                merged[i].has_double = merged[i].has_double || tmp[i].has_double
            }
        }
        for i in 0 ..< 2 {
            eb[i].class      = merge_abi_class(eb[i].class, merged[i].class)
            eb[i].hi         = max(eb[i].hi, merged[i].hi)
            eb[i].f32_count  += merged[i].f32_count
            eb[i].f16_count  += merged[i].f16_count
            eb[i].has_double = eb[i].has_double || merged[i].has_double
        }
    }
    case .FixedSizeArray: {
        elem_size := type_size(ty.fixed_size_array.type)
        for i in 0 ..< ty.fixed_size_array.size {
            classify_into_eightbytes(ty.fixed_size_array.type, base_offset + i * elem_size, eb)
        }
    }
    case .Slice, .String, .Any: {
        // { ptr, i64 } — two INTEGER eightbytes, always eightbyte-aligned.
        // `any`'s second word is a typeid tag, not a length, but both are
        // 8-byte Integer words. This case must exist so a nested slice/any
        // doesn't fall through to the scalar default and lose its 2nd word.
        idx0 := base_offset / 8
        eb[idx0].class = merge_abi_class(eb[idx0].class, .Integer)
        eb[idx0 + 1].class = merge_abi_class(eb[idx0 + 1].class, .Integer)
        if base_offset + 8 > eb[idx0].hi do eb[idx0].hi = base_offset + 8
        if base_offset + 16 > eb[idx0 + 1].hi do eb[idx0 + 1].hi = base_offset + 16
    }
    case: {
        class := scalar_abi_class(ty.kind)
        idx := base_offset / 8

        eb[idx].class = merge_abi_class(eb[idx].class, class)

        if ty.kind == .Flt32 {
            eb[idx].f32_count += 1
        }
        if ty.kind == .Flt16 {
            eb[idx].f16_count += 1
        }
        if ty.kind == .Flt64 {
            eb[idx].has_double = true
        }

        end := base_offset + type_size(type_id)
        if end > eb[idx].hi do eb[idx].hi = end
    }
    }
}

// Integer type covering exactly `nbytes` bytes of real data. Clang uses
// odd-width integers (i24, i40, i48, i56) for 3/5/6/7-byte remainders;
// rounding up would make the memory round-trip in cg_emit_abi_arg /
// cg_emit_call read or write PAST the end of a smaller slot.
int_class_llvm_type :: proc(nbytes: int) -> string {
    switch nbytes {
    case 1: return "i8"
    case 2: return "i16"
    case 3: return "i24"
    case 4: return "i32"
    case 5: return "i40"
    case 6: return "i48"
    case 7: return "i56"
    case 8: return "i64"
    case: return "i64"
    }
}

// Scalar LLVM type strings, hardcoded rather than routed through
// ty_to_llvm_str/CGCtx — classify_type doesn't always have a CGCtx handy,
// and scalars never need memory-roundtrip coercion anyway.
scalar_llvm_str :: proc(type_id: TypeId) -> string {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .Pointer, .Function: return "ptr"
    case .Flt64: return "double"
    case .Flt32: return "float"
    case .Flt16: return "half"
    case .Flt_8: return "i8" // no dedicated llvm 8-bit float type in use here
    case .Int64, .UInt64: return "i64"
    case .Int32, .UInt32: return "i32"
    case .Int16, .UInt16: return "i16"
    case .Int_8, .UInt_8, .Byte: return "i8"
    case .Rune: return "i32"
    case .Bool: return "i1"
    case:
        debugln(type_id, ty, get_span(type_id))
        highlight_lines(get_span(type_id))
        gala_panic("scalar_llvm_str: unhandled scalar kind", ty.kind)
    }
    return ""
}

// Extension attribute a scalar parameter / return value needs under the
// x86-64 SysV ABI as implemented by clang: anything narrower than 32 bits is
// extended to 32 bits by the CALLER, and clang/gcc callees rely on that.
//
//   bool, unsigned char/short -> "zeroext"
//   signed char/short         -> "signext"
//
// Flt_8 is lowered as a plain i8, so it is treated as unsigned. Returns ""
// for everything else (including all aggregates).
abi_scalar_ext :: proc(type_id: TypeId) -> string {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .Bool, .Byte, .UInt_8, .UInt16, .Flt_8:
        return "zeroext"
    case .Int_8, .Int16:
        return "signext"
    }
    return ""
}

abi_content_size :: proc(type_id: TypeId) -> int {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .Struct: {
        n := len(ty.structure.fields)
        if n == 0 do return 0
        offsets := struct_field_offsets(type_id)
        last := n - 1
        return offsets[last] + abi_content_size(ty.structure.fields[last].type)
    }
    case .Union: {
        biggest := 0
        for f in ty.union_fields {
            biggest = max(biggest, abi_content_size(f.type))
        }
        return biggest
    }
    case .FixedSizeArray: {
        if ty.fixed_size_array.size == 0 do return 0
        elem_size := type_size(ty.fixed_size_array.type)
        return (ty.fixed_size_array.size - 1) * elem_size + abi_content_size(ty.fixed_size_array.type)
    }
    case:
        return type_size(type_id)
    }
}

// Classifies an aggregate (struct / fixed array / union) for ABI purposes.
// Slices and strings are handled inline in lower_abi_value since they're
// always exactly the right shape already.
classify_type :: proc(type_id: TypeId) -> AbiClassified {
    size := type_size(type_id)
    align := type_align_of(type_id)

    r: AbiClassified
    r.size = size
    r.align = align

    // MEMORY class: too big, or over-aligned past 16 bytes.
    if size > 16 || align > 16 {
        r.is_memory = true
        return r
    }

    eb: [2]AbiEightbyte
    classify_into_eightbytes(type_id, 0, &eb)
    r.num_eightbytes = size <= 8 ? 1 : 2

    for i in 0 ..< r.num_eightbytes {
        eb[i].only_f32 = true
        class := eb[i].class
        if class == .NoClass do class = .Integer
        r.eightbytes[i].class = class
        r.eightbytes[i].f32_count = eb[i].f32_count
        r.eightbytes[i].f16_count = eb[i].f16_count

        // Like clang, shrink the coercion type to the real data in THIS
        // eightbyte only: padding or data in the other eightbyte never
        // changes its width. E.g. `{i32,f64}` -> `{i32,double}` and
        // `{f32,i64}` -> `{float,i64}`.
        lo := i * 8
        nbytes := eb[i].hi - lo
        if nbytes <= 0 || nbytes > 8 do nbytes = 8

        if class == .Sse {
            n32 := eb[i].f32_count
            n16 := eb[i].f16_count
            switch {
            case eb[i].has_double:
                // only possible through a union overlapping a double
                r.eightbytes[i].llvm_type = "double"
            case n16 == 0 && n32 == 2:
                r.eightbytes[i].llvm_type = "<2 x float>"
            case n16 == 0 && n32 == 1:
                r.eightbytes[i].llvm_type = "float"
            case n32 == 0 && n16 == 1:
                r.eightbytes[i].llvm_type = "half"
            case n32 == 0 && n16 == 2:
                r.eightbytes[i].llvm_type = "<2 x half>"
            case n32 == 0 && n16 > 2:
                r.eightbytes[i].llvm_type = "<4 x half>"
            case:
                // a plain double (or an exotic float/half mix that just
                // needs to occupy one SSE register)
                r.eightbytes[i].llvm_type = "double"
            }
        } else {
            r.eightbytes[i].llvm_type = int_class_llvm_type(nbytes)
        }
    }
    return r
}

// ----------------------------------------------------------------------------
// Per-value lowering shared by arguments and the return value.
// ----------------------------------------------------------------------------

// is_memory, coerced llvm type (Direct only), needs_coercion, alignment.
lower_abi_value :: proc(type_id: TypeId) -> (bool, string, bool, int) {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .UInt64, .UInt32, .UInt16, .UInt_8,
         .Int64, .Int32, .Int16, .Int_8,
         .Flt64, .Flt32, .Flt16, .Flt_8,
         .Bool, .Byte, .Rune, .Pointer, .Function:
        // plain scalar, passed as-is, never coerced
        return false, scalar_llvm_str(type_id), false, type_align_of(type_id)
    case .Slice, .String, .Any:
        // Already the correct 2-eightbyte { ptr, i64 } layout. `any` is
        // boxed at the call site (cg_box_any) into this shape before ABI
        // lowering, so defs, extern decls, and calls all agree via
        // cg_abi_lower_signature.
        return false, "{ ptr, i64 }", false, 8
    case .Struct, .FixedSizeArray, .Union:
        c := classify_type(type_id)
        if c.is_memory {
            // byval args are always at least 8-byte aligned on x86-64 SysV
            // (clang emits `byval(%T) align 8` even for 4-aligned structs).
            // sret uses the natural alignment instead — see
            // cg_abi_lower_signature.
            return true, "", false, max(c.align, 8)
        }
        if c.num_eightbytes == 1 {
            return false, c.eightbytes[0].llvm_type, true, c.align
        }
        coerced := fmt.tprintf("{{ %s, %s }}", c.eightbytes[0].llvm_type, c.eightbytes[1].llvm_type)
        return false, coerced, true, c.align
    case:
        debugln(type_id, ty, get_span(type_id))
        highlight_lines(get_span(type_id))
        gala_panic("lower_abi_value: unhandled kind", ty.kind)
    }
    return false, "", false, 0
}

AbiArgMode :: enum {
    Direct, // passed as a (possibly coerced) SSA value
    ByVal,  // passed as `ptr byval(%T) align N`
}

AbiArgLowering :: struct {
    orig_type:      TypeId,
    mode:           AbiArgMode,
    coerced_type:   string, // Direct only
    needs_coercion: bool,   // Direct only
    byval_align:    int,    // ByVal only
    ext:            string, // Direct scalars only: "", "zeroext" or "signext".
                            // Emit as `<coerced_type> <ext>` in defs/decls/calls.
}

AbiRetMode :: enum {
    Direct,
    Indirect, // sret
}

AbiRetLowering :: struct {
    orig_type:      TypeId,
    mode:           AbiRetMode,
    coerced_type:   string, // Direct: llvm return type. Indirect: "void"
    needs_coercion: bool,   // Direct only
    sret_align:     int,    // Indirect only
    ext:            string, // Direct scalars only: "", "zeroext" or "signext".
                            // Emit as `<ext> <coerced_type>` in defs/decls/calls.
}

AbiSignature :: struct {
    ret:  AbiRetLowering,
    args: []AbiArgLowering,
}

// The single entry point every function definition, declaration, and call
// goes through.
cg_abi_lower_signature :: proc(c: ^CGCtx, fn_type_id: TypeId, kind: AbiKind) -> AbiSignature {
    _ = kind // .None and .SysV currently lower identically — see AbiKind
    fn_ty := get_type(fn_type_id)
    sig: AbiSignature

    if get_type(fn_ty.fn.ret_ty).kind == .Void {
        sig.ret = AbiRetLowering{orig_type = fn_ty.fn.ret_ty, mode = .Direct, coerced_type = "void"}
    } else {
        is_mem, coerced, needs_coerce, _ := lower_abi_value(fn_ty.fn.ret_ty)
        if is_mem {
            // sret uses the type's natural alignment (not the >=8 byval
            // minimum lower_abi_value reports for memory-class values).
            sig.ret = AbiRetLowering{
                orig_type    = fn_ty.fn.ret_ty,
                mode         = .Indirect,
                coerced_type = "void",
                sret_align   = type_align_of(fn_ty.fn.ret_ty),
            }
        } else {
            sig.ret = AbiRetLowering{
                orig_type      = fn_ty.fn.ret_ty,
                mode           = .Direct,
                coerced_type   = coerced,
                needs_coercion = needs_coerce,
                ext            = abi_scalar_ext(fn_ty.fn.ret_ty),
            }
        }
    }

    args := make([dynamic]AbiArgLowering, allocator = get_ctx().allocator)
    for a in fn_ty.fn.args {
        is_mem, coerced, needs_coerce, align := lower_abi_value(a.type)
        if is_mem {
            append(&args, AbiArgLowering{orig_type = a.type, mode = .ByVal, byval_align = align})
        } else {
            append(&args, AbiArgLowering{
                orig_type      = a.type,
                mode           = .Direct,
                coerced_type   = coerced,
                needs_coercion = needs_coerce,
                ext            = abi_scalar_ext(a.type),
            })
        }
    }
    sig.args = args[:]
    return sig
}

// C "default argument promotions" (C11 §6.5.2.2p7), applied to every
// argument landing in a true C-variadic `...` slot — never to a fixed
// parameter, and never to a Gala `..T` slice-packed tail (which has a real
// declared element type the callee expects exactly).
//
// Decided before SysV classification: `float` becomes `double` and any
// integer narrower than `int` becomes `int`; SysV then classifies the
// promoted type like any other. Scalars only — aggregates must not be passed
// here.
AbiVariadicPromotion :: enum {
    None,
    FloatToDouble,   // fpext
    ZeroExtendToInt, // zext  (unsigned sub-int types, and bool)
    SignExtendToInt, // sext  (signed sub-int types)
}

// Returns the promotion (if any) required for `type_id` in a C-variadic
// slot, plus the resulting LLVM type string after promotion (identical to
// scalar_llvm_str(type_id) when no promotion applies).
c_variadic_promote :: proc(type_id: TypeId) -> (AbiVariadicPromotion, string) {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .Flt32, .Flt16:
        return .FloatToDouble, "double"
    case .Bool, .Byte, .UInt_8, .UInt16, .Flt_8:
        // Flt_8 is lowered as an i8, so it widens like an unsigned 8-bit int
        // (an fpext from i8 would be invalid IR).
        return .ZeroExtendToInt, "i32"
    case .Int_8, .Int16:
        return .SignExtendToInt, "i32"
    case:
        // Int32/UInt32 and wider, Flt64, Rune, Pointer, Function: already
        // >= variadic minimum width.
        return .None, scalar_llvm_str(type_id)
    }
}
