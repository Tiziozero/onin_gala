package main

import "core:path/filepath"
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
    ctx.parsing = make(map[string]string, allocator = al)
    ctx.o_files = make([dynamic]string, allocator = al)

    ctx.base_mod = new_module_scope(allocator=ctx.allocator)
    ctx.llvm_ty = make(map[TypeId]string, allocator=ctx.allocator);
    ctx.cg_item_names = make(map[ItemId]string, allocator=ctx.allocator);
    ctx.cg_module_prefix =  make(map[ModId]string, allocator=ctx.allocator);

    return ctx
}

// Resolves `import_path` (as written in source) to a canonical absolute
// path, relative to whoever is doing the importing (`importer_path`) rather
// than the process's current working directory. This is what makes
// "src/a.gala" containing `import "../b.gala"` correctly resolve to a path
// next to "src/", instead of relative to wherever the compiler was invoked.
//
// `importer_path` may be "" (no importer yet — i.e. a top-level file passed
// on the command line), in which case resolution falls back to cwd.
resolve_import_path :: proc(importer_path: string, import_path: string) -> string {
    joined: string

    if filepath.is_abs(import_path) {
        joined = import_path
    } else {
        importer_dir := len(importer_path) > 0 ? filepath.dir(importer_path) : "."
        joined, _ = filepath.join({importer_dir, import_path})
    }

    abs_path, abs_ok := filepath.abs(joined)
    if abs_ok != .NONE {
        abs_path = joined
    }

    cleaned, cerr := filepath.clean(abs_path)
    assert(cerr == .None)

    cwd, _ := os.get_working_directory(get_ctx().allocator)

    rel, rerr := filepath.rel(cwd, cleaned)
    if rerr != .None {
        // Can't be made relative (e.g. different drive on Windows) — fall
        // back to the absolute path.
        return cleaned
    }

    return rel
}

// `file_name` is the raw path as written (either a CLI arg or the string
// literal from an `import` statement). It gets resolved relative to
// `ctx.current_file` (the file doing the importing), then that resolved,
// canonical absolute path is used as the key everywhere (ctx.files,
// ctx.parsing, ctx.modules) and is what's now passed to resolve_module_ast.
//
// Returns the resolved path, so callers (e.g. import-handling code in the
// resolver) can use it too — e.g. to record which module an import refers
// to.
handle_file :: proc(ctx: ^Context, file_name: string) -> string {
    resolved := resolve_import_path(ctx.current_file, file_name)

    if _, ok := ctx.parsing[resolved]; ok {
        gala_panicf("Cyclical imports with file: \"%s\".", resolved)
    }
    if _, ok := ctx.modules[resolved]; ok {
        // Already fully parsed/resolved (e.g. two files import the same
        // dependency) — nothing more to do.
        return resolved
    }
    debugln("resolved:", resolved)

    data, err := os.read_entire_file(resolved, ctx.allocator)
    if err != io.Error.None {
        gala_panic("Failed to read file:", resolved)
    }

    debugln("file size:", len(data));
    ctx.files[resolved] = string(data)
    ctx.parsing[resolved] = string(data)

    // Save/restore ctx.current_file around this (possibly nested) call so
    // that once this imported file is fully handled, whoever imported it
    // goes back to resolving *its own* further imports relative to itself,
    // not to whatever file we just finished.
    prev_file := ctx.current_file
    ctx.current_file = resolved
    defer ctx.current_file = prev_file

    tokens := lex_file(data)
    defer delete(tokens)

    debugln("PARSING FILE");
    ast := parse_tokens(resolved, tokens[:])
    debugln("RESOLVINF SYMBOLS");
    mid := resolve_module_ast(&ast, resolved)
    debugln("TYPECHECKING");
    typecheck_module(&ast)
    debugln("CODE GEN");
    cg_module(mid)
    ctx.modules[resolved] = mid
    delete_key(&ctx.parsing, resolved)

    return resolved
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

    entry_file: string
    entry_file_set := false

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
            if entry_file_set {
                gala_panic("Must specify exactly one \".gala\" file, got an extra one:", arg);
            }
            entry_file = arg
            entry_file_set = true
        }
    }
    if !entry_file_set {
        gala_panic("Must specify exactly one \".gala\" file.");
    }

    get_ctx().entry_file = entry_file
    handle_file(ctx, entry_file);
    {
        // link ld a.o -o a.out
        /* ld \
        /usr/lib/crt1.o \
        /usr/lib/crti.o \
        -lc \
        a.o \
        /usr/lib/crtn.o
        -o name*/
        command := make([dynamic]string, allocator=get_ctx().allocator)
        append(&command, "ld")
        append(&command, "-dynamic-linker")
        append(&command, "/lib64/ld-linux-x86-64.so.2")
        if os.exists("/usr/lib/crt1.o") {
            // Arch and similar
            append(&command, "/usr/lib/crt1.o")
            append(&command, "/usr/lib/crti.o")
            append(&command, "-L/usr/lib")
        } else {
            // Ubuntu/Debian
            append(&command, "/usr/lib/x86_64-linux-gnu/crt1.o")
            append(&command, "/usr/lib/x86_64-linux-gnu/crti.o")
            append(&command, "-L/usr/lib/x86_64-linux-gnu")
        }

        append(&command, "-lc")
        append(&command, "-lm")

        for f in get_ctx().o_files {
            append(&command, f)
        }

        if os.exists("/usr/lib/crtn.o") {
            append(&command, "/usr/lib/crtn.o")
        } else {
            append(&command, "/usr/lib/x86_64-linux-gnu/crtn.o")
        }

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
        if p_state.exit_code != 0 {
            gala_panic("clang exit code:", p_state.exit_code);
        }
    }
    destroy_context(ctx);
    free_all(context.temp_allocator);

    gala_info("Finished parsing");
}
