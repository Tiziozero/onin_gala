; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"
%Color = type {i8,i8,i8,i8}
@tstring1 = private unnamed_addr constant [18 x i8] c"Hello, World! %d\0A\00", align 1

@tstring2 = private unnamed_addr constant [26 x i8] c"Hello, Raylib from Gala!!\00", align 1

@tstring3 = private unnamed_addr constant [7 x i8] c"r: %d\0A\00", align 1

@tstring4 = private unnamed_addr constant [7 x i8] c"g: %d\0A\00", align 1

@tstring5 = private unnamed_addr constant [7 x i8] c"b: %d\0A\00", align 1

@tstring6 = private unnamed_addr constant [7 x i8] c"a: %d\0A\00", align 1

@tstring7 = private unnamed_addr constant [11 x i8] c"GetColor:\0A\00", align 1

@tstring8 = private unnamed_addr constant [8 x i8] c"\09r: %d\0A\00", align 1

@tstring9 = private unnamed_addr constant [8 x i8] c"\09g: %d\0A\00", align 1

@tstring10 = private unnamed_addr constant [8 x i8] c"\09b: %d\0A\00", align 1

@tstring11 = private unnamed_addr constant [8 x i8] c"\09a: %d\0A\00", align 1

declare void @printf (ptr %fmt, ...)
declare ptr @calloc (i64 %n, i64 %size)
declare void @memcpy (ptr %dest, ptr %src, i64 %size)
declare void @free (ptr %ptr)
declare void @InitWindow (i64 %width, i64 %height, ptr %title)
declare void @CloseWindow ()
declare i1 @WindowShouldClose ()
declare void @BeginDrawing ()
declare void @EndDrawing ()
declare void @ClearBackground (i64 %color)
declare i64 @GetColor (i32 %v)
define ptr @to_cstr ({ ptr, i64 } %s) {
entry:
	%t12 = extractvalue { ptr, i64 } %s, 1
	%t13 = mul i64 %t12, 1
	%size = alloca i64
	store i64 %t13, ptr %size

	%t14 = load i64, ptr %size
	%t15 = add i64 %t14, 1
	%t16 = call ptr @calloc(i64 1, i64 %t15)
	%cstr = alloca ptr
	store ptr %t16, ptr %cstr

	%t17 = load ptr, ptr %cstr
	%t18 = extractvalue { ptr, i64 } %s, 0
	%t19 = getelementptr inbounds i8, ptr %t18, i64 0
	%t20 = alloca ptr
	store ptr %t19, ptr %t20
	%t21 = load ptr, ptr %t20
	%t22 = load i64, ptr %size
	call void @memcpy(ptr %t17, ptr %t21, i64 %t22)

	%t23 = load ptr, ptr %cstr
	%t24 = bitcast ptr %t23 to ptr
	ret ptr %t24

}
define void @printf_slice ({ ptr, i64 } %s, i64 %n) {
entry:
	%t25 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t25, ptr %data

	%t26 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t26, i64 %n)

	%t27 = load ptr, ptr %data
	%t28 = bitcast ptr %t27 to ptr
	call void @free(ptr %t28)

	ret void

}
define i64 @main () {
entry:
	%t29 = getelementptr inbounds [18 x i8], ptr @tstring1, i64 0, i64 0
	%t30 = insertvalue { ptr, i64 } undef, ptr %t29, 0
	%t31 = insertvalue { ptr, i64 } %t30, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t31, ptr %s

	%t32 = load { ptr, i64 }, ptr %s
	%t33 = call ptr @to_cstr({ ptr, i64 } %t32)
	%data = alloca ptr
	store ptr %t33, ptr %data

	%t34 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t34, i64 9)

	%t35 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t35, i64 8)

	%t36 = getelementptr inbounds [26 x i8], ptr @tstring2, i64 0, i64 0
	%t37 = insertvalue { ptr, i64 } undef, ptr %t36, 0
	%t38 = insertvalue { ptr, i64 } %t37, i64 25, 1       
	%t39 = call ptr @to_cstr({ ptr, i64 } %t38)
	%name = alloca ptr
	store ptr %t39, ptr %name

	%t40 = insertvalue %Color undef, i8 123, 0
	%t41 = insertvalue %Color %t40, i8 222, 1
	%t42 = insertvalue %Color %t41, i8 255, 2
	%t43 = insertvalue %Color %t42, i8 255, 3
	%c = alloca %Color
	store %Color %t43, ptr %c

	%t45 = xor i1 1, true
	br i1 %t45, label %base_block_label44, label %end_label44
base_block_label44:
	%t46 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t46, i64 7)

	br label %end_label44
