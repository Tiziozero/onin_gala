; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
; external functions (declare, not define)
declare i32 @printf(ptr, ...)
declare ptr @malloc(i64)
declare void @free(ptr)
define i64 @main () {
entry:
	%a = alloca i64
	store i64 0, ptr %a
	%t1 = load i64, ptr %a
	%cond2 = icmp ne i64 %t1, 0
	br i1 %cond2, label %base_block_label2, label %end_label2
base_block_label2:
	ret i64 4
	br label %end_label2
end_label2:
	ret i64 3
}
