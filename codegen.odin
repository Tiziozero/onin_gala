// codegen.odin
package main

import "core:os"
import "core:io"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:mem"
parse_integer_literal :: proc(s: string) -> (i64, bool) {
    if len(s) >= 2 && s[0] == '0' &&
        (s[1] == 'x' || s[1] == 'X') {

        if len(s) == 2 {
            return 0, false
        }

        value: i64 = 0

        for c in s[2:] {
            d := hex_digit_val(cast(byte)c)
            if d < 0 {
                return 0, false
            }

            value = value * 16 + i64(d)
        }

        return value, true
    }

    v, ok := strconv.parse_int(s)
    return cast(i64)v, ok
}
CGExprRes :: struct {
    id: ExprId,
    kind: enum {Invalid, Address, Value, Binop, Number, Struct, None},
    v: string,
    struct_lit: struct {
        fields: []string, // string of results
    }
}

CGCtx :: struct {
    arena: ^mem.Dynamic_Arena,
    b: ^strings.Builder,
    tmp_id: int,
    scope: CGScope,
    strings: map[string]StringGlobalResult,
    cur_fn_ret: AbiRetLowering, // ABI lowering of the return value of the function currently being emitted
    break_labels: map[StmtId]string,    // loop (or if/else passthrough) StmtId -> label to jump to on `break`
    continue_labels: map[StmtId]string, // loop (or if/else passthrough) StmtId -> label to jump to on `continue`
    // "currently active" loop targets, saved/restored around each WhileLoop's
    // body so that any IfElse nested inside (however deeply) can register
    // itself as pointing at the same targets — see cg_stmt's IfElse case.
    cur_break_label: string,
    cur_continue_label: string,
}
CGObjectKind :: enum {
    Invalid,
    Argument,
    Variable,
    Symbol, // like functions
}
CGObj :: struct {
    kind: CGObjectKind,
    name: string
}
CGScope :: struct {
    vars : map[string]CGObj,
    parent: ^CGScope,
}
new_gcscope :: proc(parent: ^CGScope) -> CGScope {
    s := CGScope{}
    s.vars = make(map[string]CGObj, allocator=get_ctx().allocator);
    s.parent = parent
    return s;
}
free_cgscope :: proc(s: ^CGScope) {
    // delete(s.vars);
}
cwritef :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintf(c.b, format, ..data)
}
cwrite :: proc(c: ^CGCtx, format: string) {
    fmt.sbprint(c.b, format)
}
cwriteln :: proc(c: ^CGCtx, format: string) {
    fmt.sbprintln(c.b, format);
}
cwritefln :: proc(c: ^CGCtx, format: string, data: ..any) {
    fmt.sbprintfln(c.b, format, ..data);
}
// ---- TypeKind-level helpers (is_integer/is_float take TypeId and exclude
// Byte/Rune/Bool — these work on raw TypeKind and include them, since all
// three are LLVM integer types) ----

is_int_kind :: proc(k: TypeKind) -> bool {
    #partial switch k {
    case .UInt64, .UInt32, .UInt16, .UInt_8,
         .Int64, .Int32, .Int16, .Int_8,
         .Byte, .Rune, .Bool:
        return true
    }
    return false
}

is_float_kind :: proc(k: TypeKind) -> bool {
    #partial switch k {
    case .Flt64, .Flt32, .Flt16, .Flt_8:
        return true
    }
    return false
}

bit_width_of :: proc(k: TypeKind) -> int {
    #partial switch k {
    case .UInt64, .Int64, .Flt64:               return 64
    case .UInt32, .Int32, .Flt32:               return 32
    case .UInt16, .Int16, .Flt16:               return 16
    case .UInt_8, .Int_8, .Flt_8, .Byte, .Rune: return 8
    case .Bool:                                  return 1 // LLVM i1, not i8
    case: gala_panic("bit_width_of: not a scalar numeric kind")
    }
}

is_signed :: proc(k: TypeKind) -> bool {
    #partial switch k {
    case .Int64, .Int32, .Int16, .Int_8:
        return true
    case .UInt64, .UInt32, .UInt16, .UInt_8, .Byte, .Rune, .Bool:
        return false
    case:
        gala_panic("is_signed: not an integer-ish kind")
    }
}


