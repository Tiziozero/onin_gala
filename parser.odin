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
Transmute :: struct {
    to: TypeSpecifier,
    target: ExprId,
}
ZeroInit :: struct {}
StructLit :: struct {
    name: string,
    fields: map[string]struct{expr:ExprId,span:Span},
}
Len :: struct { target: ExprId };
Sizeof :: struct { t: TypeSpecifier };
BoolLitTrue :: distinct struct {}
BoolLitFalse :: distinct struct {}
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
    Reference,
    Deref,
    UnNot,
    FixedSizeArray,
    String,
    Len,
    Sizeof,
    ZeroInit,
    BoolLitTrue,
    BoolLitFalse,
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
    initialiser: any,
}
FieldAccess :: struct {
    target: ExprId,
    field: string,
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
// Entry point
parse_condition :: proc(p: ^Parser) -> ExprId {
    prev_ignore_struct_lit := p.ignore_struct_lit
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
                highlight_lines(fname.span)
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
        // eg: "v := [1024]byte{}
        open_b := consume_token(p); // "["
        n := consume_token(p); // number
        if n.kind != .Number {
            highlight_lines(n.span);
            gala_panic("expected number for fixed size array init");
        }
        size, ok := strconv.parse_int(n.text); assert(ok);
        close_b := expect_symbol(p, "]");

        t := parse_type(p);

        // for now, only zero initialiser, so all 0s ("{}")
        expect_symbol(p, "{");
        end := expect_symbol(p, "}");

        id := new_expr(Expr(FixedSizeArray{size=size,ty=t,initialiser=nil}))
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={
                start=open_b.span.start,
                end=end.span.end
            }
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

parse_potential_cast :: proc(p: ^Parser) -> ExprId {
    if current_token(p).kind == .Cast {
        token := consume_token(p); // "cast"
        expect_symbol(p, "(");
        ty := parse_type(p);
        expect_symbol(p, ")");
        expr := parse_potential_cast(p);
        id := new_expr(Expr(Cast{ty, expr}));
        get_ctx().spans.exprs[id] = {
            file_name=get_ctx().current_file,
            span={token.span.start, get_span(expr).span.end},
        }
        return id
    } else if current_token(p).kind == .Transmute {
        token := consume_token(p); // "transmute"
        expect_symbol(p, "(");
        ty := parse_type(p);
        expect_symbol(p, ")");
        expr := parse_potential_cast(p);
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
                start=get_span(prev).span.start,
                end=get_span(rhs).span.end,
            }
        }
    }

    return lhs
}
BaseType :: struct { ident: string, span: Span };
// can't have ptr to itself
PointerType :: struct {ptr:^TypeSpecifier, span: Span };
FixedArreySpecifier :: struct { size: int, base: ^TypeSpecifier, span: Span };
SliceSpecifier :: struct {base : ^TypeSpecifier, span: Span }
AnySpecifier :: struct { span: Span }
TypeSpecifier :: union {
    BaseType,
    PointerType,
    FixedArreySpecifier,
    SliceSpecifier,
    AnySpecifier,
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
    WhileLoop,
}
WhileLoop :: struct { cond: ExprId, block: Block }
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
        s.base_con = parse_expr(p);
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
    } else { // otherwise try stmt
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
            args := make([dynamic]ExprId, allocator=get_ctx().allocator);
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
    // debugln(current_token(p));
    highlight_lines(current_token(p).span);
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

FnDecArg :: struct{name: string, t: TypeSpecifier, span: Span}
FnDecSignature :: struct {
    name: string,
    args: []FnDecArg, 
    ret_ty: Maybe(TypeSpecifier),
    is_variadic: bool,
    variadic_ty: TypeSpecifier,
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

Item :: union {
    StructDec,
    FnDec,
    ExternFnDec,
}

base_span :: proc(t: ^TypeSpecifier) -> Span {
    switch t in t {
    case BaseType: return t.span;
    case PointerType: return t.span;
    case SliceSpecifier: return t.span;
    case FixedArreySpecifier: return t.span;
    case AnySpecifier: return t.span;
    }
    panic("impl")
}
parse_type :: proc(p: ^Parser) -> TypeSpecifier {
    if current_token(p).kind == .Ident {
        token := consume_token(p)
        return TypeSpecifier(BaseType({token.text, token.span}));
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
    panic("impl");
}

parse_fn_signature :: proc(p: ^Parser) -> FnDec {
    kw := consume_token(p); // "fn"
    assert(kw.kind == .Keyword && kw.kw == .Fn);
    f := FnDec{};
    name := expect_ident(p);
    f.name = name.text;
    // args
    args := make([dynamic]FnDecArg)
    expect_symbol(p, "(");
    for !is_symbol(current_token(p), ")") {
        if is_symbol(current_token(p), ".") &&
            is_symbol(next_token(p), ".") {
            token := consume_token(p); // "."
            consume_token(p); // "."
            t := parse_type(p);
            f.is_variadic = true;
            f.variadic_ty = t;
            break;
        }
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
    end := expect_symbol(p, ")");
    f.args = args[:]

    if is_symbol(current_token(p), ":") {
        consume_token(p); // ":"
        f.ret_ty = parse_type(p);
    }
    f.span.start = kw.span.start
    f.span.end = end.span.end
    debugln(f)
    return f;
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
    case: panic("impl");
    }
}
expect_symbol :: proc(p: ^Parser, str: string) -> Token {
    c := current_token(p);
    if c.kind != .Symbol {
        highlight_lines(c.span);
        debugln("Expected symbol, got:", c);
        gala_panic(c);
    }
    if c.text != str {
        highlight_lines(c.span);
        debugln("Expected", str, "got:", c.text);
        gala_panic(c);
    }
    return consume_token(p)
}
expect_ident :: proc(p: ^Parser) -> Token {
    c := current_token(p);
    if c.kind != .Ident {
        debugln("Expected ident got:", c);
        gala_panic("");
    }
    return consume_token(p)
}
AST :: struct {
    items: []ItemId,
}
parse_tokens :: proc(file_name: string, tokens: []Token) -> AST {
    _p:= Parser{file_name, tokens, 0, false};
    p := &_p
    items := make([dynamic]ItemId, allocator=get_ctx().allocator)
    for current_token(p).kind != .EOF {
        #partial switch current_token(p).kind {
        case .Keyword: {
            append(&items,parse_module_kw(p));
        }
        case: panic("impl");
        }
    }
    return AST{items=items[:]}
}
