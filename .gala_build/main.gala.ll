; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu" 
%Color = type {i8,i8,i8,i8}
%v2 = type {float,float}
@tstring1 = private unnamed_addr constant [16 x i8] c"n byte 0: %.2x\0A\00", align 1

@tstring2 = private unnamed_addr constant [16 x i8] c"n byte 1: %.2x\0A\00", align 1

@tstring3 = private unnamed_addr constant [16 x i8] c"n byte 2: %.2x\0A\00", align 1

@tstring4 = private unnamed_addr constant [16 x i8] c"n byte 3: %.2x\0A\00", align 1

@tstring5 = private unnamed_addr constant [18 x i8] c"Hello, World! %d\0A\00", align 1

@tstring6 = private unnamed_addr constant [26 x i8] c"Hello, Raylib from Gala!!\00", align 1

@tstring7 = private unnamed_addr constant [7 x i8] c"r: %d\0A\00", align 1

@tstring8 = private unnamed_addr constant [7 x i8] c"g: %d\0A\00", align 1

@tstring9 = private unnamed_addr constant [7 x i8] c"b: %d\0A\00", align 1

@tstring10 = private unnamed_addr constant [7 x i8] c"a: %d\0A\00", align 1

@tstring11 = private unnamed_addr constant [11 x i8] c"GetColor:\0A\00", align 1

@tstring12 = private unnamed_addr constant [8 x i8] c"\09r: %d\0A\00", align 1

@tstring13 = private unnamed_addr constant [8 x i8] c"\09g: %d\0A\00", align 1

@tstring14 = private unnamed_addr constant [8 x i8] c"\09b: %d\0A\00", align 1

@tstring15 = private unnamed_addr constant [8 x i8] c"\09a: %d\0A\00", align 1

@tstring16 = private unnamed_addr constant [10 x i8] c"smth: %f\0A\00", align 1

@tstring17 = private unnamed_addr constant [8 x i8] c"\09x: %f\0A\00", align 1

@tstring18 = private unnamed_addr constant [8 x i8] c"\09y: %f\0A\00", align 1

@tstring19 = private unnamed_addr constant [13 x i8] c"buf 0: %.2x\0A\00", align 1

@tstring20 = private unnamed_addr constant [13 x i8] c"buf 1: %.2x\0A\00", align 1

@tstring21 = private unnamed_addr constant [13 x i8] c"buf 2: %.2x\0A\00", align 1

@tstring22 = private unnamed_addr constant [13 x i8] c"buf 3: %.2x\0A\00", align 1

