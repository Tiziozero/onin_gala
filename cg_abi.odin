// cg_abi.odin
package main

import "core:fmt"

// ============================================================================
// Unified ABI layer.
//
// Every function definition, declaration, and call goes through
// cg_abi_lower_signature instead of branching on `is_external`. AbiKind
// exists so a distinct calling convention can be added later without
// touching call sites — right now BOTH .None and .SysV resolve to the same
// SysV x86-64 lowering below (per design decision: internal Gala-to-Gala
// calls get full SysV treatment too, not a separate "raw aggregate"
// convention). If that's ever wanted, give .None its own branch inside
// cg_abi_lower_signature.
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
    class:     AbiClass,
    llvm_type: string, // valid once class != .NoClass
    hi:        int,    // exclusive end (absolute struct offset) of the furthest real data byte seen in this eightbyte
}

// Result of classifying an aggregate (struct / fixed array / slice /
// string) for argument/return purposes. Scalars are handled separately in
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
    case .Flt64, .Flt32, .Flt16, .Flt_8:
        return .Sse
    case:
        return .Integer // ints, Byte, Rune, Bool, Pointer, Function
    }
}

// Naive sequential (no field reordering) struct layout — natural C-style
// alignment, no explicit #packed support. Good enough for classification.
type_align_of :: proc(type_id: TypeId) -> int {
    ty := get_type(type_id)
    #partial switch ty.kind {
    case .UInt64, .Int64, .Flt64, .Pointer, .Function:
        return 8
    case .UInt32, .Int32, .Flt32:
        return 4
    case .UInt16, .Int16, .Flt16:
        return 2
    case .UInt_8, .Int_8, .Flt_8, .Byte, .Rune, .Bool:
        return 1
    case .Slice, .String:
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
    case:
        gala_panic("type_align_of: unhandled kind")
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
    case .FixedSizeArray: {
        elem_size := type_size(ty.fixed_size_array.type)
        for i in 0 ..< ty.fixed_size_array.size {
            classify_into_eightbytes(ty.fixed_size_array.type, base_offset + i * elem_size, eb)
        }
    }
    case .Slice, .String: {
        // { ptr, i64 } — two INTEGER eightbytes. Always eightbyte-aligned
        // within the parent since its own alignment is 8.
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
        end := base_offset + type_size(type_id)
        if end > eb[idx].hi do eb[idx].hi = end
    }
    }
}

int_class_llvm_type :: proc(nbytes: int) -> string {
    switch {
    case nbytes <= 1: return "i8"
    case nbytes <= 2: return "i16"
    case nbytes <= 4: return "i32"
    case: return "i64"
    }
}

// Scalar LLVM type strings, hardcoded rather than routed through
// ty_to_llvm_str/CGCtx — classify_type doesn't always have a CGCtx handy,
// and scalars never need memory-roundtrip coercion anyway (see
// AbiArgLowering.needs_coercion), so there's nothing to memoize.
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
        gala_panic("scalar_llvm_str: unhandled scalar kind")
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
    case .FixedSizeArray: {
        if ty.fixed_size_array.size == 0 do return 0
        elem_size := type_size(ty.fixed_size_array.type)
        return (ty.fixed_size_array.size - 1) * elem_size + abi_content_size(ty.fixed_size_array.type)
    }
    case:
        return type_size(type_id)
    }
}
// Classifies an aggregate (struct / fixed array) for ABI purposes. Slices
// and strings are handled inline in lower_abi_value since they're always
// exactly the right shape already.
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
        class := eb[i].class
        if class == .NoClass do class = .Integer
        r.eightbytes[i].class = class

        // SysV/clang shrink a coercion type to how much real data THIS
        // eightbyte alone holds. Padding elsewhere in the struct -- even a
        // same-eightbyte gap before the next field starts -- never widens
        // it, and data sitting in the OTHER eightbyte never does either.
        // (Previously this used `size - i*8`, i.e. the struct's overall
        // size minus this eightbyte's offset -- that leaks information
        // from one eightbyte into the other's width decision. It happened
        // to agree with the correct answer for S12/DoubleInt/LongFloat,
        // where only ONE of the two eightbytes is ever short on data, but
        // it's wrong for IntDouble/FloatLong, where eightbyte 0 is short
        // (only 4 real bytes, alignment padding fills the rest) while
        // eightbyte 1 is completely full -- confirmed against clang's
        // actual output: `{i32,f64}` -> `{i32,double}`, `{f32,i64}` ->
        // `{float,i64}`, not `{i64,double}` / `{double,i64}`.)
        lo := i * 8
        nbytes := eb[i].hi - lo
        if nbytes <= 0 || nbytes > 8 do nbytes = 8

        if class == .Sse {
            r.eightbytes[i].llvm_type = nbytes <= 4 ? "float" : "double"
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
    case .Slice, .String:
        // already the correct 2-eightbyte { ptr, i64 } layout
        return false, "{ ptr, i64 }", false, 8
    case .Struct, .FixedSizeArray:
        c := classify_type(type_id)
        if c.is_memory {
            return true, "", false, c.align
        }
        if c.num_eightbytes == 1 {
            return false, c.eightbytes[0].llvm_type, true, c.align
        }
        coerced := fmt.tprintf("{{ %s, %s }}", c.eightbytes[0].llvm_type, c.eightbytes[1].llvm_type)
        return false, coerced, true, c.align
    case:
        gala_panic("lower_abi_value: unhandled kind")
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
}

AbiSignature :: struct {
    ret:  AbiRetLowering,
    args: []AbiArgLowering,
}

// The single entry point every function definition, declaration, and call
// goes through.
cg_abi_lower_signature :: proc(c: ^CGCtx, fn_type_id: TypeId, kind: AbiKind) -> AbiSignature {
    _ = kind // .None and .SysV currently lower identically — see AbiKind doc comment
    fn_ty := get_type(fn_type_id)
    sig: AbiSignature

    if get_type(fn_ty.fn.ret_ty).kind == .Void {
        sig.ret = AbiRetLowering{orig_type = fn_ty.fn.ret_ty, mode = .Direct, coerced_type = "void"}
    } else {
        is_mem, coerced, needs_coerce, align := lower_abi_value(fn_ty.fn.ret_ty)
        if is_mem {
            sig.ret = AbiRetLowering{
                orig_type = fn_ty.fn.ret_ty,
                mode      = .Indirect,
                coerced_type = "void",
                sret_align = align,
            }
        } else {
            sig.ret = AbiRetLowering{
                orig_type      = fn_ty.fn.ret_ty,
                mode           = .Direct,
                coerced_type   = coerced,
                needs_coercion = needs_coerce,
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
            })
        }
    }
    sig.args = args[:]
    return sig
}
