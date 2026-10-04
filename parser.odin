package main

import "core:fmt"
import "core:strconv"

BinopKind :: enum {
    Addition,
    Subtraction,
    Multiply,
    Divide,
    Modulo,
    Equal,
    NotEqual,
    LessEqual,
    GreaterEqual,
    Less,
    Greater,
    LogicalAnd,
    LogicalOr,
    BitAnd,
    BitOr,
    BitXor,
};
Binop :: struct {
    kind: BinopKind,
    left, right: ExprId,
}
Number :: struct {
    text: string,
}
Symbol :: struct {
    name: string,
}
Cast :: struct {
    to: TypeSpecifier,
    target: ExprId,
}
Transmute :: struct {
    to: TypeSpecifier,
    target: ExprId,
}
TypeIdOf :: struct { t: TypeSpecifier }
ZeroInit :: struct {}
BreakStmt :: struct {label: string};
ContinueStmt :: struct {label: string};
StructLit :: struct {
    name: string,
    fields: map[string]struct{expr:ExprId,span:Span},
}
Len :: struct { target: ExprId };
Sizeof :: struct { t: TypeSpecifier };
BoolLitTrue :: distinct struct {}
BoolLitFalse :: distinct struct {}
UnNegative :: struct {
    expr: ExprId,
}
// Anonymous function expression. Both surface forms produce this node:
//   fn(i: i32, j: i32): i32 { return i + j }
//   fn(i: i32, j: i32): i32 => i + j
// The `=>` form is desugared by the parser into a block containing a single
// `return <expr>;`, so later passes only ever see one shape (a block body).
FnLit :: struct {
    using signature: FnDecSignature,
    span: Span,
    block: Block,
}
Expr :: union {
    StructLit,
    Binop,
    Number,
    Symbol,
    FnCall,
    FieldAccess,
    Index,
    TakeSlice,
    Cast,
    Transmute,
    TypeIdOf,
    Reference,
    Deref,
    UnNot,
    UnNegative,
    FixedSizeArray,
    String,
    Len,
    Sizeof,
    ZeroInit,
    BoolLitTrue,
    BoolLitFalse,
    FnLit,
}
BoolLit :: struct { text: string }
String :: struct {
    s: string
}
Deref :: struct {
    expr: ExprId,
}
Reference :: struct {
    expr: ExprId,
}
UnNot :: struct {
    expr: ExprId,
}
Index :: struct {
    target, index: ExprId,
}
TakeSlice :: struct {
    target, start, end: ExprId,
}
FixedSizeArray :: struct {
    size: int,
    ty: TypeSpecifier,
    initialiser: []ExprId,
}
FieldAccess :: struct {
    target: ExprId,
    field: string,
}
FnCall :: struct {
    target: ExprId,
    args: [dynamic]FnCallArg,
}
FnCallArg :: struct{
    expr: ExprId,
    needs_boxing: bool,
    box_type: TypeId,
};
BaseType :: struct { ident: string, span: Span };
// can't have ptr to itself
PointerType :: struct {ptr:^TypeSpecifier, span: Span };
FixedArreySpecifier :: struct { size: int, base: ^TypeSpecifier, span: Span };
SliceSpecifier :: struct {base : ^TypeSpecifier, span: Span }
AnySpecifier :: struct { span: Span }
FnSpecifier :: struct { span: Span, using signature: ^FnDecSignature }
TypeSpecifier :: union {
    BaseType,
    PointerType,
    FixedArreySpecifier,
    SliceSpecifier,
    AnySpecifier,
    FnSpecifier,
}
VarDec :: struct {
    name: string,
    type: Maybe(TypeSpecifier),
    value: ExprId,
}
Assignment :: struct {
    kind: BinopKind,
    target, value: ExprId,
}
Return :: struct {
    expr: Maybe(ExprId),
}
Stmt :: union {
    VarDec,
    Assignment,
    Return,
    ExprId,
    IfElse,
    WhileLoop,
    ForLoop,
    BreakStmt,
    ContinueStmt,
}
WhileLoop :: struct { cond: ExprId, block: Block }
ForLoop :: struct { name: string, expr: ExprId, block: Block }
AltCon :: struct{cond:ExprId, block:Block}
IfElse :: struct {
    base_con: ExprId,
    base_block: Block,
    alt: []AltCon,
    has_else_block: bool,
    else_block: Block,
}
Parser::struct{
    file: string,
    tokens: []Token,
    i: int,

    ignore_struct_lit: bool,

    // Hidden top-level items created while parsing the current top-level
    // item (see make_default_thunk). parse_tokens moves them into the item
    // list, ahead of the item that caused them.
    extra_items: [dynamic]ItemId,
}
op_kind :: proc(t: Token) -> (kind: BinopKind, ok: bool) {
    switch t.text {
    case "+":  return .Addition,     true
    case "-":  return .Subtraction,  true
    case "*":  return .Multiply,     true
    case "/":  return .Divide,       true
    case "%":  return .Modulo,       true
    case "==": return .Equal,        true
    case "!=": return .NotEqual,     true
    case "<=": return .LessEqual,    true
    case ">=": return .GreaterEqual, true
    case "<":  return .Less,         true
    case ">":  return .Greater,      true
    case "&&": return .LogicalAnd,   true
    case "||": return .LogicalOr,    true
    case "&":  return .BitAnd,       true
    case "~":  return .BitXor,       true
    case "|":  return .BitOr,        true
    }
    return {}, false
}

