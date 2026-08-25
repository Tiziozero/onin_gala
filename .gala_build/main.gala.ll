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

@tstring19 = private unnamed_addr constant [14 x i8] c"xbuf 0: %.2x\0A\00", align 1

@tstring20 = private unnamed_addr constant [14 x i8] c"xbuf 1: %.2x\0A\00", align 1

@tstring21 = private unnamed_addr constant [14 x i8] c"xbuf 2: %.2x\0A\00", align 1

@tstring22 = private unnamed_addr constant [14 x i8] c"xbuf 3: %.2x\0A\00", align 1

@tstring23 = private unnamed_addr constant [14 x i8] c"ybuf 0: %.2x\0A\00", align 1

@tstring24 = private unnamed_addr constant [14 x i8] c"ybuf 1: %.2x\0A\00", align 1

@tstring25 = private unnamed_addr constant [14 x i8] c"ybuf 2: %.2x\0A\00", align 1

@tstring26 = private unnamed_addr constant [14 x i8] c"ybuf 3: %.2x\0A\00", align 1

@tstring27 = private unnamed_addr constant [13 x i8] c"zbuf 0: %dx\0A\00", align 1

@tstring28 = private unnamed_addr constant [13 x i8] c"zbuf 1: %dx\0A\00", align 1

@tstring29 = private unnamed_addr constant [13 x i8] c"zbuf 2: %dx\0A\00", align 1

@tstring30 = private unnamed_addr constant [13 x i8] c"zbuf 3: %dx\0A\00", align 1

