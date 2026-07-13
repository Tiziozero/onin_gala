package main

import "core:strings"

Span :: struct {
    start, end: int,
}

TokenKind :: enum {
    Ident,
    Symbol,
    Number,
    String,
    Transmute,
    Keyword,
    Cast,
    EOF,
}
Keyword :: enum {
    Invalid,
    Fn,
    Return,
    If, Else,
    Extern,
    Struct,
}

Token :: struct {
    span: Span,
    kind: TokenKind,
    text: string,
    sid: StringId,
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

hex_digit_val :: proc(c: byte) -> int {
    switch {
    case c >= '0' && c <= '9': return int(c - '0')
    case c >= 'a' && c <= 'f': return int(c - 'a' + 10)
    case c >= 'A' && c <= 'F': return int(c - 'A' + 10)
    case: return -1
    }
}
lex_file :: proc(buf: []byte) -> [dynamic]Token {
    tokens := make([dynamic]Token, get_ctx().allocator)
    i := 0
    for i < len(buf) {
        c := buf[i]
        if is_space(c) {
            i += 1
            } else if c == '/' && i + 1 < len(buf) && buf[i+1] == '/' {
            // line comment: skip to end of line
            i += 2
            for i < len(buf) && buf[i] != '\n' {
                i += 1
            }
        } else if c == '/' && i + 1 < len(buf) && buf[i+1] == '*' {
            // block comment: skip to closing */
            start := i
            i += 2
            for i + 1 < len(buf) && !(buf[i] == '*' && buf[i+1] == '/') {
                i += 1
            }
            if i + 1 < len(buf) {
                i += 2 // consume the closing */
            } else {
                gala_panic("unterminated block comment")
                // i = len(buf)
            }
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
                gala_panic("invalid ident \"_\".");
            }else if ident == "fn" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Keyword,
                    kw   = .Fn,
                })
            }else if ident == "struct" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Keyword,
                    kw   = .Struct,
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
            }else if ident == "extern" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Keyword,
                    kw   = .Extern,
                })
            }else if ident == "cast" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Cast,
                    kw   = .Invalid,
                })
            }else if ident == "transmute" {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Transmute,
                    kw   = .Invalid,
                })
            } else {
                append(&tokens, Token{
                    span = Span{start, i},
                    kind = .Ident,
                    text = ident,
                })
            }
            } else if c == '"' {
            start := i
            i += 1 // consume opening quote

            out := make([dynamic]byte, get_ctx().allocator)

            for i < len(buf) && buf[i] != '"' {
                ch := buf[i]

                if ch == '\n' {
                    gala_panic("unterminated string literal (hit newline)")
                }

                if ch == '\\' {
                    if i + 1 >= len(buf) {
                        gala_panic("unterminated escape sequence")
                    }
                    esc := buf[i+1]
                    switch esc {
                    case 'n':
                        append(&out, byte('\n'))
                        i += 2
                    case 't':
                        append(&out, byte('\t'))
                        i += 2
                    case 'r':
                        append(&out, byte('\r'))
                        i += 2
                    case '\\':
                        append(&out, byte('\\'))
                        i += 2
                    case '"':
                        append(&out, byte('"'))
                        i += 2
                    case '0':
                        append(&out, byte(0))
                        i += 2
                    case 'x':
                        // \xNN — exactly two hex digits
                        if i + 3 >= len(buf) {
                            gala_panic("truncated \\x escape sequence")
                        }
                        hi := hex_digit_val(buf[i+2])
                        lo := hex_digit_val(buf[i+3])
                        if hi < 0 || lo < 0 {
                            gala_panic("invalid hex digits in \\x escape")
                        }
                        append(&out, byte(hi * 16 + lo))
                        i += 4
                    case:
                        gala_panic("unknown escape sequence")
                    }
                } else {
                    append(&out, ch)
                    i += 1
                }
            }

            if i >= len(buf) {
                gala_panic("unterminated string literal (hit EOF)")
            } else {
                i += 1 // consume closing quote
            }

            sid := intern_string(cast(string)out[:])
            append(&tokens, Token{
                span = Span{start, i},
                kind = .String,
                sid = sid,
                text = get_ctx().data[sid], // or store the StringId itself on the token
            })
        } else {
            if  buf[i] == ':' && buf[i+1] == '=' ||
                buf[i] == '<' && buf[i+1] == '=' ||
                buf[i] == '>' && buf[i+1] == '=' ||
                buf[i] == '!' && buf[i+1] == '=' ||
                buf[i] == '=' && buf[i+1] == '=' {
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

StringId :: distinct int


intern_string :: proc(s: string) -> StringId {
    if id, ok := get_ctx().table[s]; ok {
        return id
    }
    id := StringId(len(get_ctx().data))
    // NB: `s` must be a stable/owned copy, not a view into a
    // temporary buffer that gets reused/freed later
    owned := strings.clone(s, get_ctx().allocator)
    append(&get_ctx().data, owned)
    get_ctx().table[owned] = id
    return id
}
