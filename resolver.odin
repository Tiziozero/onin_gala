package main

import "core:fmt"
import "core:strings"
Field :: struct {
    name: string,
    type: TypeId,
    span: Span,
}
// `default` is the (already resolved) call to the hidden default function a
// call falls back to when it omits this argument.
//
// For `name := expr` parameters `inferred` is set: `type` is a placeholder
// (void) until tc_default_args infers it from `default_src` (the written
// expression), and `obj` is the parameter's object so its type can be patched
// too.
Arg :: struct {
    name: string,
    type: TypeId,
    span: Span,
    is_variadic: bool,
    default: Maybe(ExprId),
    inferred: bool,
    default_src: Maybe(ExprId),
    obj: ObjId,
}
ObjectKind :: enum {
    Invalid,
    Variable,
    Argument,
}
Object :: struct {
    kind: ObjectKind,
    name: string,
    type: Maybe(TypeId),
}
// set this here cus it's needed for scopes to access
Scope :: struct {
    objects:        map[string]ObjId,
    types:          map[string]TypeId,
    obj_foreward:   map[string]ObjId,
    ty_foreward:    map[string]TypeId,
    parent:         ^Scope,
}
ModuleScope :: struct {
    using scope: Scope,
    obj_exports:   map[string]ObjId,
    ty_exports:    map[string]TypeId,
}
name_exists :: proc(scope: ^Scope, n: string, error := false) -> bool {
    s := scope
    for s != nil {
        tid, ok := s.types[n];
        if ok {
            if error { fmt.println("First declared here:"); highlight_lines(get_span(tid)); }
            return true
        }

        oid, ok1  := s.objects[n];
        if ok1 {
            if error { fmt.println("First declared here:"); highlight_lines(get_span(oid)); }
            return true
        }

        ftid, ok2  := s.ty_foreward[n];
        if ok2 {
            if error { fmt.println("First declared here:"); highlight_lines(get_span(ftid)); }
            return true
        }

        foid, ok3  := s.obj_foreward[n];
        if ok3 {
            if error { fmt.println("First declared here:"); highlight_lines(get_span(foid)); }
            return true
        }

        s = s.parent
    }
    return false
}
new_object :: proc(s: ^Scope, o: Object, span: SpanStruct) -> ObjId {
    ctx := get_ctx()
    assert(o.kind != .Invalid);
    assert(len(o.name) > 0);

    // make sure they're not already declared
    if name_exists(s, o.name, true) {
        highlight_lines(span)
        gala_panicf("object %s already exists.", o.name);
    }

    append(&ctx.objs, o);
    id := ObjId(len(ctx.objs)-1);
    s.objects[o.name] = id
    ctx.obj_modules[id] = get_ctx().current_module_id;
    ctx.spans.objs_decs[id] = span
    return id
}

