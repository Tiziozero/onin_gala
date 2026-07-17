package main

import "core:strings"
import "core:mem/virtual"
import "core:mem"
import "core:os"
import "core:io"

init_context :: proc() -> ^Context {
    ctx := new(Context)
    ctx.program_name = "main"; // overwrite eventually
    // NOTE: no context.user_ptr assignment here — it wouldn't survive return

    aerr := virtual.arena_init_growing(&ctx.arena)
    assert(aerr == virtual.Allocator_Error.None)
    ctx.allocator = virtual.arena_allocator(&ctx.arena)

    al := ctx.allocator
    ctx.debug = true
    ctx.items = make([dynamic]Item, allocator = al)
    ctx.exprs = make([dynamic]Expr, allocator = al)
    ctx.stmts = make([dynamic]Stmt, allocator = al)
    ctx.objs  = make([dynamic]Object, allocator = al)
    ctx.types = make([dynamic]Type, allocator = al)

    ctx.data  = make([dynamic]string, allocator = al)
    ctx.table = make(map[string]StringId, allocator = al)

    ctx.expr_types   = make(map[ExprId]TypeId, allocator = al)
    ctx.expr_objects = make(map[ExprId]ObjId, allocator = al)
    ctx.item_types   = make(map[ItemId]TypeId, allocator = al)
    ctx.item_objects = make(map[ItemId]ObjId, allocator = al)
    ctx.stmt_objects = make(map[StmtId]ObjId, allocator = al)
    ctx.stmt_types   = make(map[StmtId]TypeId, allocator = al)
    ctx.expr_resolution_types = make(map[ExprId]TypeId, allocator = al)

    ctx.spans.exprs = make(map[ExprId]struct{file_name: string, span: Span}, allocator = al)
    ctx.spans.items = make(map[ItemId]struct{file_name: string, span: Span}, allocator = al)
    ctx.spans.stmts = make(map[StmtId]struct{file_name: string, span: Span}, allocator = al)
    ctx.spans.objs_decs = make(map[ObjId]struct{file_name: string, span: Span}, allocator = al)

    ctx.files = make(map[string]string, allocator = al)
    ctx.o_files = make([dynamic]string, allocator = al)

    ctx.base_mod = new_module_scope(allocator=ctx.allocator)
    return ctx
}

