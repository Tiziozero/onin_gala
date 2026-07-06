; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
; external functions (declare, not define)
declare i32 @printf(ptr, ...)
declare ptr @malloc (i64 %size)
declare void @free (ptr %size)
define i64 @main () {
entry:
	%t1 = call ptr @malloc(i64 8)
	%ptr = alloca ptr
	store ptr %t1, ptr %ptr
	%t2 = load ptr, ptr %ptr
	call void @free(ptr %t2)
	ret i64 0
}
