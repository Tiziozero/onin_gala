package main

import "core:fmt"

// Lowering: runs after typecheck_module and before cg_module.
//
// Rewrites sugar into simpler, already-typed AST so codegen only has to know
// about the core forms. Every node built here gets its type / object / span
// filled in by hand, because the typechecker has already run.
//
// Currently lowers:
//   for name in expr { body }
//
// into
//   __for_iterN := expr;               (expr[:] if expr is a fixed array)
//   __for_idxN  := 0;
//   while __for_idxN < len(__for_iterN) {
//       name := __for_iterN[__for_idxN];
//       __for_idxN += 1;               // before the body, so `continue` is safe
//       body...
//   }
//
// The original ForLoop StmtId is reused for the WhileLoop, so the
// break_lables entries recorded by the typechecker stay valid.

lower_counter: int

lower_module :: proc(ast: ^AST) {
    ctx := get_ctx()
    for id in ast.items {
        #partial switch item in ctx.items[id] {
        case FnDec: {
            f := item
            f.block = lower_block(f.block)
            ctx.items[id] = Item(f)
        }
        case GlobalVarDec: {
            lower_expr(item.value)
        }
        }
    }
}

// Returns a new block; a lowered statement can expand into several, so the
// statement slice has to be rebuilt.
lower_block :: proc(b: Block) -> Block {
    out := make([dynamic]StmtId, allocator=get_ctx().allocator)
    for s in b.stmts {
        lower_stmt(s, &out)
    }
    return Block{stmts=out[:]}
}

// Appends `s` (and anything it expands into) to `out`.
lower_stmt :: proc(s: StmtId, out: ^[dynamic]StmtId) {
    ctx := get_ctx()
    // copy, never a pointer: new_stmt/new_expr below can reallocate the arrays
    stmt := ctx.stmts[s]

    #partial switch v in stmt {
    case ForLoop: {
        lower_for(s, v, out)
        return
    }
    case WhileLoop: {
        w := v
        lower_expr(w.cond)
        w.block = lower_block(w.block)
        ctx.stmts[s] = Stmt(w)
    }
    case IfElse: {
        ie := v
        lower_expr(ie.base_con)
        ie.base_block = lower_block(ie.base_block)
        for &a in ie.alt {
            lower_expr(a.cond)
            a.block = lower_block(a.block)
        }
        if ie.has_else_block {
            ie.else_block = lower_block(ie.else_block)
        }
        ctx.stmts[s] = Stmt(ie)
    }
    case VarDec: {
        lower_expr(v.value)
    }
    case Assignment: {
        lower_expr(v.target)
        lower_expr(v.value)
    }
    case Return: {
        if e, ok := v.expr.(ExprId); ok {
            lower_expr(e)
        }
    }
    case ExprId: {
        lower_expr(v)
    }
    }
    append(out, s)
}

// Walks an expression looking for function literals (their bodies are blocks
// that may contain `for` loops).
lower_expr :: proc(id: ExprId) {
    ctx := get_ctx()
    #partial switch e in ctx.exprs[id] {
    case FnLit: {
        lit := e
        lit.block = lower_block(lit.block)
        ctx.exprs[id] = Expr(lit)
    }
    case Binop:         { lower_expr(e.left); lower_expr(e.right) }
    case UnNegative:    { lower_expr(e.expr) }
    case UnNot:         { lower_expr(e.expr) }
    case Deref:         { lower_expr(e.expr) }
    case Reference:     { lower_expr(e.expr) }
    case Len:           { lower_expr(e.target) }
    case Cast:          { lower_expr(e.target) }
    case Transmute:     { lower_expr(e.target) }
    case FieldAccess:   { lower_expr(e.target) }
    case Index:         { lower_expr(e.target); lower_expr(e.index) }
    case TakeSlice: {
        lower_expr(e.target)
        if !e.empty_start do lower_expr(e.start)
        if !e.empty_end   do lower_expr(e.end)
    }
    case FnCall: {
        lower_expr(e.target)
        for a in e.args do lower_expr(a.expr)
    }
    case FixedSizeArray: {
        for el in e.initialiser do lower_expr(el)
    }
    case StructLit: {
        for _, f in e.fields do lower_expr(f.expr)
    }
    }
}