op_precedence :: proc(t: Token) -> int {
    switch t.text {
    case "||":
        return 1
    case "&&":
        return 2
    case "|":
        return 3
    case "~":
        return 4
    case "&":
        return 5
    case "==", "!=", "<=", ">=", "<", ">":
        return 6
    case "+", "-":
        return 7
    case "*", "/", "%":
        return 8
    }
    return -1
}

op_is_right_assoc :: proc(t: Token) -> bool {
    return false // extend for ** etc.
}
parse_condition :: proc(p: ^Parser) -> ExprId {
    prev_ignore_struct_lit := p.ignore_struct_lit
    p.ignore_struct_lit = true
    e := parse_expr(p)
    p.ignore_struct_lit = prev_ignore_struct_lit
    return e;
}
parse_expr :: proc(p: ^Parser) -> ExprId {
    if current_token(p).kind ==.Ident && is_symbol(next_token(p), "{") &&
            !p.ignore_struct_lit { // flag to ignore struct lits
        name := expect_ident(p); // "name
        consume_token(p); // "{"
        fields := make(map[string]struct{expr: ExprId,span:Span}, allocator=get_ctx().allocator);
        for !is_symbol(current_token(p), "}") {
            fname := expect_ident(p);
            expect_symbol(p, "=");
            expr:=parse_expr(p);
            if f, ok := fields[fname.text]; ok {
                highlight_lines(get_ctx().current_file, fname.span)
                gala_panic("duplicate fields.");
            }
            fields[fname.text] = {expr, fname.span}
            if is_symbol(current_token(p), ",") {
                consume_token(p); // ","
            } else do break
        }
        end := expect_symbol(p, "}");
        id := new_expr(StructLit{name.text, fields})
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={name.span.start, end.span.end}
        }
        return id;
    } else if is_symbol(current_token(p), "[") {
        // eg: "v := [1024]byte{}"       (all zeroes)
        //     "v := [3]i32{1, 2, 3}"    (initialised, trailing comma ok)
        open_b := consume_token(p); // "["
        n := consume_token(p); // number
        if n.kind != .Number {
            highlight_lines(get_ctx().current_file, n.span);
            gala_panic("expected number for fixed size array init");
        }
        size, ok := strconv.parse_int(n.text); assert(ok);
        close_b := expect_symbol(p, "]");

        t := parse_type(p);

        expect_symbol(p, "{");

        // The elements are full expressions, so struct literals must be
        // allowed in here even when this literal sits inside an `if`/`for`
        // header that has ignore_struct_lit set.
        saved_ignore := p.ignore_struct_lit
        p.ignore_struct_lit = false

        elems := make([dynamic]ExprId, allocator=get_ctx().allocator)
        for !is_symbol(current_token(p), "}") {
            append(&elems, parse_expr(p))
            if is_symbol(current_token(p), ",") {
                consume_token(p)
            } else {
                break
            }
        }

        p.ignore_struct_lit = saved_ignore
        end := expect_symbol(p, "}")

        span := Span{start=open_b.span.start, end=end.span.end}

        if len(elems) > size {
            highlight_lines(get_ctx().current_file, span)
            gala_panic("too many elements in array initialiser")
        }

        init: [dynamic]ExprId // stays nil for `{}`
        if len(elems) > 0 {
            init = elems
        }

        id := new_expr(Expr(FixedSizeArray{size=size, ty=t, initialiser=init[:]}))
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span=span,
        }
        return id
    } else if is_symbol(current_token(p), "{") {
        open_b := consume_token(p); // "{"
        close_b := expect_symbol(p, "}");
        id := new_expr(Expr(ZeroInit{}))
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={
                start=open_b.span.start,
                end=close_b.span.end
            }
        }
        panic("not implemented yet")
        // return id;

    } else if current_token(p).kind == .String {
        s := consume_token(p);
        id := new_expr(String{s=s.text})
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span=s.span
        }
        return id;
    }
    return parse_binop(p, 0)
}