ty_to_llvm_str :: proc(c: ^CGCtx, id: TypeId) -> string {
    t, ok := get_ctx().llvm_ty[id];
    if ok { /*debugln("type found for:", id);*/ return t }
    ty := get_type(id)
    #partial switch ty.kind {
    case .UntypedInteger: fallthrough
    case .UntypedFloat: 
        panic("bug")
    case .Pointer: {
        s := fmt.aprintf("ptr", allocator=c.arena.block_allocator )
        get_ctx().llvm_ty[id]=s
        return s
    }
    case .Flt64: {
        get_ctx().llvm_ty[id]="double";
        return get_ctx().llvm_ty[id]
    }
    case .Flt32: {
        get_ctx().llvm_ty[id]="float";
        return get_ctx().llvm_ty[id]
    }
    case .Int64: {
        get_ctx().llvm_ty[id]="i64";
        return get_ctx().llvm_ty[id]
    }
    case .Int32: {
        get_ctx().llvm_ty[id]="i32";
        return get_ctx().llvm_ty[id]
    }
    case .Int16: {
        get_ctx().llvm_ty[id]="i16";
        return get_ctx().llvm_ty[id]
    }
    case .Int_8: {
        get_ctx().llvm_ty[id] = "i8";
        return get_ctx().llvm_ty[id]
    }
    case .UInt64: {
        get_ctx().llvm_ty[id] = "i64";
        return get_ctx().llvm_ty[id]
    }
    case .UInt32: {
        get_ctx().llvm_ty[id] = "i32";
        return get_ctx().llvm_ty[id]
    }
    case .UInt16: {
        get_ctx().llvm_ty[id] = "i16";
        return get_ctx().llvm_ty[id]
    }
    case .UInt_8: {
        get_ctx().llvm_ty[id] = "i8";
        return get_ctx().llvm_ty[id]
    }
    case .Void: {
        get_ctx().llvm_ty[id]="void";
        return get_ctx().llvm_ty[id]
    }
    case .Byte: return "i8";
    case .Bool: return "i1";
    case .Function: return "ptr"; // functions are just pointers
    case .Struct: {
        if ty.name != "" {
            n := aprintf(c, "%%%s", ty.name);
            get_ctx().llvm_ty[id]=n;
            return get_ctx().llvm_ty[id]
        } else {
            debugln(ty);
            panic("impl")
        }
    }
    case .FixedSizeArray: {
            n := aprintf(c, "[%d x %s]", ty.fixed_size_array.size,
                   ty_to_llvm_str(c, ty.fixed_size_array.type));
            get_ctx().llvm_ty[id]=n;
            return get_ctx().llvm_ty[id]
    }
    case .Slice, .String, .Any: {
        // "any" is boxed as { data ptr, typeid } — same two-word shape as
        // a slice/string header, just with the second field reinterpreted
        // as a runtime type tag instead of a length. See cg_box_any.
        return "{ ptr, i64 }";
    }
    }
    debugln(ty);
    panic("impl")
}
// eg "%t1"
new_tmp::proc(c: ^CGCtx, p:="",symbol:=false) -> string {
    if symbol {
        return fmt.aprintf("@%s%d", p, next_tmp_index(c), allocator=c.arena.block_allocator);
    }
    return fmt.aprintf("%%%s%d", p, next_tmp_index(c), allocator=c.arena.block_allocator);
}
aprintf :: proc(c: ^CGCtx, format: string, data: ..any) -> string {
    res := fmt.aprintf(format, ..data, allocator=get_ctx().allocator)
    return res
}
// returns value
cg_fn_call_target :: proc(c: ^CGCtx, id: ExprId) -> string {
    #partial switch e in get(id) {
        case Symbol: {
            v := cgscope_get(&c.scope, e.name);
            return v.name;
        }
    }
    panic("no");
}

// Stable per-TypeId integer used as the runtime tag inside a boxed `any`
// value. TypeId is already a small dense index into the type table, so it
// doubles as its own typeid. IMPORTANT: this must be the exact same
// function the `TypeAssert` (downcast, e.g. `x.(int)`) codegen uses to
// compare tags against — box and unbox have to agree on what a type's id
// is, or every assertion will spuriously fail (or worse, spuriously pass).
typeid_of :: proc(t: TypeId) -> i64 {
    return i64(t)
}


// LLVM textual IR: a `float`-typed constant that doesn't round-trip exactly
// through decimal must be printed as hex bits of the *double* representation
// of the value (not the float's raw bits) — this is LLVM's own quirk, not
// a bug in our lowering.
llvm_float_const :: proc(v: f32) -> string {
    as_f64 := f64(v)
    bits := transmute(u64)as_f64
    return fmt.tprintf("0x%016X", bits)
}

