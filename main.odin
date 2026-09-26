package main

import "core:path/filepath"
import "core:strings"
import "core:mem/virtual"
import "core:mem"
import "core:os"
import "core:io"

init_context :: proc(debug := false) -> ^Context {
    ctx := new(Context)
    ctx.program_name = "main"; // overwrite eventually
    // NOTE: no context.user_ptr assignment here — it wouldn't survive return

    aerr := virtual.arena_init_growing(&ctx.arena)
    assert(aerr == virtual.Allocator_Error.None)
    ctx.allocator = virtual.arena_allocator(&ctx.arena)

    al := ctx.allocator
    ctx.debug = debug
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

    data, err := os.read_entire_file(resolved, ctx.allocator)
    if err != io.Error.None {
        gala_panic("Failed to read file:", resolved)
    }

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

    ast := parse_tokens(resolved, tokens[:])
    mid := resolve_module_ast(&ast, resolved)
    typecheck_module(&ast)
    cg_module(mid)
    ctx.modules[resolved] = mid
    delete_key(&ctx.parsing, resolved)

    return resolved
}

destroy_context :: proc(ctx: ^Context) {
    virtual.arena_destroy(&ctx.arena)
    free(ctx)
}

// ---------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------

Cli_Args :: struct {
    entry_file:   string,
    program_name: string,
    debug:        bool,
    extra_libs:   [dynamic]string, // paths passed via -l/--link, e.g. "-l libfoo.so"
}

// Program names are restricted to something `ld -o` and the shell will
// both be happy with: letters, digits (not leading), underscore, and
// dash (not leading).
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

print_usage :: proc() {
    gala_info("usage: galac <file.gala> [-o <name>] [-l <path-to-lib.so>]...")
}

// Parses CLI args in the clang/gcc style: `galac main.gala -o main`.
// Exactly one ".gala" file is allowed (the entry point); anything else
// unrecognized is a hard error rather than being silently ignored.
parse_cli_args :: proc(args: []string) -> Cli_Args {
    result := Cli_Args{program_name = "main", debug = false}
    result.extra_libs = make([dynamic]string)
    entry_file_set := false

    i := 0
    for i < len(args) {
        arg := args[i]

        switch {
        case arg == "-o":
            i += 1
            if i >= len(args) {
                gala_panic("expected program name after \"-o\".")
            }
            name := args[i]
            if !is_legal_program_name(name) {
                gala_panic("illegal program name:", name)
            }
            result.program_name = name

        case arg == "-l" || arg == "--link":
            // Link an extra shared library (.so) at the given path, e.g.
            // "-l ./libfoo.so" or "--link /usr/lib/libbar.so". Passed
            // straight through to `ld` alongside our own .o files.
            i += 1
            if i >= len(args) {
                gala_panic("expected a path to a .so file after \"-l\".")
            }
            lib_path := args[i]
            if !strings.has_suffix(lib_path, ".so") {
                gala_panic("expected a \".so\" file after \"-l\", got:", lib_path)
            }
            if !os.exists(lib_path) {
                gala_panic("cannot find library to link:", lib_path)
            }
            append(&result.extra_libs, lib_path)

        case arg == "-h" || arg == "--help":
            print_usage()
            os.exit(0)

        case arg == "-d" || arg == "--debug":
            result.debug = true
        case strings.has_suffix(arg, ".gala") && len(arg) > len(".gala"): // "not just \".gala\""
            if entry_file_set {
                gala_panic("must specify exactly one \".gala\" file, got an extra one:", arg)
            }
            result.entry_file = arg
            entry_file_set = true

        case:
            gala_panic("unrecognized argument:", arg)
        }

        i += 1
    }

    if !entry_file_set {
        print_usage()
        gala_panic("must specify exactly one \".gala\" file.")
    }

    return result
}

// Links the object files gathered during compilation (ctx.o_files),
// plus any extra shared libraries passed via -l/--link, into a final
// executable at ctx.program_name, shelling out to `ld` the same way
// clang would under the hood.
link_executable :: proc(ctx: ^Context, extra_libs: []string) {
    // link ld a.o -o a.out
    /* ld \
    /usr/lib/crt1.o \
    /usr/lib/crti.o \
    -lc \
    a.o \
    /usr/lib/crtn.o
    -o name*/
    command := make([dynamic]string, allocator = ctx.allocator)
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

    for f in ctx.o_files {
        append(&command, f)
    }

    // Extra shared libraries requested via -l/--link on the CLI.
    for lib in extra_libs {
        append(&command, lib)
    }

    if os.exists("/usr/lib/crtn.o") {
        append(&command, "/usr/lib/crtn.o")
    } else {
        append(&command, "/usr/lib/x86_64-linux-gnu/crtn.o")
    }

    append(&command, "-o")
    append(&command, ctx.program_name)

    debug("Link command: ")
    for a in command {
        debugf("%s ", a)
    }
    debugfln("")

    p, err := os.process_start({command = command[:]})
    if err != .NONE {
        gala_panic("Failed to start link (ld) process:", err)
    }

    p_state, werr := os.process_wait(p)
    if werr != .NONE {
        gala_panic("Failed to wait for link (ld) process:", werr)
    }
    if p_state.exit_code != 0 {
        gala_panic("Failed to link machine code. exit code:", p_state.exit_code)
    }
}

main :: proc() { // odins context is passed down, not up, or some shi
    cli := parse_cli_args(os.args[1:]) // skip program name itself

    ctx := init_context(debug=cli.debug)
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

    ctx.program_name = cli.program_name

    get_ctx().entry_file = cli.entry_file
    handle_file(ctx, cli.entry_file)

    link_executable(ctx, cli.extra_libs[:])

    destroy_context(ctx);
    free_all(context.temp_allocator);
    // gala_info("Finished parsing");
}
