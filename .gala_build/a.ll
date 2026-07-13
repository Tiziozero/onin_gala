; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
declare void @free (ptr %ptr)
declare ptr @calloc (i64 %n, i64 %size)
declare void @memcpy (ptr %dst, ptr %src, i64 %size)
%v2 = type {double,double}
define i64 @main () {
entry:
	%i = alloca i64
	store i64 10, ptr %i

	%buf = alloca [1024 x i8]
	store [1024 x i8] zeroinitializer, ptr %buf

	%t1 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 3, ptr %t1

	call void @b(ptr %buf)

	%t2 = getelementptr inbounds i8, ptr %buf, i64 2
	%t3 = load i8, ptr %t2
	%t4 = zext i8 %t3 to i64
	ret i64 %t4

}
define void @b (ptr %buf) {
entry:
	%t5 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 68, ptr %t5

	ret void

}
define void @c (ptr %v) {
entry:
	%t6 = getelementptr inbounds %v2, ptr %v, i32 0, i32 0
	store double 1.0, ptr %t6

	ret void

}
define void @d (ptr %v) {
entry:
	%t7 = fptosi double 1.0 to i64
	store i64 %t7, ptr %v

	ret void

}
