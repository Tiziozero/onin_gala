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

@tstring12 = private unnamed_addr constant [10 x i8] c"smth: %f\0A\00", align 1

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
	%t13 = extractvalue { ptr, i64 } %s, 1
	%t14 = mul i64 %t13, 1
	%size = alloca i64
	store i64 %t14, ptr %size

	%t15 = load i64, ptr %size
	%t16 = add i64 %t15, 1
	%t17 = call ptr @calloc(i64 1, i64 %t16)
	%cstr = alloca ptr
	store ptr %t17, ptr %cstr

	%t18 = load ptr, ptr %cstr
	%t19 = extractvalue { ptr, i64 } %s, 0
	%t20 = getelementptr inbounds i8, ptr %t19, i64 0
	%t21 = alloca ptr
	store ptr %t20, ptr %t21
	%t22 = load ptr, ptr %t21
	%t23 = load i64, ptr %size
	call void @memcpy(ptr %t18, ptr %t22, i64 %t23)

	%t24 = load ptr, ptr %cstr
	%t25 = bitcast ptr %t24 to ptr
	ret ptr %t25

}
define void @print_int ({ ptr, i64 } %s, i64 %n) {
entry:
	%t26 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t26, ptr %data

	%t27 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t27, i64 %n)

	%t28 = load ptr, ptr %data
	%t29 = bitcast ptr %t28 to ptr
	call void @free(ptr %t29)

	ret void

}
define void @print_flt ({ ptr, i64 } %s, double %n) {
entry:
	%t30 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t30, ptr %data

	%t31 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t31, double %n)

	%t32 = load ptr, ptr %data
	%t33 = bitcast ptr %t32 to ptr
	call void @free(ptr %t33)

	ret void

}
define i64 @main () {
entry:
	%t34 = getelementptr inbounds [18 x i8], ptr @tstring1, i64 0, i64 0
	%t35 = insertvalue { ptr, i64 } undef, ptr %t34, 0
	%t36 = insertvalue { ptr, i64 } %t35, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t36, ptr %s

	%t37 = load { ptr, i64 }, ptr %s
	%t38 = call ptr @to_cstr({ ptr, i64 } %t37)
	%data = alloca ptr
	store ptr %t38, ptr %data

	%t39 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t39, i64 9)

	%t40 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t40, i64 8)

	%t41 = getelementptr inbounds [26 x i8], ptr @tstring2, i64 0, i64 0
	%t42 = insertvalue { ptr, i64 } undef, ptr %t41, 0
	%t43 = insertvalue { ptr, i64 } %t42, i64 25, 1       
	%t44 = call ptr @to_cstr({ ptr, i64 } %t43)
	%name = alloca ptr
	store ptr %t44, ptr %name

	%t45 = insertvalue %Color undef, i8 123, 0
	%t46 = insertvalue %Color %t45, i8 222, 1
	%t47 = insertvalue %Color %t46, i8 255, 2
	%t48 = insertvalue %Color %t47, i8 255, 3
	%c = alloca %Color
	store %Color %t48, ptr %c

	%t50 = xor i1 1, true
	br i1 %t50, label %base_block_label49, label %end_label49
base_block_label49:
	%t51 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t51, i64 7)

	br label %end_label49