llvm_double_const :: proc(v: f64) -> string {
    // f64 constants print fine in decimal as long as they round-trip;
    // easiest to just always go through the same hex path to avoid the
    // same class of bug for doubles with more precision than %f gives you.
    bits := transmute(u64)v
    return fmt.tprintf("0x%016X", bits)
}
// some expressions (fn calls with void returns) don't return so are invalid
reduce_expr_to_single_value :: proc(c: ^CGCtx, e: CGExprRes) -> (string, bool) {
    switch e.kind {
    case .Address: {
        return e.v, true;
    }
    case .Struct: {
        lit := get_expr(e.id).(StructLit)
        tid := expr_ty(e.id)
        ty := get_type(tid);
        ty_str := ty_to_llvm_str(c, tid)

        cur := "undef"   // starting aggregate — a literal LLVM keyword, not a register
        i := 0;
        for field in ty.structure.fields {
            f := lit.fields[field.name]
            fv, returns := reduce_expr_to_single_value(c, cg_expr(c, f.expr))
            assert(returns)
            next := new_tmp(c)
            cwritefln(c, "\t%s = insertvalue %s %s, %s %s, %d",
                next, ty_str, cur, ty_to_llvm_str(c, expr_ty(f.expr)), fv, i)
            cur = next
            i+=1;
        }
        return cur, true
    }
    case .Invalid: gala_panic("invalid")
    case .None: return "", false
    case .Value: {
        return e.v, true
    }
    case .Number: {
        return e.v, true
    }
    case .Binop: {
        t := new_tmp(c)
        cwritefln(c, "\t%s = %s", t, e.v);
        return t, true
    }
    }
    panic("impl");
}
stmt_ends_block :: proc(stmt: StmtId) -> bool {
    switch s in get(stmt) {
    // both are unconditional jumps (`br label ...`) — an LLVM basic-block
    // terminator, exactly like Return, so nothing may follow either in
    // the same block.
    case BreakStmt, ContinueStmt: return true;
    case WhileLoop: {
        return check_rets(s.block);
    }
    case IfElse: {
        has_all_returns := s.has_else_block
        if !check_rets(s.base_block) do has_all_returns = false;
        for a in s.alt {
            if !check_rets(a.block) do has_all_returns = false;
        }
        if s.has_else_block {
            if !check_rets(s.else_block) do has_all_returns = false;
        }
        return has_all_returns
    }
    case Return: return true
    case VarDec: return false
    case Assignment: return false
    case ExprId: return false;
    case: panic("impl");
    }
    panic("impl");
}
next_tmp_index :: proc(c: ^CGCtx) -> int {
    c.tmp_id += 1;
    return c.tmp_id;
}
cg_stmt :: proc(c: ^CGCtx, id: StmtId) {
    span := get_span(id).span
    data := get_file_lines(get_ctx().current_file, span)
    // cwritefln(c, "\t; cg_stmt \"%s\"",
        // string(get_ctx().files[get_ctx().current_file][span.start:span.end]))
    switch s in get_stmt(id) {
    case BreakStmt: {
        // get_ctx().break_lables maps this break's own StmtId to the
        // StmtId of the construct it targets (the enclosing loop, or —
        // if it was registered while inside nested if/else — the
        // innermost IfElse, which itself carries the same loop's label
        // through via the passthrough registration below).
        target_id := get_ctx().break_lables[id]
        label, ok := c.break_labels[target_id]
        if !ok {
            gala_panic("break: no enclosing loop label found")
        }
        cwritefln(c, "\tbr label %%%s", label)
    }
    case ContinueStmt: {
        target_id := get_ctx().break_lables[id]
        label, ok := c.continue_labels[target_id]
        if !ok {
            gala_panic("continue: no enclosing loop label found")
        }
        cwritefln(c, "\tbr label %%%s", label)
    }
    case WhileLoop: {
        
        id_suffix := next_tmp_index(c)

        cond_label := aprintf(c, "while_cond_label%d", id_suffix);
        body_label := aprintf(c, "while_body_label%d", id_suffix);
        end_label  := aprintf(c, "while_end_label%d", id_suffix);

        // register this loop's break/continue targets, keyed by its own
        // StmtId (this is what get_ctx().break_lables[break/continue id]
        // resolves to), and set them as "current" so any IfElse nested in
        // the body — at any depth — can register the same targets under
        // its own StmtId too.
        c.break_labels[id] = end_label
        c.continue_labels[id] = cond_label

        old_break := c.cur_break_label
        old_continue := c.cur_continue_label
        c.cur_break_label = end_label
        c.cur_continue_label = cond_label

        // jump into condition check
        cwritefln(c, "\tbr label %%%s", cond_label);

        // condition block
        cwritefln(c, "%s:", cond_label);

        cond, returns := reduce_expr_to_single_value(c, cg_expr(c, s.cond));
        assert(returns);

        // type checker guarantees this, but keep this assertion in codegen
        assert(get_type(expr_ty(s.cond)).kind == .Bool);

        cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s",
            cond, body_label, end_label);


        // body
        cwritefln(c, "%s:", body_label);

        old := c.scope;
        c.scope = new_gcscope(&old);

        for statement, i in s.block.stmts {
            cg_stmt(c, statement);

            if stmt_ends_block(statement) && i != len(s.block.stmts)-1 {
                gala_panic("nothing past will be executed");
            }
        }

        free_cgscope(&c.scope);
        c.scope = old;


        // only loop back if body doesn't terminate
        if !check_rets(s.block) {
            cwritefln(c, "\tbr label %%%s", cond_label);
        }


        // exit
        cwritefln(c, "%s:", end_label);

        c.cur_break_label = old_break
        c.cur_continue_label = old_continue
    }
    case ExprId:
        reduce_expr_to_single_value(c, cg_expr(c, s));
    case IfElse: {
        id_suffix := next_tmp_index(c)
        end_label := aprintf(c, "end_label%d", id_suffix);

        // Passthrough registration: if this IfElse sits inside an
        // enclosing loop (tracked via c.cur_break_label/cur_continue_label,
        // set by WhileLoop around its body), register the SAME targets
        // under this IfElse's own StmtId. This makes a break/continue
        // resolve correctly regardless of whether the resolution phase
        // pointed it directly at the loop or at this intermediate IfElse.
        // Guarded so an IfElse outside any loop doesn't insert a bogus
        // empty-string entry (which would otherwise satisfy the `ok` check
        // in BreakStmt/ContinueStmt and mask a real "break outside loop"
        // error).
        if c.cur_break_label != "" {
            c.break_labels[id] = c.cur_break_label
        }
        if c.cur_continue_label != "" {
            c.continue_labels[id] = c.cur_continue_label
        }

        // Precompute all labels we'll need up front so branch targets
        // can reference "the next check" before that block is emitted.
        base_block := aprintf(c, "base_block_label%d", id_suffix);

        alt_cond_labels := make([dynamic]string, get_ctx().allocator)
        alt_body_labels := make([dynamic]string, get_ctx().allocator)
        for _, i in s.alt {
            append(&alt_cond_labels, aprintf(c, "alt_cond_label%d_%d", id_suffix, i))
            append(&alt_body_labels, aprintf(c, "alt_block_label%d_%d", id_suffix, i))
        }
        has_else := s.has_else_block;
        else_label := aprintf(c, "else_block_label%d", id_suffix);

        // what to jump to if the base condition is false
        next_after_base := end_label
        if len(s.alt) > 0 {
            next_after_base = alt_cond_labels[0]
        } else if has_else {
            next_after_base = else_label
        }

        // --- base condition ---
        {
            cond, returns := reduce_expr_to_single_value(c, cg_expr(c, s.base_con));
            assert(returns);
            ty := get_type(expr_ty(s.base_con));
            assert(ty.kind == .Bool);
            cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", cond, base_block, next_after_base);

            cwritefln(c, "%s:", base_block);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in s.base_block.stmts {
                cg_stmt(c, statement);
                if stmt_ends_block(statement) && i != len(s.base_block.stmts) - 1 {
                    gala_panic("nothing past will be executed");
                }
            }
            free_cgscope(&c.scope)
            c.scope = old;
            if !check_rets(s.base_block) {
                cwritefln(c, "\tbr label %%%s", end_label);
            }
        }

        // --- else-if chain ---
        for a, i in s.alt {
            next := end_label
            if i < len(s.alt) - 1 {
                next = alt_cond_labels[i + 1]
            } else if has_else {
                next = else_label
            }

            cwritefln(c, "%s:", alt_cond_labels[i]);
            cond, returns := reduce_expr_to_single_value(c, cg_expr(c, a.cond));
            assert(returns);
            ty := get_type(expr_ty(a.cond));
            assert(ty.kind == .Bool);
            cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", cond, alt_body_labels[i], next);

            cwritefln(c, "%s:", alt_body_labels[i]);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in a.block.stmts {
                cg_stmt(c, statement);
                // fixed: was comparing against len(s.base_block.stmts) —
                // must check this alt branch's own block length.
                if stmt_ends_block(statement) && i != len(a.block.stmts) - 1 {
                    gala_panic("nothing past will be executed");
                }
            }
            free_cgscope(&c.scope)
            c.scope = old;
            if !check_rets(a.block) {
                cwritefln(c, "\tbr label %%%s", end_label);
            }
        }

        // --- else ---
        if has_else {
            cwritefln(c, "%s:", else_label);
            old := c.scope;
            c.scope = new_gcscope(&old);
            for statement, i in s.else_block.stmts {
                cg_stmt(c, statement);
                // fixed: was comparing against len(s.base_block.stmts) —
                // must check the else block's own length.
                if stmt_ends_block(statement) && i != len(s.else_block.stmts) - 1 {
                    gala_panic("nothing past will be executed");
                }
            }
            free_cgscope(&c.scope)
            c.scope = old;
            if !check_rets(s.else_block) {
                cwritefln(c, "\tbr label %%%s", end_label);
            }
        }

        has_all_returns := has_else
        if !check_rets(s.base_block) do has_all_returns = false;
        for a in s.alt {
            if !check_rets(a.block) do has_all_returns = false;
        }
        if has_else {
            if !check_rets(s.else_block) do has_all_returns = false;
        }
        // returns in every branch, so never needs end label
        if !has_all_returns {
            cwritefln(c, "%s:", end_label);
        }
    }
    case VarDec:{
        // get object
        id :=get_ctx().stmt_objects[id] 
        obj := get_obj(id);
        // gen value
        v := cg_expr(c, s.value)
        // write name to scope
        c.scope.vars[s.name] = {.Variable, aprintf(c, "%%%s.%d", s.name, id)};
        name := c.scope.vars[s.name].name
        if true {
            value, returns :=  reduce_expr_to_single_value(c, v);
            assert(returns);
            // allocate
            cwritefln(c, "\t%s = alloca %s", name,
                ty_to_llvm_str(c, obj.type.(TypeId)));
            // init
            cwritefln(c, "\tstore %s %s, ptr %s", ty_to_llvm_str(c, obj.type.(TypeId)),
                value, name);
        } else {
            cwritefln(c, "\t%s = alloca %s",name, 
                ty_to_llvm_str(c, obj.type.(TypeId)));
            tid := get_ctx().expr_resolution_types[v.id]
            ty := get_type(tid);
            for v, i in v.struct_lit.fields {
                // load
                // %y_addr = getelementptr inbounds %Vec2, %Vec2* %ptr, i32 0, i32 1
                t := new_tmp(c)
                llvm_t := ty_to_llvm_str(c, tid)
                cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i32 0, i32 %d",
                            t, llvm_t, name, i)
                // store
                // store float 3.0, float* %y_addr
                field_ty := ty_to_llvm_str(c, ty.structure.fields[i].type);
                cwritefln(c, "\tstore %s %s, ptr %s",
                            field_ty, v, t)
            }
        }
    }
    case Return: {
        if e, ok := s.expr.(ExprId); ok {
            r, returns := reduce_expr_to_single_value(c, cg_expr(c, e));
            assert(returns);
            ret_ty_str := ty_to_llvm_str(c, expr_ty(e))

            switch c.cur_fn_ret.mode {
            case .Indirect: {
                // caller-allocated slot, already passed in as %.sret
                cwritefln(c, "\tstore %s %s, ptr %s", ret_ty_str, r, "%.sret")
                cwriteln(c, "\tret void")
            }
            case .Direct: {
                if c.cur_fn_ret.needs_coercion {
                    slot := new_tmp(c)
                    cwritefln(c, "\t%s = alloca %s", slot, ret_ty_str)
                    cwritefln(c, "\tstore %s %s, ptr %s", ret_ty_str, r, slot)
                    coerced := new_tmp(c)
                    cwritefln(c, "\t%s = load %s, ptr %s", coerced, c.cur_fn_ret.coerced_type, slot)
                    cwritefln(c, "\tret %s %s", c.cur_fn_ret.coerced_type, coerced)
                } else {
                    cwritefln(c, "\tret %s %s", ret_ty_str, r)
                }
            }
            }
        } else {
            cwriteln(c, "\tret void")
        }
    }
    case Assignment: {
        value, returns := reduce_expr_to_single_value(c, cg_expr(c, s.value))
        assert(returns)
        target_ptr := cg_addr(c, s.target)
        cwritefln(c, "\tstore %s %s, ptr %s",
            ty_to_llvm_str(c, expr_ty(s.target)), value, target_ptr)
    }
    case:panic("impl");
    }
    cwriteln(c, "");
}
// Resolves ANY indexable expression down to a pointer that already points at
// element 0, plus that element's LLVM type string. This is the one place
// that needs to know how array/slice/pointer differ — everything downstream
// (Index, TakeSlice, and later `for x in ...`) is a uniform single-index GEP
// off the result.
cg_data_ptr :: proc(c: ^CGCtx, id: ExprId) -> (ptr: string, elem_ty_str: string) {
    ty := get_type(expr_ty(id))
    // cwritefln(c, "\t; cg_data_ptr expr tye: %s", tts(expr_ty(id)));
    #partial switch ty.kind {
    case .FixedSizeArray:
        // arrays are always addressable, never SSA values — get its address,
        // which (with opaque pointers) already IS "pointer to element 0"
        return cg_addr(c, id), ty_to_llvm_str(c, ty.fixed_size_array.type)

    case .Slice: {
        // slices are a small by-value {ptr, i64} — get the value however it
        // naturally arises (load, extractvalue, straight from TakeSlice,
        // a function return, whatever cg_expr already knows how to do) and
        // pull the data pointer straight out of it
        v, ok := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(ok)
        p := new_tmp(c)
        cwritefln(c, "\t%s = extractvalue {{ ptr, i64 }} %s, 0", p, v)
        return p, ty_to_llvm_str(c, ty.slice.type) // check your real field name
    }
    case .String: {
        // same as slice but base is just "byte"
        v, ok := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(ok)
        p := new_tmp(c)
        cwritefln(c, "\t%s = extractvalue {{ ptr, i64 }} %s, 0", p, v)
        return p, ty_to_llvm_str(c, byte_type()) // check your real field name
    }

    case .Pointer: {
        // already IS a pointer to element 0
        v, ok := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(ok)
        return v, ty_to_llvm_str(c, ty.ptr) // check your real field name
    }

    case: gala_panic("cg_data_ptr: not indexable")
    }
}