new_type :: proc(s: ^Scope, t: Type, span: SpanStruct) -> TypeId {
    ctx := get_ctx();
    assert(t.kind != .Invalid);
    assert(len(t.name) > 0);

    // make sure it doesn't exist
    if name_exists(s, t.name, true) {
        highlight_lines(span);
        gala_panicf("Name \"%s\" already declared.", t.name);
    }

    append(&ctx.types, t);
    id := TypeId(len(ctx.types)-1);  // allocate type
    s.types[t.name] = id
    ctx.ty_modules[id] = ctx.current_module_id;
    ctx.spans.ty_decs[id] = span
    return id
}
new_object_fd :: proc(s: ^ModuleScope, o: Object, span: SpanStruct) -> ObjId {
    ctx := get_ctx()
    assert(o.kind != .Invalid);
    assert(len(o.name) > 0);

    // make sure it doesn't exist
    if name_exists(s, o.name, true) {
        highlight_lines(span);
        gala_panicf("Name \"%s\" already declared in object fd.", o.name);
    }

    append(&ctx.objs, o);
    id := ObjId(len(ctx.objs)-1);
    s.obj_foreward[o.name] = id
    ctx.obj_modules[id] = ctx.current_module_id;
    ctx.spans.objs_decs[id] = span
    return id
}
new_type_fd :: proc(s: ^ModuleScope, t: Type, span: SpanStruct) -> TypeId {
    ctx := get_ctx()
    assert(t.kind != .Invalid);
    assert(len(t.name) > 0);

    // make sure it doesn't exist
    if name_exists(s, t.name, true) {
        highlight_lines(span);
        gala_panicf("Name \"%s\" already declared.", t.name);
    }

    append(&ctx.types, t);
    id := TypeId(len(ctx.types)-1); 
    s.ty_foreward[t.name] = id
    ctx.ty_modules[id] = ctx.current_module_id;
    ctx.spans.ty_decs[id] = span
    return id
}
// Function literals don't capture: their body is resolved against the module
// scope, not the enclosing block scopes, so referring to a local/arg of the
// surrounding function is a resolve error instead of silently producing an
// invalid reference in codegen.
//
// Module scopes are the only scopes that have their forward maps allocated
// (see new_module_scope), which is how we find one from any nested scope.
enclosing_module_scope :: proc(s: ^Scope) -> ^Scope {
    sc := s
    for sc != nil && sc.obj_foreward == nil {
        sc = sc.parent
    }
    if sc == nil do return s // shouldn't happen, fall back to the given scope
    return sc
}
// `Box(i32)` where an expression is parsed is a call to `Box`. When the callee
// names a generic struct, turn it back into a type specifier. Only works for
// args that are plain names or the same shape again; anything with `^`/`[]`
// was already parsed as a type.
expr_as_type_spec :: proc(id: ExprId) -> (TypeSpecifier, bool) {
    #partial switch e in get_expr(id) {
    case Symbol:
        return TypeSpecifier(BaseType{e.name, get_span(id).span}), true
    case FnCall:
        sym, is_sym := get_expr(e.target).(Symbol)
        if !is_sym do return {}, false
        args := make([dynamic]TypeSpecifier, allocator=get_ctx().allocator)
        for a in e.args {
            if len(a.name) > 0 do return {}, false
            spec, ok := expr_as_type_spec(a.expr)
            if !ok do return {}, false
            append(&args, spec)
        }
        return TypeSpecifier(GenericInstSpecifier{name=sym.name, args=args, span=get_span(id).span}), true
    }
    return {}, false
}
resolve_expr :: proc(s: ^Scope, id: ExprId) {
    switch e in get(id) {
    case TypeIdOf: {
        // written with type-only syntax (`^T`, `[]T`, `fn(..)`)
        if spec, is_ty := e.t.(TypeSpecifier); is_ty {
            get_ctx().expr_resolution_types[id] = resolve_type_specifier(s, spec)
            return
        }

        inner := e.expr.(ExprId)

        // a bare name is a type if one is in scope, otherwise a variable
        // (no shadowing, so a name can't be both)
        node := get_expr(id).(TypeIdOf)
        node.names_type = false
        if sym, is_sym := get_expr(inner).(Symbol); is_sym {
            if tid, is_ty := scope_find_type(s, sym.name); is_ty {
                // `type_id(Box)`: a generic struct is only a type once it has arguments
                if bt := get_type(tid); bt.kind == .Struct && bt.structure.is_generic {
                    highlight_lines(get_span(id))
                    gala_panicf("Generic struct \"%s\" needs type arguments, e.g. %s(i64).",
                        sym.name, sym.name)
                }
                node.names_type = true
                get_ctx().expr_resolution_types[id] = tid
            }
        }
        get_expr(id)^ = node

        // a type name has nothing to resolve; anything else is a real expression
        if !node.names_type do resolve_expr(s, inner)
    }
    case UnNegative: {
        resolve_expr(s, e.expr);
    }
    case UnNot: {
        resolve_expr(s, e.expr);
    }
    case BoolLitTrue: {
    }
    case BoolLitFalse: {
    }
    case Len: {
        resolve_expr(s, e.target);
    }
    case SizeOf: {
        // written with type-only syntax (`^T`, `[]T`, `fn(..)`)
        if spec, is_ty := e.t.(TypeSpecifier); is_ty {
            get_ctx().expr_resolution_types[id] = resolve_type_specifier(s, spec)
            return
        }

        inner := e.expr.(ExprId)
        node := get_expr(id).(SizeOf)
        node.names_type = false

        // `sizeof(Box(i32))` parses as a call; if the callee is a generic struct it's a type
        if call, is_call := get_expr(inner).(FnCall); is_call {
            if sym, is_sym := get_expr(call.target).(Symbol); is_sym {
                if tid, is_ty := scope_find_type(s, sym.name); is_ty &&
                   get_type(tid).kind == .Struct && get_type(tid).structure.is_generic {
                    if spec, ok := expr_as_type_spec(inner); ok {
                        node.t = spec
                        get_expr(id)^ = node
                        get_ctx().expr_resolution_types[id] = resolve_type_specifier(s, spec)
                        return
                    }
                }
            }
        }

        // a bare name is a type if one is in scope, otherwise a variable
        // (no shadowing, so a name can't be both)
        if sym, is_sym := get_expr(inner).(Symbol); is_sym {
            if tid, is_ty := scope_find_type(s, sym.name); is_ty {
                if bt := get_type(tid); bt.kind == .Struct && bt.structure.is_generic {
                    highlight_lines(get_span(id))
                    gala_panicf("Generic struct \"%s\" needs type arguments, e.g. %s(i64).",
                        sym.name, sym.name)
                }
                node.names_type = true
                get_ctx().expr_resolution_types[id] = tid
            }
        }
        get_expr(id)^ = node

        if !node.names_type do resolve_expr(s, inner)
    }
    case String: // ok
    case Deref: {
        resolve_expr(s, e.expr);
    }
    case Reference: {
        resolve_expr(s, e.expr);
    }
    case TakeSlice: {
        resolve_expr(s, e.target);
        if !e.empty_start do resolve_expr(s, e.start);
        if !e.empty_end do   resolve_expr(s, e.end);
    }
    case Index: {
        resolve_expr(s, e.target);
        resolve_expr(s, e.index);
    }
    case FixedSizeArray: {
        // `[MAX_COUNT]byte{}`: fold the constant size into `size`
        if se, has_size_expr := e.size_expr.(ExprId); has_size_expr {
            node := get_expr(id).(FixedSizeArray)
            node.size = const_array_size(s, se)
            node.size_expr = nil
            if len(node.initialiser) > node.size {
                highlight_lines(get_span(id))
                gala_panic("too many elements in array initialiser")
            }
            get_expr(id)^ = node
        }
        // CHANGED: resolve the initialiser elements too
        t := resolve_type_specifier(s, e.ty);
           get_ctx().expr_resolution_types[id] = t;
           for el in e.initialiser {
               resolve_expr(s, el);
           }
       }
    case FieldAccess: {
        // check field in type checking
        resolve_expr(s, e.target);
    }
    case StructLit: {
        resolve_struct_lit(s, id)
    }
    case ZeroInit: {
    }
    case Transmute: {
        ty := resolve_type_specifier(s, e.to);
        resolve_expr(s, e.target);
        // store in context. why not atp
        get_ctx().expr_resolution_types[id] = ty;
    }
    case Cast: {
        ty := resolve_type_specifier(s, e.to);
        resolve_expr(s, e.target);
        // store in context. why not atp
        get_ctx().expr_resolution_types[id] = ty;
    }
    case Binop: {
        resolve_expr(s, e.left);
        resolve_expr(s, e.right);
    }
    case Number: {
    } // nothing
    case Symbol: {
        obj, ok := scope_get_object(s, e.name);
        if !ok {
            highlight_lines(get_span(id));
            gala_panic("Couldn't find", e.name, "in scope.");
        }
        // `name :: value`: this use becomes the value itself
        if is_const_obj(obj) {
            inline_constant(id, obj)
            return
        }
        get_ctx().expr_objects[id] = obj
    }
    case FnCall: {
        resolve_expr(s, e.target);
        for a in e.args {
            resolve_expr(s, a.expr);
        }
    }
    case FnLit: {
        // same steps as resolve_fn_dec_item, minus the forward-declared object:
        // build the fn type from the signature, resolve the body in the
        // signature's scope, and stash the type for the type checker.
        fnty, fnscope := resolve_fn_dec_signature(enclosing_module_scope(s), e.signature)
        if fnty.fn.is_generic {
            free_scope(&fnscope)
            highlight_lines(get_span(id))
            gala_panic("Function literals can't be generic.")
        }

        body := e.block
        resolve_block(&fnscope, &body)
        free_scope(&fnscope)

        // not interned: function types are nominal (see new_fn_type)
        get_ctx().expr_resolution_types[id] = new_fn_type(fnty)
    }

    case: panic("impl");
    }
}
resolve_struct_lit :: proc(s: ^Scope, id: ExprId) {
    e := get_expr(id).(StructLit)

    // `Foo`, `Foo(i64)`, or a generic struct named without arguments (`Box{..}`):
    // the latter keeps the template's id, the type checker infers the instance.
    tid: TypeId
    inferred := false
    if bt, is_base := e.ty.(BaseType); is_base {
        if tmpl, found := scope_find_type(s, string(bt.ident)); found {
            tt := get_type(tmpl)
            if tt.kind == .Struct && tt.structure.is_generic {
                tid = tmpl
                inferred = true
            }
        }
    }
    if !inferred do tid = resolve_type_specifier(s, e.ty)

    ty := get_type(tid)
    if ty.kind != .Struct {
        highlight_lines(get_ctx().current_file, get_span(id).span)
        gala_panicf("\"%s\" is not a struct type.", e.name)
    }
    sfields := ty.structure.fields

    // `Foo{1, 2}`: assign the values to the struct's fields in declaration
    // order, so everything after this sees an ordinary named literal.
    if len(e.positional) > 0 {
        if len(e.positional) != len(sfields) {
            highlight_lines(get_ctx().current_file, get_span(id).span)
            gala_panicf("Type %s has %d fields, but the literal has %d values.",
                e.name, len(sfields), len(e.positional));
        }
        // the parser may not have allocated the map for a purely positional literal
        if e.fields == nil {
            e.fields = make(type_of(e.fields), allocator=get_ctx().allocator)
        }
        for sf, i in sfields {
            e.fields[sf.name] = e.positional[i]
        }
    }

    if len(sfields) != len(e.fields) {
        highlight_lines(get_ctx().current_file, get_span(id).span)
        gala_panicf("Type %s has %d fields, but the literal sets %d.",
            e.name, len(sfields), len(e.fields));
    }

    for name, f in e.fields {
        found := false
        for k in sfields {
            if k.name == name do found = true
        }
        if !found {
            highlight_lines(get_ctx().current_file, f.span)
            gala_panicf("Field %s doesn't exist in type %s.",
                name, e.name);
        }
        resolve_expr(s, f.expr);
    }
    get_ctx().expr_resolution_types[id]=tid
    get_expr(id)^ = e
}
// always allocates a new TypeId, never dedupes — function types are nominal,
// not structural (distinct decls with identical signatures must stay distinct)
new_fn_type :: proc(t: Type) -> TypeId {
    assert(t.kind == .Function)
    append(&get_ctx().types, t);
    return TypeId(len(get_ctx().types)-1)
}
// only interns pointers, slices, fixed arrays, strings, any and the untyped
// kinds; structs and functions are nominal and never go through here
intern_type :: proc(t: Type) -> TypeId {
    assert(t.kind == .Pointer || 
            t.kind == .UntypedInteger || t.kind == .UntypedFloat || 
            t.kind == .FixedSizeArray || t.kind == .ZeroInit ||
            t.kind == .Slice || t.kind == .String || t.kind == .Any)
    for ty, id in get_ctx().types {
        if type_equal(ty, t) { return TypeId(id) }
    }
    append(&get_ctx().types, t);
    return TypeId(len(get_ctx().types)-1)
}
scope_get_object :: proc(s: ^Scope, n: string) -> (ObjId, bool) {
    scope := s
    for scope != nil {
        id, ok := scope.objects[n];
        if ok { return id, true }
        // check fds too
        id, ok = scope.obj_foreward[n];
        if ok { return id, true }
        scope = scope.parent
    }
    return 0, false
}
// silent lookup: a miss is a normal answer here (see TypeIdOf)
scope_find_type :: proc(s: ^Scope, n: string) -> (TypeId, bool) {
    scope := s
    for scope != nil {
        id, ok := scope.types[n];
        if ok { return id, true }
        // check fds too
        id, ok = scope.ty_foreward[n];
        if ok { return id, true }
        scope = scope.parent
    }
    return 0, false
}
scope_get_type :: proc(s: ^Scope, n: string) -> (TypeId, bool) {
    id, ok := scope_find_type(s, n)
    if !ok do debugln(n, "Not found")
    return id, ok
}
new_generic_ty :: proc(s: ^Scope, t: TypeSpecifier) -> TypeId {
    type := Type{
        kind=.Generic /* should never be processed, really. */,
        name=t.(GenericSpecifier).name,
    };
    return new_type(s, type, {get_ctx().current_file, t.(GenericSpecifier).span});
}
resolve_type_specifier :: proc(s: ^Scope, t: TypeSpecifier, no_declare_generic := false,
        bindings: map[string]TypeId = nil) -> TypeId {
    switch k in t {
    case GenericSpecifier: {
        // instantiating a clone: declare the name as the concrete type
        if bindings != nil {
            if existing, ok := s.types[k.name]; ok do return existing
            tid, ok := bindings[k.name]
            if !ok {
                highlight_lines({get_ctx().current_file, k.span})
                gala_panicf("No binding for generic \"%s\".", k.name)
            }
            s.types[k.name] = tid
            return tid
        }
        if name_exists(s, k.name) {
            highlight_lines({get_ctx().current_file, k.span})
            gala_panicf("Name \"%s\" already declared.", k.name);
        }
        if no_declare_generic {
            highlight_lines({get_ctx().current_file, k.span})
            gala_panicf("Can't specify generic in return type.");
        }
        return new_generic_ty(s, t)
    }
    case AnySpecifier: {
        return intern_type({kind=.Any})
    }
    case SliceSpecifier: {
        // no_declare_generic must reach the element type: `fn f(): []$T` is as
        // wrong as `fn f(): $T`
        base := resolve_type_specifier(s, k.base^, no_declare_generic, bindings)
        return intern_type({kind=.Slice, slice={type=base}})
    }
    case BaseType: { // will get declared type id
        ty, ok := scope_get_type(s, string(k.ident));
        if !ok {
            lines := get_file_lines(get_ctx().current_file, k.span);
            print_lines(lines, k.span)
            gala_panic("type doesn't exist");
        }
        assert(ok)
        if bt := get_type(ty); bt.kind == .Struct && bt.structure.is_generic {
            highlight_lines({get_ctx().current_file, k.span})
            gala_panicf("Generic struct \"%s\" needs type arguments, e.g. %s(i64).",
                k.ident, k.ident)
        }
        return ty
    }
    case GenericInstSpecifier: { // Name(args)
        tmpl_id, ok := scope_get_type(s, k.name)
        if !ok {
            highlight_lines({get_ctx().current_file, k.span})
            gala_panic("type doesn't exist")
        }
        tmpl := get_type(tmpl_id)
        if tmpl.kind != .Struct || !tmpl.structure.is_generic {
            highlight_lines({get_ctx().current_file, k.span})
            gala_panicf("\"%s\" is not a generic struct.", k.name)
        }
        if len(k.args) != len(tmpl.structure.generic_names) {
            highlight_lines({get_ctx().current_file, k.span})
            gala_panicf("\"%s\" takes %d type argument(s), got %d.",
                k.name, len(tmpl.structure.generic_names), len(k.args))
        }
        args := make([]TypeId, len(k.args), allocator=get_ctx().allocator)
        for a, i in k.args {
            // same flags as the outer type: `Box($T)` in a return type is still an error
            args[i] = resolve_type_specifier(s, a, no_declare_generic, bindings)
            if args[i] == void_type() {
                highlight_lines({get_ctx().current_file, k.span})
                gala_panicf("\"void\" can't be a type argument of \"%s\".", k.name)
            }
        }
        tid := get_or_add_struct_instance(tmpl_id, args)
        return tid
    }
    case PointerType: {
        id := resolve_type_specifier(s, k.ptr^, no_declare_generic, bindings)
        return intern_type({kind=.Pointer, ptr=id})
    }
    case FixedArreySpecifier: {
        id := resolve_type_specifier(s, k.base^, no_declare_generic, bindings)
        size := k.size
        if se, has_size_expr := k.size_expr.(ExprId); has_size_expr {
            size = const_array_size(s, se)
        }
        return intern_type({kind=.FixedSizeArray,
            fixed_size_array={type=id, size=size}})
    }
    case FnSpecifier: {
        for a in k.signature.args {
            if a.default != nil {
                highlight_lines(get_ctx().current_file, a.span)
                gala_panic("Default values aren't allowed in function types.")
            }
        }
        // `fn(x: $T): T` in a return position would declare a generic nobody can bind
        if no_declare_generic && bindings == nil && is_fn_signature_generic(k.signature^) {
            highlight_lines(get_ctx().current_file, k.signature.args[0].span)
            gala_panic("Can't specify generic in return type.")
        }

        fnty, fnscope := resolve_fn_dec_signature(s, k.signature^, bindings = bindings)

        // Generics declared inside the fn type (`$T`) belong to the enclosing
        // signature, so later params and the return type can use them.
        // (also covers the bindings != nil clone path, which binds names into fnscope)
        for name, tid in fnscope.types {
            if _, exists := s.types[name]; !exists {
                s.types[name] = tid
            }
        }
        free_scope(&fnscope)

        // a function-typed *value* is never itself a generic function; its
        // generic-ness comes from the enclosing signature
        fnty.fn.is_generic = false
        return new_fn_type(fnty)
    }
    case: panic("impl");
    }
}

