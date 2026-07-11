; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
%vec2 = type {double,%abc}
%abc = type {i64,double}
define i64 @main () {
entry:
	%t1 = insertvalue %abc undef, i64 7, 0
	%t2 = insertvalue %abc %t1, double 3.0, 1
	%t3 = insertvalue %vec2 undef, double 2.9, 0
	%t4 = insertvalue %abc undef, i64 7, 0
	%t5 = insertvalue %abc %t4, double 3.0, 1
	%t6 = insertvalue %vec2 %t3, %abc %t5, 1
	%v = alloca %vec2
	store %vec2 %t6, ptr %v
	%t7 = getelementptr inbounds %vec2, ptr %v, i32 0, i32 0
	store double 9.1, ptr %t7
	%t8 = load %vec2, ptr %v
	%t9 = extractvalue %vec2 %t8, 0
	%t10 = fptosi double %t9 to i64
	%t11 = getelementptr inbounds %vec2, ptr %v, i32 0, i32 1
	%t12 = getelementptr inbounds %abc, ptr %t11, i32 0, i32 0
	store i64 %t10, ptr %t12
	%t13 = insertvalue %abc undef, i64 1, 0
	%t14 = insertvalue %abc %t13, double 1.2, 1
	%x = alloca %abc
	store %abc %t14, ptr %x
	%t15 = load %vec2, ptr %v
	%t16 = extractvalue %vec2 %t15, 1
	%t17 = load %abc, ptr %x
	%t18 = call %abc @abc_add(%abc %t16, %abc %t17)
	%t19 = getelementptr inbounds %vec2, ptr %v, i32 0, i32 1
	store %abc %t18, ptr %t19
	%t20 = load %vec2, ptr %v
	%t21 = extractvalue %vec2 %t20, 1
	%t22 = extractvalue %abc %t21, 0
	ret i64 %t22
}
define %abc @abc_add (%abc %a, %abc %b) {
entry:
	%t23 = extractvalue %abc %a, 0
	%t24 = extractvalue %abc %b, 0
	%t25 = add i64 %t23, %t24
	%a1 = alloca i64
	store i64 %t25, ptr %a1
	%t26 = extractvalue %abc %a, 1
	%t27 = extractvalue %abc %b, 1
	%t28 = fadd double %t26, %t27
	%b1 = alloca double
	store double %t28, ptr %b1
	%t29 = load i64, ptr %a1
	%t30 = load double, ptr %b1
	%t31 = load i64, ptr %a1
	%t32 = insertvalue %abc undef, i64 %t31, 0
	%t33 = load double, ptr %b1
	%t34 = insertvalue %abc %t32, double %t33, 1
	ret %abc %t34
}
