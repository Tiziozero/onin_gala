package main

import "core:fmt"

CAbiInfo :: struct {
    type: TypeId,
    needs_conversion: bool,
}

lower_c_abi_type :: proc(type_id: TypeId) -> CAbiInfo {
    ty := get_type(type_id)

    #partial switch ty.kind {
    case .Struct:
        size := type_size(type_id)
        switch {
        case size <= 8:
            // one eightbyte, treated as INTEGER class. (SSE/float
            // classification not implemented — an all-float small
            // struct should go in an XMM reg, not GPR. Known gap.)
            return {type = int_type_for_size(size), needs_conversion = true}
        case size <= 16:
            // two eightbytes, both INTEGER class
            return {type = two_eightbytes_type(), needs_conversion = true}
        case:
            // MEMORY class: passed/returned via hidden pointer
            return {type = intern_type({kind = .Pointer, ptr = type_id}), needs_conversion = true}
        }

    case .Slice, .String:
        // Already { ptr, i64 } — exactly the two-eightbyte layout SysV
        // wants for a 16-byte aggregate. No repacking needed.
        return {type = type_id, needs_conversion = false}

    case .UInt64, .UInt32, .UInt16, .UInt_8,
         .Int64, .Int32, .Int16, .Int_8,
         .Flt64, .Flt32, .Flt16, .Flt_8,
         .Bool, .Byte, .Rune, .Pointer:
        return {type = type_id, needs_conversion = false}

    case:
        gala_panic(fmt.tprintf("unsupported C ABI argument type: %v", ty.kind))
    }
}

int_type_for_size :: proc(size: int) -> TypeId {
    switch {
    case size <= 1: return ty_from_name("i8")
    case size <= 2: return ty_from_name("i16")
    case size <= 4: return ty_from_name("i32")
    case size <= 8: return ty_from_name("i64")
    case: gala_panic("int_type_for_size: size too large for a single eightbyte")
    }
}

// NOTE: assumes Field is roughly {name, type}. Adjust if your Field
// struct needs offsets or anything else filled in.
two_eightbytes_type :: proc() -> TypeId {
    i64_ty := ty_from_name("i64");
    return intern_type({
        kind = .Struct,
        structure = {fields = {
            {name = "_0", type = i64_ty},
            {name = "_1", type = i64_ty},
        }},
    })
}

cg_abi_convert :: proc(c: ^CGCtx, value: string, from: TypeId, to: TypeId) -> string {
    from_ty := get_type(from)
    to_ty := get_type(to)

    #partial switch from_ty.kind {
    case .Struct:
        // Indirect (MEMORY class): spill to a stack slot and hand back
        // the pointer itself. Nothing to load — the pointer IS the arg.
        if to_ty.kind == .Pointer {
            slot := new_tmp(c)
            cwritef(c, "\t%s = alloca %s\n", slot, ty_to_llvm_str(c, from))
            cwritef(c, "\tstore %s %s, ptr %s\n", ty_to_llvm_str(c, from), value, slot)
            return slot
        }

        // Register class: bit-reinterpret through memory. Slot must be
        // sized to the LARGER of from/to or a small struct overreads
        // when loaded back as a wider integer.
        n := max(type_size(from), type_size(to))
        slot := new_tmp(c)
        cwritef(c, "\t%s = alloca [%d x i8]\n", slot, n)
        cwritef(c, "\tstore %s %s, ptr %s\n", ty_to_llvm_str(c, from), value, slot)
        loaded := new_tmp(c)
        cwritef(c, "\t%s = load %s, ptr %s\n", loaded, ty_to_llvm_str(c, to), slot)
        return loaded

    case:
        gala_panic("missing abi conversion")
    }
}

// Reverse of cg_abi_convert: given a raw ABI-typed value, unpack it into
// the real type.
cg_abi_unconvert :: proc(c: ^CGCtx, value: string, from: TypeId, to: TypeId) -> string {
    from_ty := get_type(from)

    // Indirect: `value` already points at the real data (sret-style
    // return, or a >16-byte struct received by address). Load straight
    // out of it — don't alloca a slot and copy the pointer's bytes in,
    // that stores 8 bytes then overreads them as a whole struct.
    if from_ty.kind == .Pointer {
        loaded := new_tmp(c)
        cwritef(c, "\t%s = load %s, ptr %s\n", loaded, ty_to_llvm_str(c, to), value)
        return loaded
    }

    // Register class: same oversized-slot fix as cg_abi_convert.
    n := max(type_size(from), type_size(to))
    tmp := new_tmp(c)
    cwritef(c, "\t%s = alloca [%d x i8]\n", tmp, n)
    cwritef(c, "\tstore %s %s, ptr %s\n", ty_to_llvm_str(c, from), value, tmp)
    loaded := new_tmp(c)
    cwritef(c, "\t%s = load %s, ptr %s\n", loaded, ty_to_llvm_str(c, to), tmp)
    return loaded
}
