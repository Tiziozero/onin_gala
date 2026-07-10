; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
%vec2 = type {%abc,double}
%abc = type {i64,double}
define i64 @main () {
entry:
	%t1 = insertvalue %abc undef, i64 7, 0
	%t2 = insertvalue %abc %t1, double 3.0, 1
	%t3 = insertvalue %abc undef, i64 7, 0
	%t4 = insertvalue %abc %t3, double 3.0, 1
	%t5 = insertvalue %vec2 undef, %abc %t4, 0
	%t6 = insertvalue %vec2 %t5, double 2.9, 1
	%v = alloca %vec2
	store %vec2 %t6, ptr %v
	%t7 = getelementptr inbounds %vec2, ptr %v, i32 0, i32 1
	store double 9.1, ptr %t7
	%t8 = load %vec2, ptr %v
	%t9 = extractvalue %vec2 %t8, 1
	%t10 = fptosi double %t9 to i64
	ret i64 %t10
}