parse_compiler_op :: proc(p: ^Parser) -> ExprId {
    if current_token(p).kind == .Cast {
        token := consume_token(p); // "cast"
        expect_symbol(p, "(");
        ty := parse_type(p);
        expect_symbol(p, ")");
        expr := parse_compiler_op(p);
        id := new_expr(Expr(Cast{ty, expr}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, get_span(expr).span.end},
        }
        return id
    } else if current_token(p).kind == .TypeIdOf {
        token := consume_token(p); // "type_id"
        expect_symbol(p, "(");
        ty := parse_type(p);
        end := expect_symbol(p, ")");
        id := new_expr(Expr(TypeIdOf{ty}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, end.span.end},
        }
        return id
    } else if current_token(p).kind == .Transmute {
        token := consume_token(p); // "transmute"
        expect_symbol(p, "(");
        ty := parse_type(p);
        expect_symbol(p, ")");
        expr := parse_compiler_op(p);
        id := new_expr(Expr(Transmute{ty, expr}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, get_span(expr).span.end},
        }
        return id
    }
    return parse_unary(p);
}
parse_unary :: proc(p: ^Parser) -> ExprId {
    if is_symbol(current_token(p), "&") {
        token := consume_token(p); // "&"
        expr := parse_unary(p);
        id := new_expr(Expr(Reference{expr}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start,get_span(expr).span.end}
        }
        return id
    } else if is_symbol(current_token(p), "!") {
        token := consume_token(p); // "!"
        expr := parse_unary(p);
        id := new_expr(Expr(UnNot{expr}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start,get_span(expr).span.end}
        }
        return id
        } else if is_symbol(current_token(p), "-") {
            token := consume_token(p); // "-"
            expr := parse_unary(p);
            id := new_expr(Expr(UnNegative{expr}));
            get_ctx().spans.exprs[id] = {
                file_name=get_ctx().current_file,
                span={token.span.start, get_span(expr).span.end}
            }
            return id
        } else if is_symbol(current_token(p), "+") {
            consume_token(p); // "+", unary plus is a no-op
            return parse_unary(p);
        }
    return parse_postfix(p);
}
parse_binop :: proc(p: ^Parser, min_prec: int) -> ExprId {
    lhs := parse_compiler_op(p)

    for {
        op := current_token(p)
        prec := op_precedence(op)
        if prec < min_prec { break }

        consume_token(p)

        next_min := prec + (0 if op_is_right_assoc(op) else 1)
        rhs := parse_binop(p, next_min)

        kind, _ := op_kind(op)
        prev := lhs
        lhs = new_expr(Expr(Binop{
            kind  = kind,
            left  = lhs,
            right = rhs,
        }))
        // start at lhs start and end at rhs end
        get_ctx().spans.exprs[lhs] = {
            file_name=get_ctx().current_file,
            span={
                start=get_span(prev).span.start,
                end=get_span(rhs).span.end,
            }
        }
    }

    return lhs
}
consume_token :: proc(p: ^Parser) -> Token {
    if p.i < len(p.tokens) {
        t := p.tokens[p.i];
       p.i += 1;
       return t;
    } else {
        return Token{kind=.EOF}
    }
}
current_token :: proc(p: ^Parser) -> Token {
    if p.i < len(p.tokens) {
        t := p.tokens[p.i];
       return t;
    } else {;
        return Token{kind=.EOF}
    }
}
next_token :: proc(p: ^Parser) -> Token {
    if p.i + 1 < len(p.tokens) {
        t := p.tokens[p.i + 1];
       return t;
    } else {
        return Token{kind=.EOF}
    }
}
// span of the most recently consumed token (used to find the end of a block)
prev_token_span :: proc(p: ^Parser) -> Span {
    if p.i > 0 && p.i - 1 < len(p.tokens) {
        return p.tokens[p.i - 1].span
    }
    return Span{}
}
Block :: struct {
    stmts: []StmtId,
}
is_symbol :: proc(t: Token, s: string) -> bool {
    if t.kind == .Symbol && t.text == s { return true }
    return false;
}
parse_stmt :: proc(p: ^Parser) -> StmtId {
    if current_token(p).kind == .Ident &&
        is_symbol(next_token(p), ":=") {
        name := consume_token(p)
        consume_token(p);
        expr := parse_expr(p);
        end := expect_symbol(p, ";");
        id := new_stmt(Stmt(VarDec{name=name.text, type=nil, value=expr}));
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span={name.span.start, end.span.end},
        }
        return id
    } else if current_token(p).kind == .Ident &&
        is_symbol(next_token(p), ":") {
        name := consume_token(p);
        consume_token(p); // ":"
        ty := parse_type(p);
        expect_symbol(p, "=");
        expr := parse_expr(p);
        end := expect_symbol(p, ";");
        id := new_stmt(Stmt(VarDec{name=name.text, type=ty, value=expr}));
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span={name.span.start, end.span.end},
        }
        return id
    } else if is_kw(current_token(p), .Return) {
        token := consume_token(p); // "return";
        
        if is_symbol(current_token(p), ";") {
            end_semi := consume_token(p); // ";"
            id := new_stmt(Stmt(Return{expr=nil}));
            get_ctx().spans.stmts[id] = {
                file_name=get_ctx().current_file,
                span={
                    start=token.span.start,
                    end=end_semi.span.end
                }
            }
            return id
        }
        e := parse_expr(p);
        end_semi := expect_symbol(p, ";");
        id := new_stmt(Stmt(Return{expr=e}));
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span={
                start=token.span.start,
                end=end_semi.span.end
            }
        }
        return id
    } else if is_kw(current_token(p), .If) {
        token := consume_token(p); // "if"
        s := IfElse{}
        s.base_con = parse_condition(p);
        s.base_block = parse_block(p);
        alts := make([dynamic]AltCon, allocator=get_ctx().allocator);
        for is_kw(current_token(p), .Else) && is_kw(next_token(p), .If) {
            consume_token(p); // else
            consume_token(p); // if
            cond := parse_expr(p);
            block := parse_block(p);
            append(&alts, AltCon{cond, block})
        }
        s.alt = alts[:]
        if is_kw(current_token(p), .Else) {
            consume_token(p); // else
            block := parse_block(p);
            s.else_block = block
            s.has_else_block = true
        }
        id := new_stmt(s);
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id;
    } else if is_kw(current_token(p), .While) {
        token := consume_token(p); // "while"
        cond := parse_condition(p);
        block := parse_block(p);
        id := new_stmt(WhileLoop{cond, block});
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id;
    // "for name in obj {..."
    } else if is_kw(current_token(p), .For) {
        token := consume_token(p); // "for"
        ident := expect_ident(p);
        if !is_kw(current_token(p), .In) {
            highlight_lines(get_ctx().current_file, current_token(p).span);
            gala_panic("Expected \"in\".");
        }
        in_kw := consume_token(p);

        prev := p.ignore_struct_lit
        p.ignore_struct_lit = true
        expr := parse_expr(p)
        block := parse_block(p);
        p.ignore_struct_lit = prev;

        id := new_stmt(ForLoop{name=ident.text, expr=expr, block=block});
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id;
    } else if is_kw(current_token(p), .Break) {
        token := consume_token(p); // "break"
        end_semi := expect_symbol(p, ";");
        id := new_stmt(BreakStmt{});
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id;
    } else if is_kw(current_token(p), .Continue) {
        token := consume_token(p); // "continue"
        end_semi := expect_symbol(p, ";");
        id := new_stmt(ContinueStmt{});
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id;
    } else {
        expr := parse_expr(p);
        if is_symbol(current_token(p), "=") {
            token := consume_token(p); // "="
            v := parse_expr(p);
            end := expect_symbol(p, ";");
            id := new_stmt(Stmt(Assignment{target=expr, value=v}));
            get_ctx().spans.stmts[id] = {
                file_name=get_ctx().current_file,
                span={
                    start=get_ctx().spans.exprs[expr].span.start,
                    end=end.span.end
                }
            }
            return id;
        } else if is_symbol(current_token(p), "+=") ||
                  is_symbol(current_token(p), "-=") ||
                  is_symbol(current_token(p), "*=") ||
                  is_symbol(current_token(p), "/=") ||
                  is_symbol(current_token(p), "%=") ||
                  is_symbol(current_token(p), "&=") ||
                  is_symbol(current_token(p), "|=") ||
                  is_symbol(current_token(p), "~=") {
            token := consume_token(p);

            kind : BinopKind;
            if token.text == "+=" {
                kind = .Addition;
            } else if token.text == "-=" {
                kind = .Subtraction;
            } else if token.text == "*=" {
                kind = .Multiply;
            } else if token.text == "/=" {
                kind = .Divide;
            } else if token.text == "%=" {
                kind = .Modulo;
            } else if token.text == "&=" {
                kind = .BitAnd;
            } else if token.text == "|=" {
                kind = .BitOr;
            } else if token.text == "~=" {
                kind = .BitXor;
            }

            v := parse_expr(p);
            end := expect_symbol(p, ";");

            value := new_expr(Binop{kind=kind,left=expr, right=v})
            get_ctx().spans.exprs[value] = {
                file_name=get_ctx().current_file,
                span={
                    start=get_span(expr).span.start,
                    end=get_span(v).span.end,
                }
            }; // set span for expr
            id := new_stmt(Stmt(Assignment{
                target=expr,
                value=value,
                kind=kind,
            }));

            get_ctx().spans.stmts[id] = {
                file_name=get_ctx().current_file,
                span={
                    start=get_ctx().spans.exprs[expr].span.start,
                    end=end.span.end,
                }
            }

            return id;
        }

        expect_symbol(p, ";");
        id := new_stmt(Stmt(ExprId(expr)));
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=get_ctx().spans.exprs[expr].span
        }
        return id;
    }
}
is_current_kw :: proc(p: ^Parser, k: Keyword) -> bool {
    if current_token(p).kind == .Keyword && current_token(p).kw == k do return true
    return false
}
is_kw :: proc(t: Token, k: Keyword) -> bool {
    if t.kind == .Keyword && t.kw == k do return true
    return false
}