// How deep instances nest inside each other: `i32` is 0, `^i32` is 1,
// `Box(^i32)` is 2. Polymorphic recursion (`next: ^Bad(^T)`,
// `kids: []Bad(Box(T))`) makes this grow forever, so it needs a ceiling.
MAX_STRUCT_INSTANCE_DEPTH :: 32

type_nesting_depth :: proc(t: TypeId) -> int {
    ty := get_type(t)
    #partial switch ty.kind {
    case .Pointer:        return 1 + type_nesting_depth(ty.ptr)
    case .Slice:          return 1 + type_nesting_depth(ty.slice.type)
    case .FixedSizeArray: return 1 + type_nesting_depth(ty.fixed_size_array.type)
    case .Struct: {
        deepest := 0
        for a in ty.structure.args {
            deepest = max(deepest, type_nesting_depth(a))
        }
        return 1 + deepest
    }
    }
    return 0
}

// The one instance of generic struct `tmpl_id` for these args (made on first use).
get_or_add_struct_instance :: proc(tmpl_id: TypeId, args: []TypeId) -> TypeId {
    ctx := get_ctx()

    for inst in get_type(tmpl_id).structure.instances {
        same := len(inst.args) == len(args)
        for a, i in args {
            if !same do break
            if !types_equal(inst.args[i], a) do same = false
        }
        if same do return inst.type
    }

    // a new instance: refuse the ones that only a runaway expansion asks for
    for a in args {
        if type_nesting_depth(a) > MAX_STRUCT_INSTANCE_DEPTH {
            highlight_lines(ctx.spans.ty_decs[tmpl_id])
            gala_panicf("Generic struct \"%s\" is instantiated with ever deeper types (polymorphic recursion?).",
                get_type(tmpl_id).name)
        }
    }

    tmpl := get_type(tmpl_id)^ // copy: the type table can move below
    // not intern_type: structs are nominal
    append(&ctx.types, Type{
        kind = .Struct,
        name = mangle_struct_instance(tmpl.name, args),
        structure = {is_instance = true, origin = tmpl_id, args = args},
    })
    new_id := TypeId(len(ctx.types) - 1)
    ctx.spans.ty_decs[new_id] = ctx.spans.ty_decs[tmpl_id]
    ctx.ty_modules[new_id] = ctx.ty_modules[tmpl_id]

    // register BEFORE filling the fields: a field may name this very
    // instance (`next: ^Node(T)`), which must find it and not recurse
    append(&get_type(tmpl_id).structure.instances, StructInstance{args = args, type = new_id})

    fill_struct_instance(tmpl_id, new_id)
    return new_id
}

