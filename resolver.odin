package main

TypeKind :: enum {
    Invalid,
    Function,
    Integer,
    Float,
    Rune,
    Byte,
    Pointer,
}
Arg :: struct {
    name: string,
    type: TypeId
}
Type :: struct {
    name: string,
    kind: TypeKind,
    ptr: TypeId,
    fn: struct { args: []Arg, ret_ty: Maybe(TypeId)},
}
Object :: struct {
    name: string,
    type: TypeId,
}
Scope :: struct {
    objects:        map[string]ObjId,
    types:          map[string]TypeId,
    items:          map[string]ItemId,
    parent:         ^Scope,
}
ModuleScope :: struct {
    using scope: Scope,
    obj_foreward:   map[string]ObjId,
    ty_foreward:    map[string]TypeId,
}
new_object :: proc(s: ^Scope, o: Object) -> ObjId {
    ctx := get()
    append(&ctx.objs, o);
    id := ObjId(len(ctx.objs)-1);
    _, ok := s.types[o.name];       assert(!ok);
    _, ok = s.objects[o.name];      assert(!ok);
    s.objects[o.name] = id
    return id
}
new_type :: proc(s: ^Scope, t: Type) -> TypeId {
    ctx := get_ctx();
    append(&ctx.types, t);
    id := TypeId(len(ctx.types)-1);  // allocate type

    // make sure it doesn't exist
    _, ok := s.types[t.name];       assert(!ok);
    _, ok = s.objects[t.name];      assert(!ok);
    s.types[t.name] = id
    return id
}
new_object_fd :: proc(s: ^ModuleScope, o: Object) -> ObjId {
    ctx := get()
    append(&ctx.objs, o);
    id := ObjId(len(ctx.objs)-1);

    // make sure it doesn't exist
    _, ok := s.ty_foreward[o.name]; assert(!ok);
    _, ok = s.obj_foreward[o.name]; assert(!ok);
    _, ok = s.types[o.name];        assert(!ok);
    _, ok = s.objects[o.name];      assert(!ok);

    s.obj_foreward[o.name] = id
    return id
}
new_type_fd :: proc(s: ^ModuleScope, t: Type) -> TypeId {
    ctx := get()
    append(&ctx.types, t);
    id := TypeId(len(ctx.types)-1); 
    // make sure it doesn't exist
    _, ok := s.ty_foreward[t.name]; assert(!ok);
    _, ok = s.obj_foreward[t.name]; assert(!ok);
    _, ok = s.types[t.name];        assert(!ok);
    _, ok = s.objects[t.name];      assert(!ok);
    s.ty_foreward[t.name] = id
    return id
}
resolve_expr :: proc(s: ^Scope, id: ExprId) {
    switch e in get(id) {
    case Binop: {
        resolve_expr(s, e.left);
        resolve_expr(s, e.right);
    }
    case Number: {
    } // nothing
    case Symbol: {
        obj := scope_get_object(s, e.name);
        get_ctx().expr_objects[id] = obj
    }

    case: panic("impl");
    }
}
cmp_types :: proc(l, r: Type) -> bool {
    if l.kind != r.kind { return false } 

    if l.kind == .Function {
        if l.fn.ret_ty != r.fn.ret_ty { return false }
        if len(l.fn.args) != len(r.fn.args) { return false }
        /// cehck each arg
        for i in 0..<len(l.fn.args) {
            if l.fn.args[i] != r.fn.args[i] { return false }
        }
        return true // same type
    } else if l.kind == .Pointer {
        return cmp_types(get(l.ptr)^, get(r.ptr)^)
    } else {
        return true // same kind, same type for now
    }
}
// only intern function and pointers
intern_type :: proc(t: Type) -> TypeId {
    assert(t.kind == .Pointer || t.kind == .Function)
    for ty, id in get_ctx().types {
        if cmp_types(ty, t) { return TypeId(id) }
    }
    append(&get_ctx().types, t);
    return TypeId(len(get_ctx().types)-1)
}
scope_get_object :: proc(s: ^Scope, n: string) -> ObjId {
    scope := s
    for scope != nil {
        id, ok := scope.objects[n];
        if ok { return id }
        scope = scope.parent
    }
    panic("object doesn't exist");
}
scope_get_type :: proc(s: ^Scope, n: string) -> TypeId {
    scope := s
    for scope != nil {
        id, ok := scope.types[n];
        if ok { return id }
        scope = scope.parent
    }
    panic("type doesn't exist");
}
resolve_type_specifier :: proc(s: ^Scope, t: TypeSpecifier) -> TypeId {
    switch k in t {
    case BaseType: { // will get declared type id
        ty := scope_get_type(s, string(k));
        return ty
    }
    case PointerType: { // creates a pointer and will ge that one
        id := resolve_type_specifier(s, k^)
        return intern_type({kind=.Pointer, ptr=id})
    }
    case: panic("impl");
    }
}
resolve_stmt :: proc(s: ^Scope, id: StmtId) {
    switch stmt in get(id) {
    case VarDec: {
        resolve_expr(s, stmt.value);
        if stmt.type != nil {
            ty, ok := stmt.type.(TypeSpecifier); assert(ok);
            resolve_type_specifier(s, ty);
        }
    }
    case: panic("Impl");
    }
}
resolve_block :: proc(s: ^Scope, b: ^Block) {
    b_scope := new_scope(s);
    for id in b.stmts {
        resolve_stmt(&b_scope, id)
    }
    free_scope(&b_scope)
}
resolve_fn_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    fndec, ok := get(id).(FnDec); assert(ok); // assert it's a fn dec
    oid, ook := s.obj_foreward[fndec.name]; assert(ook); // make sure fd exists
    obj := get(oid); // gets pointer, so modify that

    // impl
    resolve_block(s, &fndec.block);
    // create fn type
    fnty := Type{}
    fnty.kind = .Function;
    fnty.fn.args = make([]Arg, 0, allocator=context.temp_allocator)
    fnty.fn.ret_ty = nil
    tyid := intern_type(fnty);

    obj.type = tyid
    obj.name =fndec.name;

    delete_key(&s.obj_foreward, fndec.name); // delete fd and create object
    s.objects[fndec.name] = oid; // recreate link
}
forward_item :: proc(s: ^ModuleScope, id: ItemId) {
    item := get(id)
    // foreward
    switch i in item {
    case FnDec:         new_object_fd(s, Object{name=i.name});
    case:               panic("impl")
    }
}
resolve_item :: proc(s: ^ModuleScope, id: ItemId) {
    item := get(id)

    switch _ in item {
    case FnDec:         resolve_fn_dec_item(s, id);
    case:               panic("impl")
    }
}
new_scope :: proc(parent:^Scope=nil) -> Scope {
    s := Scope{}
    s.objects       = make(map[string]ObjId,  allocator=context.allocator);
    s.types         = make(map[string]TypeId, allocator=context.allocator);
    s.items         = make(map[string]ItemId, allocator=context.allocator);
    s.parent = parent;
    return s;
}
new_module_scope :: proc() -> ModuleScope {
    s := ModuleScope{}
    s.scope = new_scope()
    s.obj_foreward  = make(map[string]ObjId,  allocator=context.allocator);
    s.ty_foreward   = make(map[string]TypeId, allocator=context.allocator);
    return s
}
free_scope :: proc(s: ^Scope) {
    if s == nil do return;

    delete(s.objects);
    delete(s.types);
    delete(s.items);

    s^ = {};
}

free_module_scope :: proc(s: ^ModuleScope) {
    if s == nil do return;

    free_scope(&s.scope);

    delete(s.obj_foreward);
    delete(s.ty_foreward);

    s^ = {};
}
resolve_module_ast :: proc(ast: ^AST) {
    global_scope := new_module_scope()

    for id in ast.items {
        forward_item(&global_scope, id)
    }

    for id in ast.items {
        resolve_item(&global_scope, id)
    }
    free_module_scope(&global_scope)
}

