; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
; external functions (declare, not define)
declare i32 @printf(ptr, ...)
declare ptr @malloc(i64)
declare void @free(ptr)
define i32 @main () {
entry:
	%t2 = add i32 5, 3
	%i32 = %t2 %!(MISSING ARGUMENT)
	%t3 = load i32, ptr %v
	ret i32 %t3
}