// True for the struct types that exist at runtime and so may be sized, laid
// out and emitted: plain structs and fully concrete instances. False for a
// template (`Box`, its fields still hold `Generic` types) and for a
// placeholder instance (`Box(T)` while a generic signature is resolved, no
// fields). Codegen, type_size and struct_field_offsets must skip those.
struct_is_concrete :: proc(tid: TypeId) -> bool {
    ty := get_type(tid)
    if ty.kind != .Struct do return false
    if ty.structure.is_generic do return false
    if ty.structure.is_instance {
        for a in ty.structure.args {
            if gen_has(a) do return false
        }
    }
    return true
}

// Lowers the template's fields into the instance. Does nothing for a
// placeholder (an arg is still generic) or while the template's own fields
// aren't resolved yet; finish_struct_instances catches those later.
fill_struct_instance :: proc(tmpl_id, inst_id: TypeId) {
    ctx := get_ctx()
    inst := get_type(inst_id)^
    if inst.structure.fields != nil do return
    for a in inst.structure.args {
        if gen_has(a) do return
    }
    tmpl := get_type(tmpl_id)^ // copy: gen_subst can append types
    if len(tmpl.structure.fields) == 0 do return

    bound := make(map[string]TypeId, allocator = ctx.allocator)
    for n, i in tmpl.structure.generic_names {
        bound[n] = inst.structure.args[i]
    }
    fields := make([]Field, len(tmpl.structure.fields), allocator = ctx.allocator)
    for f, i in tmpl.structure.fields {
        fields[i] = f
        fields[i].type = gen_subst(f.type, bound, {})
    }
    get_type(inst_id).structure.fields = fields // fetched fresh: gen_subst appends
}

// Instances made before their template was resolved (`A { b: Box(i64) }`
// above `Box`). Instances made while filling go on the end of the list, so
// this loops by index.
finish_struct_instances :: proc(ast: ^AST) {
    for id in ast.items {
        if _, is_struct := get(id).(StructDec); !is_struct do continue
        tid := get_ctx().item_types[id]
        if !get_type(tid).structure.is_generic do continue
        for i := 0; i < len(get_type(tid).structure.instances); i += 1 {
            fill_struct_instance(tid, get_type(tid).structure.instances[i].type)
        }
    }
}

