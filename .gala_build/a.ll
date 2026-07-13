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
	%i = alloca i64
	store i64 10, ptr %i

	; cg_stmt "bbuf := [1024]byte{};"
	%bbuf = alloca [1024 x i8]
	store [1024 x i8] zeroinitializer, ptr %bbuf

	; cg_stmt "buf : ^[1024]byte = cast(^[1024]byte)malloc(1024);"
	%t1 = call ptr @malloc(i64 1024)
	%t2 = bitcast ptr %t1 to ptr
	%buf = alloca ptr
	store ptr %t2, ptr %buf

	; cg_stmt "memcpy(cast(rawptr)buf, cast(rawptr)&bbuf[0], 1024)"
	%t3 = load ptr, ptr %buf
	%t4 = bitcast ptr %t3 to ptr
	; cg_addr "bbuf[0]"
	; for index addr, cg_elem_ptr
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: [1024]byte
	; cg_addr "bbuf"
	%t5 = getelementptr inbounds i8, ptr %bbuf, i64 0
	%t6 = bitcast ptr %t5 to ptr
	call void @memcpy(ptr %t4, ptr %t6, i64 1024)

	; cg_stmt "buf^[2] = 3;"
	; cg_addr "buf^[2]"
	; for index addr, cg_elem_ptr
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: [1024]byte
	; cg_addr "buf^"
	%t7 = load ptr, ptr %buf
	%t8 = load ptr, ptr %t7
	%t9 = getelementptr inbounds i8, ptr %t8, i64 2
	store i8 3, ptr %t9

	; cg_stmt "b(buf)"
	%t10 = load ptr, ptr %buf
	call void @b(ptr %t10)

	; cg_stmt "return cast(int)buf^[2];"
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: [1024]byte
	; cg_addr "buf^"
	%t11 = load ptr, ptr %buf
	%t12 = load ptr, ptr %t11
	%t13 = getelementptr inbounds i8, ptr %t12, i64 2
	%t14 = load i8, ptr %t13
	%t15 = zext i8 %t14 to i64
	ret i64 %t15

}
define void @b (ptr %buf) {
entry:
	; cg_stmt "buf^[2] = 67;"
	; cg_addr "buf^[2]"
	; for index addr, cg_elem_ptr
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: [1024]byte
	; cg_addr "buf^"
	%t16 = load ptr, ptr %buf
	%t17 = getelementptr inbounds i8, ptr %t16, i64 2
	store i8 67, ptr %t17

	; cg_stmt "return;"
	ret void

}