// "=>" may be lexed as a single symbol, or as "=" followed by ">" depending on
// the lexer; accept both so the parser doesn't care.
is_fat_arrow :: proc(p: ^Parser) -> bool {
    if is_symbol(current_token(p), "=>") do return true
    return is_symbol(current_token(p), "=") && is_symbol(next_token(p), ">")
}
consume_fat_arrow :: proc(p: ^Parser) {
    if is_symbol(current_token(p), "=>") {
        consume_token(p) // "=>"
    } else {
        consume_token(p) // "="
        consume_token(p) // ">"
    }
}

// fn(args): ret { ... }      block body
// fn(args): ret => expr      expression body (desugared to `{ return expr; }`)
parse_fn_lit :: proc(p: ^Parser) -> ExprId {
    kw := consume_token(p) // "fn"

    lit := FnLit{}
    lit.signature = parse_args_dec(p)

    // the body is a fresh context: a struct literal is fine in here even if
    // the lambda itself sits inside an `if`/`while` condition.
    prev_ignore_struct_lit := p.ignore_struct_lit
    p.ignore_struct_lit = false
    defer p.ignore_struct_lit = prev_ignore_struct_lit

    end_pos: int
    if is_fat_arrow(p) {
        consume_fat_arrow(p)
        e := parse_expr(p)
        end_pos = get_span(e).span.end

        ret_id := new_stmt(Stmt(Return{expr=e}))
        get_ctx().spans.stmts[ret_id] = {
            file_name=get_ctx().current_file,
            span=get_span(e).span,
        }
        stmts := make([dynamic]StmtId, allocator=get_ctx().allocator)
        append(&stmts, ret_id)
        lit.block = Block{stmts=stmts[:]}
    } else if is_symbol(current_token(p), "{") {
        lit.block = parse_block(p)
        end_pos = prev_token_span(p).end // the closing "}"
    } else {
        highlight_lines(get_ctx().current_file, current_token(p).span)
        gala_panic("Expected '{' or '=>' after function literal signature.")
    }

    lit.span = {start=kw.span.start, end=end_pos}

    id := new_expr(Expr(lit))
    get_ctx().spans.exprs[id] = {
        file_name=get_ctx().current_file,
        span=lit.span,
    }
    return id
}

