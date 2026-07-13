; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
@tstring1 = private unnamed_addr constant [14 x i8] c"Hello, World!\00", align 1

define i64 @main () {
entry:
	; cg_stmt "s := "Hello, World!";"
	; cg_expr ""Hello, World!""
	%t2 = getelementptr inbounds [14 x i8], ptr @tstring1, i64 0, i64 0
	%t3 = insertvalue { ptr, i64 } undef, ptr %t2, 0
	%t4 = insertvalue { ptr, i64 } %t3, i64 13, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t4, ptr %s

	; cg_stmt "stringer(s[0:13])"
	; cg_expr "stringer(s[0:13])"
	; cg_expr "s[0:13]"
	; cg_expr "0"
	; cg_expr "13"
	%t5 = sub nsw nuw i64 13, 0
	; cg_data_ptr expr tye: String
	; cg_expr "s"
	%t6 = load { ptr, i64 }, ptr %s
	%t7 = extractvalue { ptr, i64 } %t6, 0
	%t8 = getelementptr inbounds i8, ptr %t7, i64 0
	%t9 = insertvalue { ptr, i64 } undef, ptr %t8, 0
	%t10 = insertvalue { ptr, i64 } %t9, i64 %t5, 1
	call void @stringer({ ptr, i64 } %t10)

	; cg_stmt "return cast(int)s[0];"
	; cg_expr "cast(int)s[0]"
	; cg_expr "s[0]"
	; get_elem_ptr gens:
	; cg_data_ptr expr tye: String
	; cg_expr "s"
	%t11 = load { ptr, i64 }, ptr %s
	%t12 = extractvalue { ptr, i64 } %t11, 0
	; cg_expr "0"
	%t13 = getelementptr inbounds i8, ptr %t12, i64 0
	%t14 = load i8, ptr %t13
	%t15 = zext i8 %t14 to i64
	ret i64 %t15

}
define void @stringer ({ ptr, i64 } %s) {
entry:
	; cg_stmt "return;"
	ret void

}
