; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
declare void @free (ptr %ptr)
declare ptr @malloc (i64 %size)
declare void @memcpy (ptr %dst, ptr %src, i64 %size)
%v2 = type {double,double}
define i64 @main () {
entry:
	; cg_stmt "i := 10;"
	; cg_expr "10"
	%i = alloca i64
	store i64 10, ptr %i

	; cg_stmt "bbuf := [1024]byte{};"
	; cg_expr "[1024]byte{}"
	%bbuf = alloca [1024 x i8]
	store [1024 x i8] zeroinitializer, ptr %bbuf

	; cg_stmt "buf : ^[1024]byte = cast(^[1024]byte)malloc(1024);"
	; cg_expr "cast(^[1024]byte)malloc(1024)"
	; cg_expr "malloc(1024)"
	; cg_expr "1024"
	%t1 = call ptr @malloc(i64 1024)
	%t2 = bitcast ptr %t1 to ptr
	%buf = alloca ptr
	store ptr %t2, ptr %buf

	; cg_stmt "memcpy(cast(rawptr)buf, cast(rawptr)&bbuf[0], 1024)"
	; cg_expr "memcpy(cast(rawptr)buf, cast(rawptr)&bbuf[0], 1024)"
	; cg_expr "cast(rawptr)buf"
	; cg_expr "buf"
	%t3 = load ptr, ptr %buf
	%t4 = bitcast ptr %t3 to ptr
	; cg_expr "cast(rawptr)&bbuf[0]"
	; cg_expr "&bbuf[0]"
	; cg_addr "bbuf[0]"
	; for index addr, cg_elem_ptr
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: [1024]byte
	; cg_addr "bbuf"
	; cg_expr "0"
	%t5 = getelementptr inbounds i8, ptr %bbuf, i64 0
	%t6 = bitcast ptr %t5 to ptr
	; cg_expr "1024"
	call void @memcpy(ptr %t4, ptr %t6, i64 1024)

	; cg_stmt "buf^[2] = 3;"
	; cg_expr "3"
	; cg_addr "buf^[2]"
	; for index addr, cg_elem_ptr
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: [1024]byte
	; cg_addr "buf^"
	; cg_expr "buf"
	%t7 = load ptr, ptr %buf
	; cg_expr "2"
	%t9 = getelementptr inbounds i8, ptr %t7, i64 2
	store i8 3, ptr %t9

	; cg_stmt "b(buf)"
	; cg_expr "b(buf)"
	; cg_expr "buf"
	%t10 = load ptr, ptr %buf
	call void @b(ptr %t10)

	; cg_stmt "v := v2{x=0.0, y=0.0};"
	; cg_expr "v2{x=0.0, y=0.0}"
	; cg_expr "0.0"
	; cg_expr "0.0"
	; cg_expr "0.0"
	%t11 = insertvalue %v2 undef, double 0.0, 0
	; cg_expr "0.0"
	%t12 = insertvalue %v2 %t11, double 0.0, 1
	%v = alloca %v2
	store %v2 %t12, ptr %v

	; cg_stmt "c(&v)"
	; cg_expr "c(&v)"
	; cg_expr "&v"
	; cg_addr "v"
	call void @c(ptr %v)

	; cg_stmt "return cast(int)(v.x*v.y);"
	; cg_expr "cast(int)(v.x*v.y)"
	; cg_expr "(v.x*v.y)"
	; cg_expr "v.x"
	; cg_expr "v"
	%t13 = load %v2, ptr %v
	%t14 = extractvalue %v2 %t13, 0
	; cg_expr "v.y"
	; cg_expr "v"
	%t15 = load %v2, ptr %v
	%t16 = extractvalue %v2 %t15, 1
	%t17 = fmul double %t14, %t16
	%t18 = fptosi double %t17 to i64
	ret i64 %t18

}
define void @b (ptr %buf) {
entry:
	; cg_stmt "buf^[2] = 67;"
	; cg_expr "67"
	; cg_addr "buf^[2]"
	; for index addr, cg_elem_ptr
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: [1024]byte
	; cg_addr "buf^"
	; cg_expr "buf"
	; cg_expr "2"
	%t20 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 67, ptr %t20

	; cg_stmt "return;"
	ret void

}
define void @c (ptr %v) {
entry:
	; cg_stmt "v^.x = 1.2;"
	; cg_expr "1.2"
	; cg_addr "v^.x"
	; cg_addr "v^"
	; cg_expr "v"
	%t22 = getelementptr inbounds %v2, ptr %v, i32 0, i32 0
	store double 1.2, ptr %t22

	; cg_stmt "v^.y = 3.14159;"
	; cg_expr "3.14159"
	; cg_addr "v^.y"
	; cg_addr "v^"
	; cg_expr "v"
	%t24 = getelementptr inbounds %v2, ptr %v, i32 0, i32 1
	store double 3.14159, ptr %t24

	; cg_stmt "return;"
	ret void

}
