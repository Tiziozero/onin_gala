; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
define i64 @main () {
entry:
	%v = alloca [1024 x i8]
	store [1024 x i8] zeroinitializer, ptr %v

	%t1 = sub nsw nuw i64 11, 10
	%t2 = getelementptr inbounds i8, ptr %v, i64 10
	%t3 = insertvalue { ptr, i64 } undef, ptr %t2, 0
	%t4 = insertvalue { ptr, i64 } %t3, i64 %t1, 1
	%a = alloca { ptr, i64 }
	store { ptr, i64 } %t4, ptr %a

	%t5 = load { ptr, i64 }, ptr %a
	%t6 = extractvalue { ptr, i64 } %t5, 0
	%t7 = getelementptr inbounds i8, ptr %t6, i64 0
	store i8 10, ptr %t7

	%t8 = getelementptr inbounds i8, ptr %v, i64 10
	%t9 = load i8, ptr %t8
	%t10 = zext i8 %t9 to i64
	ret i64 %t10

}