end_label49:

	%t52 = getelementptr inbounds [7 x i8], ptr @tstring3, i64 0, i64 0
	%t53 = insertvalue { ptr, i64 } undef, ptr %t52, 0
	%t54 = insertvalue { ptr, i64 } %t53, i64 6, 1       
	%t55 = load %Color, ptr %c
	%t56 = extractvalue %Color %t55, 0
	%t57 = zext i8 %t56 to i64
	call void @print_int({ ptr, i64 } %t54, i64 %t57)

	%t58 = getelementptr inbounds [7 x i8], ptr @tstring4, i64 0, i64 0
	%t59 = insertvalue { ptr, i64 } undef, ptr %t58, 0
	%t60 = insertvalue { ptr, i64 } %t59, i64 6, 1       
	%t61 = load %Color, ptr %c
	%t62 = extractvalue %Color %t61, 1
	%t63 = zext i8 %t62 to i64
	call void @print_int({ ptr, i64 } %t60, i64 %t63)

	%t64 = getelementptr inbounds [7 x i8], ptr @tstring5, i64 0, i64 0
	%t65 = insertvalue { ptr, i64 } undef, ptr %t64, 0
	%t66 = insertvalue { ptr, i64 } %t65, i64 6, 1       
	%t67 = load %Color, ptr %c
	%t68 = extractvalue %Color %t67, 2
	%t69 = zext i8 %t68 to i64
	call void @print_int({ ptr, i64 } %t66, i64 %t69)

	%t70 = getelementptr inbounds [7 x i8], ptr @tstring6, i64 0, i64 0
	%t71 = insertvalue { ptr, i64 } undef, ptr %t70, 0
	%t72 = insertvalue { ptr, i64 } %t71, i64 6, 1       
	%t73 = load %Color, ptr %c
	%t74 = extractvalue %Color %t73, 3
	%t75 = zext i8 %t74 to i64
	call void @print_int({ ptr, i64 } %t72, i64 %t75)

	%t76 = call i64 @GetColor(i32 4278190335)
	%t77 = alloca i64
	store i64 %t76, ptr %t77
	%t78 = load %Color, ptr %t77
	%from_int = alloca %Color
	store %Color %t78, ptr %from_int

	%t79 = getelementptr inbounds [11 x i8], ptr @tstring7, i64 0, i64 0
	%t80 = insertvalue { ptr, i64 } undef, ptr %t79, 0
	%t81 = insertvalue { ptr, i64 } %t80, i64 10, 1       
	call void @print_int({ ptr, i64 } %t81, i64 0)

	%t82 = getelementptr inbounds [8 x i8], ptr @tstring8, i64 0, i64 0
	%t83 = insertvalue { ptr, i64 } undef, ptr %t82, 0
	%t84 = insertvalue { ptr, i64 } %t83, i64 7, 1       
	%t85 = load %Color, ptr %from_int
	%t86 = extractvalue %Color %t85, 0
	%t87 = zext i8 %t86 to i64
	call void @print_int({ ptr, i64 } %t84, i64 %t87)

	%t88 = getelementptr inbounds [8 x i8], ptr @tstring9, i64 0, i64 0
	%t89 = insertvalue { ptr, i64 } undef, ptr %t88, 0
	%t90 = insertvalue { ptr, i64 } %t89, i64 7, 1       
	%t91 = load %Color, ptr %from_int
	%t92 = extractvalue %Color %t91, 1
	%t93 = zext i8 %t92 to i64
	call void @print_int({ ptr, i64 } %t90, i64 %t93)

	%t94 = getelementptr inbounds [8 x i8], ptr @tstring10, i64 0, i64 0
	%t95 = insertvalue { ptr, i64 } undef, ptr %t94, 0
	%t96 = insertvalue { ptr, i64 } %t95, i64 7, 1       
	%t97 = load %Color, ptr %from_int
	%t98 = extractvalue %Color %t97, 2
	%t99 = zext i8 %t98 to i64
	call void @print_int({ ptr, i64 } %t96, i64 %t99)

	%t100 = getelementptr inbounds [8 x i8], ptr @tstring11, i64 0, i64 0
	%t101 = insertvalue { ptr, i64 } undef, ptr %t100, 0
	%t102 = insertvalue { ptr, i64 } %t101, i64 7, 1       
	%t103 = load %Color, ptr %from_int
	%t104 = extractvalue %Color %t103, 3
	%t105 = zext i8 %t104 to i64
	call void @print_int({ ptr, i64 } %t102, i64 %t105)

	%t106 = getelementptr inbounds [10 x i8], ptr @tstring12, i64 0, i64 0
	%t107 = insertvalue { ptr, i64 } undef, ptr %t106, 0
	%t108 = insertvalue { ptr, i64 } %t107, i64 9, 1       
	call void @print_flt({ ptr, i64 } %t108, double 3.1416)

	%t109 = load ptr, ptr %data
	%t110 = bitcast ptr %t109 to ptr
	call void @free(ptr %t110)

	%t111 = load ptr, ptr %name
	%t112 = bitcast ptr %t111 to ptr
	call void @free(ptr %t112)

	%t113 = load { ptr, i64 }, ptr %s
	%t114 = extractvalue { ptr, i64 } %t113, 1
	ret i64 %t114

}