parse_postfix :: proc(p: ^Parser) -> ExprId {
    t := parse_primary(p);
    for {
        if is_symbol(current_token(p), "(") {
            start := consume_token(p); // "("
            args := make([dynamic]FnCallArg, allocator=get_ctx().allocator);
            // "until it meets a ")"
            for !is_symbol(current_token(p), ")") {
                e := parse_expr(p);
                append(&args, FnCallArg{expr=e})
                if is_symbol(current_token(p), ",") {
                    consume_token(p); // ","
                } else do break
            }
            end := expect_symbol(p, ")"); // expect ")"

            id := new_expr(FnCall{target=t, args=args});
            get_ctx().spans.exprs[id] = {
                file_name=get_ctx().current_file,
                span={start=get_span(t).span.start,end=end.span.end}
            }
            t = id
        } else if is_symbol(current_token(p), ".") {
            token := consume_token(p); // "."
            ident := expect_ident(p);
            id := new_expr(FieldAccess{target=t, field=ident.text});
            get_ctx().spans.exprs[id] = {
                file_name=get_ctx().current_file,
                span={start=get_span(t).span.start,end=ident.span.end}
            }
            t = id
        } else if is_symbol(current_token(p), "[") {
            start := consume_token(p); // "["
            index := parse_expr(p);

            if is_symbol(current_token(p), "]") {
                end := expect_symbol(p, "]");
                id := new_expr(Index{target=t, index=index});
                get_ctx().spans.exprs[id] = {
                    file_name=get_ctx().current_file,
                    span={start=get_span(t).span.start,end=end.span.end}
                }
                t = id
            } else if is_symbol(current_token(p), ":") {
                consume_token(p); // ":"
                end_index := parse_expr(p);
                end := expect_symbol(p, "]");
                id := new_expr(TakeSlice{target=t, start=index, end=end_index});
                get_ctx().spans.exprs[id] = {
                    file_name=get_ctx().current_file,
                    span={start=get_span(t).span.start,end=end.span.end}
                }
                t = id
            }
        } else if is_symbol(current_token(p), "^") {
            token := consume_token(p); // "^"
            id := new_expr(Deref{t});
            get_ctx().spans.exprs[id] = {
                file_name=get_ctx().current_file,
                span={get_span(t).span.start, token.span.end}
            }
            t = id

        } else do break
    }
    return t;
}
parse_primary :: proc(p: ^Parser) -> ExprId {
    if is_kw(current_token(p), .Fn) {
        return parse_fn_lit(p)
    } else if current_token(p).kind == .Ident {
        token := consume_token(p)
        e :=  Expr(Symbol{token.text});
        id := new_expr(e)
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id
    } else if current_token(p).kind == .Number {
        token := consume_token(p)
        id := new_expr(Expr(Number{token.text}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id
    } else if is_symbol(current_token(p), "(") {
        token := consume_token(p); // "("
        e := parse_expr(p);
        end := expect_symbol(p, ")"); // ")";
        id := e;
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, end.span.end}
        }
        return id
    } else if current_token(p).kind == .Len {
        token := consume_token(p);// "len"
        open := expect_symbol(p, "("); // "("
        e := parse_expr(p);
        close := expect_symbol(p, ")"); // ")"
        id := new_expr(Len{e});
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, close.span.end}
        }
        return id
    } else if current_token(p).kind == .Sizeof {
        token := consume_token(p);// "sizeof"
        open := expect_symbol(p, "("); // "("
        t := parse_type(p);
        close := expect_symbol(p, ")"); // ")"
        id := new_expr(Sizeof{t});
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, close.span.end}
        }
        return id
    } else if current_token(p).kind == .True {
        token := consume_token(p);
        id := new_expr(BoolLitTrue{});
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id
    } else if current_token(p).kind == .False {
        token := consume_token(p);
        id := new_expr(BoolLitFalse{});
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span=token.span
        }
        return id
    }
    highlight_lines(get_ctx().current_file, current_token(p).span);
    gala_panic("invalid primary token")
}
parse_block :: proc(p: ^Parser) -> Block{
    expect_symbol(p, "{");
    stmts := make([dynamic]StmtId, allocator=get_ctx().allocator);
    for !(current_token(p).kind == .Symbol && current_token(p).text == "}") &&
        (current_token(p).kind != .EOF) {
        stmt := parse_stmt(p);
        append(&stmts, stmt)
    }
    expect_symbol(p, "}");
    return Block{stmts=stmts[:]}
}

