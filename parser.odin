package main

import "core:strconv"

BinopKind :: enum {
    Addition,
    Subtraction,
    Multiply,
    Divide,
    Equal,
    NotEqual,
    LessEqual,
    GreaterEqual,
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
ZeroInit :: struct {}
Expr :: union {
    Binop,
    Number,
    Symbol,
    FnCall,
    Cast,
    ZeroInit,
}
FnCall :: struct {
    target: ExprId,
    args: [dynamic]ExprId,
}

op_kind :: proc(t: Token) -> (kind: BinopKind, ok: bool) {
    switch t.text {
    case "+":  return .Addition,     true
    case "-":  return .Subtraction,  true
    case "*":  return .Multiply,     true
    case "/":  return .Divide,       true
    case "==": return .Equal,        true
    case "!=": return .NotEqual,     true
    case "<=": return .LessEqual,    true
    case ">=": return .GreaterEqual, true
    }
    return {}, false
}

// Standard precedence: comparisons bind looser than + -, which bind looser than * /
op_precedence :: proc(t: Token) -> int {
    switch t.text {
    case "==", "!=", "<=", ">=":
        return 1
    case "+", "-":
        return 2
    case "*", "/":
        return 3
    }
    return -1 // not a binop -> stops parse_binop loop
}

op_is_right_assoc :: proc(t: Token) -> bool {
    return false // extend for ** etc.
}
// Entry point — replaces your old parse_binop
parse_expr :: proc(p: ^Parser) -> ExprId {
    if is_symbol(current_token(p), "{") {
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
        return id;

    }
    return parse_binop(p, 0)
}

parse_potential_cast :: proc(p: ^Parser) -> ExprId {
    if current_token(p).kind == .Cast {
        token := consume_token(p); // "cast"
        expect_symbol(p, "(");
        ty := parse_type(p);
        expect_symbol(p, ")");
        expr := parse_postfix(p);
        id := new_expr(Expr(Cast{ty, expr}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span=token.span,
        }
        return id
    }
    return parse_postfix(p);
}
parse_binop :: proc(p: ^Parser, min_prec: int) -> ExprId {
    lhs := parse_potential_cast(p)

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
                start=get_ctx().spans.exprs[prev].span.start,
                end=get_ctx().spans.exprs[rhs].span.end,
            }
        }
    }

    return lhs
}
BaseType :: struct { ident: string, span: Span};
// can't have ptr to itself
PointerType :: struct {ptr:^TypeSpecifier, span: Span};;
FixedArray :: struct { size: int, base: ^TypeSpecifier, span: Span};
TypeSpecifier :: union {
    BaseType,
    PointerType,
    FixedArray,
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
    ExprId,
    IfElse,
}
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
        id := new_stmt(Stmt(VarDec{name=name.text, type=nil, value=expr}));
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=name.span,
        }
        return id
    } else if current_token(p).kind == .Ident &&
        is_symbol(next_token(p), ":") {
        name := consume_token(p);
        consume_token(p); // ":"
        ty := parse_type(p);
        expect_symbol(p, "=");
        expr := parse_expr(p);
        id := new_stmt(Stmt(VarDec{name=name.text, type=ty, value=expr}));
        get_ctx().spans.stmts[id] = {
            file_name=get_ctx().current_file,
            span=name.span,
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
        s.base_con = parse_expr(p);
        s.base_block = parse_block(p);
        alts := make([dynamic]AltCon, allocator=context.temp_allocator);
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
    } else { // otherwise try stmt
        expr := parse_expr(p);
        if is_symbol(current_token(p), "=") {
            token := consume_token(p); // "="
            v := parse_expr(p);
            expect_symbol(p, ";");
            id := new_stmt(Stmt(Assignment{target=expr, value=v}));
            get_ctx().spans.stmts[id] = {
                file_name=get_ctx().current_file,
                span={
                    start=get_ctx().spans.exprs[expr].span.start,
                    end=token.span.end
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

parse_postfix :: proc(p: ^Parser) -> ExprId {
    t := parse_primary(p);
    for {
        if is_symbol(current_token(p), "(") {
            start := consume_token(p); // "("
            args := make([dynamic]ExprId, allocator=context.temp_allocator);
            // "until it meets a ")"
            for !is_symbol(current_token(p), ")") {
                e := parse_expr(p);
                append(&args, e)
                if is_symbol(current_token(p), ",") {
                    consume_token(p); // ","
                } else do break
            }
            end := expect_symbol(p, ")"); // expect ")"

            id := new_expr(FnCall{target=t, args=args});
            get_ctx().spans.exprs[id] = {
                file_name=get_ctx().current_file,
                span={start=start.span.start,end=end.span.end}
            }
            t = id
        } else do break
    }
    return t;
}
parse_primary :: proc(p: ^Parser) -> ExprId {
    if current_token(p).kind == .Ident {
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
    }
    debugln(current_token(p));
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

FnDecArg :: struct{name: string, t: TypeSpecifier, span: Span}
FnDec :: struct {
    name: string,
    args: [dynamic]FnDecArg, 
    ret_ty: Maybe(TypeSpecifier),
    block: Block,
}
ExternFnDec :: struct {
    name: string,
    args: [dynamic]FnDecArg, 
    ret_ty: Maybe(TypeSpecifier),
}

Item :: union {
    FnDec,
    ExternFnDec,
}

parse_type :: proc(p: ^Parser) -> TypeSpecifier {
    if current_token(p).kind == .Ident {
        token := consume_token(p)
        return TypeSpecifier(BaseType({token.text, token.span}));
    }
    if is_symbol(current_token(p), "[") {
        token := consume_token(p); // "["
        n := consume_token(p);
        assert(n.kind == .Number);
        size, ok := strconv.parse_int(n.text)
        assert(ok);
        end := expect_symbol(p, "]");

        base_specifier := new(TypeSpecifier, allocator=context.temp_allocator);
        base_specifier^ = parse_type(p);

        return TypeSpecifier(FixedArray{
            size=size,base=base_specifier,
            span={
                start=token.span.start,
                end=end.span.end
            }
        })
    }
    panic("impl");
}
parse_kw :: proc(p: ^Parser) -> ItemId {
    #partial switch current_token(p).kw {
    case .Fn: {
        f := FnDec{}
        kw := consume_token(p);
        name := expect_ident(p);
        f.name = name.text;
        // args
        args := make([dynamic]FnDecArg)
        expect_symbol(p, "(");
        for !is_symbol(current_token(p), ")") {
            name := expect_ident(p);
            expect_symbol(p, ":")
            ty := parse_type(p);
            append(&args, FnDecArg{name=name.text, t=ty, span=name.span})
            if is_symbol(current_token(p), ",") {
                consume_token(p);
            } else {
                break;
            }
        }
        expect_symbol(p, ")");
        f.args = args

        if is_symbol(current_token(p), ":") {
            consume_token(p); // ":"
            f.ret_ty = parse_type(p);
        }
        b := parse_block(p);
        f.block = b;

        id := new_item(Item(f))
        get_ctx().spans.items[id] = {
            file_name=get_ctx().current_file,
            span=name.span
        }

        return id
    }
    case .Extern: {
        token := consume_token(p); // "extern"
        kw := consume_token(p); // "extern"
        assert(kw.kind == .Keyword && kw.kw == .Fn);
        f := ExternFnDec{};
        name := expect_ident(p);
        f.name = name.text;
        // args
        args := make([dynamic]FnDecArg)
        expect_symbol(p, "(");
        for !is_symbol(current_token(p), ")") {
            name := expect_ident(p);
            expect_symbol(p, ":")
            ty := parse_type(p);
            append(&args, FnDecArg{name=name.text, t=ty, span=name.span})
            if is_symbol(current_token(p), ",") {
                consume_token(p);
            } else {
                break;
            }
        }
        expect_symbol(p, ")");
        f.args = args

        if is_symbol(current_token(p), ":") {
            consume_token(p); // ":"
            f.ret_ty = parse_type(p);
        }
        expect_symbol(p, ";");

        id := new_item(Item(f))
        get_ctx().spans.items[id] = {
            file_name=get_ctx().current_file,
            span=name.span
        }
        return id;
    }
    case: panic("impl");
    }
}
expect_symbol :: proc(p: ^Parser, str: string) -> Token {
    c := current_token(p);
    if c.kind != .Symbol {
        debugln("Expected symbol, got:", c);
        panic("");
    }
    if c.text != str {
        debugln("Expected", str, "got:", c.text);
        panic("");
    }
    return consume_token(p)
}
expect_ident :: proc(p: ^Parser) -> Token {
    c := current_token(p);
    if c.kind != .Ident {
        debugln("Expected ident got:", c);
        panic("");
    }
    return consume_token(p)
}
AST :: struct {
    items: []ItemId,
}
parse_tokens :: proc(file_name: string, tokens: []Token) -> AST {
    _p:= Parser{file_name, tokens, 0};
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