end_label44:

	%t47 = getelementptr inbounds [7 x i8], ptr @tstring3, i64 0, i64 0
	%t48 = insertvalue { ptr, i64 } undef, ptr %t47, 0
	%t49 = insertvalue { ptr, i64 } %t48, i64 6, 1       
	%t50 = load %Color, ptr %c
	%t51 = extractvalue %Color %t50, 0
	%t52 = zext i8 %t51 to i64
	call void @printf_slice({ ptr, i64 } %t49, i64 %t52)

	%t53 = getelementptr inbounds [7 x i8], ptr @tstring4, i64 0, i64 0
	%t54 = insertvalue { ptr, i64 } undef, ptr %t53, 0
	%t55 = insertvalue { ptr, i64 } %t54, i64 6, 1       
	%t56 = load %Color, ptr %c
	%t57 = extractvalue %Color %t56, 1
	%t58 = zext i8 %t57 to i64
	call void @printf_slice({ ptr, i64 } %t55, i64 %t58)

	%t59 = getelementptr inbounds [7 x i8], ptr @tstring5, i64 0, i64 0
	%t60 = insertvalue { ptr, i64 } undef, ptr %t59, 0
	%t61 = insertvalue { ptr, i64 } %t60, i64 6, 1       
	%t62 = load %Color, ptr %c
	%t63 = extractvalue %Color %t62, 2
	%t64 = zext i8 %t63 to i64
	call void @printf_slice({ ptr, i64 } %t61, i64 %t64)

	%t65 = getelementptr inbounds [7 x i8], ptr @tstring6, i64 0, i64 0
	%t66 = insertvalue { ptr, i64 } undef, ptr %t65, 0
	%t67 = insertvalue { ptr, i64 } %t66, i64 6, 1       
	%t68 = load %Color, ptr %c
	%t69 = extractvalue %Color %t68, 3
	%t70 = zext i8 %t69 to i64
	call void @printf_slice({ ptr, i64 } %t67, i64 %t70)

	%t71 = call i64 @GetColor(i32 4278190335)
	%t72 = alloca i64
	store i64 %t71, ptr %t72
	%t73 = load %Color, ptr %t72
	%from_int = alloca %Color
	store %Color %t73, ptr %from_int

	%t74 = getelementptr inbounds [11 x i8], ptr @tstring7, i64 0, i64 0
	%t75 = insertvalue { ptr, i64 } undef, ptr %t74, 0
	%t76 = insertvalue { ptr, i64 } %t75, i64 10, 1       
	call void @printf_slice({ ptr, i64 } %t76, i64 0)

	%t77 = getelementptr inbounds [8 x i8], ptr @tstring8, i64 0, i64 0
	%t78 = insertvalue { ptr, i64 } undef, ptr %t77, 0
	%t79 = insertvalue { ptr, i64 } %t78, i64 7, 1       
	%t80 = load %Color, ptr %from_int
	%t81 = extractvalue %Color %t80, 0
	%t82 = zext i8 %t81 to i64
	call void @printf_slice({ ptr, i64 } %t79, i64 %t82)

	%t83 = getelementptr inbounds [8 x i8], ptr @tstring9, i64 0, i64 0
	%t84 = insertvalue { ptr, i64 } undef, ptr %t83, 0
	%t85 = insertvalue { ptr, i64 } %t84, i64 7, 1       
	%t86 = load %Color, ptr %from_int
	%t87 = extractvalue %Color %t86, 1
	%t88 = zext i8 %t87 to i64
	call void @printf_slice({ ptr, i64 } %t85, i64 %t88)

	%t89 = getelementptr inbounds [8 x i8], ptr @tstring10, i64 0, i64 0
	%t90 = insertvalue { ptr, i64 } undef, ptr %t89, 0
	%t91 = insertvalue { ptr, i64 } %t90, i64 7, 1       
	%t92 = load %Color, ptr %from_int
	%t93 = extractvalue %Color %t92, 2
	%t94 = zext i8 %t93 to i64
	call void @printf_slice({ ptr, i64 } %t91, i64 %t94)

	%t95 = getelementptr inbounds [8 x i8], ptr @tstring11, i64 0, i64 0
	%t96 = insertvalue { ptr, i64 } undef, ptr %t95, 0
	%t97 = insertvalue { ptr, i64 } %t96, i64 7, 1       
	%t98 = load %Color, ptr %from_int
	%t99 = extractvalue %Color %t98, 3
	%t100 = zext i8 %t99 to i64
	call void @printf_slice({ ptr, i64 } %t97, i64 %t100)

	%t101 = load ptr, ptr %data
	%t102 = bitcast ptr %t101 to ptr
	call void @free(ptr %t102)

	%t103 = load ptr, ptr %name
	%t104 = bitcast ptr %t103 to ptr
	call void @free(ptr %t104)

	%t105 = load { ptr, i64 }, ptr %s
	%t106 = extractvalue { ptr, i64 } %t105, 1
	ret i64 %t106

}