// `default` is set for `name: type = <expr>` parameters. The parser never
// stores the written expression here directly: it is moved into a hidden
// function and `default` is a call to that function (see make_default_thunk).
FnDecArg :: struct{name: string, t: TypeSpecifier, span: Span, default: Maybe(ExprId)}
FnDecSignature :: struct {
    name: string,
    args: []FnDecArg, 
    ret_ty: Maybe(TypeSpecifier),
    is_variadic: bool,
    variadic_ty: TypeSpecifier,
    variadic_arg_name: string,
}
FnDec :: struct {
    using signature: FnDecSignature,
    span: Span,
    block: Block,
}
StructField :: struct{name: string, t: TypeSpecifier, span: Span}
StructDec :: struct {
    name: string,
    fields: []StructField,
}
ExternFnDec :: struct {
    using signature: FnDecSignature,
    span: Span,
}
// Top-level variable:
//   counter := 0;
//   limit: i32 = 100;
// `type` is nil for the `:=` form (inferred by the type checker). The value
// can be any expression: codegen runs it in a per-module init function
// before gala `main`, in declaration order.
GlobalVarDec :: struct {
    name: string,
    type: Maybe(TypeSpecifier),
    value: ExprId,
}

Import :: struct {
    fname, alias: string,
}
Item :: union {
    Import,
    StructDec,
    FnDec,
    ExternFnDec,
    GlobalVarDec,
}

base_span :: proc(t: ^TypeSpecifier) -> Span {
    switch t in t {
    case BaseType: return t.span;
    case PointerType: return t.span;
    case SliceSpecifier: return t.span;
    case FixedArreySpecifier: return t.span;
    case AnySpecifier: return t.span;
    case FnSpecifier: return t.span;
    }
    panic("impl")
}
parse_type :: proc(p: ^Parser) -> TypeSpecifier {
    if current_token(p).kind == .Ident {
        token := consume_token(p)
        return TypeSpecifier(BaseType({token.text, token.span}));
    }
    if is_kw(current_token(p), .Fn) {
        token:=consume_token(p); // "fn"

        spec := new(FnDecSignature, get_ctx().allocator);
        spec^ = parse_args_dec(p);
        return FnSpecifier{ span = token.span, signature = spec };

    }
    if is_symbol(current_token(p), "[") {
        token := consume_token(p); // "["
        if is_symbol(current_token(p), "]") { // slice
            consume_token(p); // "]"
            base_specifier := new(TypeSpecifier, allocator=get_ctx().allocator);
            base_specifier^ = parse_type(p);

            return TypeSpecifier(SliceSpecifier{
                base=base_specifier,
                span={
                    start=token.span.start,
                    end=base_span(base_specifier).end
                }
            })
        }
        n := consume_token(p);
        assert(n.kind == .Number);
        size, ok := strconv.parse_int(n.text)
        assert(ok);
        end := expect_symbol(p, "]");

        base_specifier := new(TypeSpecifier, allocator=get_ctx().allocator);
        base_specifier^ = parse_type(p);

        return TypeSpecifier(FixedArreySpecifier{
            size=size,base=base_specifier,
            span={
                start=token.span.start,
                end=base_span(base_specifier).end
            }
        })
    } else if is_symbol(current_token(p), "^") {
        token := consume_token(p); // "^"
        base_specifier := new(TypeSpecifier, allocator=get_ctx().allocator);
        base_specifier^ = parse_type(p);
        return TypeSpecifier(PointerType{
            ptr=base_specifier,
            span=token.span,
        })
    } else if current_token(p).kind == .Any {
        t := consume_token(p); // "any"
        return AnySpecifier{span=t.span};
    }
    highlight_lines(get_ctx().current_file, current_token(p).span)
    gala_panic("Invalid token in type specifier.");
}

ArgSpecs :: struct {
}

// Unique across the whole compiler run, not per file: codegen binds items
// into its scope by *name*, and an output file sees the items of every
// module it imports, so two modules must never produce the same thunk name.
default_thunk_counter: int