lower_for :: proc(s: StmtId, f: ForLoop, out: ^[dynamic]StmtId) {
    ctx  := get_ctx()
    span := ctx.spans.stmts[s]
    n    := lower_counter
    lower_counter += 1

    // inner stuff first, so nested for loops are already lowered
    lower_expr(f.expr)
    body := lower_block(f.block)

    // the iterable: arrays become slices so only slice/string reach codegen
    iter_src := f.expr
    iter_ty  := expr_ty(f.expr)
    elem_ty  := get_iterale_base_type(iter_ty)
    if get_type(iter_ty).kind == .FixedSizeArray {
        slice_ty := intern_type(Type{kind=.Slice, slice={type=elem_ty}})
        iter_src = new_expr(Expr(TakeSlice{target=f.expr, empty_start=true, empty_end=true}))
        lower_set(iter_src, slice_ty, span)
        iter_ty = slice_ty
    }

    // __for_iterN := <iterable>;
    iter_obj := lower_new_local(
        fmt.aprintf("__for_iter%d", n, allocator=ctx.allocator), iter_ty, span)
    append(out, lower_vardec(iter_obj, iter_src, span))

    // __for_idxN := 0;
    idx_obj := lower_new_local(
        fmt.aprintf("__for_idx%d", n, allocator=ctx.allocator), integer_type(), span)
    append(out, lower_vardec(idx_obj, lower_number("0", span), span))

    // the user's loop variable keeps its ObjId (body Symbols point at it);
    // it's just a normal local now
    var_obj := ctx.stmt_objects[s]
    ctx.objs[var_obj].kind = .Variable
    delete_key(&ctx.stmt_objects, s)

    // cond: __for_idxN < len(__for_iterN)
    len_e := new_expr(Expr(Len{target=lower_sym(iter_obj, iter_ty, span)}))
    lower_set(len_e, integer_type(), span)
    cond := new_expr(Expr(Binop{
        kind=.Less, left=lower_sym(idx_obj, integer_type(), span), right=len_e}))
    lower_set(cond, ty_from_name("bool"), span)

    stmts := make([dynamic]StmtId, allocator=ctx.allocator)

    // name := __for_iterN[__for_idxN];
    index := new_expr(Expr(Index{
        target=lower_sym(iter_obj, iter_ty, span),
        index=lower_sym(idx_obj, integer_type(), span)}))
    lower_set(index, elem_ty, span)
    append(&stmts, lower_vardec(var_obj, index, span))

    // __for_idxN += 1;   (same shape the parser produces for `+=`)
    sum := new_expr(Expr(Binop{
        kind=.Addition,
        left=lower_sym(idx_obj, integer_type(), span),
        right=lower_number("1", span)}))
    lower_set(sum, integer_type(), span)
    inc := new_stmt(Stmt(Assignment{
        kind=.Addition, target=lower_sym(idx_obj, integer_type(), span), value=sum}))
    ctx.spans.stmts[inc] = span
    append(&stmts, inc)

    for st in body.stmts do append(&stmts, st)

    // the ForLoop becomes the WhileLoop, in place
    ctx.stmts[s] = Stmt(WhileLoop{cond=cond, block=Block{stmts=stmts[:]}})
    append(out, s)
}

// ---- helpers for building already-typed nodes ----

lower_set :: proc(id: ExprId, ty: TypeId, span: SpanStruct) {
    ctx := get_ctx()
    ctx.expr_types[id] = ty
    ctx.spans.exprs[id] = span
}

lower_new_local :: proc(name: string, ty: TypeId, span: SpanStruct) -> ObjId {
    ctx := get_ctx()
    append(&ctx.objs, Object{kind=.Variable, name=name, type=ty})
    oid := ObjId(len(ctx.objs) - 1)
    ctx.obj_modules[oid] = ctx.current_module_id
    ctx.spans.objs_decs[oid] = span
    return oid
}

lower_sym :: proc(oid: ObjId, ty: TypeId, span: SpanStruct) -> ExprId {
    ctx := get_ctx()
    id := new_expr(Expr(Symbol{ctx.objs[oid].name}))
    ctx.expr_objects[id] = oid
    lower_set(id, ty, span)
    return id
}

lower_number :: proc(text: string, span: SpanStruct) -> ExprId {
    id := new_expr(Expr(Number{text}))
    lower_set(id, integer_type(), span)
    return id
}

// `name := value;` bound to an existing object
lower_vardec :: proc(oid: ObjId, value: ExprId, span: SpanStruct) -> StmtId {
    ctx := get_ctx()
    id := new_stmt(Stmt(VarDec{name=ctx.objs[oid].name, type=nil, value=value}))
    ctx.stmt_objects[id] = oid
    ctx.spans.stmts[id] = span
    return id
}