declare void @printf (ptr %fmt, ...)
declare ptr @calloc (i64 %n, i64 %size)
declare void @memcpy (ptr %dest, ptr %src, i64 %size)
declare void @free (ptr %ptr)
declare void @InitWindow (i64 %width, i64 %height, ptr %title)
declare void @CloseWindow ()
declare i1 @WindowShouldClose ()
declare void @BeginDrawing ()
declare void @EndDrawing ()
declare void @ClearBackground (i32 %color)
declare i32 @GetColor (i32 %v)
define ptr @to_cstr ({ ptr, i64 } %s) {
entry:
	%t23 = extractvalue { ptr, i64 } %s, 1
	%t24 = mul i64 %t23, 1
	%size = alloca i64
	store i64 %t24, ptr %size

	%t25 = load i64, ptr %size
	%t26 = add i64 %t25, 1
	%t27 = call ptr @calloc(i64 1, i64 %t26)
	%cstr = alloca ptr
	store ptr %t27, ptr %cstr

	%t28 = load ptr, ptr %cstr
	%t29 = extractvalue { ptr, i64 } %s, 0
	%t30 = getelementptr inbounds i8, ptr %t29, i64 0
	%t31 = load i64, ptr %size
	call void @memcpy(ptr %t28, ptr %t30, i64 %t31)

	%t32 = load ptr, ptr %cstr
	%t33 = bitcast ptr %t32 to ptr
	ret ptr %t33

}
define void @print_int ({ ptr, i64 } %s, i64 %n) {
entry:
	%t34 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t34, ptr %data

	%t35 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t35, i64 %n)

	%t36 = load ptr, ptr %data
	%t37 = bitcast ptr %t36 to ptr
	call void @free(ptr %t37)

	ret void

}
define void @print_flt ({ ptr, i64 } %s, float %n) {
entry:
	%t38 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t38, ptr %data

	%t39 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t39, float %n)

	%t40 = load ptr, ptr %data
	%t41 = bitcast ptr %t40 to ptr
	call void @free(ptr %t41)

	ret void

}
define void @print_byte ({ ptr, i64 } %s, i8 %n) {
entry:
	%t42 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t42, ptr %data

	%t43 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t43, i8 %n)

	%t44 = load ptr, ptr %data
	%t45 = bitcast ptr %t44 to ptr
	call void @free(ptr %t45)

	ret void

}
declare i64 @Vector2Add (i64 %a, i64 %b)
define [4 x i8] @dump_i32_2 (i32 %n) {
entry:
	%y = alloca i32
	store i32 %n, ptr %y

	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%t46 = bitcast ptr %buf to ptr
	%t47 = bitcast ptr %y to ptr
	call void @memcpy(ptr %t46, ptr %t47, i64 4)

	%t48 = load [4 x i8], ptr %buf
	ret [4 x i8] %t48

}
define [4 x i8] @dump_i32 (i32 %n) {
entry:
	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%y = alloca i32
	store i32 %n, ptr %y

	%t49 = bitcast ptr %y to ptr
	%t50 = load i8, ptr %t49
	%s1 = alloca i8
	store i8 %t50, ptr %s1

	%a = alloca i64
	store i64 1, ptr %a

	%t51 = getelementptr inbounds [16 x i8], ptr @tstring1, i64 0, i64 0
	%t52 = insertvalue { ptr, i64 } undef, ptr %t51, 0
	%t53 = insertvalue { ptr, i64 } %t52, i64 15, 1       
	%t54 = load i8, ptr %s1
	call void @print_byte({ ptr, i64 } %t53, i8 %t54)

	%t55 = ptrtoint ptr %y to i64
	%t56 = add i64 %t55, 1
	%t57 = inttoptr i64 %t56 to ptr
	%t58 = load i8, ptr %t57
	%s2 = alloca i8
	store i8 %t58, ptr %s2

	%t59 = getelementptr inbounds [16 x i8], ptr @tstring2, i64 0, i64 0
	%t60 = insertvalue { ptr, i64 } undef, ptr %t59, 0
	%t61 = insertvalue { ptr, i64 } %t60, i64 15, 1       
	%t62 = load i8, ptr %s2
	call void @print_byte({ ptr, i64 } %t61, i8 %t62)

	%t63 = ptrtoint ptr %y to i64
	%t64 = add i64 %t63, 2
	%t65 = inttoptr i64 %t64 to ptr
	%t66 = load i8, ptr %t65
	%s3 = alloca i8
	store i8 %t66, ptr %s3

	%t67 = getelementptr inbounds [16 x i8], ptr @tstring3, i64 0, i64 0
	%t68 = insertvalue { ptr, i64 } undef, ptr %t67, 0
	%t69 = insertvalue { ptr, i64 } %t68, i64 15, 1       
	%t70 = load i8, ptr %s3
	call void @print_byte({ ptr, i64 } %t69, i8 %t70)

	%t71 = ptrtoint ptr %y to i64
	%t72 = add i64 %t71, 3
	%t73 = inttoptr i64 %t72 to ptr
	%t74 = load i8, ptr %t73
	%s4 = alloca i8
	store i8 %t74, ptr %s4

	%t75 = getelementptr inbounds [16 x i8], ptr @tstring4, i64 0, i64 0
	%t76 = insertvalue { ptr, i64 } undef, ptr %t75, 0
	%t77 = insertvalue { ptr, i64 } %t76, i64 15, 1       
	%t78 = load i8, ptr %s4
	call void @print_byte({ ptr, i64 } %t77, i8 %t78)

	%t79 = load i8, ptr %s1
	%t80 = getelementptr inbounds i8, ptr %buf, i64 0
	store i8 %t79, ptr %t80

	%t81 = load i8, ptr %s2
	%t82 = getelementptr inbounds i8, ptr %buf, i64 1
	store i8 %t81, ptr %t82

	%t83 = load i8, ptr %s3
	%t84 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 %t83, ptr %t84

	%t85 = load i8, ptr %s4
	%t86 = getelementptr inbounds i8, ptr %buf, i64 3
	store i8 %t85, ptr %t86

	%t87 = load [4 x i8], ptr %buf
	ret [4 x i8] %t87

}
define i64 @main () {
entry:
	%t88 = getelementptr inbounds [18 x i8], ptr @tstring5, i64 0, i64 0
	%t89 = insertvalue { ptr, i64 } undef, ptr %t88, 0
	%t90 = insertvalue { ptr, i64 } %t89, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t90, ptr %s

	%t91 = load { ptr, i64 }, ptr %s
	%t92 = call ptr @to_cstr({ ptr, i64 } %t91)
	%data = alloca ptr
	store ptr %t92, ptr %data

	%t93 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t93, i64 9)

	%t94 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t94, i64 8)

	%t95 = getelementptr inbounds [26 x i8], ptr @tstring6, i64 0, i64 0
	%t96 = insertvalue { ptr, i64 } undef, ptr %t95, 0
	%t97 = insertvalue { ptr, i64 } %t96, i64 25, 1       
	%t98 = call ptr @to_cstr({ ptr, i64 } %t97)
	%name = alloca ptr
	store ptr %t98, ptr %name

	%t99 = insertvalue %Color undef, i8 123, 0
	%t100 = insertvalue %Color %t99, i8 222, 1
	%t101 = insertvalue %Color %t100, i8 255, 2
	%t102 = insertvalue %Color %t101, i8 255, 3
	%c = alloca %Color
	store %Color %t102, ptr %c

	%t104 = xor i1 1, true
	br i1 %t104, label %base_block_label103, label %end_label103