// Address of target[index]. Used by both cg_expr's Index (which loads
// afterward) and cg_addr's Index (which just returns this).
cg_elem_ptr :: proc(c: ^CGCtx, target: ExprId, index: ExprId) -> string {
    // cwritefln(c, "\t; get_elem_ptr gens:");
    base_ptr, elem_ty := cg_data_ptr(c, target)
    idx_v, ok := reduce_expr_to_single_value(c, cg_expr(c, index)); assert(ok)
    idx_ty := ty_to_llvm_str(c, expr_ty(index))

    t := new_tmp(c)
    cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, %s %s",
        t, elem_ty, base_ptr, idx_ty, idx_v)
    return t
}
cg_addr :: proc(c: ^CGCtx, id: ExprId) -> string {
    span := get_span(id).span
    data := get_file_lines(get_ctx().current_file, span)
    // cwritefln(c, "\t; cg_addr \"%s\"",
        // string(get_ctx().files[get_ctx().current_file][span.start:span.end]))
    #partial switch e in get_expr(id) {
    case Symbol: {
        v := cgscope_get(&c.scope, e.name)
        if v.kind == .Variable do return v.name
        if v.kind == .Argument do return v.name

        panic("impl");
        // args aren't addressable — can't assign to a by-value param
        // can however if args is a ptr/array
    }
    case FieldAccess: {
        base_ptr := cg_addr(c, e.target)
        base_ty := expr_ty(e.target)
        ty := get_type(base_ty)

        idx := -1
        for f, k in ty.structure.fields {
            if f.name == e.field {
                idx = k
                break
            }
        }
        assert(idx != -1)

        t := new_tmp(c)
        cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i32 0, i32 %d",
            t, ty_to_llvm_str(c, base_ty), base_ptr, idx)
        return t
    }
    case Index: {
        // cwritefln(c, "\t; for index addr, cg_elem_ptr");
        return cg_elem_ptr(c, e.target, e.index)
    }
    case Deref: {
        debugln("deref inner:", get(e.expr));
        // generate expression, as that would already be a pointer, otherwise
        // dereferencing wouldn't make sense
        ptr_val, returns := reduce_expr_to_single_value(c, cg_expr(c, e.expr));
        assert(returns);
        ptr_ty := get_type(expr_ty(e.expr))

        if ptr_ty.kind != .Pointer {
            panic("cannot dereference non-pointer type")
        }
        t := new_tmp(c);

        /* cwritefln(c, "\t%s = load %s, ptr %s",
            t, ty_to_llvm_str(c, expr_ty(e.expr)), ptr_val)*/

        // return t;
        return ptr_val;
    }
    case Cast, Transmute: {
            v, returns := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(returns);
            return v;
    }
    case:
        debugln(get(id))
        highlight_lines(get_span(id).span);
        panic("not an lvalue")
    }
}
// Declarations go through the same cg_abi_lower_signature as
// definitions and calls — no more separate hand-rolled C ABI path.
// Writes the signature line for a function — `declare` for a prototype
// (extern, or a forward-declared import), `define` for the header of an
// actual definition. Both extern and gala (non-extern) forms go through
// the same ABI lowering and the same parameter-writing loop; the only
// per-kind divergence is:
//   - is_extern: only extern C functions get a literal `...` for a
//     trailing variadic — a gala function's trailing variadic parameter
//     has already been lowered to an ordinary Slice(variadic_type) arg
//     by this point, so it just falls through the normal ByVal/Direct
//     path like any other parameter.
//   - define: whether we're opening a definition (needs real parameter
//     names to bind and reference in the body, and binds them into
//     c.scope) or just declaring a prototype (types only, no names,
//     nothing bound into scope).
//
// Returns the lowered signature and, when define==true, the raw
// (pre-coercion) SSA names of each parameter as they appear on the
// `define` line — the caller needs both to emit the prologue and set
// `c.cur_fn_ret` before generating the body.
cg_fn_declaration :: proc(c: ^CGCtx, i: Item, id: ItemId, is_extern := false, define := false) -> (sig: AbiSignature, param_raw_names: [dynamic]string) {
    objid := get_ctx().item_objects[id]
    obj := get_ctx().objs[objid]
    fn_type_id := obj.type.(TypeId)
    fn_ty := get_type(fn_type_id)

    sig = cg_abi_lower_signature(c, fn_type_id, .SysV)

    cwrite(c, define ? "define " : "declare ")
    name: string
    if is_extern {
        name = obj.name
    } else {
        name = get_ctx().cg_item_names[id] // use compilers cg item name
    }
    cwritef(c, "%s ", sig.ret.mode == .Indirect ? "void" : sig.ret.coerced_type)
    cwritef(c, "@%s ", name)
    cwrite(c, "(")

    wrote_any := false
    if sig.ret.mode == .Indirect {
        if define {
            cwritef(c, "ptr sret(%s) align %d %%.sret", ty_to_llvm_str(c, sig.ret.orig_type), sig.ret.sret_align)
        } else {
            cwritef(c, "ptr sret(%s) align %d", ty_to_llvm_str(c, sig.ret.orig_type), sig.ret.sret_align)
        }
        wrote_any = true
    }

    if define {
        param_raw_names = make([dynamic]string, allocator = get_ctx().allocator)
    }

    for a, k in fn_ty.fn.args {
        if wrote_any { cwritef(c, ", ") }
        wrote_any = true

        al := sig.args[k]
        switch al.mode {
        case .ByVal:
            if define {
                // already an address — the parameter itself IS the pointer,
                // no local alloca needed; bind as .Variable (load-on-read,
                // same as any other addressable local)
                pname := aprintf(c, "%%%s", a.name)
                cwritef(c, "ptr byval(%s) align %d %s", ty_to_llvm_str(c, al.orig_type), al.byval_align, pname)
                append(&param_raw_names, pname)
                c.scope.vars[a.name] = {.Variable, pname}
            } else {
                cwritef(c, "ptr byval(%s) align %d", ty_to_llvm_str(c, al.orig_type), al.byval_align)
            }
        case .Direct:
            if define {
                if al.needs_coercion {
                    // raw coerced value comes in under a temp name; the
                    // real binding is reconstructed in the prologue
                    pname := aprintf(c, "%%%s.abi", a.name)
                    cwritef(c, "%s %s", al.coerced_type, pname)
                    append(&param_raw_names, pname)
                } else {
                    pname := aprintf(c, "%%%s", a.name)
                    cwritef(c, "%s %s", al.coerced_type, pname)
                    append(&param_raw_names, pname)
                    c.scope.vars[a.name] = {.Argument, pname}
                }
            } else {
                cwritef(c, "%s", al.coerced_type)
            }
        }
    }
    if fn_ty.fn.is_variadic {
        if wrote_any { cwritef(c, ", ") }
        if is_extern { // extern just use "..."
            cwrite(c, "...")
        } else { // gala functions write arg name as "[]ty"
            ty := fn_ty.fn.gala_abi_ty;
            name := fn_ty.fn.variadic_name;
            sty := ty_to_llvm_str(c, ty)
            pname := aprintf(c, "%%%s.gala_variadic", name)
            c.scope.vars[name] = {kind=.Argument, name=pname}
            cwritef(c, "%s %s", sty, pname)
        }
    }

    if define {
        cwrite(c, ") ")
    } else {
        cwriteln(c, ")")
    }
    return
}
cg_item :: proc(c: ^CGCtx, id: ItemId) {
    switch i in get_item(id) {
    case Import: {} // ok
    case StructDec: {
    }
    case ExternFnDec: {
        cg_fn_declaration(c, i, id, is_extern = true)
    }
    case FnDec: {
        // double check type is a function
        // assert(check_fn(i))

        old_scope := c.scope
        c.scope = new_gcscope(&old_scope)

        old_ret := c.cur_fn_ret

        sig, param_raw_names := cg_fn_declaration(c, i, id, is_extern = false, define = true)
        c.cur_fn_ret = sig.ret

        cwriteln(c, "{")
        cwriteln(c, "entry:")

        fn_type_id := get_ctx().objs[get_ctx().item_objects[id]].type.(TypeId)
        fn_ty := get_type(fn_type_id)

        // prologue: unconvert any coerced-by-value struct args back into
        // a real aggregate SSA value via a memory roundtrip
        for a, k in fn_ty.fn.args {
            al := sig.args[k]
            if al.mode == .Direct && al.needs_coercion {
                real_ty_str := ty_to_llvm_str(c, al.orig_type)
                slot := new_tmp(c)
                cwritefln(c, "\t%s = alloca %s", slot, real_ty_str)
                cwritefln(c, "\tstore %s %s, ptr %s", al.coerced_type, param_raw_names[k], slot)
                loaded := new_tmp(c)
                cwritefln(c, "\t%s = load %s, ptr %s", loaded, real_ty_str, slot)
                c.scope.vars[a.name] = {.Argument, loaded}
            }
        }

        block_ends := false

        for statement, index in i.block.stmts {
            cg_stmt(c, statement)

            if stmt_ends_block(statement) {
                block_ends = true

                if index != len(i.block.stmts) - 1 {
                    gala_panic("nothing past will be executed")
                }

                break
            }
        }

        if !block_ends {
            switch sig.ret.mode {
            case .Direct:
                if sig.ret.coerced_type == "void" {
                    cwriteln(c, "\tret void")
                } else {
                    gala_panic("Function does not return a value")
                }

            case .Indirect:
                // sret functions have an ABI return of void, so reaching
                // the end still needs `ret void`.
                cwriteln(c, "\tret void")
            }
        }
        cwriteln(c, "}")
        // reset scope + return-lowering context
        c.scope = old_scope
        c.cur_fn_ret = old_ret
    }
    case: panic("impl")
    }
}
cg_ast :: proc(c: ^CGCtx, ast: ^AST) {
    for id in ast.items {
        cg_item(c, id)
    }
}
check_rets :: proc(b: Block) -> bool {
    if len(b.stmts) < 1 { return false }
    last := b.stmts[len(b.stmts)-1];
    return stmt_ends_block(last); // check if last statement ends block
}
check_fn :: proc(f: FnDec) -> bool {
    if !check_rets(f.block) {
        highlight_lines(f.span);
        gala_panic("function must return at all branches")
    }
    return true
}
cgscope_get :: proc(scope: ^CGScope, v: string) -> CGObj {
    s := scope
    for s != nil {
        n, ok := s.vars[v];
        if ok do return n
        s = s.parent
    }
    s = scope
    for s != nil {
        for var in s.vars {
            debugln("\t:", var)
        }
        s = s.parent
    }
    debugln(v, "doesn't exist")
    return CGObj{kind=.Invalid}
}