declare void @printf (ptr %fmt, ...)
declare ptr @calloc (i64 %n, i64 %size)
declare void @memcpy (ptr %dest, ptr %src, i64 %size)
declare void @free (ptr %ptr)
declare void @InitWindow (i64 %width, i64 %height, ptr %title)
declare void @CloseWindow ()
declare i1 @WindowShouldClose ()
declare void @BeginDrawing ()
declare void @EndDrawing ()
declare void @ClearBackground (i32 %colour)
declare i32 @GetColor (i32 %v)
define ptr @to_cstr ({ ptr, i64 } %s) {
entry:
	%t31 = extractvalue { ptr, i64 } %s, 1
	%t32 = mul i64 %t31, 1
	%size = alloca i64
	store i64 %t32, ptr %size

	%t33 = load i64, ptr %size
	%t34 = add i64 %t33, 1
	%t35 = call ptr @calloc(i64 1, i64 %t34)
	%cstr = alloca ptr
	store ptr %t35, ptr %cstr

	%t36 = load ptr, ptr %cstr
	%t37 = extractvalue { ptr, i64 } %s, 0
	%t38 = getelementptr inbounds i8, ptr %t37, i64 0
	%t39 = load i64, ptr %size
	call void @memcpy(ptr %t36, ptr %t38, i64 %t39)

	%t40 = load ptr, ptr %cstr
	%t41 = bitcast ptr %t40 to ptr
	ret ptr %t41

}
define void @print_int ({ ptr, i64 } %s, i64 %n) {
entry:
	%t42 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t42, ptr %data

	%t43 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t43, i64 %n)

	%t44 = load ptr, ptr %data
	%t45 = bitcast ptr %t44 to ptr
	call void @free(ptr %t45)

	ret void

}
define void @print_flt ({ ptr, i64 } %s, float %n) {
entry:
	%t46 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t46, ptr %data

	%t47 = load ptr, ptr %data
	%t48 = fpext float %n to double
	call void (ptr, ...)@printf(ptr %t47, double %t48)

	%t49 = load ptr, ptr %data
	%t50 = bitcast ptr %t49 to ptr
	call void @free(ptr %t50)

	ret void

}
define void @print_byte ({ ptr, i64 } %s, i8 %n) {
entry:
	%t51 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t51, ptr %data

	%t52 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t52, i8 %n)

	%t53 = load ptr, ptr %data
	%t54 = bitcast ptr %t53 to ptr
	call void @free(ptr %t54)

	ret void

}
declare i64 @Vector2Add (i64 %a, i64 %b)
define [4 x i8] @dump_i32_2 (i32 %n) {
entry:
	%y = alloca i32
	store i32 %n, ptr %y

	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%t55 = bitcast ptr %buf to ptr
	%t56 = bitcast ptr %y to ptr
	call void @memcpy(ptr %t55, ptr %t56, i64 4)

	%t57 = load [4 x i8], ptr %buf
	ret [4 x i8] %t57

}
define [4 x i8] @dump_i32 (i32 %n) {
entry:
	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%y = alloca i32
	store i32 %n, ptr %y

	%t58 = bitcast ptr %y to ptr
	%t59 = load i8, ptr %t58
	%s1 = alloca i8
	store i8 %t59, ptr %s1

	%a = alloca i64
	store i64 1, ptr %a

	%t60 = getelementptr inbounds [16 x i8], ptr @tstring1, i64 0, i64 0
	%t61 = insertvalue { ptr, i64 } undef, ptr %t60, 0
	%t62 = insertvalue { ptr, i64 } %t61, i64 15, 1       
	%t63 = load i8, ptr %s1
	call void @print_byte({ ptr, i64 } %t62, i8 %t63)

	%t64 = ptrtoint ptr %y to i64
	%t65 = add i64 %t64, 1
	%t66 = inttoptr i64 %t65 to ptr
	%t67 = load i8, ptr %t66
	%s2 = alloca i8
	store i8 %t67, ptr %s2

	%t68 = getelementptr inbounds [16 x i8], ptr @tstring2, i64 0, i64 0
	%t69 = insertvalue { ptr, i64 } undef, ptr %t68, 0
	%t70 = insertvalue { ptr, i64 } %t69, i64 15, 1       
	%t71 = load i8, ptr %s2
	call void @print_byte({ ptr, i64 } %t70, i8 %t71)

	%t72 = ptrtoint ptr %y to i64
	%t73 = add i64 %t72, 2
	%t74 = inttoptr i64 %t73 to ptr
	%t75 = load i8, ptr %t74
	%s3 = alloca i8
	store i8 %t75, ptr %s3

	%t76 = getelementptr inbounds [16 x i8], ptr @tstring3, i64 0, i64 0
	%t77 = insertvalue { ptr, i64 } undef, ptr %t76, 0
	%t78 = insertvalue { ptr, i64 } %t77, i64 15, 1       
	%t79 = load i8, ptr %s3
	call void @print_byte({ ptr, i64 } %t78, i8 %t79)

	%t80 = ptrtoint ptr %y to i64
	%t81 = add i64 %t80, 3
	%t82 = inttoptr i64 %t81 to ptr
	%t83 = load i8, ptr %t82
	%s4 = alloca i8
	store i8 %t83, ptr %s4

	%t84 = getelementptr inbounds [16 x i8], ptr @tstring4, i64 0, i64 0
	%t85 = insertvalue { ptr, i64 } undef, ptr %t84, 0
	%t86 = insertvalue { ptr, i64 } %t85, i64 15, 1       
	%t87 = load i8, ptr %s4
	call void @print_byte({ ptr, i64 } %t86, i8 %t87)

	%t88 = load i8, ptr %s1
	%t89 = getelementptr inbounds i8, ptr %buf, i64 0
	store i8 %t88, ptr %t89

	%t90 = load i8, ptr %s2
	%t91 = getelementptr inbounds i8, ptr %buf, i64 1
	store i8 %t90, ptr %t91

	%t92 = load i8, ptr %s3
	%t93 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 %t92, ptr %t93

	%t94 = load i8, ptr %s4
	%t95 = getelementptr inbounds i8, ptr %buf, i64 3
	store i8 %t94, ptr %t95

	%t96 = load [4 x i8], ptr %buf
	ret [4 x i8] %t96

}
define i64 @main () {
entry:
	%t97 = getelementptr inbounds [18 x i8], ptr @tstring5, i64 0, i64 0
	%t98 = insertvalue { ptr, i64 } undef, ptr %t97, 0
	%t99 = insertvalue { ptr, i64 } %t98, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t99, ptr %s

	%t100 = load { ptr, i64 }, ptr %s
	%t101 = call ptr @to_cstr({ ptr, i64 } %t100)
	%data = alloca ptr
	store ptr %t101, ptr %data

	%t102 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t102, i64 9)

	%t103 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t103, i64 8)

	%t104 = getelementptr inbounds [26 x i8], ptr @tstring6, i64 0, i64 0
	%t105 = insertvalue { ptr, i64 } undef, ptr %t104, 0
	%t106 = insertvalue { ptr, i64 } %t105, i64 25, 1       
	%t107 = call ptr @to_cstr({ ptr, i64 } %t106)
	%name = alloca ptr
	store ptr %t107, ptr %name

	%t108 = insertvalue %Color undef, i8 123, 0
	%t109 = insertvalue %Color %t108, i8 222, 1
	%t110 = insertvalue %Color %t109, i8 255, 2
	%t111 = insertvalue %Color %t110, i8 255, 3
	%c = alloca %Color
	store %Color %t111, ptr %c

	%t113 = xor i1 1, true
	br i1 %t113, label %base_block_label112, label %end_label112
