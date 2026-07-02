package main

import "core:fmt"
TypeKind :: enum {
    Invalid,
    UntypedInteger,
    UntypedFloat,
    Function,
    Integer,
    Float,
    Rune,
    Byte,
    Bool,
    Pointer,
    Void,
}
Arg :: struct {
    name: string,
    type: TypeId
}
Type :: struct {
    name: string,
    kind: TypeKind,
    ptr: TypeId,
    fn: struct { args: []Arg, ret_ty: TypeId},
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
    items:          map[string]ItemId,
    parent:         ^Scope,
}
ModuleScope :: struct {
    using scope: Scope,
}
name_exists :: proc(scope: ^Scope, n: string) -> bool {
    s := scope
    for s != nil {
        _, ok := s.types[n];            if ok do return true
        _, ok  = s.objects[n];          if ok do return true
        _, ok  = s.ty_foreward[n];      if ok do return true
        _, ok  = s.obj_foreward[n];     if ok do return true
        s = s.parent
    }
    return false
}
new_object :: proc(s: ^Scope, o: Object) -> ObjId {
    ctx := get_ctx()
    assert(o.kind != .Invalid);
    assert(len(o.name) > 0);

    // make sure they're not already declared
    assert(!name_exists(s, o.name));

    append(&ctx.objs, o);
    id := ObjId(len(ctx.objs)-1);
    s.objects[o.name] = id
    fmt.println("new object:", o.name, o.kind);
    return id
}
new_type :: proc(s: ^Scope, t: Type) -> TypeId {
    ctx := get_ctx();
    assert(t.kind != .Invalid);
    assert(len(t.name) > 0);

    // make sure it doesn't exist
    assert(!name_exists(s, t.name));

    append(&ctx.types, t);
    id := TypeId(len(ctx.types)-1);  // allocate type
    s.types[t.name] = id
    return id
}
new_object_fd :: proc(s: ^ModuleScope, o: Object) -> ObjId {
    ctx := get_ctx()
    assert(o.kind != .Invalid);
    assert(len(o.name) > 0);

    // make sure it doesn't exist
    assert(!name_exists(s, o.name));

    append(&ctx.objs, o);
    id := ObjId(len(ctx.objs)-1);
    s.obj_foreward[o.name] = id
    return id
}
new_type_fd :: proc(s: ^ModuleScope, t: Type) -> TypeId {
    ctx := get_ctx()
    assert(t.kind != .Invalid);
    assert(len(t.name) > 0);

    // make sure it doesn't exist
    assert(!name_exists(s, t.name));

    append(&ctx.types, t);
    id := TypeId(len(ctx.types)-1); 
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
        obj, ok := scope_get_object(s, e.name);
        if !ok {
            fmt.println("Couldn't find", e.name, "in scope.");
            assert(ok)
        }
        get_ctx().expr_objects[id] = obj
    }
    case FnCall: {
        resolve_expr(s, e.target);
        for a in e.args {
            resolve_expr(s, a);
        }
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
    assert(t.kind == .Pointer || t.kind == .Function || 
            t.kind == .UntypedInteger || t.kind == .UntypedFloat)
    for ty, id in get_ctx().types {
        if cmp_types(ty, t) { return TypeId(id) }
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
    fmt.println(n)

    fmt.println("existing:")
    t := s;
    for t != nil {
        for ty in s.types {
            fmt.println(ty)
        }
        fmt.println("scope:", t.parent)
        t = t.parent
    }
    return 0, false
}
resolve_type_specifier :: proc(s: ^Scope, t: TypeSpecifier) -> TypeId {
    switch k in t {
    case BaseType: { // will get declared type id
        ty, ok := scope_get_type(s, string(k));
        assert(ok)
        return ty
    }
    case PointerType: { // creates a pointer and will ge that one
        id := resolve_type_specifier(s, k^)
        return intern_type({kind=.Pointer, ptr=id})
    }
    case: panic("impl");
    }
}
get_untyped_default :: proc(t: TypeId) -> TypeId {
    #partial switch get_type(t).kind {
    case .UntypedInteger: {
        fmt.println("returning int for untyped int");
        v, ok := get_ctx().base_mod.types["int"]; assert(ok);
        return v
    }
    case .UntypedFloat: {
        fmt.println("returning float for untyped float");
        v, ok := get_ctx().base_mod.types["flt"]; assert(ok);
        return v
    }

    case: panic("impl");
    }
}
propagate_type :: proc(ty: TypeId, expr: ExprId) {
    fmt.println("propagating:", get_type(ty), "to", get_expr(expr));
    switch e in get_expr(expr) {
    case Binop: {
        propagate_type(ty, e.left)
        propagate_type(ty, e.right)
    }
    case Number: {
    }
    case Symbol: {
    }
    case FnCall: {
    }
    case: panic("impl");
    }
    // set to all
    get_ctx().expr_types[expr] = ty;
}
resolve_stmt :: proc(s: ^Scope, id: StmtId) {
    #partial switch stmt in get(id) {
    case VarDec: {
        resolve_expr(s, stmt.value);
        resolved_ty : Maybe(TypeId) = nil
        if stmt.type != nil {
            ty, ok := stmt.type.(TypeSpecifier); assert(ok);
            resolved_ty = resolve_type_specifier(s, ty);
        }
        oid := new_object(s, Object{kind=.Variable, name=stmt.name, type=resolved_ty})
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
        b = stmt.else_block
        resolve_block(s, &b)
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
void_type :: proc() -> TypeId {
    v, ok := get_ctx().base_mod.types["void"];
    assert(ok);
    return v;
}
resolve_fn_dec_item :: proc(s: ^ModuleScope, id: ItemId) {
    fndec, ok := get(id).(FnDec); assert(ok); // assert it's a fn dec
    oid, ook := s.obj_foreward[fndec.name]; assert(ook); // make sure fd exists
    obj := get(oid); // gets pointer, so modify that

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
    args := make([]Arg, len(fndec.args), allocator=context.temp_allocator)
    declared := make(map[string]Arg)
    for a, i in fndec.args {
        t := resolve_type_specifier(&new_scope, a.t)
        if da, ok := declared[a.name]; ok {
            fmt.println(a, da);
            panic("arg already exists")
        }
        args[i] = Arg{a.name, t}
        declared[a.name] = Arg{a.name, t}
        new_object(&new_scope, Object{.Argument, a.name, t});
    }
    fnty.fn.args = args
    // impl
    resolve_block(&new_scope, &fndec.block);
    // free args scope
    free_scope(&new_scope);


    // intern type
    tyid := intern_type(fnty);

    obj.type = tyid
    obj.name = fndec.name;

    delete_key(&s.obj_foreward, fndec.name); // delete fd and create object
    s.objects[fndec.name] = oid; // recreate link
    get_ctx().item_objects[id] = oid;
}
forward_item :: proc(s: ^ModuleScope, id: ItemId) {
    item := get(id)
    // foreward
    switch i in item {
    case FnDec:         new_object_fd(s, Object{kind=.Variable, name=i.name});
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
new_module_scope :: proc(parent:^Scope=nil) -> ModuleScope {
    s := ModuleScope{}
    s.scope = new_scope()
    s.parent = parent
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
    global_scope := new_module_scope(&get_ctx().base_mod)

    for id in ast.items {
        forward_item(&global_scope, id)
    }

    for id in ast.items {
        resolve_item(&global_scope, id)
    }
    free_module_scope(&global_scope)
}