base_block_label103:
	%t105 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t105, i64 7)

	br label %end_label103
end_label103:

	%t106 = getelementptr inbounds [7 x i8], ptr @tstring7, i64 0, i64 0
	%t107 = insertvalue { ptr, i64 } undef, ptr %t106, 0
	%t108 = insertvalue { ptr, i64 } %t107, i64 6, 1       
	%t109 = load %Color, ptr %c
	%t110 = extractvalue %Color %t109, 0
	%t111 = zext i8 %t110 to i64
	call void @print_int({ ptr, i64 } %t108, i64 %t111)

	%t112 = getelementptr inbounds [7 x i8], ptr @tstring8, i64 0, i64 0
	%t113 = insertvalue { ptr, i64 } undef, ptr %t112, 0
	%t114 = insertvalue { ptr, i64 } %t113, i64 6, 1       
	%t115 = load %Color, ptr %c
	%t116 = extractvalue %Color %t115, 1
	%t117 = zext i8 %t116 to i64
	call void @print_int({ ptr, i64 } %t114, i64 %t117)

	%t118 = getelementptr inbounds [7 x i8], ptr @tstring9, i64 0, i64 0
	%t119 = insertvalue { ptr, i64 } undef, ptr %t118, 0
	%t120 = insertvalue { ptr, i64 } %t119, i64 6, 1       
	%t121 = load %Color, ptr %c
	%t122 = extractvalue %Color %t121, 2
	%t123 = zext i8 %t122 to i64
	call void @print_int({ ptr, i64 } %t120, i64 %t123)

	%t124 = getelementptr inbounds [7 x i8], ptr @tstring10, i64 0, i64 0
	%t125 = insertvalue { ptr, i64 } undef, ptr %t124, 0
	%t126 = insertvalue { ptr, i64 } %t125, i64 6, 1       
	%t127 = load %Color, ptr %c
	%t128 = extractvalue %Color %t127, 3
	%t129 = zext i8 %t128 to i64
	call void @print_int({ ptr, i64 } %t126, i64 %t129)

	%t130 = call i32 @GetColor(i32 4278190335)
	%t131 = alloca [4 x i8]
	store i32 %t130, ptr %t131
	%t132 = load %Color, ptr %t131
	%from_int = alloca %Color
	store %Color %t132, ptr %from_int

	%t133 = getelementptr inbounds [11 x i8], ptr @tstring11, i64 0, i64 0
	%t134 = insertvalue { ptr, i64 } undef, ptr %t133, 0
	%t135 = insertvalue { ptr, i64 } %t134, i64 10, 1       
	call void @print_int({ ptr, i64 } %t135, i64 0)

	%t136 = getelementptr inbounds [8 x i8], ptr @tstring12, i64 0, i64 0
	%t137 = insertvalue { ptr, i64 } undef, ptr %t136, 0
	%t138 = insertvalue { ptr, i64 } %t137, i64 7, 1       
	%t139 = load %Color, ptr %from_int
	%t140 = extractvalue %Color %t139, 0
	%t141 = zext i8 %t140 to i64
	call void @print_int({ ptr, i64 } %t138, i64 %t141)

	%t142 = getelementptr inbounds [8 x i8], ptr @tstring13, i64 0, i64 0
	%t143 = insertvalue { ptr, i64 } undef, ptr %t142, 0
	%t144 = insertvalue { ptr, i64 } %t143, i64 7, 1       
	%t145 = load %Color, ptr %from_int
	%t146 = extractvalue %Color %t145, 1
	%t147 = zext i8 %t146 to i64
	call void @print_int({ ptr, i64 } %t144, i64 %t147)

	%t148 = getelementptr inbounds [8 x i8], ptr @tstring14, i64 0, i64 0
	%t149 = insertvalue { ptr, i64 } undef, ptr %t148, 0
	%t150 = insertvalue { ptr, i64 } %t149, i64 7, 1       
	%t151 = load %Color, ptr %from_int
	%t152 = extractvalue %Color %t151, 2
	%t153 = zext i8 %t152 to i64
	call void @print_int({ ptr, i64 } %t150, i64 %t153)

	%t154 = getelementptr inbounds [8 x i8], ptr @tstring15, i64 0, i64 0
	%t155 = insertvalue { ptr, i64 } undef, ptr %t154, 0
	%t156 = insertvalue { ptr, i64 } %t155, i64 7, 1       
	%t157 = load %Color, ptr %from_int
	%t158 = extractvalue %Color %t157, 3
	%t159 = zext i8 %t158 to i64
	call void @print_int({ ptr, i64 } %t156, i64 %t159)

	%t160 = getelementptr inbounds [10 x i8], ptr @tstring16, i64 0, i64 0
	%t161 = insertvalue { ptr, i64 } undef, ptr %t160, 0
	%t162 = insertvalue { ptr, i64 } %t161, i64 9, 1       
	call void @print_flt({ ptr, i64 } %t162, float 0x400921FF20000000)

	%t163 = insertvalue %v2 undef, float 0x3FF3333340000000, 0
	%t164 = insertvalue %v2 %t163, float 0x40019999A0000000, 1
	%a = alloca %v2
	store %v2 %t164, ptr %a

	%t165 = insertvalue %v2 undef, float 0x3FF0000000000000, 0
	%t166 = insertvalue %v2 %t165, float 0x4000000000000000, 1
	%b = alloca %v2
	store %v2 %t166, ptr %b

	%t167 = load %v2, ptr %a
	%t168 = alloca [8 x i8]
	store %v2 %t167, ptr %t168
	%t169 = load i64, ptr %t168
	%t170 = load %v2, ptr %b
	%t171 = alloca [8 x i8]
	store %v2 %t170, ptr %t171
	%t172 = load i64, ptr %t171
	%t173 = call i64 @Vector2Add(i64 %t169, i64 %t172)
	%t174 = alloca [8 x i8]
	store i64 %t173, ptr %t174
	%t175 = load %v2, ptr %t174
	%x = alloca %v2
	store %v2 %t175, ptr %x

	%t176 = getelementptr inbounds [8 x i8], ptr @tstring17, i64 0, i64 0
	%t177 = insertvalue { ptr, i64 } undef, ptr %t176, 0
	%t178 = insertvalue { ptr, i64 } %t177, i64 7, 1       
	%t179 = load %v2, ptr %x
	%t180 = extractvalue %v2 %t179, 0
	call void @print_flt({ ptr, i64 } %t178, float %t180)

	%t181 = getelementptr inbounds [8 x i8], ptr @tstring18, i64 0, i64 0
	%t182 = insertvalue { ptr, i64 } undef, ptr %t181, 0
	%t183 = insertvalue { ptr, i64 } %t182, i64 7, 1       
	%t184 = load %v2, ptr %x
	%t185 = extractvalue %v2 %t184, 1
	call void @print_flt({ ptr, i64 } %t183, float %t185)

	%t186 = load %v2, ptr %x
	%t187 = extractvalue %v2 %t186, 1
	%t188 = getelementptr inbounds %v2, ptr %x, i32 0, i32 0
	store float %t187, ptr %t188

	%y = alloca i32
	store i32 4278255361, ptr %y

	%t189 = load i32, ptr %y
	%t190 = call [4 x i8] @dump_i32_2(i32 %t189)
	%buf = alloca [4 x i8]
	store [4 x i8] %t190, ptr %buf

	%t191 = getelementptr inbounds [13 x i8], ptr @tstring19, i64 0, i64 0
	%t192 = insertvalue { ptr, i64 } undef, ptr %t191, 0
	%t193 = insertvalue { ptr, i64 } %t192, i64 12, 1       
	%t194 = getelementptr inbounds i8, ptr %buf, i64 0
	%t195 = load i8, ptr %t194
	call void @print_byte({ ptr, i64 } %t193, i8 %t195)

	%t196 = getelementptr inbounds [13 x i8], ptr @tstring20, i64 0, i64 0
	%t197 = insertvalue { ptr, i64 } undef, ptr %t196, 0
	%t198 = insertvalue { ptr, i64 } %t197, i64 12, 1       
	%t199 = getelementptr inbounds i8, ptr %buf, i64 1
	%t200 = load i8, ptr %t199
	call void @print_byte({ ptr, i64 } %t198, i8 %t200)

	%t201 = getelementptr inbounds [13 x i8], ptr @tstring21, i64 0, i64 0
	%t202 = insertvalue { ptr, i64 } undef, ptr %t201, 0
	%t203 = insertvalue { ptr, i64 } %t202, i64 12, 1       
	%t204 = getelementptr inbounds i8, ptr %buf, i64 2
	%t205 = load i8, ptr %t204
	call void @print_byte({ ptr, i64 } %t203, i8 %t205)

	%t206 = getelementptr inbounds [13 x i8], ptr @tstring22, i64 0, i64 0
	%t207 = insertvalue { ptr, i64 } undef, ptr %t206, 0
	%t208 = insertvalue { ptr, i64 } %t207, i64 12, 1       
	%t209 = getelementptr inbounds i8, ptr %buf, i64 3
	%t210 = load i8, ptr %t209
	call void @print_byte({ ptr, i64 } %t208, i8 %t210)

	%t211 = load ptr, ptr %data
	%t212 = bitcast ptr %t211 to ptr
	call void @free(ptr %t212)

	%t213 = load ptr, ptr %name
	%t214 = bitcast ptr %t213 to ptr
	call void @free(ptr %t214)

	%t215 = getelementptr inbounds i8, ptr %buf, i64 2
	%t216 = load i8, ptr %t215
	%t217 = zext i8 %t216 to i64
	ret i64 %t217

}