// Appends `t` to `b` using only [A-Za-z0-9_]: `^i32` -> `p_i32`, `[]f64` -> `a_f64`.
// Anything else (including the `.` in an instance name) becomes `_`.
mangle_ty :: proc(b: ^strings.Builder, t: TypeId) {
    for r in tts(t) {
        switch {
        case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '_':
            strings.write_rune(b, r)
        case r == '^': strings.write_string(b, "p_")
        case r == '[': strings.write_string(b, "a_")
        case r == ']': // dropped
        case: strings.write_byte(b, '_')
        }
    }
}

// "f" + params [f64, ^i32] -> "f.f64.p_i32.v0"
mangle_version :: proc(base: string, params: []TypeId, idx: int) -> string {
    b: strings.Builder
    strings.builder_init(&b, get_ctx().allocator)
    strings.write_string(&b, base)
    for p in params {
        strings.write_byte(&b, '.')
        mangle_ty(&b, p)
    }
    // names are for readability only; the index is what makes them unique
    strings.write_string(&b, ".v")
    strings.write_int(&b, idx)
    return strings.to_string(b)
}

// `DynArray.i64`, `Pair.i64.p_f64`, `Box.Box_i64`
mangle_struct_instance :: proc(name: string, args: []TypeId) -> string {
    b := strings.builder_make(allocator = get_ctx().allocator)
    strings.write_string(&b, name)
    for a in args {
        strings.write_byte(&b, '.')
        mangle_ty(&b, a)
    }
    return strings.to_string(b)
}
get_untyped_default :: proc(t: TypeId) -> TypeId {
    #partial switch get_type(t).kind {
    case .UntypedInteger: {
        v, ok := get_ctx().base_mod.types["i64"]; assert(ok);
        return v
    }
    case .UntypedFloat: {
        v, ok := get_ctx().base_mod.types["f64"]; assert(ok);
        return v
    }

    case: {
        gala_panic("compiler bug: no default type for", tts(t))
    }
    }
    return 0
}
resolve_stmt :: proc(s: ^Scope, id: StmtId) {
    switch stmt in get(id) {
    case BreakStmt, ContinueStmt: {}
    case ForLoop: {
        resolve_expr(s, stmt.expr);
        new_s := new_scope(s)
        // create new object with no type yet, get that in typechecking
        get_ctx().stmt_objects[id] = new_object(&new_s, Object{kind=.Argument, name=stmt.name}, get_span(id))
        b := stmt.block
        resolve_block(&new_s, &b);
        free_scope(&new_s)
    }
    case WhileLoop: {
        resolve_expr(s, stmt.cond);
        b := stmt.block
        resolve_block(s, &b);
    }
    case VarDec: {
        resolve_expr(s, stmt.value);
        resolved_ty : Maybe(TypeId) = nil
        if stmt.type != nil {
            ty, ok := stmt.type.(TypeSpecifier); assert(ok);
            if is_type_specifier_generic(ty) {
                highlight_lines(get_span(id));
                gala_panic("can't have generics in vardecs.");
            }
            resolved_ty = resolve_type_specifier(s, ty);
        }
        oid := new_object(s, Object{kind=.Variable,
            name=stmt.name, type=resolved_ty}, get_span(id))
        get_ctx().stmt_objects[id] = oid;
    }
    case Return: {
        if e, ok := stmt.expr.(ExprId); ok {
            resolve_expr(s, e);
        }
    }
    case Assignment: {
        resolve_expr(s, stmt.target);
        resolve_expr(s, stmt.value);
    }
    case IfElse: {
        resolve_expr(s, stmt.base_con)
        b := stmt.base_block
        resolve_block(s, &b)
        for a in stmt.alt {
            resolve_expr(s, a.cond)
            b := a.block
            resolve_block(s, &b)
        }
        if stmt.has_else_block {
            b = stmt.else_block
            resolve_block(s, &b)
        }
    }
    case ExprId: {
        resolve_expr(s, stmt);
    }
    case: gala_panic("Impl");
    }
}
resolve_block :: proc(s: ^Scope, b: ^Block) {
    b_scope := new_scope(s);
    for id in b.stmts {
        resolve_stmt(&b_scope, id)
    }
    free_scope(&b_scope)
}
void_type :: proc() -> TypeId {
    v, ok := get_ctx().base_mod.types["void"];
    assert(ok);
    return v;
}
integer_type :: proc() -> TypeId {
    v, ok := get_ctx().base_mod.types["i64"];
    assert(ok);
    return v;
}
byte_type :: proc() -> TypeId {
    v, ok := get_ctx().base_mod.types["byte"];
    assert(ok);
    return v;
}
ty_from_name :: proc(name:string) -> TypeId {
    v, ok := get_ctx().base_mod.types[name];
    assert(ok);
    return v;
}

// `$` names in order of first appearance (this is the order of `Name(a, b)`)
collect_generic_names :: proc(t: TypeSpecifier, out: ^[dynamic]string) {
    #partial switch k in t {
    case GenericSpecifier: {
        for n in out^ {
            if n == k.name do return
        }
        append(out, k.name)
    }
    case SliceSpecifier:        collect_generic_names(k.base^, out)
    case PointerType:           collect_generic_names(k.ptr^, out)
    case FixedArreySpecifier:   collect_generic_names(k.base^, out)
    case GenericInstSpecifier: {
        for a in k.args do collect_generic_names(a, out)
    }
    case FnSpecifier: {
        for a in k.signature.args {
            if !a.inferred do collect_generic_names(a.t, out)
        }
        if k.signature.is_variadic do collect_generic_names(k.signature.variadic_ty, out)
        if r, ok := k.signature.ret_ty.(TypeSpecifier); ok do collect_generic_names(r, out)
    }
    }
}

resolve_struct_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    sd, ok := get_item(id).(StructDec); assert(ok)
    tid, iok := s.ty_foreward[sd.name]; assert(iok) // make sure fd exists

    // the first `$T` declares T in this scope, plain `T` refers to it after
    scope := new_scope(s)
    fields := make([]Field, len(sd.fields), allocator=get_ctx().allocator)
    declared := make(map[string]Field, allocator=get_ctx().allocator)

    for f, i in sd.fields {
        if _, ok := declared[f.name]; ok {
            highlight_lines(get_ctx().current_file, f.span)
            gala_panic("Field already exists.")
        }
        t := resolve_type_specifier(&scope, f.t)
        field := Field{name=f.name, type=t, span=f.span}
        fields[i] = field
        declared[f.name] = field
    }
    free_scope(&scope)

    // fill the forward-declared type in place: it already carries
    // is_generic / generic_names and any instances made so far
    get_type(tid).structure.fields = fields

    // link item to type
    delete_key(&s.ty_foreward, sd.name) // delete fd and create object
    s.types[sd.name] = tid
    get_ctx().item_types[id] = tid
}

