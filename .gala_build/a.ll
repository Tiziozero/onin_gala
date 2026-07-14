; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
@tstring1 = private unnamed_addr constant [15 x i8] c"Hello, World!\0A\00", align 1

declare void @abc ()
declare void @printf (ptr %fmt, ...)
define void @print ({ ptr, i64 } %fmt) {
entry:
	; cg_stmt "printf(transmute(^byte)&fmt[0])"
	; cg_expr "printf(transmute(^byte)&fmt[0])"
	; cg_expr "transmute(^byte)&fmt[0]"
	; cg_expr "&fmt[0]"
	; cg_addr "fmt[0]"
	; for index addr, cg_elem_ptr
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: String
	; cg_expr "fmt"
	%t2 = extractvalue { ptr, i64 } %fmt, 0
	; cg_expr "0"
	%t3 = getelementptr inbounds i8, ptr %t2, i64 0
	%t4 = alloca ptr
	store ptr %t3, ptr %t4
	%t5 = load ptr, ptr %t4
	call void (ptr, ...)@printf(ptr %t5)

	; cg_stmt "return;"
	ret void

}
declare ptr @malloc (i64 %size)
declare void @memcpy (ptr %dest, ptr %src, i64 %size)
define i64 @main () {
entry:
	; cg_stmt "s := "Hello, World!\n";"
	; cg_expr ""Hello, World!\n""
	%t6 = getelementptr inbounds [15 x i8], ptr @tstring1, i64 0, i64 0
	%t7 = insertvalue { ptr, i64 } undef, ptr %t6, 0
	%t8 = insertvalue { ptr, i64 } %t7, i64 14, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t8, ptr %s

	; cg_stmt "buf := [1024]byte{};"
	; cg_expr "[1024]byte{}"
	%buf = alloca [1024 x i8]
	store [1024 x i8] zeroinitializer, ptr %buf

	; cg_stmt "print(s)"
	; cg_expr "print(s)"
	; cg_expr "s"
	%t9 = load { ptr, i64 }, ptr %s
	call void @print({ ptr, i64 } %t9)

	; cg_stmt "return 0;"
	; cg_expr "0"
	ret i64 0

}
