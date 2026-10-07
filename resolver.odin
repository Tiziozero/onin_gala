package main

import "core:fmt"
Field :: struct {
    name: string,
    type: TypeId,
    span: Span,
}
// `default` is the (already resolved) constant expression a call falls back to
// when it omits this argument. See resolve_fn_dec_signature.
Arg :: struct {
    name: string,
    type: TypeId,
    span: Span,
    is_variadic: bool,
    default: Maybe(ExprId),
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
            if error { fmt.print("First declared here:"); highlight_lines(get_span(tid)); }
            return true
        }

        oid, ok1  := s.objects[n];
        if ok1 {
            if error { fmt.print("First declared here:"); highlight_lines(get_span(oid)); }
            return true
        }

        ftid, ok2  := s.ty_foreward[n];
        if ok2 {
            if error { fmt.print("First declared here:"); highlight_lines(get_span(ftid)); }
            return true
        }

        foid, ok3  := s.obj_foreward[n];
        if ok3 {
            if error { fmt.print("First declared here:"); highlight_lines(get_span(foid)); }
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
        gala_panicf("Name \"%s\" already declared.", o.name);
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
resolve_expr :: proc(s: ^Scope, id: ExprId) {
    switch e in get(id) {
    case TypeIdOf: {
        get_ctx().expr_resolution_types[id] = resolve_type_specifier(s, e.t);
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
    case Sizeof: {
        t := resolve_type_specifier(s, e.t);
        get_ctx().expr_resolution_types[id] = t
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
        resolve_expr(s, e.start);
        resolve_expr(s, e.end);
    }
    case Index: {
        resolve_expr(s, e.target);
        resolve_expr(s, e.index);
    }
    case FixedSizeArray: {
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
    // check type exists
    tid, ok := scope_get_type(s, e.name); assert(ok);
    ty := get_type(tid);
    assert(ty.kind == .Struct);
    sfields := ty.structure.fields

    // `Foo{1, 2}`: assign the values to the struct's fields in declaration
    // order, so everything after this sees an ordinary named literal.
    if len(e.positional) > 0 {
        if len(e.positional) != len(sfields) {
            highlight_lines(get_ctx().current_file, get_span(id).span)
            gala_panicf("Type %s has %d fields, but the literal has %d values.",
                e.name, len(sfields), len(e.positional));
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
// only intern function and pointers
intern_type :: proc(t: Type) -> TypeId {
    assert(t.kind == .Pointer || 
            t.kind == .UntypedInteger || t.kind == .UntypedFloat || 
            t.kind == .FixedSizeArray || t.kind == .ZeroInit ||
            t.kind == .Slice || t.kind == .String || t.kind == .Any)
    for ty, id in get_ctx().types {
        if type_cmp(ty, t, true) { return TypeId(id) }
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
scope_get_type :: proc(s: ^Scope, n: string) -> (TypeId, bool) {
    scope := s
    for scope != nil {
        id, ok := scope.types[n];
        if ok { return id, true }
        // check fds too
        id, ok = scope.ty_foreward[n];
        if ok { return id, true }
        scope = scope.parent
    }
    debugln(n, "Not found")
    return 0, false
}
resolve_type_specifier :: proc(s: ^Scope, t: TypeSpecifier) -> TypeId {
    switch k in t {
    case AnySpecifier: {
        return intern_type({kind=.Any})
    }
    case SliceSpecifier: {
        base := resolve_type_specifier(s, k.base^)
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
        return ty
    }
    case PointerType: { // creates a pointer and will ge that one
        id := resolve_type_specifier(s, k.ptr^)
        return intern_type({kind=.Pointer, ptr=id})
    }
    case FixedArreySpecifier: { // creates a pointer and will ge that one
        id := resolve_type_specifier(s, k.base^)
        return intern_type({kind=.FixedSizeArray,
            fixed_size_array={type=id, size=k.size}})
    }
    case FnSpecifier: {
        // a function *type* has no body to fall back from, and a default
        // would have no meaning for calls through a pointer of that type.
        for a in k.signature.args {
            if a.default != nil {
                highlight_lines(get_ctx().current_file, a.span)
                gala_panic("Default values aren't allowed in function types.")
            }
        }
        // resolve the signature (ret type, args, variadic) into a Function type.
        // the returned scope only exists so a fn body could be resolved in it;
        // a bare specifier has no body, so just free it.
        fnty, fnscope := resolve_fn_dec_signature(s, k.signature^)
        free_scope(&fnscope)
        // not interned: function types are nominal here (see new_fn_type), so
        // the type checker must compare two fn specifier types structurally.
        return new_fn_type(fnty)
    }
    case: panic("impl");
    }
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

    case: panic("impl");
    }
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

resolve_struct_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    sd, ok := get_item(id).(StructDec); assert(ok); // assert it's a fn dec
    tid, iok := s.ty_foreward[sd.name]; assert(iok); // make sure fd exists
    // ty := get_type(tid); // gets pointer, so modify that
    // check duplicate fields
    fields := make([]Field, len(sd.fields), allocator=get_ctx().allocator)
    declared := make(map[string]Field, allocator=get_ctx().allocator);

    for f,i in sd.fields {
        if d, ok := declared[f.name]; ok {
            highlight_lines(get_ctx().current_file, f.span);
            gala_panic("Field already exists.");
        }
        t := resolve_type_specifier(s, f.t);
        field := Field{name=f.name, type=t, span=f.span}
        fields[i] = field;
        declared[f.name] = field;
    }


    // redefine type
    t := Type{name=sd.name, kind=.Struct, structure={fields=fields}}
    get_ctx().types[tid] = t;

    // link item to type
    delete_key(&s.ty_foreward, sd.name); // delete fd and create object
    s.types[sd.name] = tid;
    get_ctx().item_types[id] = tid;
}

// for gala functions, add an aditional arg to function body of type slice of var arg type
// takes ^Scope (not ^ModuleScope) so fn type specifiers can be resolved from any scope
resolve_fn_dec_signature :: proc(s: ^Scope, fndec: FnDecSignature, extern := false) -> (Type, Scope) {
    // create fn type
    fnty := Type{}
    fnty.kind = .Function;
    // return type
    if fndec.ret_ty != nil {
        fnty.fn.ret_ty = resolve_type_specifier(s, fndec.ret_ty.(TypeSpecifier))
    } else {
        fnty.fn.ret_ty = void_type();
    }
    // new scope for args
    // args
    new_scope := new_scope(s);
    args := make([]Arg, len(fndec.args), allocator=get_ctx().allocator)
    declared := make(map[string]Arg)
    variadic_ty: TypeId
    for a, i in fndec.args {
        t := resolve_type_specifier(&new_scope, a.t)
        if da, ok := declared[a.name]; ok {
            // print declared arg
            print_lines(get_file_lines(get_ctx().current_file, da.span), da.span)
            gala_panic("Duplicate argument. Arg already declared here.")
        }
        arg_t := t;
        arg := Arg{name=a.name, type=arg_t, span=a.span}

        // Default value: must be a constant expression (checked first so
        // e.g. naming another parameter gives this message instead of a
        // confusing "couldn't find in scope"), and is resolved against the
        // *outer* scope `s`, not `new_scope`, so it can't see parameters.
        if def, has_default := a.default.(ExprId); has_default {
            resolve_expr(s, def)
            arg.default = def
        }

        args[i] = arg
        declared[a.name] = arg
        new_object(&new_scope, Object{.Argument, a.name, arg_t}, {file_name=get_ctx().current_file, span=a.span});
    }
    fnty.fn.args = args

    if fndec.is_variadic {
        variadic_ty := resolve_type_specifier(&new_scope, fndec.variadic_ty)
        name := fndec.variadic_arg_name
        if da, ok := declared[name]; ok {
            // print declared arg
            print_lines(get_file_lines(get_ctx().current_file, da.span), da.span)
            gala_panic("Duplicate argument. Arg already declared here.")
        }
        // type is slice of type
        new_ty := Type{kind=.Slice, slice={type=variadic_ty}}
        new_ty_id := intern_type(new_ty)
        fnty.fn.gala_abi_ty = new_ty_id;

        // don't apend to args, as it's not an argument in the function ig
        // but declare object for fn body
        // it's fine because extern fn doesn't make use of it either way
        new_object(&new_scope, Object{.Argument, name, new_ty_id},
            {file_name=get_ctx().current_file, span=fndec.variadic_arg_span});
        fnty.fn.is_variadic = true
        fnty.fn.variadic_ty = variadic_ty
        fnty.fn.variadic_name = name
    }
    // free args scope
    return fnty, new_scope
}
resolve_extern_fn_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    fndec, ok := get(id).(ExternFnDec); assert(ok); // assert it's a fn dec
    oid, ook := s.obj_foreward[fndec.name]; assert(ook); // make sure fd exists
    obj := get(oid); // gets pointer, so modify that

    fnty, scope := resolve_fn_dec_signature(s, fndec);
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

    resolve_block(&fnscope, &fndec.block);
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
            fmt.panicf("File import \"%s\" doesn't have a module id associated with it.\n", resolved);
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
    ast: AST,
    path: string,
}
resolve_module_ast :: proc(ast: ^AST, path: string) -> ModId {
    append(&get_ctx().mods, Module{});
    mid := ModId(len(get_ctx().mods) - 1);
    get_ctx().current_module_id = mid; // for objects and what not

    global_scope := new_module_scope(&get_ctx().base_mod)

    for id in ast.items {
        forward_item(&global_scope, id)
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
    for id in ast.items {
        if _, is_struct := get(id).(StructDec); !is_struct {
            resolve_item(&global_scope, id)
        }
    }
    // assign module
    get_ctx().mods[mid] = Module {
        declarations=global_scope,
        ast=ast^,
        path=path,
    }
    return mid;
}