// for gala functions, add an aditional arg to function body of type slice of var arg type
// takes ^Scope (not ^ModuleScope) so fn type specifiers can be resolved from any scope
resolve_fn_dec_signature :: proc(s: ^Scope, fndec: FnDecSignature, extern := false,
        bindings: map[string]TypeId = nil) -> (Type, Scope) {
    // create fn type
    fnty := Type{}
    fnty.kind = .Function;
    // a clone built from bindings is concrete
    fnty.fn.is_generic = is_fn_signature_generic(fndec) && bindings == nil
    arg_scope := new_scope(s);
    if len(fndec.args) > 0 || fndec.is_variadic {
        args := make([]Arg, len(fndec.args), allocator=get_ctx().allocator)
        declared := make(map[string]Arg)
        for a, i in fndec.args {
            t: TypeId
            if a.inferred {
                t = void_type()
            } else {
                t = resolve_type_specifier(&arg_scope, a.t, bindings = bindings)
            }
            if da, ok := declared[a.name]; ok {
                print_lines(get_file_lines(get_ctx().current_file, da.span), da.span)
                gala_panic("Duplicate argument. Arg already declared here.")
            }
            arg_t := t;
            arg := Arg{name=a.name, type=arg_t, span=a.span, inferred=a.inferred}

            if def, has_default := a.default.(ExprId); has_default {
                resolve_expr(s, def)
                arg.default = def
                arg.default_src = a.default_src
            }

            obj_ty: Maybe(TypeId) = arg_t
            if a.inferred do obj_ty = nil
            arg.obj = new_object(&arg_scope,
                Object{.Argument, a.name, obj_ty},
                {file_name=get_ctx().current_file, span=a.span});

            args[i] = arg
            declared[a.name] = arg
        }
        fnty.fn.args = args
        if fndec.is_variadic {
            variadic_ty := resolve_type_specifier(&arg_scope, fndec.variadic_ty, bindings = bindings)
            name := fndec.variadic_arg_name
            if da, ok := declared[name]; ok {
                print_lines(get_file_lines(get_ctx().current_file, da.span), da.span)
                gala_panic("Duplicate argument. Arg already declared here.")
            }
            new_ty := Type{kind=.Slice, slice={type=variadic_ty}}
            new_ty_id := intern_type(new_ty)
            fnty.fn.gala_abi_ty = new_ty_id;

            new_object(&arg_scope, Object{.Argument, name, new_ty_id},
                {file_name=get_ctx().current_file, span=fndec.variadic_arg_span});
            fnty.fn.is_variadic = true
            fnty.fn.variadic_ty = variadic_ty
            fnty.fn.variadic_name = name
        }
    }
    if fndec.ret_ty != nil {
        fnty.fn.ret_ty = resolve_type_specifier(&arg_scope,
            fndec.ret_ty.(TypeSpecifier), no_declare_generic = true, bindings = bindings)
    } else {
        fnty.fn.ret_ty = void_type();
    }
    return fnty, arg_scope
}
is_type_specifier_generic :: proc(t: TypeSpecifier) -> bool {
    #partial switch k in t {
        case GenericSpecifier: return true
        case PointerType: {
            if is_type_specifier_generic(k.ptr^) do return true
        }
        case FnSpecifier: {
            for a in k.args {
                if is_type_specifier_generic(a.t) do return true
            }
            if k.is_variadic {
                if is_type_specifier_generic(k.variadic_ty) do return true;
            }
            rt, has_rt := k.ret_ty.(TypeSpecifier);
            if  has_rt { if is_type_specifier_generic(rt) do return true };
        }
        case SliceSpecifier: {
            if is_type_specifier_generic(k.base^) do return true
        }
        case FixedArreySpecifier: { // no size yet.
            if is_type_specifier_generic(k.base^) do return true
        }
        case GenericInstSpecifier: {
            for a in k.args {
                if is_type_specifier_generic(a) do return true
            }
        }

    }
    return false
}
specifier_has_generic :: proc(t: TypeSpecifier) -> bool {
    #partial switch k in t {
    case GenericInstSpecifier:
        for a in k.args {
            if specifier_has_generic(a) do return true
        }
        return false
    case GenericSpecifier:
        return true
    case SliceSpecifier:
        return specifier_has_generic(k.base^)
    case PointerType:
        return specifier_has_generic(k.ptr^)
    case FixedArreySpecifier:
        return specifier_has_generic(k.base^)
    case FnSpecifier:
        for a in k.signature.args {
            if !a.inferred && specifier_has_generic(a.t) do return true
        }
        if k.signature.is_variadic && specifier_has_generic(k.signature.variadic_ty) {
            return true
        }
        if r, ok := k.signature.ret_ty.(TypeSpecifier); ok {
            return specifier_has_generic(r)
        }
        return false
    case BaseType, AnySpecifier:
        return false
    }
    return false
}

