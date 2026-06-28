package main

import "core:fmt"

BinopKind :: enum { Addition, Subtraction, Multiply, Divide };
Binop :: struct {
    kind: BinopKind,
    left, right: ExprId,
}
op_precedence :: proc(t: Token) -> int {
    if t.kind != .Symbol { return -1 }
    switch t.text {
    case "+", "-": return 1
    case "*", "/": return 2
    }
    return -1
}
Number :: struct {
    text: string,
}
Symbol :: struct {
    name: string,
}
Expr :: union {
    Binop,
    Number,
    Symbol,
    FnCall,
}
FnCall :: struct {
    target: ExprId,
    args: [dynamic]ExprId,
}
op_is_right_assoc :: proc(t: Token) -> bool {
    return false // extend for ** etc.
}
op_kind :: proc(t: Token) -> (kind: BinopKind, ok: bool) {
    switch t.text {
    case "+": return .Addition,    true
    case "-": return .Subtraction, true
    case "*": return .Multiply,    true
    case "/": return .Divide,      true
    }
    return {}, false
}
// Entry point — replaces your old parse_binop
parse_expr :: proc(p: ^Parser) -> ExprId {
    return parse_binop(p, 0)
}

parse_binop :: proc(p: ^Parser, min_prec: int) -> ExprId {
    lhs := parse_postfix(p)

    for {
        op := current_token(p)
        prec := op_precedence(op)
        if prec < min_prec { break }

        consume_token(p)

        next_min := prec + (0 if op_is_right_assoc(op) else 1)
        rhs := parse_binop(p, next_min)

        kind, _ := op_kind(op)
        lhs = new_expr(Expr(Binop{
            kind  = kind,
            left  = lhs,
            right = rhs,
        }))
    }

    return lhs
}
BaseType :: distinct string;
// can't have ptr to itself
PointerType :: distinct ^TypeSpecifier;
TypeSpecifier :: union {
    BaseType,
    PointerType,
}
VarDec :: struct {
    name: string,
    type: Maybe(TypeSpecifier),
    value: ExprId,
}
Assignment :: struct {
    target, value: ExprId,
}
Return :: struct {
    expr: Maybe(ExprId),
}
Stmt :: union {
    VarDec,
    Assignment,
    Return,
    ExprId
}
Parser::struct{
    tokens: []Token,
    i: int,
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
Block :: struct {
    stmts: []StmtId,
}
is_symbol :: proc(t: Token, s: string) -> bool {
    if t.kind == .Symbol && t.text == s { return true }
    return false;
}
parse_stmt :: proc(p: ^Parser) -> StmtId {
    a := 7;
    if current_token(p).kind == .Ident &&
        is_symbol(next_token(p), ":=") {
        name := consume_token(p)
        consume_token(p);
        expr := parse_expr(p);
        expect_symbol(p, ";");
        return new_stmt(Stmt(VarDec{name=name.text, type=nil, value=expr}));
    } else if is_kw(p, .Return) {
        consume_token(p); // "return";
        if is_symbol(current_token(p), ";") {
            consume_token(p); // ";"
            return new_stmt(Stmt(Return{expr=nil}));
        }
        e := parse_expr(p);
        expect_symbol(p, ";");
        return new_stmt(Stmt(Return{expr=e}));
    } else { // otherwise try stmt
        expr := parse_expr(p);
        if is_symbol(current_token(p), "=") {
            consume_token(p); // "="
            v := parse_expr(p);
            expect_symbol(p, ";");
            return new_stmt(Stmt(Assignment{target=expr, value=v}));
        }
        expect_symbol(p, ";");
        return new_stmt(Stmt(ExprId(expr)));
    }
}
is_kw :: proc(p: ^Parser, k: Keyword) -> bool {
    if current_token(p).kind == .Keyword && current_token(p).kw == k do return true
    return false
}

parse_postfix :: proc(p: ^Parser) -> ExprId {
    t := parse_primary(p);
    for {
        if is_symbol(current_token(p), "(") {
            consume_token(p); // "("
                              // "until it meets a ")"
            args := make([dynamic]ExprId, allocator=context.temp_allocator);
            for !is_symbol(current_token(p), ")") {
                e := parse_expr(p);
                if is_symbol(current_token(p), ",") {
                    consume_token(p); // ","
                } else do break
            }
            expect_symbol(p, ")"); // expect ")"
            t = new_expr(FnCall{target=t, args=args});
        } else do break
    }
    return t;
}
parse_primary :: proc(p: ^Parser) -> ExprId {
    if current_token(p).kind == .Ident {
        e :=  Expr(Symbol{consume_token(p).text});
        return new_expr(e)
    } else if current_token(p).kind == .Number {
        return new_expr(Expr(Number{consume_token(p).text}));
    }
    fmt.println(current_token(p));
    panic("invalid primary token")
}
parse_block :: proc(p: ^Parser) -> Block{
    expect_symbol(p, "{");
    stmts := make([dynamic]StmtId, allocator=context.temp_allocator);
    for !(current_token(p).kind == .Symbol && current_token(p).text == "}") &&
        (current_token(p).kind != .EOF) {
        stmt := parse_stmt(p);
        append(&stmts, stmt)
    }
    expect_symbol(p, "}");
    return Block{stmts=stmts[:]}
}
FnDec :: struct {
    name: string,
    ret_ty: Maybe(TypeSpecifier),
    block: Block,
}

Item :: union {
    FnDec,
}

parse_type :: proc(p: ^Parser) -> TypeSpecifier {
    if current_token(p).kind == .Ident {
        return TypeSpecifier(BaseType(consume_token(p).text));
    }
    panic("impl");
}
parse_kw :: proc(p: ^Parser) -> ItemId {
    #partial switch current_token(p).kw {
    case .Fn: {
        f := FnDec{}
        kw := consume_token(p);
        name := expect_ident(p).text;
        f.name = name;
        expect_symbol(p, "(");
        // parse args
        expect_symbol(p, ")");
        if is_symbol(current_token(p), ":") {
            consume_token(p); // ":"
            f.ret_ty = parse_type(p);
        }
        b := parse_block(p);
        f.block = b;

        return new_item(Item(f))
    }
    case: panic("impl");
    }
}
expect_symbol :: proc(p: ^Parser, str: string) -> Token {
    c := current_token(p);
    if c.kind != .Symbol {
        fmt.println("Expected symbol, got:", c);
        panic("");
    }
    if c.text != str {
        fmt.println("Expected", str, "got:", c.text);
        panic("");
    }
    return consume_token(p)
}
expect_ident :: proc(p: ^Parser) -> Token {
    c := current_token(p);
    if c.kind != .Ident {
        fmt.println("Expected ident got:", c);
        panic("");
    }
    return consume_token(p)
}
AST :: struct {
    items: []ItemId,
}
parse_tokens :: proc(tokens: []Token) -> AST {
    _p:= Parser{tokens, 0};
    p := &_p
    items := make([dynamic]ItemId, allocator=context.temp_allocator)
    for current_token(p).kind != .EOF {
        #partial switch current_token(p).kind {
        case .Keyword: {
            append(&items,parse_kw(p));
        }
        case: panic("impl");
        }
    }
    return AST{items=items[:]}
}
