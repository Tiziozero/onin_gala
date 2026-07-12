; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
%v2 = type {double,double}
define i64 @main () {
entry:
	%v = alloca [1024 x %v2]
	store [1024 x %v2] zeroinitializer, ptr %v

	%t1 = sub nsw nuw i64 11, 10
	%t2 = getelementptr inbounds %v2, ptr %v, i64 10
	%t3 = insertvalue { ptr, i64 } undef, ptr %t2, 0
	%t4 = insertvalue { ptr, i64 } %t3, i64 %t1, 1
	%a = alloca { ptr, i64 }
	store { ptr, i64 } %t4, ptr %a

	%t5 = insertvalue %v2 undef, double 0.0, 0
	%t6 = insertvalue %v2 %t5, double 3.0, 1
	%t7 = load { ptr, i64 }, ptr %a
	%t8 = extractvalue { ptr, i64 } %t7, 0
	%t9 = getelementptr inbounds %v2, ptr %t8, i64 0
	store %v2 %t6, ptr %t9

	%t10 = getelementptr inbounds %v2, ptr %v, i64 10
	%t11 = load %v2, ptr %t10
	%t12 = extractvalue %v2 %t11, 1
	%t13 = fptosi double %t12 to i64
	ret i64 %t13

}
