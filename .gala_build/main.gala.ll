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
	%t27 = extractvalue { ptr, i64 } %s, 1
	%t28 = mul i64 %t27, 1
	%size = alloca i64
	store i64 %t28, ptr %size

	%t29 = load i64, ptr %size
	%t30 = add i64 %t29, 1
	%t31 = call ptr @calloc(i64 1, i64 %t30)
	%cstr = alloca ptr
	store ptr %t31, ptr %cstr

	%t32 = load ptr, ptr %cstr
	%t33 = extractvalue { ptr, i64 } %s, 0
	%t34 = getelementptr inbounds i8, ptr %t33, i64 0
	%t35 = load i64, ptr %size
	call void @memcpy(ptr %t32, ptr %t34, i64 %t35)

	%t36 = load ptr, ptr %cstr
	%t37 = bitcast ptr %t36 to ptr
	ret ptr %t37

}
define void @print_int ({ ptr, i64 } %s, i64 %n) {
entry:
	%t38 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t38, ptr %data

	%t39 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t39, i64 %n)

	%t40 = load ptr, ptr %data
	%t41 = bitcast ptr %t40 to ptr
	call void @free(ptr %t41)

	ret void

}
define void @print_flt ({ ptr, i64 } %s, float %n) {
entry:
	%t42 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t42, ptr %data

	%t43 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t43, float %n)

	%t44 = load ptr, ptr %data
	%t45 = bitcast ptr %t44 to ptr
	call void @free(ptr %t45)

	ret void

}
define void @print_byte ({ ptr, i64 } %s, i8 %n) {
entry:
	%t46 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %t46, ptr %data

	%t47 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t47, i8 %n)

	%t48 = load ptr, ptr %data
	%t49 = bitcast ptr %t48 to ptr
	call void @free(ptr %t49)

	ret void

}
declare i64 @Vector2Add (i64 %a, i64 %b)
define [4 x i8] @dump_i32_2 (i32 %n) {
entry:
	%y = alloca i32
	store i32 %n, ptr %y

	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%t50 = bitcast ptr %buf to ptr
	%t51 = bitcast ptr %y to ptr
	call void @memcpy(ptr %t50, ptr %t51, i64 4)

	%t52 = load [4 x i8], ptr %buf
	ret [4 x i8] %t52

}
define [4 x i8] @dump_i32 (i32 %n) {
entry:
	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%y = alloca i32
	store i32 %n, ptr %y

	%t53 = bitcast ptr %y to ptr
	%t54 = load i8, ptr %t53
	%s1 = alloca i8
	store i8 %t54, ptr %s1

	%a = alloca i64
	store i64 1, ptr %a

	%t55 = getelementptr inbounds [16 x i8], ptr @tstring1, i64 0, i64 0
	%t56 = insertvalue { ptr, i64 } undef, ptr %t55, 0
	%t57 = insertvalue { ptr, i64 } %t56, i64 15, 1       
	%t58 = load i8, ptr %s1
	call void @print_byte({ ptr, i64 } %t57, i8 %t58)

	%t59 = ptrtoint ptr %y to i64
	%t60 = add i64 %t59, 1
	%t61 = inttoptr i64 %t60 to ptr
	%t62 = load i8, ptr %t61
	%s2 = alloca i8
	store i8 %t62, ptr %s2

	%t63 = getelementptr inbounds [16 x i8], ptr @tstring2, i64 0, i64 0
	%t64 = insertvalue { ptr, i64 } undef, ptr %t63, 0
	%t65 = insertvalue { ptr, i64 } %t64, i64 15, 1       
	%t66 = load i8, ptr %s2
	call void @print_byte({ ptr, i64 } %t65, i8 %t66)

	%t67 = ptrtoint ptr %y to i64
	%t68 = add i64 %t67, 2
	%t69 = inttoptr i64 %t68 to ptr
	%t70 = load i8, ptr %t69
	%s3 = alloca i8
	store i8 %t70, ptr %s3

	%t71 = getelementptr inbounds [16 x i8], ptr @tstring3, i64 0, i64 0
	%t72 = insertvalue { ptr, i64 } undef, ptr %t71, 0
	%t73 = insertvalue { ptr, i64 } %t72, i64 15, 1       
	%t74 = load i8, ptr %s3
	call void @print_byte({ ptr, i64 } %t73, i8 %t74)

	%t75 = ptrtoint ptr %y to i64
	%t76 = add i64 %t75, 3
	%t77 = inttoptr i64 %t76 to ptr
	%t78 = load i8, ptr %t77
	%s4 = alloca i8
	store i8 %t78, ptr %s4

	%t79 = getelementptr inbounds [16 x i8], ptr @tstring4, i64 0, i64 0
	%t80 = insertvalue { ptr, i64 } undef, ptr %t79, 0
	%t81 = insertvalue { ptr, i64 } %t80, i64 15, 1       
	%t82 = load i8, ptr %s4
	call void @print_byte({ ptr, i64 } %t81, i8 %t82)

	%t83 = load i8, ptr %s1
	%t84 = getelementptr inbounds i8, ptr %buf, i64 0
	store i8 %t83, ptr %t84

	%t85 = load i8, ptr %s2
	%t86 = getelementptr inbounds i8, ptr %buf, i64 1
	store i8 %t85, ptr %t86

	%t87 = load i8, ptr %s3
	%t88 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 %t87, ptr %t88

	%t89 = load i8, ptr %s4
	%t90 = getelementptr inbounds i8, ptr %buf, i64 3
	store i8 %t89, ptr %t90

	%t91 = load [4 x i8], ptr %buf
	ret [4 x i8] %t91

}
define i64 @main () {
entry:
	%t92 = getelementptr inbounds [18 x i8], ptr @tstring5, i64 0, i64 0
	%t93 = insertvalue { ptr, i64 } undef, ptr %t92, 0
	%t94 = insertvalue { ptr, i64 } %t93, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %t94, ptr %s

	%t95 = load { ptr, i64 }, ptr %s
	%t96 = call ptr @to_cstr({ ptr, i64 } %t95)
	%data = alloca ptr
	store ptr %t96, ptr %data

	%t97 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t97, i64 9)

	%t98 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t98, i64 8)

	%t99 = getelementptr inbounds [26 x i8], ptr @tstring6, i64 0, i64 0
	%t100 = insertvalue { ptr, i64 } undef, ptr %t99, 0
	%t101 = insertvalue { ptr, i64 } %t100, i64 25, 1       
	%t102 = call ptr @to_cstr({ ptr, i64 } %t101)
	%name = alloca ptr
	store ptr %t102, ptr %name

	%t103 = insertvalue %Color undef, i8 123, 0
	%t104 = insertvalue %Color %t103, i8 222, 1
	%t105 = insertvalue %Color %t104, i8 255, 2
	%t106 = insertvalue %Color %t105, i8 255, 3
	%c = alloca %Color
	store %Color %t106, ptr %c

	%t108 = xor i1 1, true
	br i1 %t108, label %base_block_label107, label %end_label107