// Escapes a byte for LLVM's c"..." string-constant syntax.
// LLVM requires every byte outside printable, non-special ASCII
// to be hex-escaped as \XX (two uppercase hex digits, no 0x prefix).
llvm_escape_byte :: proc(sb: ^strings.Builder, b: byte) {
    switch b {
    case '\\':
        strings.write_string(sb, "\\5C")
    case '"':
        strings.write_string(sb, "\\22")
    case:
        if b >= 0x20 && b < 0x7f {
            // printable ASCII, safe to emit directly
            strings.write_byte(sb, b)
        } else {
            strings.write_string(sb, fmt.tprintf("\\%02X", b))
        }
    }
}

StringGlobalResult :: struct {
    ir:         string, // the full .ll global definition text
    array_type: string, // e.g. "[6 x i8]" -- the array type as declared (INCLUDES null term)
    len:        int,    // logical length, EXCLUDING the null terminator
    s:          string, // name
}

emit_string_global :: proc(name: string, content: string) -> StringGlobalResult {
    sb: strings.Builder
    strings.builder_init(&sb, get_ctx().allocator)

    logical_len := len(content)       // length WITHOUT null term (this is what you store as `i64` len)
    total_len   := logical_len + 1    // actual array size WITH null term

    array_type := fmt.tprintf("[%d x i8]", total_len)

    strings.write_string(&sb, fmt.tprintf(
        "%s = private unnamed_addr constant %s c\"",
        name, array_type,
    ))
    for i := 0; i < len(content); i += 1 {
        llvm_escape_byte(&sb, content[i])
    }
    strings.write_string(&sb, "\\00\"") // trailing null terminator
    strings.write_string(&sb, ", align 1\n")

    return StringGlobalResult{
        ir          = strings.to_string(sb),
        array_type  = array_type,
        len         = logical_len,
        s           = name,
    }
}
cg_items_dec :: proc(ctx: ^CGCtx, items: []ItemId, is_import:=false) {
    for id in items {
        switch i in get_item(id) {
        case Import: {
            mid := get_ctx().modules[i.fname];
            m := get_ctx().mods[mid];
            cg_items_dec(ctx, m.ast.items, true); // gen items into this
        }
        case StructDec: {
            item := i;
            c := ctx;
            name := mod_item_type_name(c, id);
            cwritef(c, "%%%s = ", name);
            cwrite(c, "type {")
            ty :=get_type(get_ctx().item_types[id])
            for f, i in ty.structure.fields {
                cwritef(c, "%s", ty_to_llvm_str(c,f.type));
                if i != len(get_type(get_ctx().item_types[id]).structure.fields) -1 {
                    cwrite(c, ",");
                }
            }
            cwriteln(c, "}")
        }
        case FnDec: { 
            name := mod_item_obj_name(ctx, id);
            // declare first;
            // it's a function , so use "@main" instead of "%main"
            ctx.scope.vars[i.name] = {.Symbol, aprintf(ctx, "@%s", name)};
            if is_import {
                cg_fn_declaration(ctx, i, id, is_extern=false);
            }
        }
        case ExternFnDec: { 
            name := i.name // use normal name here since it's external
            get_ctx().cg_item_names[id] = name
            // declare first;
            // it's a function , so use "@main" instead of "%main"
            ctx.scope.vars[i.name] = {.Symbol, aprintf(ctx, "@%s", name)};
            if is_import {
                cg_fn_declaration(ctx, i, id, is_extern = true);
            }
        }
        }
    }
}
// Finds the top-level `main` function item in this module's AST (not one
// pulled in via an import — entry point must be declared directly in the
// entry file). Returns its ItemId so the caller can resolve its name
// through the normal item/obj lookup, since item naming is going to change
// soon and we don't want a separate hardcoded path for the entry symbol.
find_main_item :: proc(ast: ^AST) -> (ItemId, bool) {
    for id in ast.items {
        #partial switch i in get_item(id) {
        case FnDec:
            if i.name == "main" {
                return id, true
            }
        }
    }
    return {}, false
}
cg_module :: proc(m: ModId) {
    module := get_ctx().mods[m]
    ast := &module.ast;
    is_entry := false
    if module.path == get_ctx().entry_file {
        is_entry = true
    }
    cgctx := CGCtx{}
    arena : mem.Dynamic_Arena;
    mem.dynamic_arena_init(&arena)
    defer mem.dynamic_arena_free_all(&arena);
    cgctx.arena = &arena
    sb : strings.Builder
    strings.builder_init(&sb)
    defer strings.builder_destroy(&sb)
    cgctx.b = &sb
    cgctx.strings = make(map[string]StringGlobalResult, allocator=get_ctx().allocator);
    cgctx.break_labels = make(map[StmtId]string, allocator=get_ctx().allocator);
    cgctx.continue_labels = make(map[StmtId]string, allocator=get_ctx().allocator);
    cgctx.scope = new_gcscope(nil);


    // boilerplate + garbage
    fmt.sbprintfln(cgctx.b, "; target info")
    fmt.sbprintfln(cgctx.b, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"");
    fmt.sbprintfln(cgctx.b, "target triple = \"x86_64-pc-linux-gnu\" ");


    // structs need to be declared first??
    cg_items_dec(&cgctx, ast.items);

    for s in get_ctx().data {
        t := new_tmp(&cgctx,p="string", symbol=true)
        v := emit_string_global(t, s);
        cwritefln(&cgctx, "%s", v.ir);
        cgctx.strings[s] = v;
    }
    // gen
    cg_ast(&cgctx, ast)
    if is_entry {
        main_id, found := find_main_item(ast)
        if !found {
            gala_panic("entry file has no `main` function")
        }
        name := get_ctx().cg_item_names[main_id];
        entry := aprintf(&cgctx, "@%s", name)

        fmt.sbprintfln(cgctx.b,` define i32 @main(i32 %%argc, ptr %%argv) {{
            %%result = call i32 %s()
            ret i32 %%result
        }`,  entry);
    }
    // write
    dir_err := os.make_directory(".gala_build")
    if dir_err != io.Error.None {
        if dir_err != .Exist {
            gala_panic("Failed make .gala_build directory:", dir_err);
        }
    }
    c := &cgctx;
    name := mod_prefix_from_path(get_ctx().current_file, "gala.mod");
    ll_name := aprintf(c,".gala_build/%s.ll", name)
    e := os.write_entire_file_from_string(ll_name, strings.to_string(sb))
    if e != io.Error.None {
        gala_panic("Failed to write to file:", e);
    }
    
    {
        o_name := aprintf(c,".gala_build/%s.o", name)
        // compile llvm "llc -filetype=obj a.ll -o a.o"
        p, err := os.process_start({command={"llc", "-filetype=obj", "-O2", 
            ll_name, "-o", o_name}});
        if err != .NONE {
            debugln("llc", "-filetype=obj", "-O2", 
            ll_name, "-o", o_name)
            gala_panic("Failed to start clang process:", err);
        }
        p_state, werr := os.process_wait(p)
        if werr != .NONE {
            gala_panic("Failed to wait for clang process:", werr);
        }
        if p_state.exit_code != 0 {
            gala_panic("Failed to compile llvm ir. exit code:", p_state.exit_code);
        }
        debugln("clang exit code:", p_state.exit_code);
        append(&get_ctx().o_files, o_name)
    }
}
// eg src/some/folder_file -> src_some_folder_file
files_prefixes: map[string]string
path_to_file_prefix :: proc(c: ^CGCtx, path: string) -> string {
    if v, ok := files_prefixes[path]; ok {
        return v
    }

    assert(strings.has_suffix(path, ".gala"))

    base := path[:len(path)-len(".gala")]

    buf := make([]byte, len(base), allocator=c.arena.block_allocator)

    for ch, i in base {
        if ch == '/' {
            buf[i] = '_'
        } else {
            buf[i] = byte(ch)
        }
    }

    out := string(buf)
    files_prefixes[path] = out
    return out
}