base_block_label112:
	%t114 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t114, i64 7)

	br label %end_label112
end_label112:

	%t115 = getelementptr inbounds [7 x i8], ptr @tstring7, i64 0, i64 0
	%t116 = insertvalue { ptr, i64 } undef, ptr %t115, 0
	%t117 = insertvalue { ptr, i64 } %t116, i64 6, 1       
	%t118 = load %Color, ptr %c
	%t119 = extractvalue %Color %t118, 0
	%t120 = zext i8 %t119 to i64
	call void @print_int({ ptr, i64 } %t117, i64 %t120)

	%t121 = getelementptr inbounds [7 x i8], ptr @tstring8, i64 0, i64 0
	%t122 = insertvalue { ptr, i64 } undef, ptr %t121, 0
	%t123 = insertvalue { ptr, i64 } %t122, i64 6, 1       
	%t124 = load %Color, ptr %c
	%t125 = extractvalue %Color %t124, 1
	%t126 = zext i8 %t125 to i64
	call void @print_int({ ptr, i64 } %t123, i64 %t126)

	%t127 = getelementptr inbounds [7 x i8], ptr @tstring9, i64 0, i64 0
	%t128 = insertvalue { ptr, i64 } undef, ptr %t127, 0
	%t129 = insertvalue { ptr, i64 } %t128, i64 6, 1       
	%t130 = load %Color, ptr %c
	%t131 = extractvalue %Color %t130, 2
	%t132 = zext i8 %t131 to i64
	call void @print_int({ ptr, i64 } %t129, i64 %t132)

	%t133 = getelementptr inbounds [7 x i8], ptr @tstring10, i64 0, i64 0
	%t134 = insertvalue { ptr, i64 } undef, ptr %t133, 0
	%t135 = insertvalue { ptr, i64 } %t134, i64 6, 1       
	%t136 = load %Color, ptr %c
	%t137 = extractvalue %Color %t136, 3
	%t138 = zext i8 %t137 to i64
	call void @print_int({ ptr, i64 } %t135, i64 %t138)

	%t139 = call i32 @GetColor(i32 4278190335)
	%t140 = alloca [4 x i8]
	store i32 %t139, ptr %t140
	%t141 = load %Color, ptr %t140
	%from_int = alloca %Color
	store %Color %t141, ptr %from_int

	%t142 = getelementptr inbounds [11 x i8], ptr @tstring11, i64 0, i64 0
	%t143 = insertvalue { ptr, i64 } undef, ptr %t142, 0
	%t144 = insertvalue { ptr, i64 } %t143, i64 10, 1       
	call void @print_int({ ptr, i64 } %t144, i64 0)

	%t145 = getelementptr inbounds [8 x i8], ptr @tstring12, i64 0, i64 0
	%t146 = insertvalue { ptr, i64 } undef, ptr %t145, 0
	%t147 = insertvalue { ptr, i64 } %t146, i64 7, 1       
	%t148 = load %Color, ptr %from_int
	%t149 = extractvalue %Color %t148, 0
	%t150 = zext i8 %t149 to i64
	call void @print_int({ ptr, i64 } %t147, i64 %t150)

	%t151 = getelementptr inbounds [8 x i8], ptr @tstring13, i64 0, i64 0
	%t152 = insertvalue { ptr, i64 } undef, ptr %t151, 0
	%t153 = insertvalue { ptr, i64 } %t152, i64 7, 1       
	%t154 = load %Color, ptr %from_int
	%t155 = extractvalue %Color %t154, 1
	%t156 = zext i8 %t155 to i64
	call void @print_int({ ptr, i64 } %t153, i64 %t156)

	%t157 = getelementptr inbounds [8 x i8], ptr @tstring14, i64 0, i64 0
	%t158 = insertvalue { ptr, i64 } undef, ptr %t157, 0
	%t159 = insertvalue { ptr, i64 } %t158, i64 7, 1       
	%t160 = load %Color, ptr %from_int
	%t161 = extractvalue %Color %t160, 2
	%t162 = zext i8 %t161 to i64
	call void @print_int({ ptr, i64 } %t159, i64 %t162)

	%t163 = getelementptr inbounds [8 x i8], ptr @tstring15, i64 0, i64 0
	%t164 = insertvalue { ptr, i64 } undef, ptr %t163, 0
	%t165 = insertvalue { ptr, i64 } %t164, i64 7, 1       
	%t166 = load %Color, ptr %from_int
	%t167 = extractvalue %Color %t166, 3
	%t168 = zext i8 %t167 to i64
	call void @print_int({ ptr, i64 } %t165, i64 %t168)

	%t169 = getelementptr inbounds [10 x i8], ptr @tstring16, i64 0, i64 0
	%t170 = insertvalue { ptr, i64 } undef, ptr %t169, 0
	%t171 = insertvalue { ptr, i64 } %t170, i64 9, 1       
	call void @print_flt({ ptr, i64 } %t171, float 0x400921FF20000000)

	%t172 = insertvalue %v2 undef, float 0x3FF3333340000000, 0
	%t173 = insertvalue %v2 %t172, float 0x40019999A0000000, 1
	%a = alloca %v2
	store %v2 %t173, ptr %a

	%t174 = insertvalue %v2 undef, float 0x3FF0000000000000, 0
	%t175 = insertvalue %v2 %t174, float 0x4000000000000000, 1
	%b = alloca %v2
	store %v2 %t175, ptr %b

	%t176 = load %v2, ptr %a
	%t177 = alloca [8 x i8]
	store %v2 %t176, ptr %t177
	%t178 = load i64, ptr %t177
	%t179 = load %v2, ptr %b
	%t180 = alloca [8 x i8]
	store %v2 %t179, ptr %t180
	%t181 = load i64, ptr %t180
	%t182 = call i64 @Vector2Add(i64 %t178, i64 %t181)
	%t183 = alloca [8 x i8]
	store i64 %t182, ptr %t183
	%t184 = load %v2, ptr %t183
	%v = alloca %v2
	store %v2 %t184, ptr %v

	%t185 = getelementptr inbounds [8 x i8], ptr @tstring17, i64 0, i64 0
	%t186 = insertvalue { ptr, i64 } undef, ptr %t185, 0
	%t187 = insertvalue { ptr, i64 } %t186, i64 7, 1       
	%t188 = load %v2, ptr %v
	%t189 = extractvalue %v2 %t188, 0
	call void @print_flt({ ptr, i64 } %t187, float %t189)

	%t190 = getelementptr inbounds [8 x i8], ptr @tstring18, i64 0, i64 0
	%t191 = insertvalue { ptr, i64 } undef, ptr %t190, 0
	%t192 = insertvalue { ptr, i64 } %t191, i64 7, 1       
	%t193 = load %v2, ptr %v
	%t194 = extractvalue %v2 %t193, 1
	call void @print_flt({ ptr, i64 } %t192, float %t194)

	%t195 = load %v2, ptr %v
	%t196 = extractvalue %v2 %t195, 0
	%t197 = bitcast float %t196 to i32
	%x = alloca i32
	store i32 %t197, ptr %x

	%t198 = load i32, ptr %x
	%t199 = call [4 x i8] @dump_i32_2(i32 %t198)
	%buf = alloca [4 x i8]
	store [4 x i8] %t199, ptr %buf

	%t200 = getelementptr inbounds [14 x i8], ptr @tstring19, i64 0, i64 0
	%t201 = insertvalue { ptr, i64 } undef, ptr %t200, 0
	%t202 = insertvalue { ptr, i64 } %t201, i64 13, 1       
	%t203 = getelementptr inbounds i8, ptr %buf, i64 0
	%t204 = load i8, ptr %t203
	call void @print_byte({ ptr, i64 } %t202, i8 %t204)

	%t205 = getelementptr inbounds [14 x i8], ptr @tstring20, i64 0, i64 0
	%t206 = insertvalue { ptr, i64 } undef, ptr %t205, 0
	%t207 = insertvalue { ptr, i64 } %t206, i64 13, 1       
	%t208 = getelementptr inbounds i8, ptr %buf, i64 1
	%t209 = load i8, ptr %t208
	call void @print_byte({ ptr, i64 } %t207, i8 %t209)

	%t210 = getelementptr inbounds [14 x i8], ptr @tstring21, i64 0, i64 0
	%t211 = insertvalue { ptr, i64 } undef, ptr %t210, 0
	%t212 = insertvalue { ptr, i64 } %t211, i64 13, 1       
	%t213 = getelementptr inbounds i8, ptr %buf, i64 2
	%t214 = load i8, ptr %t213
	call void @print_byte({ ptr, i64 } %t212, i8 %t214)

	%t215 = getelementptr inbounds [14 x i8], ptr @tstring22, i64 0, i64 0
	%t216 = insertvalue { ptr, i64 } undef, ptr %t215, 0
	%t217 = insertvalue { ptr, i64 } %t216, i64 13, 1       
	%t218 = getelementptr inbounds i8, ptr %buf, i64 3
	%t219 = load i8, ptr %t218
	call void @print_byte({ ptr, i64 } %t217, i8 %t219)

	%t220 = load %v2, ptr %v
	%t221 = extractvalue %v2 %t220, 1
	%t222 = bitcast float %t221 to i32
	%y = alloca i32
	store i32 %t222, ptr %y

	%t223 = load i32, ptr %y
	%t224 = call [4 x i8] @dump_i32_2(i32 %t223)
	store [4 x i8] %t224, ptr %buf

	%t225 = getelementptr inbounds [14 x i8], ptr @tstring23, i64 0, i64 0
	%t226 = insertvalue { ptr, i64 } undef, ptr %t225, 0
	%t227 = insertvalue { ptr, i64 } %t226, i64 13, 1       
	%t228 = getelementptr inbounds i8, ptr %buf, i64 0
	%t229 = load i8, ptr %t228
	call void @print_byte({ ptr, i64 } %t227, i8 %t229)

	%t230 = getelementptr inbounds [14 x i8], ptr @tstring24, i64 0, i64 0
	%t231 = insertvalue { ptr, i64 } undef, ptr %t230, 0
	%t232 = insertvalue { ptr, i64 } %t231, i64 13, 1       
	%t233 = getelementptr inbounds i8, ptr %buf, i64 1
	%t234 = load i8, ptr %t233
	call void @print_byte({ ptr, i64 } %t232, i8 %t234)

	%t235 = getelementptr inbounds [14 x i8], ptr @tstring25, i64 0, i64 0
	%t236 = insertvalue { ptr, i64 } undef, ptr %t235, 0
	%t237 = insertvalue { ptr, i64 } %t236, i64 13, 1       
	%t238 = getelementptr inbounds i8, ptr %buf, i64 2
	%t239 = load i8, ptr %t238
	call void @print_byte({ ptr, i64 } %t237, i8 %t239)

	%t240 = getelementptr inbounds [14 x i8], ptr @tstring26, i64 0, i64 0
	%t241 = insertvalue { ptr, i64 } undef, ptr %t240, 0
	%t242 = insertvalue { ptr, i64 } %t241, i64 13, 1       
	%t243 = getelementptr inbounds i8, ptr %buf, i64 3
	%t244 = load i8, ptr %t243
	call void @print_byte({ ptr, i64 } %t242, i8 %t244)

	%t245 = load ptr, ptr %data
	%t246 = bitcast ptr %t245 to ptr
	call void @free(ptr %t246)

	%t247 = load ptr, ptr %name
	%t248 = bitcast ptr %t247 to ptr
	call void @free(ptr %t248)

	%t249 = insertvalue %Color undef, i8 225, 0
	%t250 = insertvalue %Color %t249, i8 123, 1
	%t251 = insertvalue %Color %t250, i8 0, 2
	%t252 = insertvalue %Color %t251, i8 100, 3
	%colour = alloca %Color
	store %Color %t252, ptr %colour

	%t253 = load i32, ptr %colour
	%z = alloca i32
	store i32 %t253, ptr %z

	%t254 = load i32, ptr %z
	%t255 = call [4 x i8] @dump_i32_2(i32 %t254)
	store [4 x i8] %t255, ptr %buf

	%t256 = getelementptr inbounds [13 x i8], ptr @tstring27, i64 0, i64 0
	%t257 = insertvalue { ptr, i64 } undef, ptr %t256, 0
	%t258 = insertvalue { ptr, i64 } %t257, i64 12, 1       
	%t259 = getelementptr inbounds i8, ptr %buf, i64 0
	%t260 = load i8, ptr %t259
	call void @print_byte({ ptr, i64 } %t258, i8 %t260)

	%t261 = getelementptr inbounds [13 x i8], ptr @tstring28, i64 0, i64 0
	%t262 = insertvalue { ptr, i64 } undef, ptr %t261, 0
	%t263 = insertvalue { ptr, i64 } %t262, i64 12, 1       
	%t264 = getelementptr inbounds i8, ptr %buf, i64 1
	%t265 = load i8, ptr %t264
	call void @print_byte({ ptr, i64 } %t263, i8 %t265)

	%t266 = getelementptr inbounds [13 x i8], ptr @tstring29, i64 0, i64 0
	%t267 = insertvalue { ptr, i64 } undef, ptr %t266, 0
	%t268 = insertvalue { ptr, i64 } %t267, i64 12, 1       
	%t269 = getelementptr inbounds i8, ptr %buf, i64 2
	%t270 = load i8, ptr %t269
	call void @print_byte({ ptr, i64 } %t268, i8 %t270)

	%t271 = getelementptr inbounds [13 x i8], ptr @tstring30, i64 0, i64 0
	%t272 = insertvalue { ptr, i64 } undef, ptr %t271, 0
	%t273 = insertvalue { ptr, i64 } %t272, i64 12, 1       
	%t274 = getelementptr inbounds i8, ptr %buf, i64 3
	%t275 = load i8, ptr %t274
	call void @print_byte({ ptr, i64 } %t273, i8 %t275)

	%t276 = getelementptr inbounds i8, ptr %buf, i64 2
	%t277 = load i8, ptr %t276
	%t278 = zext i8 %t277 to i64
	ret i64 %t278

}
