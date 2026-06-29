; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
; external functions (declare, not define)
declare i32 @printf(ptr, ...)
declare ptr @malloc(i64)
declare void @free(ptr)
define i64 @main () {
entry:
	%t1 = call double @fib()
	%t2 = fadd double 5.0, 3.0
	%t3 = fsub double %t2, %t1
	%t4 = call i64 @smth()
	%t5 = add i64 %t4, 7
	ret i64 %t5
}
define double @fib () {
entry:
	ret double 6.0
}
define i64 @smth () {
entry:
	ret i64 6
}