mod_item_type_name :: proc(c: ^CGCtx, id: ItemId) -> string {
    tid := get_ctx().item_types[id]
    name, ok := get_ctx().cg_ty_names[tid];
    if !ok {
        mid, mid_ok := get_ctx().ty_modules[tid]
        if !mid_ok {
            debugln("MODULE:", id)
            panic("type has no module associated with it.");
        }
        mod_prefix, mok := get_ctx().cg_module_prefix[mid];
        if !mok {
            module := get_ctx().mods[mid];
            mod_prefix = mod_prefix_from_path(module.path, prefix="gala.");
            get_ctx().cg_module_prefix[mid] = mod_prefix
        }
        name = aprintf(c, "%s.%s", mod_prefix, get(tid).name);
        get_ctx().cg_ty_names[tid] = name
        get_ctx().llvm_ty[tid] = aprintf(c, "%%%s", name); // set llvm ty as well
    }
    return name
}
mod_item_obj_name :: proc(c: ^CGCtx, id: ItemId) -> string {
    oid := get_ctx().item_objects[id]
    name, ok := get_ctx().cg_item_names[id];
    if !ok {
        mid, mok2 := get_ctx().obj_modules[oid]
        if !mok2 {
            debugln("OBJ MODULE:", oid, id)
            panic("item has no module associated with it.");
        }
        mod_prefix, mok := get_ctx().cg_module_prefix[mid];
        if !mok {
            module := get_ctx().mods[mid];
            mod_prefix = mod_prefix_from_path(module.path, prefix="gala.mod");
            get_ctx().cg_module_prefix[mid] = mod_prefix
        }
        name = aprintf(c, "%s.%s", mod_prefix, get(oid).name);
        get_ctx().cg_item_names[id] = name
    }
    return name
}

import "core:path/filepath"

// "abc/efg/abc.txt" -> "myprefix_abc_efg_abc"
mod_prefix_from_path :: proc(path: string, prefix: string = "prefix") -> string {
    dir_all := filepath.dir(path); // "abc/efg"

    dir, err := filepath.clean(dir_all);
    assert(err == .None)

    normalized, was_allocated := strings.replace_all(dir, "\\", "/");
    defer if was_allocated {
        delete(normalized);
    }

    parts := strings.split(normalized, "/");
    defer delete(parts);

    sb := strings.builder_make();
    strings.write_string(&sb, prefix);

    for part in parts {
        if part == "" || part == "." {
            continue;
        }
        strings.write_string(&sb, "_");
        strings.write_string(&sb, part);
    }

    // Append the filename (without extension).
    base := filepath.base(path); // "abc.txt"
    ext := filepath.ext(base);   // ".txt"
    stem := base[:len(base)-len(ext)]; // "abc"

    if stem != "" {
        strings.write_string(&sb, "_");
        strings.write_string(&sb, stem);
    }

    return strings.to_string(sb);
}
