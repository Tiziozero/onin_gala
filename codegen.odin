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
    // .Place: the value lives in memory at `v` (a pointer operand) and has
    // the type of expression `id`. Nothing has been loaded yet; reducing it
    // loads the whole value, cg_expr_into memcpy's it.
    kind: enum {Invalid, Address, Value, Binop, Number, Struct, None, Place},
    v: string,
    struct_lit: struct {
        fields: []string, // string of results
    }
}

// A global variable whose LLVM definition line hasn't been written yet.
// cg_items_dec records these; cg_globals_dec writes them once every struct
// type has a name (see cg_globals_dec).
PendingGlobal :: struct {
    id:       ItemId,
    external: bool, // true -> `external global` (declared by an importer)
}

CGCtx :: struct {
    arena: ^mem.Dynamic_Arena,
    b: ^strings.Builder,
    tmp_id: int,
    scope: CGScope,
    cg_strings: map[string]StringGlobalResult,
    cur_fn_ret: AbiRetLowering, // ABI lowering of the return value of the function currently being emitted
    break_labels: map[StmtId]string,    // loop (or if/else passthrough) StmtId -> label to jump to on `break`
    continue_labels: map[StmtId]string, // loop (or if/else passthrough) StmtId -> label to jump to on `continue`
    // "currently active" loop targets, saved/restored around each WhileLoop's
    // (and ForLoop's) body so that any IfElse nested inside (however deeply)
    // can register itself as pointing at the same targets — see cg_stmt's
    // IfElse case.
    cur_break_label: string,
    cur_continue_label: string,
    // Finished `define` texts for function literals. A lambda is generated
    // into its own builder (you can't nest a `define` inside another
    // function's body) and parked here; cg_module writes them out after the
    // regular items. See cg_fn_lit.
    lambdas: [dynamic]string,

    // Entry-block allocas of the function currently being emitted. Local
    // variables and large temporaries are allocated here rather than where
    // they're declared, so an alloca inside a loop body doesn't grow the
    // stack every iteration (and mem2reg can promote it, since it only
    // looks at the entry block). cg_fn_definition splices this in right
    // after `entry:`. nil outside a function body (e.g. while emitting a
    // module's __init_globals), in which case allocas are written inline.
    allocas: ^strings.Builder,

    // ---- declaration dedupe (see cg_items_dec) ----
    // A module can be reached through several import paths (main -> rl ->
    // core and main -> core), and LLVM rejects redefining a type or
    // redeclaring a function. These record what this output file has
    // already seen so every declaration is written exactly once.
    declared_items: map[ItemId]bool, // items whose declaration was handled
    declared_mods: map[ModId]bool,   // modules whose items were already walked
    emitted_externs: map[string]bool, // C symbol names already `declare`d

    // ---- globals ----
    // Collected by cg_items_dec, written by cg_globals_dec once all types exist.
    pending_globals: [dynamic]PendingGlobal,
    // Imported modules that have globals, in post-order (a module's own
    // imports come before it). The entry `main` wrapper calls their
    // __init_globals functions in this order.
    init_mods: [dynamic]ModId,
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

// ---- large aggregates ----
//
// Big structs/arrays must never be first-class SSA values: LLVM's passes
// split an aggregate value into one scalar per element, so a
// `[16384 x Pixel]` becomes tens of thousands of values and llc crawls
// (or looks hung). Like Clang and rustc, such types live in memory and are
// only touched through addresses: GEP + scalar load/store for access,
// `llvm.memcpy` for whole-value copies, `llvm.memset` for zeroing, and
// destination-passing (cg_expr_into) for construction and calls.
//
// Structs/arrays up to this many bytes still travel as SSA values (cheap
// for LLVM, and the ABI coercion code relies on loading small structs).
LARGE_AGGREGATE_BYTES :: 64

is_memory_type :: proc(t: TypeId) -> bool {
    k := get_type(t).kind
    if k != .Struct && k != .FixedSizeArray {
        return false
    }
    return type_size(t) > LARGE_AGGREGATE_BYTES
}

// True if cg_addr can produce a real address for this expression, i.e. it
// names an object in memory (variable, field of one, element, deref).
is_addressable :: proc(c: ^CGCtx, id: ExprId) -> bool {
    #partial switch e in get_expr(id) {
    case Symbol:
        return cgscope_get(&c.scope, e.name).kind == .Variable
    case FieldAccess:
        return is_addressable(c, e.target)
    case Index, Deref:
        return true
    }
    return false
}

// Address of the memory holding the value of `id`. Uses the real address if
// the expression is an lvalue, otherwise evaluates it into a fresh
// entry-block temporary and returns that.
cg_value_addr :: proc(c: ^CGCtx, id: ExprId) -> string {
    if is_addressable(c, id) {
        return cg_addr(c, id)
    }
    slot := new_entry_alloca(c, ty_to_llvm_str(c, expr_ty(id)))
    cg_expr_into(c, id, slot)
    return slot
}