handle_file :: proc(ctx: ^Context, file_name: string) {
    data, err := os.read_entire_file(file_name, ctx.allocator)
    if err != io.Error.None {
        gala_panic("Failed to read file")
    }

    debugln("file size:", len(data));
    get_ctx().files[file_name] = string(data)


    ctx.current_file = file_name;

    tokens := lex_file(data)
    defer delete(tokens)

    ast := parse_tokens(file_name, tokens[:])
    decs := resolve_module_ast(&ast)
    typecheck_module(&ast)
    cg_module(&ast)
    ctx.modules[file_name] = {decs, ast};
}
destroy_context :: proc(ctx: ^Context) {
    virtual.arena_destroy(&ctx.arena)
    free(ctx)
}
main :: proc() { // odins context is passed down, not up, or some shi
    ctx := init_context()
    context.user_ptr = ctx   // <-- set it here, so it's live for the rest of main's scope

    // integer types
    new_type(&ctx.base_mod, Type{name="i8", kind=.Int_8});
    new_type(&ctx.base_mod, Type{name="i16", kind=.Int16});
    new_type(&ctx.base_mod, Type{name="i32", kind=.Int32});
    new_type(&ctx.base_mod, Type{name="i64", kind=.Int64});

    new_type(&ctx.base_mod, Type{name="u8", kind=.UInt_8});
    new_type(&ctx.base_mod, Type{name="u16", kind=.UInt16});
    new_type(&ctx.base_mod, Type{name="u32", kind=.UInt32});
    new_type(&ctx.base_mod, Type{name="u64", kind=.UInt64});

    new_type(&ctx.base_mod, Type{name="f8", kind=.Flt_8});
    new_type(&ctx.base_mod, Type{name="f16", kind=.Flt16});
    new_type(&ctx.base_mod, Type{name="f32", kind=.Flt32});
    new_type(&ctx.base_mod, Type{name="f64", kind=.Flt64});
    new_type(&ctx.base_mod, Type{name="void", kind=.Void});
    new_type(&ctx.base_mod, Type{name="any", kind=.Any});
    new_type(&ctx.base_mod, Type{name="bool", kind=.Bool});
    new_type(&ctx.base_mod, Type{name="byte", kind=.Byte});
    new_type(&ctx.base_mod, Type{name="rawptr", kind=.Pointer, ptr=void_type()});
    new_type(&ctx.base_mod, Type{name="string", kind=.String});

    is_legal_program_name :: proc(n: string) -> bool {
        if len(n) == 0 {
            return false
        }
        for c, i in n {
            switch {
            case c >= 'a' && c <= 'z':
            case c >= 'A' && c <= 'Z':
            case c == '_':
            case c == '-' && i > 0: // allow dash, but not as first char
            case c >= '0' && c <= '9' && i > 0: // digits ok, just not first char
            case:
                return false
            }
        }
        return true
    }

    next_arg :: proc(args: []string) -> ([]string, string, bool) {
        if len(args) > 0 {
            t := args[0]
            return args[1:], t, true
        }
        return args, "", false
    }

    files := make([dynamic]string, ctx.allocator)
    args := os.args[1:] // skip program name itself
    for {
        arg: string
        ok: bool
        args, arg, ok = next_arg(args) // note: `=`, reassigns outer args
        if !ok {
            break
        }
        if arg == "-o" {
            name: string
            name_ok: bool
            args, name, name_ok = next_arg(args)
            if !name_ok {
                gala_panic("expected name after \"-o\".")
            }
            if !is_legal_program_name(name) {
                gala_panic("illegal program name:", name)
            }
            ctx.program_name = name
        } else if strings.has_suffix(arg, ".gala") && len(arg) > 5 { // "not ".gala"
            append(&files, arg)
        }
    }
    if len(files) < 1 {
        gala_panic("Must specify at leas one \".gala\" file.");
    }
    for f in files {
        handle_file(ctx, f);
    }

    {
        // link ld a.o -o a.out
        /* ld \
        /usr/lib/crt1.o \
        /usr/lib/crti.o \
        -lc \
        a.o \
        /usr/lib/crtn.o
        -o name*/
        command := make([dynamic]string, allocator=get_ctx().allocator);
        append(&command, "ld");
        append(&command, "-dynamic-linker");
        append(&command, "/lib64/ld-linux-x86-64.so.2");
        append(&command, "/usr/lib/crt1.o")
        append(&command, "/usr/lib/crti.o")
        append(&command, "-lc")
        append(&command, "-lm")
        append(&command, "-L./lib")
        append(&command, "-lraylib")
        for f in get_ctx().o_files {
            append(&command, f)
        }
        append(&command, "/usr/lib/crtn.o")
        append(&command, "-o")
        append(&command, get_ctx().program_name)

        debug("Link command: ");
        for a in command {
            debugf("%s ", a);
        }
        debugfln("")

        p, err := os.process_start({command=command[:]});
        if err != .NONE {
            gala_panic("Failed to start link (ld) process:", err);
        }
        p_state, werr := os.process_wait(p)
        if werr != .NONE {
            gala_panic("Failed to wait for link (ld) process:", werr);
        }
        if p_state.exit_code != 0 {
            gala_panic("Failed to link machine code. exit code:", p_state.exit_code);
        }
        debugln("clang exit code:", p_state.exit_code);
    }
    destroy_context(ctx);
    free_all(context.temp_allocator);

    gala_info("Finished parsing");
}
