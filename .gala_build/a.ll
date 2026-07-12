; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
declare void @free (ptr %ptr)
declare ptr @calloc (i64 %n, i64 %size)
declare void @memcpy (ptr %dst, ptr %src, i64 %size)
%v2 = type {double,double}
define i64 @main () {
entry:
	%i = alloca double
	store double 10.2, ptr %i

	%buf = alloca [1024 x i8]
	store [1024 x i8] zeroinitializer, ptr %buf

	%t1 = load double, ptr %i
	%t2 = bitcast double %t1 to i64
	ret i64 %t2

}
define void @b (ptr %buf) {
entry:
	ret void

}
