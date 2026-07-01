; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
; external functions (declare, not define)
declare i32 @printf(ptr, ...)
declare ptr @malloc(i64)
declare void @free(ptr)
define i64 @main (i64 %argc, i64 %argv) {
entry:
	%t1 = sub i64 %argc, 1
	%a = alloca i64
	store i64 %t1, ptr %a
	%t2 = load i64, ptr %a
	%cond3 = icmp ne i64 %t2, 0
	br i1 %cond3, label %base_block_label3, label %end_label3
base_block_label3:
	ret i64 0
	br label %end_label3
end_label3:
	%t4 = call i64 @b(i64 %argc)
	ret i64 %t4
}
define i64 @b (i64 %i) {
entry:
	%t5 = add i64 %i, 67
	ret i64 %t5
}