// `declare`s for these three are written once at the top of every module
// (see cg_module); a declare can't be emitted from inside a function body.

// dst <- src, `size` bytes, regions must not overlap.
cg_memcpy :: proc(c: ^CGCtx, dst: string, src: string, size: int) {
    cwritefln(c, "\tcall void @llvm.memcpy.p0.p0.i64(ptr %s, ptr %s, i64 %d, i1 false)",
        dst, src, size)
}

// dst <- src, `size` bytes, overlap allowed (e.g. `a = a`).
cg_memmove :: proc(c: ^CGCtx, dst: string, src: string, size: int) {
    cwritefln(c, "\tcall void @llvm.memmove.p0.p0.i64(ptr %s, ptr %s, i64 %d, i1 false)",
        dst, src, size)
}

// fill `size` bytes at dst with `value` (0 for zero-init).
cg_memset :: proc(c: ^CGCtx, dst: string, value: int, size: int) {
    cwritefln(c, "\tcall void @llvm.memset.p0.i64(ptr %s, i8 %d, i64 %d, i1 false)",
        dst, value, size)
}

// `name = alloca ty` in the current function's entry block (or inline when
// there's no function-level allocas builder, which is only ever in an
// entry block anyway).
cg_alloca_named :: proc(c: ^CGCtx, name: string, ty_str: string) {
    if c.allocas != nil {
        fmt.sbprintfln(c.allocas, "\t%s = alloca %s", name, ty_str)
    } else {
        cwritefln(c, "\t%s = alloca %s", name, ty_str)
    }
}