// A parameter default can be any expression, so it can't be re-evaluated at
// the call site: it might name a global (which a local in the caller could
// shadow), contain a function literal (which would be emitted once per call
// site), or need the declaring module's scope. Instead it is moved into a
// hidden top-level function
//
//     fn __default_N(): <param type> { return <expr>; }
//
// and the parameter's default becomes the call `__default_N()`. Everything
// downstream then treats it like any other call:
//   - the resolver resolves the expression once, in module scope (so it can
//     see globals and functions, but not parameters or locals),
//   - typing the call only needs the thunk's signature, never its body, so
//     checking defaults doesn't depend on globals having been typed yet,
//   - codegen emits one function per default and a plain call per omitted
//     argument. The default is re-evaluated on every call that omits it.
//
// The thunk item is queued in p.extra_items; parse_tokens inserts it ahead of
// the item that contains the signature.
make_default_thunk :: proc(p: ^Parser, ty: TypeSpecifier, expr: ExprId) -> ExprId {
    span := get_span(expr).span
    file := get_ctx().current_file

    name := fmt.aprintf("__default_%d", default_thunk_counter, allocator=get_ctx().allocator)
    default_thunk_counter += 1

    // body: `return <expr>;`
    ret_id := new_stmt(Stmt(Return{expr=expr}))
    get_ctx().spans.stmts[ret_id] = {file_name=file, span=span}
    stmts := make([dynamic]StmtId, allocator=get_ctx().allocator)
    append(&stmts, ret_id)

    f := FnDec{}
    f.name = name
    f.ret_ty = ty
    f.span = span
    f.block = Block{stmts=stmts[:]}
    item_id := new_item(Item(f))
    get_ctx().spans.items[item_id] = {file_name=file, span=span}
    append(&p.extra_items, item_id)

    // the new default: `__default_N()`
    sym := new_expr(Expr(Symbol{name}))
    get_ctx().spans.exprs[sym] = {file_name=file, span=span}

    call := new_expr(FnCall{target=sym, args=make([dynamic]FnCallArg, allocator=get_ctx().allocator)})
    get_ctx().spans.exprs[call] = {file_name=file, span=span}
    return call
}

// Parameters are positional, so once one has a default every parameter after
// it must too (otherwise a call couldn't leave the earlier one out).
// Defaults can't be combined with a variadic tail: the tail would have to
// come after the defaulted params, and there'd be no way to skip them.
// `any` parameters can't have a default: the hidden function would have to
// return `any`, and `any` is only accepted as a parameter type.
parse_args_dec :: proc(p: ^Parser) -> FnDecSignature {
    f := FnDecSignature{};
    args := make([dynamic]FnDecArg, allocator=get_ctx().allocator)
    seen_default := false
    expect_symbol(p, "(");
    for !is_symbol(current_token(p), ")") {
        name := expect_ident(p);
        expect_symbol(p, ":")
        if is_symbol(current_token(p), ".") &&
            is_symbol(next_token(p), ".") {
            token := consume_token(p); // "."
            consume_token(p); // "."
            t := parse_type(p);
            f.is_variadic = true;
            f.variadic_ty = t;
            f.variadic_arg_name = name.text;
            break;
        }
        ty := parse_type(p);

        default: Maybe(ExprId) = nil
        if is_symbol(current_token(p), "=") {
            consume_token(p); // "="

            if _, is_any := ty.(AnySpecifier); is_any {
                highlight_lines(get_ctx().current_file, name.span)
                gala_panic("Default values aren't supported for `any` parameters.")
            }

            // inside the parens, so a struct literal is unambiguous even if
            // this signature sits in an `if`/`while` condition
            prev_ignore_struct_lit := p.ignore_struct_lit
            p.ignore_struct_lit = false
            written := parse_expr(p)
            p.ignore_struct_lit = prev_ignore_struct_lit

            default = make_default_thunk(p, ty, written)
            seen_default = true
        } else if seen_default {
            highlight_lines(get_ctx().current_file, name.span)
            gala_panic("A parameter without a default value can't come after one with a default.")
        }

        append(&args, FnDecArg{name=name.text, t=ty, span=name.span, default=default})
        if is_symbol(current_token(p), ",") {
            consume_token(p);
        } else {
            break;
        }
    }
    end := expect_symbol(p, ")");
    if f.is_variadic && seen_default {
        highlight_lines(get_ctx().current_file, end.span)
        gala_panic("Default parameter values can't be combined with a variadic parameter.")
    }
    f.args = args[:]
    if is_symbol(current_token(p), ":") {
        consume_token(p); // ":"
        f.ret_ty = parse_type(p);
    }
    return f;
}

