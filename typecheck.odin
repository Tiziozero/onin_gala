package main
import "core:fmt"
TcContext :: struct {
    fn: Maybe(FnDec),
}
tc_expr :: proc(tc: ^TcContext, e: ExprId) {
    switch expr in get(e) {
    case Symbol: {
        obj := get_ctx().expr_objects[e];
             get_ctx().expr_types[e] = get_obj(obj).type
    }
    case Number: {
        fmt.println("impl")
    }
    case Binop:{
        fmt.println("impl")
    }
    case: panic("impl tc expr")
    }
}
tc_stmt :: proc(tc: ^TcContext, s: StmtId) {
    switch stmt in get_stmt(s) {
    case VarDec: {
        tc_expr(tc, stmt.value)
    }
    case: panic("impl");
    }
}
tc_block :: proc(tc: ^TcContext, b: Block) {
    for s in b.stmts {
        tc_stmt(tc, s)
    }
}
tc_item :: proc(tc: ^TcContext, i: ItemId) {
    item := get_item(i)
    switch i in item {
    case FnDec: {
        prev_tc_fn := tc.fn;
        tc.fn = i;
        tc_block(tc, i.block);
        tc.fn = prev_tc_fn;
    }
    case: panic("impl")
    }
}
typecheck_module :: proc(ast: ^AST) {
    tc := TcContext{fn=nil}
    for i in ast.items {
        tc_item(&tc, i);
    }
}