// Fresh-named entry-block alloca; returns the pointer name.
//
// The name must NOT be a bare number (`%49`): LLVM requires unnamed values
// to appear in increasing numeric order in the text, and a hoisted alloca
// is written above body code that was numbered earlier. A prefixed name
// (`%slot49`) has no ordering rule. The shared counter still makes it unique.
new_entry_alloca :: proc(c: ^CGCtx, ty_str: string) -> string {
    name := new_tmp(c, "slot")
    cg_alloca_named(c, name, ty_str)
    return name
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
    v, ok := reduce_expr_to_single_value(c, cg_expr(c,id));
    if !ok {
        highlight_lines(get_span(id));
        gala_panic("Expression can't be void/must return.");
    } else {
        return v;
    }
    /* v, ok := reduce_expr_to_single_value(c, cg_expr(c,id));
    if !ok {
        highlight_lines(get_span(id).span);
        gala_panic("Expression can't be void/must return.");
    }
    debugln("this:", get(id));
    panic("no"); */
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
stmt_ends_block :: proc(stmt: StmtId) -> bool {
    switch s in get(stmt) {
    // both are unconditional jumps (`br label ...`) — an LLVM basic-block
    // terminator, exactly like Return, so nothing may follow either in
    // the same block.
    case BreakStmt, ContinueStmt: return true;
    case WhileLoop: {
        return check_rets(s.block);
    }
    // A for loop can run zero times, so control can always fall through
    // to whatever follows it — it never ends the block, even if its body
    // returns.
    case ForLoop: return false
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
    case ForLoop: {
        // `for name in expr { body }` lowers to:
        //
        //     <evaluate expr ONCE -> data ptr + length>
        //     %idx = alloca i64 ; store 0
        //     %name = alloca elem
        //     br cond
        //   cond:   %i = load idx ; br (i < len) ? body : end
        //   body:   name = data[i] ; ...user statements...  br step
        //   step:   idx += 1 ; br cond            <- `continue` jumps HERE
        //   end:                                  <- `break` jumps here
        //
        // `continue` must target `step`, not `cond` (unlike while), or the
        // index would never advance.
        id_suffix := next_tmp_index(c)

        cond_label := aprintf(c, "for_cond_label%d", id_suffix)
        body_label := aprintf(c, "for_body_label%d", id_suffix)
        step_label := aprintf(c, "for_step_label%d", id_suffix)
        end_label  := aprintf(c, "for_end_label%d", id_suffix)

        // Evaluate the iterable exactly once, before the loop, so side
        // effects (e.g. `for x in make_list()`) don't repeat per iteration.
        // These SSA values are defined in a block that dominates the whole
        // loop, so using them in cond/body is fine.
        data_ptr, len_v, elem_tid := cg_iter_parts(c, s.expr)
        elem_ty := ty_to_llvm_str(c, elem_tid)

        idx_slot := new_tmp(c, "for_idx")
        cg_alloca_named(c, idx_slot, "i64")
        cwritefln(c, "\tstore i64 0, ptr %s", idx_slot)

        // The loop variable: one slot, overwritten each iteration with a
        // by-value copy of the element.
        var_slot := aprintf(c, "%%%s.for%d", s.name, id_suffix)
        cg_alloca_named(c, var_slot, elem_ty)

        // break/continue registration (same scheme as WhileLoop)
        c.break_labels[id] = end_label
        c.continue_labels[id] = step_label

        old_break := c.cur_break_label
        old_continue := c.cur_continue_label
        c.cur_break_label = end_label
        c.cur_continue_label = step_label

        cwritefln(c, "\tbr label %%%s", cond_label)

        // --- cond ---
        cwritefln(c, "%s:", cond_label)
        cur_i := new_tmp(c, "for_i")
        cwritefln(c, "\t%s = load i64, ptr %s", cur_i, idx_slot)
        in_range := new_tmp(c, "for_lt")
        cwritefln(c, "\t%s = icmp slt i64 %s, %s", in_range, cur_i, len_v)
        cwritefln(c, "\tbr i1 %s, label %%%s, label %%%s", in_range, body_label, end_label)

        // --- body ---
        cwritefln(c, "%s:", body_label)
        elem_ptr := new_tmp(c, "for_elem_ptr")
        cwritefln(c, "\t%s = getelementptr inbounds %s, ptr %s, i64 %s",
            elem_ptr, elem_ty, data_ptr, cur_i)
        if is_memory_type(elem_tid) {
            // large element: copy it with memcpy, never load it as a value
            cg_memcpy(c, var_slot, elem_ptr, int(type_size(elem_tid)))
        } else {
            elem_val := new_tmp(c, "for_elem")
            cwritefln(c, "\t%s = load %s, ptr %s", elem_val, elem_ty, elem_ptr)
            cwritefln(c, "\tstore %s %s, ptr %s", elem_ty, elem_val, var_slot)
        }

        old := c.scope
        c.scope = new_gcscope(&old)
        c.scope.vars[s.name] = {.Variable, var_slot}

        for statement, i in s.block.stmts {
            cg_stmt(c, statement)
            if stmt_ends_block(statement) && i != len(s.block.stmts) - 1 {
                gala_panic("nothing past will be executed")
            }
        }

        free_cgscope(&c.scope)
        c.scope = old

        // fall into step unless the body already ended in a terminator
        if !check_rets(s.block) {
            cwritefln(c, "\tbr label %%%s", step_label)
        }

        // --- step --- (always emitted: `continue` targets it)
        cwritefln(c, "%s:", step_label)
        step_i := new_tmp(c, "for_i")
        cwritefln(c, "\t%s = load i64, ptr %s", step_i, idx_slot)
        next_i := new_tmp(c, "for_next")
        cwritefln(c, "\t%s = add i64 %s, 1", next_i, step_i)
        cwritefln(c, "\tstore i64 %s, ptr %s", next_i, idx_slot)
        cwritefln(c, "\tbr label %%%s", cond_label)

        // --- end ---
        cwritefln(c, "%s:", end_label)

        c.cur_break_label = old_break
        c.cur_continue_label = old_continue
    }
    case ExprId: {
        r := cg_expr(c, s)
        // a discarded large-aggregate result (e.g. `make_terrain();`) is
        // just an address — don't load the whole thing to throw it away
        if r.kind != .Place {
            reduce_expr_to_single_value(c, r);
        }
    }
    case IfElse: {
        id_suffix := next_tmp_index(c)
        end_label := aprintf(c, "end_label%d", id_suffix);

        // Passthrough registration: if this IfElse sits inside an
        // enclosing loop (tracked via c.cur_break_label/cur_continue_label,
        // set by WhileLoop/ForLoop around its body), register the SAME
        // targets under this IfElse's own StmtId. This makes a
        // break/continue resolve correctly regardless of whether the
        // resolution phase pointed it directly at the loop or at this
        // intermediate IfElse.
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
        obj_id := get_ctx().stmt_objects[id]
        obj := get_obj(obj_id);
        var_tid := obj.type.(TypeId)
        var_ty_str := ty_to_llvm_str(c, var_tid)
        name := aprintf(c, "%%%s.%d", s.name, obj_id)

        if is_memory_type(var_tid) {
            // Large aggregate: allocate the slot and build the value
            // straight into it (memcpy / in-place literal / sret call).
            // The value is never an SSA value.
            cg_alloca_named(c, name, var_ty_str)
            cg_expr_into(c, s.value, name)
        } else {
            v := cg_expr(c, s.value)
            value, returns := reduce_expr_to_single_value(c, v);
            assert(returns);
            // allocate (entry block, so loops don't grow the stack)
            cg_alloca_named(c, name, var_ty_str)
            // init
            cwritefln(c, "\tstore %s %s, ptr %s", var_ty_str, value, name);
        }

        // write name to scope (after the initialiser, so `x := x` still
        // sees the outer x)
        c.scope.vars[s.name] = {.Variable, name}
    }
    case Return: {
        if e, ok := s.expr.(ExprId); ok {
            ret_tid := expr_ty(e)

            if c.cur_fn_ret.mode == .Indirect && is_memory_type(ret_tid) {
                // Large aggregate return: construct directly into the
                // caller's sret slot (or memcpy from a local) — no SSA copy.
                cg_expr_into(c, e, "%.sret")
                cwriteln(c, "\tret void")
            } else {
                r, returns := reduce_expr_to_single_value(c, cg_expr(c, e));
                assert(returns);
                ret_ty_str := ty_to_llvm_str(c, ret_tid)

                switch c.cur_fn_ret.mode {
                case .Indirect: {
                    // caller-allocated slot, already passed in as %.sret
                    cwritefln(c, "\tstore %s %s, ptr %s", ret_ty_str, r, "%.sret")
                    cwriteln(c, "\tret void")
                }
                case .Direct: {
                    if c.cur_fn_ret.needs_coercion {
                        slot := new_entry_alloca(c, ret_ty_str)
                        cwritefln(c, "\tstore %s %s, ptr %s", ret_ty_str, r, slot)
                        coerced := new_tmp(c)
                        cwritefln(c, "\t%s = load %s, ptr %s", coerced, c.cur_fn_ret.coerced_type, slot)
                        cwritefln(c, "\tret %s %s", c.cur_fn_ret.coerced_type, coerced)
                    } else {
                        cwritefln(c, "\tret %s %s", ret_ty_str, r)
                    }
                }
                }
            }
        } else {
            cwriteln(c, "\tret void")
        }
    }
    case Assignment: {
        target_tid := expr_ty(s.target)
        if is_memory_type(target_tid) {
            size := int(type_size(target_tid))
            if is_addressable(c, s.value) {
                // memory -> memory. memmove, since `a = a` (or overlapping
                // views of the same object) is legal and memcpy forbids it.
                src := cg_addr(c, s.value)
                dst := cg_addr(c, s.target)
                cg_memmove(c, dst, src, size)
            } else {
                // Evaluate into a temporary first: the expression may read
                // the target (`t = {a = t.b}`), so it can't be built in
                // place.
                tmp := new_entry_alloca(c, ty_to_llvm_str(c, target_tid))
                cg_expr_into(c, s.value, tmp)
                dst := cg_addr(c, s.target)
                cg_memcpy(c, dst, tmp, size)
            }
        } else {
            value, returns := reduce_expr_to_single_value(c, cg_expr(c, s.value))
            assert(returns)
            target_ptr := cg_addr(c, s.target)
            cwritefln(c, "\tstore %s %s, ptr %s",
                ty_to_llvm_str(c, expr_ty(s.target)), value, target_ptr)
        }
    }
    case:panic("impl");
    }
    cwriteln(c, "");
}
// Evaluates an iterable expression (for `for x in <expr>`) EXACTLY ONCE and
// returns everything the loop needs:
//   data_ptr  - pointer to element 0
//   len_v     - element count, an i64 operand (literal or SSA value)
//   elem_tid  - TypeId of one element
// Unlike cg_data_ptr this also yields the length, which for slices/strings
// lives in the same {ptr, i64} value — so the value is evaluated once and
// both fields extracted from it, instead of evaluating the expression twice.
cg_iter_parts :: proc(c: ^CGCtx, id: ExprId) -> (data_ptr: string, len_v: string, elem_tid: TypeId) {
    ty := get_type(expr_ty(id))
    #partial switch ty.kind {
    case .FixedSizeArray:
        // iterates the array in place (no copy): the address is the data
        // pointer, the length is a compile-time constant. (An rvalue array,
        // e.g. `for x in make_arr()`, is written to a temporary first.)
        return cg_value_addr(c, id),
               fmt.aprintf("%d", ty.fixed_size_array.size, allocator = get_ctx().allocator),
               ty.fixed_size_array.type

    case .Slice:
        v, ok := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(ok)
        p := new_tmp(c, "for_data")
        cwritefln(c, "\t%s = extractvalue {{ ptr, i64 }} %s, 0", p, v)
        l := new_tmp(c, "for_len")
        cwritefln(c, "\t%s = extractvalue {{ ptr, i64 }} %s, 1", l, v)
        return p, l, ty.slice.type

    case .String:
        v, ok := reduce_expr_to_single_value(c, cg_expr(c, id)); assert(ok)
        p := new_tmp(c, "for_data")
        cwritefln(c, "\t%s = extractvalue {{ ptr, i64 }} %s, 0", p, v)
        l := new_tmp(c, "for_len")
        cwritefln(c, "\t%s = extractvalue {{ ptr, i64 }} %s, 1", l, v)
        return p, l, byte_type()

    case:
        highlight_lines(get_span(id))
        gala_panic("for: expression is not iterable (expected array, slice or string)")
    }
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
        // arrays always live in memory, never SSA values — get its address,
        // which (with opaque pointers) already IS "pointer to element 0".
        // An rvalue array (e.g. `make_arr()[3]`) is spilled to a temporary.
        return cg_value_addr(c, id), ty_to_llvm_str(c, ty.fixed_size_array.type)

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
        if v.kind == .Argument do panic("arguments can't have an address.");// return v.name

        panic("impl");
        // args aren't addressable — can't assign to a by-value param
        // can however if args is a ptr/array
    }
    case FieldAccess: {
        // cg_value_addr: for a real lvalue this is just cg_addr; an rvalue
        // struct (`make_terrain().pixels[3]`) is spilled to a temporary.
        base_ptr := cg_value_addr(c, e.target)
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
        highlight_lines(get_span(id));
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
//   - internal: `define internal` linkage, used for function literals so
//     their generated names only need to be unique within one module.
//
// Works from a function TypeId + a bare name (no `@`) rather than an item,
// so named functions and function literals share all of it.
//
// Returns the lowered signature and, when define==true, the raw
// (pre-coercion) SSA names of each parameter as they appear on the
// `define` line — the caller needs both to emit the prologue and set
// `c.cur_fn_ret` before generating the body.
cg_fn_header :: proc(c: ^CGCtx, fn_type_id: TypeId, name: string,
        is_extern := false, define := false, internal := false) -> (sig: AbiSignature, param_raw_names: [dynamic]string) {
    fn_ty := get_type(fn_type_id)

    sig = cg_abi_lower_signature(c, fn_type_id, .SysV)

    cwrite(c, define ? "define " : "declare ")
    if internal {
        cwrite(c, "internal ")
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
            vty := fn_ty.fn.gala_abi_ty;
            vname := fn_ty.fn.variadic_name;
            sty := ty_to_llvm_str(c, vty)
            pname := aprintf(c, "%%%s.gala_variadic", vname)
            c.scope.vars[vname] = {kind=.Argument, name=pname}
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
// Item-based wrapper: declarations for extern functions and for functions
// pulled in via imports. (Definitions of named functions go through
// cg_fn_definition, see cg_item.)
cg_fn_declaration :: proc(c: ^CGCtx, i: Item, id: ItemId, is_extern := false, define := false) -> (sig: AbiSignature, param_raw_names: [dynamic]string) {
    objid := get_ctx().item_objects[id]
    obj := get_ctx().objs[objid]
    fn_type_id := obj.type.(TypeId)

    name: string
    if is_extern {
        name = obj.name
    } else {
        name = get_ctx().cg_item_names[id] // use compilers cg item name
    }
    return cg_fn_header(c, fn_type_id, name, is_extern, define)
}
// Emits a complete function definition — header, entry block, argument
// prologue, body statements, implicit trailing `ret void` — into the
// current builder. Shared by named functions (cg_item's FnDec) and
// function literals (cg_fn_lit).
//
// The caller owns the scope: c.scope must already be a fresh scope with
// the right parent (parameters are bound into it by cg_fn_header).
//
// The body is generated into a separate builder so that every alloca made
// along the way (locals, big temporaries, sret slots — see c.allocas) can
// be written in one block right after the prologue, i.e. in the entry
// block, before the body text.
cg_fn_definition :: proc(c: ^CGCtx, fn_type_id: TypeId, name: string, block: Block, internal := false) {
    old_ret := c.cur_fn_ret

    sig, param_raw_names := cg_fn_header(c, fn_type_id, name, false, true, internal)
    c.cur_fn_ret = sig.ret

    cwriteln(c, "{")
    cwriteln(c, "entry:")

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

    // from here on: body -> its own builder, allocas -> their own builder
    outer_b := c.b
    saved_allocas := c.allocas

    alloca_b: strings.Builder
    strings.builder_init(&alloca_b, get_ctx().allocator)
    body_b: strings.Builder
    strings.builder_init(&body_b, get_ctx().allocator)

    c.b = &body_b
    c.allocas = &alloca_b

    block_ends := false

    for statement, index in block.stmts {
        cg_stmt(c, statement)

        if stmt_ends_block(statement) {
            block_ends = true

            if index != len(block.stmts) - 1 {
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

    // restore, then splice: entry allocas first, then the body
    c.b = outer_b
    c.allocas = saved_allocas

    cwrite(c, strings.to_string(alloca_b))
    cwrite(c, strings.to_string(body_b))
    cwriteln(c, "}")

    c.cur_fn_ret = old_ret
}
cg_item :: proc(c: ^CGCtx, id: ItemId) {
    switch i in get_item(id) {
    case Import: {} // ok
    case StructDec: {
    }
    case GlobalVarDec: {
        // declared by cg_globals_dec, initialised by cg_globals_init
    }
    case ExternFnDec: {
        // cg_items_dec may already have declared this C symbol while walking
        // an import; LLVM rejects a second `declare` of the same name.
        if c.emitted_externs[i.name] do return
        c.emitted_externs[i.name] = true
        cg_fn_declaration(c, i, id, is_extern = true)
    }
    case FnDec: {
        // double check type is a function
        // assert(check_fn(i))

        old_scope := c.scope
        c.scope = new_gcscope(&old_scope)

        fn_type_id := get_ctx().objs[get_ctx().item_objects[id]].type.(TypeId)
        cg_fn_definition(c, fn_type_id, get_ctx().cg_item_names[id], i.block)

        // reset scope
        c.scope = old_scope
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
        highlight_lines(get_ctx().current_file, f.span);
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

// ---- global variables ----
//
// A top-level `x := expr;` / `x: T = expr;` becomes an LLVM global
// `@<mod prefix>.x = global T zeroinitializer` in the module that defines it
// (`external global T` in every module that imports it). Its initialiser
// runs at startup in a per-module `__init_globals` function, in declaration
// order; the entry `main` wrapper calls the imported modules' init functions
// first (post-order over the import graph), then its own, then gala `main`.
//
// In scope a global is a `.Variable` whose name is the `@global` address, so
// the existing load-on-read / store-through-address paths work unchanged.

items_have_globals :: proc(items: []ItemId) -> bool {
    for id in items {
        if _, ok := get_item(id).(GlobalVarDec); ok do return true
    }
    return false
}

// "@gala.mod_src_foo.__init_globals"
mod_init_name :: proc(c: ^CGCtx, mid: ModId) -> string {
    mod_prefix, ok := get_ctx().cg_module_prefix[mid]
    if !ok {
        module := get_ctx().mods[mid]
        mod_prefix = mod_prefix_from_path(module.path, prefix="gala.mod")
        get_ctx().cg_module_prefix[mid] = mod_prefix
    }
    return aprintf(c, "@%s.__init_globals", mod_prefix)
}

// Writes the `@global = [external] global T` lines. Runs after cg_items_dec
// so every struct type already has its LLVM name (a global may use a struct
// declared later in the file, or in a later import).
cg_globals_dec :: proc(c: ^CGCtx) {
    for g in c.pending_globals {
        objid := get_ctx().item_objects[g.id]
        ty_str := ty_to_llvm_str(c, get_ctx().objs[objid].type.(TypeId))
        name := get_ctx().cg_item_names[g.id]
        if g.external {
            cwritefln(c, "@%s = external global %s", name, ty_str)
        } else {
            cwritefln(c, "@%s = global %s zeroinitializer", name, ty_str)
        }
    }
}

// Emits this module's init function: evaluates each global's initialiser in
// declaration order and stores it into the global.
cg_globals_init :: proc(c: ^CGCtx, mid: ModId, items: []ItemId) {
    old_ret := c.cur_fn_ret

    cwritef(c, "define void %s() ", mod_init_name(c, mid))
    cwriteln(c, "{")
    cwriteln(c, "entry:")

    for id in items {
        g, ok := get_item(id).(GlobalVarDec)
        if !ok do continue

        objid := get_ctx().item_objects[id]
        gtid := get_ctx().objs[objid].type.(TypeId)
        ty_str := ty_to_llvm_str(c, gtid)
        name := get_ctx().cg_item_names[id]

        if is_memory_type(gtid) {
            // large aggregate global: build it straight into the global
            cg_expr_into(c, g.value, aprintf(c, "@%s", name))
            continue
        }

        value, returns := reduce_expr_to_single_value(c, cg_expr(c, g.value))
        if !returns {
            highlight_lines(get_span(g.value))
            gala_panic("Global initialiser must produce a value.")
        }
        cwritefln(c, "\tstore %s %s, ptr @%s", ty_str, value, name)
    }

    cwriteln(c, "\tret void")
    cwriteln(c, "}")
    cwriteln(c, "")

    c.cur_fn_ret = old_ret
}

// Writes the type definitions and function prototypes this module needs,
// including everything reachable through its imports.
//
// A module can be reached along several import paths (main -> rl -> core
// and main -> core), and LLVM rejects redefining a type or redeclaring a
// function, so everything is emitted at most once per output file:
//   - declared_mods:    a module's items are walked only the first time we
//                       see it (this also makes import cycles terminate).
//   - declared_items:   per-item guard, keyed on ItemId. Imports share the
//                       same AST, so the same declaration always has the
//                       same ItemId however it was reached.
//   - emitted_externs:  extern C functions are keyed on their symbol name,
//                       since two different .gala files may each declare
//                       `extern fn printf` (different ItemIds, same symbol).
// Transitive imports need no `exports` flag: we follow every Import item,
// so `main -> rl -> core` still declares core's items even if `main` never
// imports core itself.
//
// Skipping an already-handled item is safe for name lookup too: the
// `ctx.scope.vars` binding is made the first time the item is seen, and
// there is one scope for the whole output file.
cg_items_dec :: proc(ctx: ^CGCtx, items: []ItemId, is_import:=false) {
    for id in items {
        switch i in get_item(id) {
        case Import: {
            mid := get_ctx().item_module[id]
            cwritefln(ctx, "; decs from mod %s %d", i.fname, mid)
            if ctx.declared_mods[mid] {
                cwritefln(ctx, "; exst already")
                continue
            }
            ctx.declared_mods[mid] = true // mark before recursing so cycles terminate
            m := get_ctx().mods[mid];
            cg_items_dec(ctx, m.ast.items, true); // gen items into this

            // Post-order: this module's own imports were appended during the
            // recursion above, so they run before it.
            if items_have_globals(m.ast.items) {
                append(&ctx.init_mods, mid)
                cwritefln(ctx, "declare void %s()", mod_init_name(ctx, mid))
            }
            cwritefln(ctx, "; end")
        }
        case StructDec: {
            if ctx.declared_items[id] do continue
            ctx.declared_items[id] = true

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
        case GlobalVarDec: {
            if ctx.declared_items[id] do continue
            ctx.declared_items[id] = true

            // Bind now (so later code can look the name up); the actual
            // `@x = global ...` line is written by cg_globals_dec once every
            // struct type has a name. A global is an address, so it's a
            // .Variable: loads/stores go through `ptr @name`.
            name := mod_item_obj_name(ctx, id)
            ctx.scope.vars[i.name] = {.Variable, aprintf(ctx, "@%s", name)}
            append(&ctx.pending_globals, PendingGlobal{id = id, external = is_import})
        }
        case FnDec: { 
            if ctx.declared_items[id] do continue
            ctx.declared_items[id] = true

            name := mod_item_obj_name(ctx, id);
            // declare first;
            // it's a function , so use "@main" instead of "%main"
            ctx.scope.vars[i.name] = {.Symbol, aprintf(ctx, "@%s", name)};
            if is_import {
                cg_fn_declaration(ctx, i, id, is_extern=false);
            }
        }
        case ExternFnDec: { 
            if ctx.declared_items[id] do continue
            ctx.declared_items[id] = true

            name := i.name // use normal name here since it's external
            get_ctx().cg_item_names[id] = name
            // declare first;
            // it's a function , so use "@main" instead of "%main"
            ctx.scope.vars[i.name] = {.Symbol, aprintf(ctx, "@%s", name)};
            if is_import && !ctx.emitted_externs[name] {
                ctx.emitted_externs[name] = true
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
    cgctx.cg_strings = make(map[string]StringGlobalResult, allocator=get_ctx().allocator);
    cgctx.break_labels = make(map[StmtId]string, allocator=get_ctx().allocator);
    cgctx.continue_labels = make(map[StmtId]string, allocator=get_ctx().allocator);
    cgctx.lambdas = make([dynamic]string, allocator=get_ctx().allocator);
    cgctx.declared_items = make(map[ItemId]bool, allocator=get_ctx().allocator);
    cgctx.declared_mods = make(map[ModId]bool, allocator=get_ctx().allocator);
    cgctx.emitted_externs = make(map[string]bool, allocator=get_ctx().allocator);
    cgctx.pending_globals = make([dynamic]PendingGlobal, allocator=get_ctx().allocator);
    cgctx.init_mods = make([dynamic]ModId, allocator=get_ctx().allocator);
    cgctx.scope = new_gcscope(nil);


    // boilerplate + garbage
    fmt.sbprintfln(cgctx.b, "; target info")
    fmt.sbprintfln(cgctx.b, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"");
    fmt.sbprintfln(cgctx.b, "target triple = \"x86_64-pc-linux-gnu\" ");

    // memory intrinsics used by cg_memcpy / cg_memmove / cg_memset.
    // Declared unconditionally: an unused `declare` costs nothing, and one
    // can't be emitted lazily from inside a function body.
    fmt.sbprintfln(cgctx.b, "declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)")
    fmt.sbprintfln(cgctx.b, "declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1)")
    fmt.sbprintfln(cgctx.b, "declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)")


    // structs need to be declared first??
    cg_items_dec(&cgctx, ast.items);

    // globals go after all type definitions (see cg_globals_dec)
    cg_globals_dec(&cgctx)

    for s in get_ctx().data {
        t := new_tmp(&cgctx,p="string", symbol=true)
        v := emit_string_global(t, s);
        cwritefln(&cgctx, "%s", v.ir);
        cgctx.cg_strings[s] = v;
    }

    // gen
    cg_ast(&cgctx, ast)

    // this module's global initialisers (needs the scope bindings made by
    // cg_items_dec, so it must come before anything resets cgctx.scope)
    has_globals := items_have_globals(ast.items)
    if has_globals {
        cg_globals_init(&cgctx, m, ast.items)
    }

    // function literals found while generating the items above were
    // generated into their own builders (see cg_fn_lit); emit them now.
    for lambda in cgctx.lambdas {
        cwritefln(&cgctx, "%s", lambda)
    }

    if is_entry {
        main_id, found := find_main_item(ast)
        if !found {
            gala_panic("entry file has no `main` function")
        }
        name := get_ctx().cg_item_names[main_id];
        entry := aprintf(&cgctx, "@%s", name)

        // Global initialisers: imported modules first (post-order), then ours.
        init_sb: strings.Builder
        strings.builder_init(&init_sb, get_ctx().allocator)
        for mid in cgctx.init_mods {
            fmt.sbprintfln(&init_sb, "            call void %s()", mod_init_name(&cgctx, mid))
        }
        if has_globals {
            fmt.sbprintfln(&init_sb, "            call void %s()", mod_init_name(&cgctx, m))
        }
        init_calls := strings.to_string(init_sb)

        // The C `main` wrapper has to match gala main's real return type.
        // Calling a `void` gala main as `i32` leaves the process exit status
        // as whatever happened to be in eax (this used to exit with the last
        // computed value). void -> exit 0; i32 -> pass it through.
        main_obj := get_ctx().objs[get_ctx().item_objects[main_id]]
        main_fn := get_type(main_obj.type.(TypeId))
        main_ret_kind := get_type(main_fn.fn.ret_ty).kind
        #partial switch main_ret_kind {
        case .Void:
            fmt.sbprintfln(cgctx.b,` define i32 @main(i32 %%argc, ptr %%argv) {{
%s            call void %s()
            ret i32 0
        }`, init_calls, entry);
        case .Int32:
            fmt.sbprintfln(cgctx.b,` define i32 @main(i32 %%argc, ptr %%argv) {{
%s            %%result = call i32 %s()
            ret i32 %%result
        }`, init_calls, entry);
        case:
            gala_panic("`main` must return void or i32")
        }
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

    ll_name := aprintf(c, ".gala_build/%s.ll", name)
    opt_name := aprintf(c, ".gala_build/%s.opt.ll", name)

    e := os.write_entire_file_from_string(ll_name, strings.to_string(sb))
    if e != io.Error.None {
        gala_panic("Failed to write to file:", e);
    }

    {
        // mem2reg
        p, err := os.process_start({command={
            "opt", "-passes=mem2reg", ll_name, "-S", "-o", opt_name, }});

        if err != .NONE {
            debugln( "opt", "-passes=mem2reg", ll_name, "-S", "-o", opt_name,)
            gala_panic("Failed to start LLVM opt process:", err);
        }

        p_state, werr := os.process_wait(p)
        if werr != .NONE {
            gala_panic("Failed to wait for LLVM opt process:", werr);
        }

        if p_state.exit_code != 0 {
            debugln( "opt", "-passes=mem2reg", ll_name, "-S", "-o", opt_name,)
            gala_panic( "Failed to optimise LLVM IR. exit code:",
                p_state.exit_code, "for:", opt_name);
        }

        debugln("opt exit code:", p_state.exit_code);
    }

    {
        debugln("compiling:", name);
        o_name := aprintf(c, ".gala_build/%s.o", name)

        // compile optimised LLVM IR
        p, err := os.process_start({command={
            "llc",
            "-filetype=obj",
            "-O2",
            opt_name,
            "-o", o_name,
        }});
        debugln("started:", name);

        if err != .NONE {
            debugln( "llc", "-filetype=obj", "-O2", opt_name, "-o", o_name,)
            gala_panic("Failed to start llc process:", err);
        }

        debugln("waiting:", name);
        debugln( "llc", "-filetype=obj", "-O2", opt_name, "-o", o_name,)
        p_state, werr := os.process_wait(p)
        if werr != .NONE {
            gala_panic("Failed to wait for llc process:", werr);
        }

        debugln("finished:", name);
        if p_state.exit_code != 0 {
            gala_panic(
                "Failed to compile llvm ir. exit code:",
                p_state.exit_code,
            );
        }

        debugln("llc exit code:", p_state.exit_code);
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
            mod_prefix = mod_prefix_from_path(module.path, prefix="gala.mod");
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
