package main

TypeKind :: enum {
    Invalid,
    // basics
    // unsigned int
    UInt64,
    UInt32,
    UInt16,
    UInt_8,
    // signed int
    Int64,
    Int32,
    Int16,
    Int_8,
    // floating point
    Flt64,
    Flt32,
    Flt16,
    Flt_8,
    // rune (just a byte/i8)
    Rune,
    // byte (i8)
    Byte,
    // bool (i1)
    Bool,
    // aggregate
    Struct,
    // pointer stuff
    Slice, // { ptr, i64 }
    Pointer,
    Function,
    // literals
    UntypedInteger,
    UntypedFloat,
    String,
    ZeroInit,
    FixedSizeArray,
    Any,
    Void,
}
Type :: struct {
    name: string,
    kind: TypeKind,
    ptr: TypeId,
    fn: struct { args: []Arg, ret_ty: TypeId, is_variadic: bool, variadic_ty: TypeId, is_external: bool},
    structure: struct {fields: []Field},
    fixed_size_array: struct { type: TypeId, size: int },
    slice: struct{type: TypeId},
}

// ---- classification helpers ----

is_integer_signed :: proc(id: TypeId) -> bool {
    k := get_type(id).kind
    #partial switch k {
    case .Int64, .Int32, .Int16, .Int_8: return true
    }
    return false
}

is_integer_unsigned :: proc(id: TypeId) -> bool {
    k := get_type(id).kind
    #partial switch k {
    case .UInt64, .UInt32, .UInt16, .UInt_8: return true
    }
    return false
}

is_integer :: proc(id: TypeId) -> bool {
    return is_integer_signed(id) || is_integer_unsigned(id)
}

is_byte_like :: proc(id: TypeId) -> bool {
    k := get_type(id).kind
    return k == .Rune || k == .Byte
}

is_float :: proc(id: TypeId) -> bool {
    k := get_type(id).kind
    #partial switch k {
    case .Flt64, .Flt32, .Flt16, .Flt_8: return true
    }
    return false
}

is_numeric_typed :: proc(id: TypeId) -> bool {
    return is_integer(id) || is_float(id) || is_byte_like(id)
}

is_numeric_untyped :: proc(id: TypeId) -> bool {
    k := get_type(id).kind
    return k == .UntypedInteger || k == .UntypedFloat
}

is_numeric :: proc(id: TypeId) -> bool {
    return is_numeric_typed(id) || is_numeric_untyped(id)
}

// Sizes for fixed-width kinds only. Struct/FixedSizeArray need the full Type
// (to walk fields/elem type via TypeId), so those take Type not TypeKind.
type_kind_size :: proc(k: TypeKind) -> int {
    #partial switch k {
    case .UInt64, .Int64, .Flt64:      return 8
    case .UInt32, .Int32, .Flt32:      return 4
    case .UInt16, .Int16, .Flt16:      return 2
    case .UInt_8, .Int_8, .Flt_8:      return 1
    case .Rune, .Byte, .Bool:          return 1
    case .Pointer, .Function, .String, .Slice: return 8 // slice ptr field / fn ptr / cstring
    }
    return 0 // caller should fall back to type_size for aggregates
}

type_size :: proc(id: TypeId) -> int {
    t := get_type(id)

    #partial switch t.kind {
    case .Struct:
        size := 0
        for f in t.structure.fields {
            size += type_size(f.type)
        }
        return size

    case .Slice:
        return 16 // { ptr, i64 }

    case .FixedSizeArray:
        return t.fixed_size_array.size * type_size(t.fixed_size_array.type)

    case .Pointer, .Function:
        return 8

    case:
        return type_kind_size(t.kind)
    }
}

// ---- fixed type_cmp switch (matches current TypeKind) ----

type_cmp :: proc(l, r: Type, strict := false) -> bool {
    if l.kind != r.kind {
        if (l.kind == .Any || r.kind == .Any) && !strict {
            return true
        }
        return false
    }

    switch l.kind {
    case .String:
        return true

    case .Function:
        if l.fn.ret_ty != r.fn.ret_ty { return false }
        if len(l.fn.args) != len(r.fn.args) { return false }

        for i in 0..<len(l.fn.args) {
            if l.fn.args[i].type != r.fn.args[i].type {
                return false
            }
        }
        return true

    case .Pointer:
        return type_cmp_by_id(l.ptr, r.ptr, strict)

    case .Struct:
        if len(l.structure.fields) != len(r.structure.fields) {
            return false
        }

        for i in 0..<len(l.structure.fields) {
            lf := l.structure.fields[i]
            rf := r.structure.fields[i]

            if lf.name != rf.name { return false }
            if lf.type != rf.type { return false }
        }
        return true

    case .Slice:
        return l.slice.type == r.slice.type

    case .FixedSizeArray:
        return l.fixed_size_array.size == r.fixed_size_array.size &&
               l.fixed_size_array.type == r.fixed_size_array.type

    case .UInt64, .UInt32, .UInt16, .UInt_8,
         .Int64, .Int32, .Int16, .Int_8,
         .Flt64, .Flt32, .Flt16, .Flt_8,
         .Rune, .Byte, .Bool, .Void,
         .UntypedInteger, .UntypedFloat, .ZeroInit:
        return true

    case .Any:
        return true

    case .Invalid:
        return false
    }

    return false
}
type_cmp_by_id :: proc(lid, rid: TypeId, strict := false) -> bool {
    l := get_type(lid)
    r := get_type(rid)

    return type_cmp(l^, r^, strict);
}
is_untyped :: proc(ty: TypeId) -> bool {
    return is_numeric_untyped(ty) || get_type(ty).kind == .ZeroInit
}
can_binop :: proc(ty: TypeId) -> bool {
    return is_numeric(ty)
}
can_transmute_to :: proc(target_id, to_id: TypeId) -> bool {
    return type_size(target_id) == type_size(to_id)
}
can_cast_to :: proc(target_id, to_id: TypeId) -> bool {
    target := get_type(target_id)
    to := get_type(to_id)

    // Integer -> integer/float/byte/bool/rune/pointer
    if is_integer(target_id) {
        if is_integer(to_id) || is_float(to_id) || is_byte_like(to_id) {
            return true
        }

        #partial switch to.kind {
        case .Bool, .Pointer:
            return true
        }

        return false
    }

    // Float -> integer/float/byte/rune
    if is_float(target_id) {
        if is_integer(to_id) || is_float(to_id) || is_byte_like(to_id) {
            return true
        }
        return false
    }

    // Pointer -> pointer/integer
    if target.kind == .Pointer {
        if to.kind == .Pointer || is_integer(to_id) {
            return true
        }
        return false
    }

    // Byte/Rune -> numeric
    if is_byte_like(target_id) {
        return is_numeric_typed(to_id) || to.kind == .Bool
    }

    // Bool -> integer/byte/rune
    if target.kind == .Bool {
        return is_integer(to_id) || is_byte_like(to_id)
    }

    // Struct, Slice, FixedSizeArray, Function, Void, ZeroInit, Untyped*, Invalid
    return false
}
is_array_type :: proc(t: TypeId) -> bool {
    #partial switch get_type(t).kind {
    case .FixedSizeArray, .Slice, .String:
        return true
    }
    return false
}
can_be_index :: proc(t: TypeId) -> bool {
    #partial switch get_type(t).kind {
    case .FixedSizeArray, .Slice, .String, .Pointer:
        return true
    }
    return false
}
is_valid_index_type :: proc(t: TypeId) -> bool {
    return is_integer(t) || is_byte_like(t)
}
