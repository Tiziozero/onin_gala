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
	%t2 = load i64, ptr %a
	%t3 = icmp eq i64 %t2, 0
	br i1 %t3, label %base_block_label1, label %alt_cond_label1_0
base_block_label1:
	ret i64 1
alt_cond_label1_0:
	%t4 = load i64, ptr %a
	%t5 = icmp eq i64 %t4, 1
	br i1 %t5, label %alt_block_label1_0, label %else_block_label1
alt_block_label1_0:
	ret i64 2
else_block_label1:
	ret i64 0
end_label1:
}