is_fn_signature_generic :: proc(sig: FnDecSignature) -> bool {
    for a in sig.args {
        if !a.inferred && specifier_has_generic(a.t) do return true
    }
    if sig.is_variadic && specifier_has_generic(sig.variadic_ty) do return true
    // a generic only in the return type is an error elsewhere
    // ("Can't specify generic in return type"), so it isn't checked here
    return false
}
_is_fn_signature_generic :: proc(fndec: FnDecSignature) -> bool {
    for a in fndec.args {
        if is_type_specifier_generic(a.t) do return true;
    }
    if fndec.is_variadic {
        if is_type_specifier_generic(fndec.variadic_ty) do return true;
    }
    rt, has_rt := fndec.ret_ty.(TypeSpecifier);
    if  has_rt { if is_type_specifier_generic(rt) do return true };
    return false
}
// can't be generic, really. so fail
resolve_extern_fn_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    fndec, ok := get(id).(ExternFnDec); assert(ok); // assert it's a fn dec
    oid, ook := s.obj_foreward[fndec.name]; assert(ook); // make sure fd exists
    obj := get(oid); // gets pointer, so modify that

    fnty, scope := resolve_fn_dec_signature(s, fndec, extern=true);
    if fnty.fn.is_generic {
        highlight_lines(get_span(id));
        gala_panic("extern function can not be generic.");
    }
    fnty.fn.is_external = true;
    free_scope(&scope);

    // intern type
    tyid := new_fn_type(fnty);
    get_ctx().spans.ty_decs[tyid] = get_span(id)

    obj.type = tyid
    obj.name = fndec.name;
    // update object
    get_ctx().objs[oid] = obj^

    delete_key(&s.obj_foreward, fndec.name); // delete fd and create object
    s.objects[fndec.name] = oid; // recreate link
    get_ctx().item_objects[id] = oid;
}
resolve_fn_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    fndec, ok := get(id).(FnDec); assert(ok); // assert it's a fn dec
    oid, ook := s.obj_foreward[fndec.name]; assert(ook); // make sure fd exists
    obj := get(oid); // gets pointer, so modify that

    fnty, fnscope := resolve_fn_dec_signature(s, fndec);

    // Generic bodies are resolved lazily, per clone, in resolve_generic_clone
    // (in the declaring module's scope). Only the signature is resolved here.
    if !fnty.fn.is_generic {
        resolve_block(&fnscope, &fndec.block);
    }
    free_scope(&fnscope);

    // intern type
    tyid := new_fn_type(fnty);
    get_ctx().spans.ty_decs[tyid] = get_span(id)

    obj.type = tyid
    obj.name = fndec.name;
    // update object
    get_ctx().objs[oid] = obj^

    delete_key(&s.obj_foreward, fndec.name); // delete fd and create object
    s.objects[fndec.name] = oid; // recreate link
    get_ctx().item_objects[id] = oid;
}
// Top-level variable. The object was forward-declared (see forward_item) so
// functions and other globals can refer to it regardless of order; here the
// initialiser is resolved in the module scope (so no locals/params are
// visible) and the explicit type, if any, is resolved. For `:=` the type
// stays nil until the type checker infers it from the initialiser.
resolve_global_var_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    gd, ok := get(id).(GlobalVarDec); assert(ok)
    oid, ook := s.obj_foreward[gd.name]; assert(ook) // make sure fd exists

    resolve_expr(s, gd.value)

    obj := get(oid) // gets pointer, so modify that
    if gd.type != nil {
        ts, tok := gd.type.(TypeSpecifier); assert(tok)
        if is_type_specifier_generic(ts) {
            highlight_lines(get_span(id));
            gala_panic("can't have generics in vardecs.");
        }
        obj.type = resolve_type_specifier(s, ts)
    }
    obj.name = gd.name
    // update object
    get_ctx().objs[oid] = obj^

    delete_key(&s.obj_foreward, gd.name); // delete fd and create object
    s.objects[gd.name] = oid; // recreate link
    get_ctx().item_objects[id] = oid;
}
forward_item :: proc(s: ^ModuleScope, id: ItemId) {
    item := get(id)
    // foreward
    switch i in item {
    case Import:        {
        resolved := resolve_import_path(get_ctx().current_file, i.fname)
        modid, ok := get_ctx().modules[resolved];
        if !ok {
            gala_panicf("File import \"%s\" doesn't have a module id associated with it.\n", resolved);
        }
        decs:= get_ctx().mods[modid];

        // import exports only
        for obj, v in decs.declarations.obj_exports {
            _, exists := s.objects[obj];
            if exists {
                debugln(item, v);
                gala_panic("duplicate name in import for object", obj);
            }
            s.objects[obj] = v
        }
        for ty, v in decs.declarations.ty_exports {
            _, exists := s.types[ty];
            if exists {
                debugln(item, v);
                gala_panic("duplicate name in import for type", ty);
            }
            s.types[ty] = v
        }
        get_ctx().item_module[id] = modid
    }
    case StructDec:     new_type_fd(s, Type{kind=.Struct, name=i.name}, get_span(id));
    case FnDec:         new_object_fd(s, Object{kind=.Variable, name=i.name}, get_span(id));
    case ExternFnDec:   new_object_fd(s, Object{kind=.Variable, name=i.name}, get_span(id));
    // kind=.Variable on purpose: a global is addressable like any local, so
    // the type checker and codegen treat its uses the same way.
    case GlobalVarDec:  new_object_fd(s, Object{kind=.Variable, name=i.name}, get_span(id));
    // never looked up as an object: uses are rewritten, and const_table says
    // which objects are constants
    case ConstDec: {
        oid := new_object_fd(s, Object{kind=.Variable, name=i.name}, get_span(id))
        const_table[oid] = ConstEntry{item = id, scope = s}
    }
    case:               panic("impl")
    }
}
resolve_item :: proc(s: ^ModuleScope, id: ItemId) {
    item := get(id)

    switch i in item {
    case Import:        {}
    case StructDec: {
        resolve_struct_dec_item(s, id);
        tid, ok := get_ctx().item_types[id]; assert(ok);
        s.ty_exports[i.name] = tid
    }
    case FnDec: {
        resolve_fn_dec_item(s, id);
        oid, ok := get_ctx().item_objects[id]; assert(ok);
        s.obj_exports[i.name] = oid
    }
    case ExternFnDec: {
        resolve_extern_fn_dec_item(s, id);
        oid, ok := get_ctx().item_objects[id]; assert(ok);
        s.obj_exports[i.name] = oid
    }
    case GlobalVarDec: {
        resolve_global_var_dec_item(s, id);
        oid, ok := get_ctx().item_objects[id]; assert(ok);
        s.obj_exports[i.name] = oid
    }
    case ConstDec: {
        // exports itself; may already be done if another constant needed it
        resolve_const_dec_item(s, id)
    }
    case:               panic("impl")
    }
}
// get_ctx().allocator may not be available on context init, so this helps
new_scope :: proc(parent:^Scope=nil, allocator:=get_ctx().allocator) -> Scope {
    s := Scope{}
    s.objects       = make(map[string]ObjId,  allocator=allocator);
    s.types         = make(map[string]TypeId, allocator=allocator);
    s.parent = parent;
    return s;
}
// get_ctx().allocator may not be available on context init, so this helps
new_module_scope :: proc(parent:^Scope=nil, allocator:=get_ctx().allocator) -> ModuleScope {
    s := ModuleScope{}
    s.scope = new_scope(parent, allocator)
    s.parent = parent
    s.obj_foreward  = make(map[string]ObjId,  allocator=allocator);
    s.ty_foreward   = make(map[string]TypeId, allocator=allocator);
    return s
}
free_scope :: proc(s: ^Scope) {
    if s == nil do return;

    delete(s.objects);
    delete(s.types);

    s^ = {};
}

free_module_scope :: proc(s: ^ModuleScope) {
    if s == nil do return;

    free_scope(&s.scope);

    delete(s.obj_foreward);
    delete(s.ty_foreward);

    s^ = {};
}
Module :: struct {
    declarations: ModuleScope,
    ast: ^AST,
    path: string,
}
// A struct can't contain itself by value, directly or through other structs
// and fixed arrays. Pointers, slices and functions break the cycle. Run once
// all of a module's structs are resolved, so declaration order doesn't matter.
// state: 0 = unvisited, 1 = in progress, 2 = done