parse_fn_signature :: proc(p: ^Parser) -> FnDec {
    kw := consume_token(p); // "fn"
    if !(kw.kind == .Keyword && kw.kw == .Fn) {
        highlight_lines(get_ctx().current_file, kw.span)
        gala_panic("Expected \"fn\".");
    }
    name := expect_ident(p);
          // args
    f := FnDec{};
    f.signature = parse_args_dec(p);
    f.name = name.text;

    f.span.start = kw.span.start
    f.span.end = current_token(p).span.end;
    return f;
}
// Top-level `name := expr;` or `name: type = expr;`
parse_global_var_dec :: proc(p: ^Parser) -> ItemId {
    name := expect_ident(p)

    ty: Maybe(TypeSpecifier) = nil
    if is_symbol(current_token(p), ":=") {
        consume_token(p) // ":="
    } else if is_symbol(current_token(p), ":") {
        consume_token(p) // ":"
        ty = parse_type(p)
        expect_symbol(p, "=")
    } else {
        highlight_lines(get_ctx().current_file, current_token(p).span)
        gala_panic("Expected \":=\" or \":\" after a top-level name (only declarations are allowed at the top level).")
    }

    value := parse_expr(p)
    end := expect_symbol(p, ";")

    id := new_item(Item(GlobalVarDec{name=name.text, type=ty, value=value}))
    get_ctx().spans.items[id] = {
        file_name=get_ctx().current_file,
        span={name.span.start, end.span.end},
    }
    return id
}
parse_module_kw :: proc(p: ^Parser) -> ItemId {
    #partial switch current_token(p).kw {
    case .Struct: {
        kw := consume_token(p); // "struct"
        name := expect_ident(p);
        expect_symbol(p, "{");
        fields := make([dynamic]StructField, allocator=get_ctx().allocator);
        for !is_symbol(current_token(p), "}") {
            name := expect_ident(p);
            expect_symbol(p, ":");
            ty := parse_type(p);
            append(&fields, StructField{name=name.text, t=ty, span=name.span});
            if is_symbol(current_token(p), ",") {
                consume_token(p); // ","
            } else do break
        }
        expect_symbol(p, "}");
        sd := StructDec{
            name=name.text,
            fields=fields[:],
        }
        id := new_item(sd)
        get_ctx().spans.items[id] = {
            file_name=get_ctx().current_file,
            span=name.span
        }

        return id
    }
    case .Fn: {
        f := parse_fn_signature(p);
        b := parse_block(p);
        f.block = b;

        id := new_item(Item(f))
        get_ctx().spans.items[id] = {
            file_name=get_ctx().current_file,
            span=f.span
        }

        return id
    }
    case .Extern: {
        token := consume_token(p); // "extern"
        f := parse_fn_signature(p);
        ef := ExternFnDec{}
        ef.name = f.name;
        ef.args = f.args;
        ef.ret_ty = f.ret_ty
        ef.signature = f.signature
        ef.span = f.span
        
        expect_symbol(p, ";");

        id := new_item(Item(ef))
        get_ctx().spans.items[id] = {
            file_name=get_ctx().current_file,
            span=ef.span
        }
        return id;
    }
    case .Import: { // import "file.gala";
        current_name := get_ctx().current_file;
        token := consume_token(p); // "import"
        fname := consume_token(p); // file name?
        if fname.kind != .String {
            highlight_lines(get_ctx().current_file, fname.span)
            gala_panic("Expected string.");
        }
        semi := expect_symbol(p, ";"); // ";"
        handle_file(fname.text);
        id := new_item(Item(Import{fname=fname.text}))
        get_ctx().spans.items[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, semi.span.end}
        }
        get_ctx().current_file = current_name
        return id;
    }
    case: panic("impl");
    }
    panic("impl");
}
expect_symbol :: proc(p: ^Parser, str: string) -> Token {
    c := current_token(p);
    if c.kind != .Symbol {
        highlight_lines(get_ctx().current_file, c.span);
        gala_panic("Expected symbol, got:", c);
    }
    if c.text != str {
        highlight_lines(get_ctx().current_file, c.span);
        gala_panic("Expected", str, "got:", c.text);
    }
    return consume_token(p)
}
expect_ident :: proc(p: ^Parser) -> Token {
    c := current_token(p);
    if c.kind != .Ident {
        highlight_lines(get_ctx().current_file, c.span)
        gala_panic("Expected ident got:", c);
    }
    return consume_token(p)
}
AST :: struct {
    items: []ItemId,
}
parse_tokens :: proc(file_name: string, tokens: []Token) -> AST {
    _p := Parser{file=file_name, tokens=tokens}
    _p.extra_items = make([dynamic]ItemId, allocator=get_ctx().allocator)
    p := &_p
    items := make([dynamic]ItemId, allocator=get_ctx().allocator)
    for current_token(p).kind != .EOF {
        id: ItemId
        #partial switch current_token(p).kind {
        case .Keyword: {
            id = parse_module_kw(p)
        }
        case .Ident: {
            id = parse_global_var_dec(p)
        }
        case:
            debugln(current_token(p));
            highlight_lines(get_ctx().current_file, current_token(p).span);
            panic("impl");
        }

        // hidden default-value functions created while parsing this item go
        // in first, so they precede the item that refers to them
        for extra in p.extra_items {
            append(&items, extra)
        }
        clear(&p.extra_items)

        append(&items, id)
    }
    return AST{items=items[:]}
}
