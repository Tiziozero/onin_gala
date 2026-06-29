package main

Span :: struct {
    start, end: int,
}

TokenKind :: enum {
    Ident,
    Symbol,
    Keyword,
    Number,
    EOF,
}
Keyword :: enum {
    Fn,
    Return,
    If, Else,
}

Token :: struct {
    span: Span,
    kind: TokenKind,
    text: string,
    kw: Keyword,
}

is_alpha :: proc(c: byte) -> bool {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

is_alnum :: proc(c: byte) -> bool {
    return is_alpha(c) || is_num(c)
}
is_num :: proc(c: byte) -> bool {
    return c >= '0' && c <= '9'
}

is_space :: proc(c: byte) -> bool {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

lex_file :: proc(buf: []byte) -> [dynamic]Token {
    tokens := make([dynamic]Token, context.temp_allocator)
    i := 0
    for i < len(buf) {
        c := buf[i]
        if is_space(c) {
            i += 1
        } else if is_num(c) {
            start := i
            for (i < len(buf) && is_num(buf[i])) ||
                (i < len(buf) && buf[i] == '.' && is_num(buf[i+1])) {
                i += 1
            }
            ident := cast(string)buf[start:i];
            append(&tokens, Token{
                span = Span{start, i},
                kind = .Number,
                text = ident,
            })
        } else if is_alpha(c) {
            start := i
            for i < len(buf) && is_alnum(buf[i]) {
                i += 1
            }
            ident := cast(string)buf[start:i];
            if ident == "_" {
                panic("invalid ident \"_\".");
            }else if ident == "fn" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Keyword,
                    kw   = .Fn,
                })
            }else if ident == "return" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Keyword,
                    kw   = .Return,
                })
            }else if ident == "if" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Keyword,
                    kw   = .If,
                })
            }else if ident == "else" || ident == "otherwise" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Keyword,
                    kw   = .Else,
                })
            } else {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Ident,
                    text = ident,
                })
            }
        } else {
            if buf[i] == ':' && buf[i+1] == '=' {
                append(&tokens, Token{
                    span = Span{i, i + 2},
                    kind = .Symbol,
                    text = cast(string)buf[i:i+2],
                })
                i += 2;
            } else {
                // symbol / punct — stub
                append(&tokens, Token{
                    span = Span{i, i + 1},
                    kind = .Symbol,
                    text = cast(string)buf[i:i+1],
                })
                i += 1
            }
        }
    }
    append(&tokens, Token{kind=.EOF})
    return tokens
}

