; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
%Color = type {i8,i8,i8,i8}
@tstring1 = private unnamed_addr constant [18 x i8] c"Hello, World! %d\0A\00", align 1

@tstring2 = private unnamed_addr constant [26 x i8] c"Hello, Raylib from Gala!!\00", align 1

declare void @printf (ptr %fmt, ...)
declare ptr @calloc (i64 %n, i64 %size)
declare void @memcpy (ptr %dest, ptr %src, i64 %size)
declare void @free (ptr %ptr)
declare void @InitWindow (i64 %width, i64 %height, ptr %title)
declare void @CloseWindow ()
declare i1 @WindowShouldClose ()
declare void @BeginDrawing ()
declare void @EndDrawing ()
declare void @ClearBackground (%Color %color)
define ptr @to_cstr ({ ptr, i64 } %s) {
entry:
	%t3 = extractvalue { ptr, i64 } %s, 1
	%t4 = mul i64 %t3, 1
	%size = alloca i64
	store i64 %t4, ptr %size

	%t5 = load i64, ptr %size
	%t6 = add i64 %t5, 1
	%t7 = call ptr @calloc(i64 1, i64 %t6)
	%cstr = alloca ptr
	store ptr %t7, ptr %cstr

	%t8 = load ptr, ptr %cstr
	%t9 = extractvalue { ptr, i64 } %s, 0
	%t10 = getelementptr inbounds i8, ptr %t9, i64 0
	%t11 = alloca ptr
	store ptr %t10, ptr %t11
	%t12 = load ptr, ptr %t11
	%t13 = load i64, ptr %size
	call void @memcpy(ptr %t8, ptr %t12, i64 %t13)

	%t14 = load ptr, ptr %cstr
	%t15 = bitcast ptr %t14 to ptr
	ret ptr %t15

}
define i64 @main () {
entry:
	%t16 = getelementptr inbounds [18 x i8], ptr @tstring1, i64 0, i64 0
	%t17 = insertvalue { ptr, i64 } undef, ptr %t16, 0
	%t18 = insertvalue { ptr, i64 } %t17, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t18, ptr %s

	%t19 = load { ptr, i64 }, ptr %s
	%t20 = call ptr @to_cstr({ ptr, i64 } %t19)
	%data = alloca ptr
	store ptr %t20, ptr %data

	%t21 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t21, i64 9)

	%t22 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t22, i64 8)

	%t23 = getelementptr inbounds [26 x i8], ptr @tstring2, i64 0, i64 0
	%t24 = insertvalue { ptr, i64 } undef, ptr %t23, 0
	%t25 = insertvalue { ptr, i64 } %t24, i64 25, 1       
	%t26 = call ptr @to_cstr({ ptr, i64 } %t25)
	%name = alloca ptr
	store ptr %t26, ptr %name

	%t27 = load ptr, ptr %name
	call void @InitWindow(i64 800, i64 600, ptr %t27)

	br i1 1, label %base_block_label28, label %end_label28
base_block_label28:
	%t29 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t29, i64 8)

	br label %end_label28
end_label28:

	br label %while_cond_label30
while_cond_label30:
	%t31 = call i1 @WindowShouldClose()
	%t32 = icmp eq i1 0, %t31
	br i1 %t32, label %while_body_label30, label %while_end_label30
while_body_label30:
	call void @BeginDrawing()

	%t33 = insertvalue %Color undef, i8 255, 0
	%t34 = insertvalue %Color %t33, i8 255, 1
	%t35 = insertvalue %Color %t34, i8 255, 2
	%t36 = insertvalue %Color %t35, i8 255, 3
	%t37 = alloca %Color
	store %Color %t36, ptr %t37
	%t38 = load i64, ptr %t37
	call void @ClearBackground(i64 %t38)

	call void @EndDrawing()

	br label %while_cond_label30
while_end_label30:

	call void @CloseWindow()

	%t39 = load ptr, ptr %data
	%t40 = bitcast ptr %t39 to ptr
	call void @free(ptr %t40)

	%t41 = load ptr, ptr %name
	%t42 = bitcast ptr %t41 to ptr
	call void @free(ptr %t42)

	%t43 = load { ptr, i64 }, ptr %s
	%t44 = extractvalue { ptr, i64 } %t43, 1
	ret i64 %t44

}