// The struct that a field type contains by value, if any (looking through
// fixed arrays). A placeholder instance (`Node(T)` inside Node's own
// declaration, or `B(T)` inside A's) has no fields yet; it stands for its
// template, and that is what closes the cycle: Node -> Node(T) -> Node.
by_value_struct :: proc(t: TypeId) -> (TypeId, bool) {
    cur := t
    for {
        ty := get_type(cur)
        #partial switch ty.kind {
        case .FixedSizeArray: cur = ty.fixed_size_array.type
        case .Struct: {
            if ty.structure.is_instance {
                for a in ty.structure.args {
                    if gen_has(a) do return ty.structure.origin, true
                }
            }
            return cur, true
        }
        case:                 return TypeId(0), false
        }
    }
    return TypeId(0), false
}
visit_struct :: proc(tid: TypeId, state: ^map[TypeId]int) {
    if state^[tid] == 2 do return
    state^[tid] = 1
    ty := get_type(tid)
    for f in ty.structure.fields {
        inner, ok := by_value_struct(f.type)
        if !ok do continue
        if state^[inner] == 1 {
            highlight_lines(get_ctx().current_file, f.span)
            gala_panicf("Struct \"%s\" would contain itself by value (infinite size): field \"%s\" (type \"%s\") closes a cycle. Use a pointer.",
                ty.name, f.name, get_type(inner).name)
        }
        visit_struct(inner, state)
    }
    state^[tid] = 2
}
check_struct_cycles :: proc(ast: ^AST) {
    state := make(map[TypeId]int, allocator=get_ctx().allocator)
    for id in ast.items {
        if _, is_struct := get(id).(StructDec); is_struct {
            tid, ok := get_ctx().item_types[id]; assert(ok)
            visit_struct(tid, &state)
        }
    }
    delete(state)
}
resolve_module_ast :: proc(ast: ^AST, path: string) -> ModId {
    append(&get_ctx().mods, Module{});
    mid := ModId(len(get_ctx().mods) - 1);
    get_ctx().current_module_id = mid; // for objects and what not

    global_scope := new_module_scope(&get_ctx().base_mod)

    for id in ast.items {
        forward_item(&global_scope, id)
    }

    // Which structs are generic, before any field is resolved, so
    // `Box(i64)` works above `Box`'s declaration.
    for id in ast.items {
        sd, is_struct := get(id).(StructDec)
        if !is_struct do continue
        names := make([dynamic]string, allocator=get_ctx().allocator)
        for f in sd.fields do collect_generic_names(f.t, &names)
        if len(names) == 0 do continue
        ty := get_type(global_scope.ty_foreward[sd.name])
        ty.structure.is_generic = true
        ty.structure.generic_names = names[:]
    }

    // Structs first: a struct literal in a function body or a global
    // initialiser asserts that the struct's fields are already filled in,
    // so it mustn't matter whether the struct is declared before or after
    // its first use in the file.
    for id in ast.items {
        if _, is_struct := get(id).(StructDec); is_struct {
            resolve_item(&global_scope, id)
        }
    }
    finish_struct_instances(ast)
    check_struct_cycles(ast)

    // Constants next: they're folded here and every later use (function
    // bodies, globals, parameter defaults) is rewritten into the value, so
    // they must all be known before anything else is resolved. Order between
    // constants doesn't matter (see ensure_const).
    for id in ast.items {
        if _, is_const := get(id).(ConstDec); is_const {
            resolve_item(&global_scope, id)
        }
    }
    for id in ast.items {
        _, is_struct := get(id).(StructDec)
        _, is_const := get(id).(ConstDec)
        if !is_struct && !is_const {
            resolve_item(&global_scope, id)
        }
    }

    // filter generics like functions
    // Generic struct declarations are templates, not runtime structs.
    // Keep them available throughout resolution, then remove their AST items.
    // Constants are fully folded into their uses, so they go too.
    write := 0
    for id in ast.items {
        drop_item := false

        if _, ok := get(id).(StructDec); ok {
            if tid, exists := get_ctx().item_types[id]; exists {
                drop_item = get_type(tid).structure.is_generic
            }
        }
        if _, ok := get(id).(ConstDec); ok {
            drop_item = true
        }

        if drop_item {
            continue
        }

        ast.items[write] = id
        write += 1
    }
    resize(&ast.items, write)

    // assign module
    get_ctx().mods[mid] = Module {
        declarations=global_scope,
        ast=ast,
        path=path,
    }
    return mid;
}
// Walks a generic specifier against a concrete type to recover `$T`.
bind_generics :: proc(spec: TypeSpecifier, concrete: TypeId, out: ^map[string]TypeId) {
    ty := get_type(concrete)
    #partial switch k in spec {
    case GenericInstSpecifier:
        if ty.kind == .Struct && ty.structure.is_instance {
            for a, i in k.args do bind_generics(a, ty.structure.args[i], out)
        }
    case GenericSpecifier:
        out^[k.name] = concrete
    case PointerType:
        if ty.kind == .Pointer do bind_generics(k.ptr^, ty.ptr, out)
    case SliceSpecifier:
        if ty.kind == .Slice do bind_generics(k.base^, ty.slice.type, out)
    case FixedArreySpecifier:
        if ty.kind == .FixedSizeArray do bind_generics(k.base^, ty.fixed_size_array.type, out)
    case FnSpecifier:
        if ty.kind != .Function do return
        for a, i in k.signature.args {
            if a.inferred || i >= len(ty.fn.args) do continue
            bind_generics(a.t, ty.fn.args[i].type, out)
        }
        if k.signature.is_variadic && ty.fn.is_variadic {
            bind_generics(k.signature.variadic_ty, ty.fn.variadic_ty, out)
        }
        if r, ok := k.signature.ret_ty.(TypeSpecifier); ok {
            bind_generics(r, ty.fn.ret_ty, out)
        }
    }
}

// Resolves clone `iid` of generic item `g` as the concrete function for `v`.
resolve_generic_clone :: proc(g, iid: ItemId, v: FnVersion) {
    ctx := get_ctx()

    // resolve in the module the generic was declared in
    mid := ctx.obj_modules[ctx.item_objects[g]]
    saved_mid := ctx.current_module_id
    ctx.current_module_id = mid
    defer ctx.current_module_id = saved_mid
    ms := &ctx.mods[mid].declarations

    orig, _ := get(g).(FnDec)
    fndec, ok := get(iid).(FnDec); assert(ok)

    bindings := make(map[string]TypeId, allocator=ctx.allocator)
    for a, i in orig.signature.args {
        bind_generics(a.t, v.params[i], &bindings)
    }
    // the variadic element is the last entry of the version key
    if orig.signature.is_variadic {
        bind_generics(orig.signature.variadic_ty, v.params[len(orig.signature.args)], &bindings)
    }

    fnty, fnscope := resolve_fn_dec_signature(ms, fndec.signature, bindings = bindings)
    resolve_block(&fnscope, &fndec.block)
    free_scope(&fnscope)

    tyid := new_fn_type(fnty)
    ctx.spans.ty_decs[tyid] = get_span(iid)

    append(&ctx.objs, Object{kind=.Variable, name=fndec.name, type=tyid})
    oid := ObjId(len(ctx.objs) - 1)
    ctx.obj_modules[oid] = mid
    ctx.spans.objs_decs[oid] = get_span(iid)
    ctx.item_objects[iid] = oid
}