base_block_label107:
	%t109 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %t109, i64 7)

	br label %end_label107
end_label107:

	%t110 = getelementptr inbounds [7 x i8], ptr @tstring7, i64 0, i64 0
	%t111 = insertvalue { ptr, i64 } undef, ptr %t110, 0
	%t112 = insertvalue { ptr, i64 } %t111, i64 6, 1       
	%t113 = load %Color, ptr %c
	%t114 = extractvalue %Color %t113, 0
	%t115 = zext i8 %t114 to i64
	call void @print_int({ ptr, i64 } %t112, i64 %t115)

	%t116 = getelementptr inbounds [7 x i8], ptr @tstring8, i64 0, i64 0
	%t117 = insertvalue { ptr, i64 } undef, ptr %t116, 0
	%t118 = insertvalue { ptr, i64 } %t117, i64 6, 1       
	%t119 = load %Color, ptr %c
	%t120 = extractvalue %Color %t119, 1
	%t121 = zext i8 %t120 to i64
	call void @print_int({ ptr, i64 } %t118, i64 %t121)

	%t122 = getelementptr inbounds [7 x i8], ptr @tstring9, i64 0, i64 0
	%t123 = insertvalue { ptr, i64 } undef, ptr %t122, 0
	%t124 = insertvalue { ptr, i64 } %t123, i64 6, 1       
	%t125 = load %Color, ptr %c
	%t126 = extractvalue %Color %t125, 2
	%t127 = zext i8 %t126 to i64
	call void @print_int({ ptr, i64 } %t124, i64 %t127)

	%t128 = getelementptr inbounds [7 x i8], ptr @tstring10, i64 0, i64 0
	%t129 = insertvalue { ptr, i64 } undef, ptr %t128, 0
	%t130 = insertvalue { ptr, i64 } %t129, i64 6, 1       
	%t131 = load %Color, ptr %c
	%t132 = extractvalue %Color %t131, 3
	%t133 = zext i8 %t132 to i64
	call void @print_int({ ptr, i64 } %t130, i64 %t133)

	%t134 = call i32 @GetColor(i32 4278190335)
	%t135 = alloca [4 x i8]
	store i32 %t134, ptr %t135
	%t136 = load %Color, ptr %t135
	%from_int = alloca %Color
	store %Color %t136, ptr %from_int

	%t137 = getelementptr inbounds [11 x i8], ptr @tstring11, i64 0, i64 0
	%t138 = insertvalue { ptr, i64 } undef, ptr %t137, 0
	%t139 = insertvalue { ptr, i64 } %t138, i64 10, 1       
	call void @print_int({ ptr, i64 } %t139, i64 0)

	%t140 = getelementptr inbounds [8 x i8], ptr @tstring12, i64 0, i64 0
	%t141 = insertvalue { ptr, i64 } undef, ptr %t140, 0
	%t142 = insertvalue { ptr, i64 } %t141, i64 7, 1       
	%t143 = load %Color, ptr %from_int
	%t144 = extractvalue %Color %t143, 0
	%t145 = zext i8 %t144 to i64
	call void @print_int({ ptr, i64 } %t142, i64 %t145)

	%t146 = getelementptr inbounds [8 x i8], ptr @tstring13, i64 0, i64 0
	%t147 = insertvalue { ptr, i64 } undef, ptr %t146, 0
	%t148 = insertvalue { ptr, i64 } %t147, i64 7, 1       
	%t149 = load %Color, ptr %from_int
	%t150 = extractvalue %Color %t149, 1
	%t151 = zext i8 %t150 to i64
	call void @print_int({ ptr, i64 } %t148, i64 %t151)

	%t152 = getelementptr inbounds [8 x i8], ptr @tstring14, i64 0, i64 0
	%t153 = insertvalue { ptr, i64 } undef, ptr %t152, 0
	%t154 = insertvalue { ptr, i64 } %t153, i64 7, 1       
	%t155 = load %Color, ptr %from_int
	%t156 = extractvalue %Color %t155, 2
	%t157 = zext i8 %t156 to i64
	call void @print_int({ ptr, i64 } %t154, i64 %t157)

	%t158 = getelementptr inbounds [8 x i8], ptr @tstring15, i64 0, i64 0
	%t159 = insertvalue { ptr, i64 } undef, ptr %t158, 0
	%t160 = insertvalue { ptr, i64 } %t159, i64 7, 1       
	%t161 = load %Color, ptr %from_int
	%t162 = extractvalue %Color %t161, 3
	%t163 = zext i8 %t162 to i64
	call void @print_int({ ptr, i64 } %t160, i64 %t163)

	%t164 = getelementptr inbounds [10 x i8], ptr @tstring16, i64 0, i64 0
	%t165 = insertvalue { ptr, i64 } undef, ptr %t164, 0
	%t166 = insertvalue { ptr, i64 } %t165, i64 9, 1       
	call void @print_flt({ ptr, i64 } %t166, float 0x400921FF20000000)

	%t167 = insertvalue %v2 undef, float 0x3FF3333340000000, 0
	%t168 = insertvalue %v2 %t167, float 0x40019999A0000000, 1
	%a = alloca %v2
	store %v2 %t168, ptr %a

	%t169 = insertvalue %v2 undef, float 0x3FF0000000000000, 0
	%t170 = insertvalue %v2 %t169, float 0x4000000000000000, 1
	%b = alloca %v2
	store %v2 %t170, ptr %b

	%t171 = load %v2, ptr %a
	%t172 = alloca [8 x i8]
	store %v2 %t171, ptr %t172
	%t173 = load i64, ptr %t172
	%t174 = load %v2, ptr %b
	%t175 = alloca [8 x i8]
	store %v2 %t174, ptr %t175
	%t176 = load i64, ptr %t175
	%t177 = call i64 @Vector2Add(i64 %t173, i64 %t176)
	%t178 = alloca [8 x i8]
	store i64 %t177, ptr %t178
	%t179 = load %v2, ptr %t178
	%v = alloca %v2
	store %v2 %t179, ptr %v

	%t180 = getelementptr inbounds [8 x i8], ptr @tstring17, i64 0, i64 0
	%t181 = insertvalue { ptr, i64 } undef, ptr %t180, 0
	%t182 = insertvalue { ptr, i64 } %t181, i64 7, 1       
	%t183 = load %v2, ptr %v
	%t184 = extractvalue %v2 %t183, 0
	call void @print_flt({ ptr, i64 } %t182, float %t184)

	%t185 = getelementptr inbounds [8 x i8], ptr @tstring18, i64 0, i64 0
	%t186 = insertvalue { ptr, i64 } undef, ptr %t185, 0
	%t187 = insertvalue { ptr, i64 } %t186, i64 7, 1       
	%t188 = load %v2, ptr %v
	%t189 = extractvalue %v2 %t188, 1
	call void @print_flt({ ptr, i64 } %t187, float %t189)

	%t190 = load %v2, ptr %v
	%t191 = extractvalue %v2 %t190, 0
	%t192 = bitcast float %t191 to i32
	%x = alloca i32
	store i32 %t192, ptr %x

	%t193 = load i32, ptr %x
	%t194 = call [4 x i8] @dump_i32_2(i32 %t193)
	%buf = alloca [4 x i8]
	store [4 x i8] %t194, ptr %buf

	%t195 = getelementptr inbounds [14 x i8], ptr @tstring19, i64 0, i64 0
	%t196 = insertvalue { ptr, i64 } undef, ptr %t195, 0
	%t197 = insertvalue { ptr, i64 } %t196, i64 13, 1       
	%t198 = getelementptr inbounds i8, ptr %buf, i64 0
	%t199 = load i8, ptr %t198
	call void @print_byte({ ptr, i64 } %t197, i8 %t199)

	%t200 = getelementptr inbounds [14 x i8], ptr @tstring20, i64 0, i64 0
	%t201 = insertvalue { ptr, i64 } undef, ptr %t200, 0
	%t202 = insertvalue { ptr, i64 } %t201, i64 13, 1       
	%t203 = getelementptr inbounds i8, ptr %buf, i64 1
	%t204 = load i8, ptr %t203
	call void @print_byte({ ptr, i64 } %t202, i8 %t204)

	%t205 = getelementptr inbounds [14 x i8], ptr @tstring21, i64 0, i64 0
	%t206 = insertvalue { ptr, i64 } undef, ptr %t205, 0
	%t207 = insertvalue { ptr, i64 } %t206, i64 13, 1       
	%t208 = getelementptr inbounds i8, ptr %buf, i64 2
	%t209 = load i8, ptr %t208
	call void @print_byte({ ptr, i64 } %t207, i8 %t209)

	%t210 = getelementptr inbounds [14 x i8], ptr @tstring22, i64 0, i64 0
	%t211 = insertvalue { ptr, i64 } undef, ptr %t210, 0
	%t212 = insertvalue { ptr, i64 } %t211, i64 13, 1       
	%t213 = getelementptr inbounds i8, ptr %buf, i64 3
	%t214 = load i8, ptr %t213
	call void @print_byte({ ptr, i64 } %t212, i8 %t214)

	%t215 = load %v2, ptr %v
	%t216 = extractvalue %v2 %t215, 1
	%t217 = bitcast float %t216 to i32
	%y = alloca i32
	store i32 %t217, ptr %y

	%t218 = load i32, ptr %y
	%t219 = call [4 x i8] @dump_i32_2(i32 %t218)
	store [4 x i8] %t219, ptr %buf

	%t220 = getelementptr inbounds [14 x i8], ptr @tstring23, i64 0, i64 0
	%t221 = insertvalue { ptr, i64 } undef, ptr %t220, 0
	%t222 = insertvalue { ptr, i64 } %t221, i64 13, 1       
	%t223 = getelementptr inbounds i8, ptr %buf, i64 0
	%t224 = load i8, ptr %t223
	call void @print_byte({ ptr, i64 } %t222, i8 %t224)

	%t225 = getelementptr inbounds [14 x i8], ptr @tstring24, i64 0, i64 0
	%t226 = insertvalue { ptr, i64 } undef, ptr %t225, 0
	%t227 = insertvalue { ptr, i64 } %t226, i64 13, 1       
	%t228 = getelementptr inbounds i8, ptr %buf, i64 1
	%t229 = load i8, ptr %t228
	call void @print_byte({ ptr, i64 } %t227, i8 %t229)

	%t230 = getelementptr inbounds [14 x i8], ptr @tstring25, i64 0, i64 0
	%t231 = insertvalue { ptr, i64 } undef, ptr %t230, 0
	%t232 = insertvalue { ptr, i64 } %t231, i64 13, 1       
	%t233 = getelementptr inbounds i8, ptr %buf, i64 2
	%t234 = load i8, ptr %t233
	call void @print_byte({ ptr, i64 } %t232, i8 %t234)

	%t235 = getelementptr inbounds [14 x i8], ptr @tstring26, i64 0, i64 0
	%t236 = insertvalue { ptr, i64 } undef, ptr %t235, 0
	%t237 = insertvalue { ptr, i64 } %t236, i64 13, 1       
	%t238 = getelementptr inbounds i8, ptr %buf, i64 3
	%t239 = load i8, ptr %t238
	call void @print_byte({ ptr, i64 } %t237, i8 %t239)

	%t240 = load ptr, ptr %data
	%t241 = bitcast ptr %t240 to ptr
	call void @free(ptr %t241)

	%t242 = load ptr, ptr %name
	%t243 = bitcast ptr %t242 to ptr
	call void @free(ptr %t243)

	%t244 = getelementptr inbounds i8, ptr %buf, i64 2
	%t245 = load i8, ptr %t244
	%t246 = zext i8 %t245 to i64
	ret i64 %t246

}
