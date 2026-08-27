; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu" 
%Color = type {i8,i8,i8,i8}
%v2 = type {float,float}
@string1 = private unnamed_addr constant [16 x i8] c"n byte 0: %.2x\0A\00", align 1

@string2 = private unnamed_addr constant [16 x i8] c"n byte 1: %.2x\0A\00", align 1

@string3 = private unnamed_addr constant [16 x i8] c"n byte 2: %.2x\0A\00", align 1

@string4 = private unnamed_addr constant [16 x i8] c"n byte 3: %.2x\0A\00", align 1

@string5 = private unnamed_addr constant [18 x i8] c"Hello, World! %d\0A\00", align 1

@string6 = private unnamed_addr constant [26 x i8] c"Hello, Raylib from Gala!!\00", align 1

@string7 = private unnamed_addr constant [7 x i8] c"r: %d\0A\00", align 1

@string8 = private unnamed_addr constant [7 x i8] c"g: %d\0A\00", align 1

@string9 = private unnamed_addr constant [7 x i8] c"b: %d\0A\00", align 1

@string10 = private unnamed_addr constant [7 x i8] c"a: %d\0A\00", align 1

@string11 = private unnamed_addr constant [11 x i8] c"GetColor:\0A\00", align 1

@string12 = private unnamed_addr constant [8 x i8] c"\09r: %d\0A\00", align 1

@string13 = private unnamed_addr constant [8 x i8] c"\09g: %d\0A\00", align 1

@string14 = private unnamed_addr constant [8 x i8] c"\09b: %d\0A\00", align 1

@string15 = private unnamed_addr constant [8 x i8] c"\09a: %d\0A\00", align 1

@string16 = private unnamed_addr constant [10 x i8] c"smth: %f\0A\00", align 1

@string17 = private unnamed_addr constant [8 x i8] c"\09x: %f\0A\00", align 1

@string18 = private unnamed_addr constant [8 x i8] c"\09y: %f\0A\00", align 1

@string19 = private unnamed_addr constant [14 x i8] c"xbuf 0: %.2x\0A\00", align 1

@string20 = private unnamed_addr constant [14 x i8] c"xbuf 1: %.2x\0A\00", align 1

@string21 = private unnamed_addr constant [14 x i8] c"xbuf 2: %.2x\0A\00", align 1

@string22 = private unnamed_addr constant [14 x i8] c"xbuf 3: %.2x\0A\00", align 1

@string23 = private unnamed_addr constant [14 x i8] c"ybuf 0: %.2x\0A\00", align 1

@string24 = private unnamed_addr constant [14 x i8] c"ybuf 1: %.2x\0A\00", align 1

@string25 = private unnamed_addr constant [14 x i8] c"ybuf 2: %.2x\0A\00", align 1

@string26 = private unnamed_addr constant [14 x i8] c"ybuf 3: %.2x\0A\00", align 1

@string27 = private unnamed_addr constant [13 x i8] c"zbuf 0: %dx\0A\00", align 1

@string28 = private unnamed_addr constant [13 x i8] c"zbuf 1: %dx\0A\00", align 1

@string29 = private unnamed_addr constant [13 x i8] c"zbuf 2: %dx\0A\00", align 1

@string30 = private unnamed_addr constant [13 x i8] c"zbuf 3: %dx\0A\00", align 1

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
	%31 = extractvalue { ptr, i64 } %s, 1
	%32 = mul i64 %31, 1
	%size = alloca i64
	store i64 %32, ptr %size

	%33 = load i64, ptr %size
	%34 = add i64 %33, 1
	%35 = call ptr @calloc(i64 1, i64 %34)
	%cstr = alloca ptr
	store ptr %35, ptr %cstr

	%36 = load ptr, ptr %cstr
	%37 = extractvalue { ptr, i64 } %s, 0
	%38 = getelementptr inbounds i8, ptr %37, i64 0
	%39 = load i64, ptr %size
	call void @memcpy(ptr %36, ptr %38, i64 %39)

	%40 = load ptr, ptr %cstr
	%41 = bitcast ptr %40 to ptr
	ret ptr %41

}
define void @print_int ({ ptr, i64 } %s, i64 %n) {
entry:
	%42 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %42, ptr %data

	%43 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %43, i64 %n)

	%44 = load ptr, ptr %data
	%45 = bitcast ptr %44 to ptr
	call void @free(ptr %45)

	ret void

}
define void @print_flt ({ ptr, i64 } %s, float %n) {
entry:
	%46 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %46, ptr %data

	%47 = load ptr, ptr %data
	%48 = fpext float %n to double
	call void (ptr, ...)@printf(ptr %47, double %48)

	%49 = load ptr, ptr %data
	%50 = bitcast ptr %49 to ptr
	call void @free(ptr %50)

	ret void

}
define void @print_byte ({ ptr, i64 } %s, i8 %n) {
entry:
	%51 = call ptr @to_cstr({ ptr, i64 } %s)
	%data = alloca ptr
	store ptr %51, ptr %data

	%52 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %52, i8 %n)

	%53 = load ptr, ptr %data
	%54 = bitcast ptr %53 to ptr
	call void @free(ptr %54)

	ret void

}
declare i64 @Vector2Add (i64 %a, i64 %b)
define [4 x i8] @dump_i32_2 (i32 %n) {
entry:
	%y = alloca i32
	store i32 %n, ptr %y

	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%55 = bitcast ptr %buf to ptr
	%56 = bitcast ptr %y to ptr
	call void @memcpy(ptr %55, ptr %56, i64 4)

	%57 = load [4 x i8], ptr %buf
	ret [4 x i8] %57

}
define [4 x i8] @dump_i32 (i32 %n) {
entry:
	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%y = alloca i32
	store i32 %n, ptr %y

	%58 = bitcast ptr %y to ptr
	%59 = load i8, ptr %58
	%s1 = alloca i8
	store i8 %59, ptr %s1

	%a = alloca i64
	store i64 1, ptr %a

	%60 = getelementptr inbounds [16 x i8], ptr @string1, i64 0, i64 0
	%61 = insertvalue { ptr, i64 } undef, ptr %60, 0
	%62 = insertvalue { ptr, i64 } %61, i64 15, 1       
	%63 = load i8, ptr %s1
	call void @print_byte({ ptr, i64 } %62, i8 %63)

	%64 = ptrtoint ptr %y to i64
	%65 = add i64 %64, 1
	%66 = inttoptr i64 %65 to ptr
	%67 = load i8, ptr %66
	%s2 = alloca i8
	store i8 %67, ptr %s2

	%68 = getelementptr inbounds [16 x i8], ptr @string2, i64 0, i64 0
	%69 = insertvalue { ptr, i64 } undef, ptr %68, 0
	%70 = insertvalue { ptr, i64 } %69, i64 15, 1       
	%71 = load i8, ptr %s2
	call void @print_byte({ ptr, i64 } %70, i8 %71)

	%72 = ptrtoint ptr %y to i64
	%73 = add i64 %72, 2
	%74 = inttoptr i64 %73 to ptr
	%75 = load i8, ptr %74
	%s3 = alloca i8
	store i8 %75, ptr %s3

	%76 = getelementptr inbounds [16 x i8], ptr @string3, i64 0, i64 0
	%77 = insertvalue { ptr, i64 } undef, ptr %76, 0
	%78 = insertvalue { ptr, i64 } %77, i64 15, 1       
	%79 = load i8, ptr %s3
	call void @print_byte({ ptr, i64 } %78, i8 %79)

	%80 = ptrtoint ptr %y to i64
	%81 = add i64 %80, 3
	%82 = inttoptr i64 %81 to ptr
	%83 = load i8, ptr %82
	%s4 = alloca i8
	store i8 %83, ptr %s4

	%84 = getelementptr inbounds [16 x i8], ptr @string4, i64 0, i64 0
	%85 = insertvalue { ptr, i64 } undef, ptr %84, 0
	%86 = insertvalue { ptr, i64 } %85, i64 15, 1       
	%87 = load i8, ptr %s4
	call void @print_byte({ ptr, i64 } %86, i8 %87)

	%88 = load i8, ptr %s1
	%89 = getelementptr inbounds i8, ptr %buf, i64 0
	store i8 %88, ptr %89

	%90 = load i8, ptr %s2
	%91 = getelementptr inbounds i8, ptr %buf, i64 1
	store i8 %90, ptr %91

	%92 = load i8, ptr %s3
	%93 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 %92, ptr %93

	%94 = load i8, ptr %s4
	%95 = getelementptr inbounds i8, ptr %buf, i64 3
	store i8 %94, ptr %95

	%96 = load [4 x i8], ptr %buf
	ret [4 x i8] %96

}
define i64 @main () {
entry:
	%97 = getelementptr inbounds [18 x i8], ptr @string5, i64 0, i64 0
	%98 = insertvalue { ptr, i64 } undef, ptr %97, 0
	%99 = insertvalue { ptr, i64 } %98, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %99, ptr %s

	%100 = load { ptr, i64 }, ptr %s
	%101 = call ptr @to_cstr({ ptr, i64 } %100)
	%data = alloca ptr
	store ptr %101, ptr %data

	%102 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %102, i64 9)

	%103 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %103, i64 8)

	%104 = getelementptr inbounds [26 x i8], ptr @string6, i64 0, i64 0
	%105 = insertvalue { ptr, i64 } undef, ptr %104, 0
	%106 = insertvalue { ptr, i64 } %105, i64 25, 1       
	%107 = call ptr @to_cstr({ ptr, i64 } %106)
	%name = alloca ptr
	store ptr %107, ptr %name

	%108 = insertvalue %Color undef, i8 123, 0
	%109 = insertvalue %Color %108, i8 222, 1
	%110 = insertvalue %Color %109, i8 255, 2
	%111 = insertvalue %Color %110, i8 255, 3
	%c = alloca %Color
	store %Color %111, ptr %c

	%113 = xor i1 1, true
	br i1 %113, label %base_block_label112, label %end_label112
base_block_label112:
	%114 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %114, i64 7)

	br label %end_label112
end_label112:

	%115 = getelementptr inbounds [7 x i8], ptr @string7, i64 0, i64 0
	%116 = insertvalue { ptr, i64 } undef, ptr %115, 0
	%117 = insertvalue { ptr, i64 } %116, i64 6, 1       
	%118 = load %Color, ptr %c
	%119 = extractvalue %Color %118, 0
	%120 = zext i8 %119 to i64
	call void @print_int({ ptr, i64 } %117, i64 %120)

	%121 = getelementptr inbounds [7 x i8], ptr @string8, i64 0, i64 0
	%122 = insertvalue { ptr, i64 } undef, ptr %121, 0
	%123 = insertvalue { ptr, i64 } %122, i64 6, 1       
	%124 = load %Color, ptr %c
	%125 = extractvalue %Color %124, 1
	%126 = zext i8 %125 to i64
	call void @print_int({ ptr, i64 } %123, i64 %126)

	%127 = getelementptr inbounds [7 x i8], ptr @string9, i64 0, i64 0
	%128 = insertvalue { ptr, i64 } undef, ptr %127, 0
	%129 = insertvalue { ptr, i64 } %128, i64 6, 1       
	%130 = load %Color, ptr %c
	%131 = extractvalue %Color %130, 2
	%132 = zext i8 %131 to i64
	call void @print_int({ ptr, i64 } %129, i64 %132)

	%133 = getelementptr inbounds [7 x i8], ptr @string10, i64 0, i64 0
	%134 = insertvalue { ptr, i64 } undef, ptr %133, 0
	%135 = insertvalue { ptr, i64 } %134, i64 6, 1       
	%136 = load %Color, ptr %c
	%137 = extractvalue %Color %136, 3
	%138 = zext i8 %137 to i64
	call void @print_int({ ptr, i64 } %135, i64 %138)

	%139 = call i32 @GetColor(i32 4278190335)
	%140 = alloca [4 x i8]
	store i32 %139, ptr %140
	%141 = load %Color, ptr %140
	%from_int = alloca %Color
	store %Color %141, ptr %from_int

	%142 = getelementptr inbounds [11 x i8], ptr @string11, i64 0, i64 0
	%143 = insertvalue { ptr, i64 } undef, ptr %142, 0
	%144 = insertvalue { ptr, i64 } %143, i64 10, 1       
	call void @print_int({ ptr, i64 } %144, i64 0)

	%145 = getelementptr inbounds [8 x i8], ptr @string12, i64 0, i64 0
	%146 = insertvalue { ptr, i64 } undef, ptr %145, 0
	%147 = insertvalue { ptr, i64 } %146, i64 7, 1       
	%148 = load %Color, ptr %from_int
	%149 = extractvalue %Color %148, 0
	%150 = zext i8 %149 to i64
	call void @print_int({ ptr, i64 } %147, i64 %150)

	%151 = getelementptr inbounds [8 x i8], ptr @string13, i64 0, i64 0
	%152 = insertvalue { ptr, i64 } undef, ptr %151, 0
	%153 = insertvalue { ptr, i64 } %152, i64 7, 1       
	%154 = load %Color, ptr %from_int
	%155 = extractvalue %Color %154, 1
	%156 = zext i8 %155 to i64
	call void @print_int({ ptr, i64 } %153, i64 %156)

	%157 = getelementptr inbounds [8 x i8], ptr @string14, i64 0, i64 0
	%158 = insertvalue { ptr, i64 } undef, ptr %157, 0
	%159 = insertvalue { ptr, i64 } %158, i64 7, 1       
	%160 = load %Color, ptr %from_int
	%161 = extractvalue %Color %160, 2
	%162 = zext i8 %161 to i64
	call void @print_int({ ptr, i64 } %159, i64 %162)

	%163 = getelementptr inbounds [8 x i8], ptr @string15, i64 0, i64 0
	%164 = insertvalue { ptr, i64 } undef, ptr %163, 0
	%165 = insertvalue { ptr, i64 } %164, i64 7, 1       
	%166 = load %Color, ptr %from_int
	%167 = extractvalue %Color %166, 3
	%168 = zext i8 %167 to i64
	call void @print_int({ ptr, i64 } %165, i64 %168)

	%169 = getelementptr inbounds [10 x i8], ptr @string16, i64 0, i64 0
	%170 = insertvalue { ptr, i64 } undef, ptr %169, 0
	%171 = insertvalue { ptr, i64 } %170, i64 9, 1       
	call void @print_flt({ ptr, i64 } %171, float 0x400921FF20000000)

	%172 = insertvalue %v2 undef, float 0x3FF3333340000000, 0
	%173 = insertvalue %v2 %172, float 0x40019999A0000000, 1
	%a = alloca %v2
	store %v2 %173, ptr %a

	%174 = insertvalue %v2 undef, float 0x3FF0000000000000, 0
	%175 = insertvalue %v2 %174, float 0x4000000000000000, 1
	%b = alloca %v2
	store %v2 %175, ptr %b

	%176 = load %v2, ptr %a
	%177 = alloca [8 x i8]
	store %v2 %176, ptr %177
	%178 = load i64, ptr %177
	%179 = load %v2, ptr %b
	%180 = alloca [8 x i8]
	store %v2 %179, ptr %180
	%181 = load i64, ptr %180
	%182 = call i64 @Vector2Add(i64 %178, i64 %181)
	%183 = alloca [8 x i8]
	store i64 %182, ptr %183
	%184 = load %v2, ptr %183
	%v = alloca %v2
	store %v2 %184, ptr %v

	%185 = getelementptr inbounds [8 x i8], ptr @string17, i64 0, i64 0
	%186 = insertvalue { ptr, i64 } undef, ptr %185, 0
	%187 = insertvalue { ptr, i64 } %186, i64 7, 1       
	%188 = load %v2, ptr %v
	%189 = extractvalue %v2 %188, 0
	call void @print_flt({ ptr, i64 } %187, float %189)

	%190 = getelementptr inbounds [8 x i8], ptr @string18, i64 0, i64 0
	%191 = insertvalue { ptr, i64 } undef, ptr %190, 0
	%192 = insertvalue { ptr, i64 } %191, i64 7, 1       
	%193 = load %v2, ptr %v
	%194 = extractvalue %v2 %193, 1
	call void @print_flt({ ptr, i64 } %192, float %194)

	%195 = load %v2, ptr %v
	%196 = extractvalue %v2 %195, 0
	%197 = bitcast float %196 to i32
	%x = alloca i32
	store i32 %197, ptr %x

	%198 = load i32, ptr %x
	%199 = call [4 x i8] @dump_i32_2(i32 %198)
	%buf = alloca [4 x i8]
	store [4 x i8] %199, ptr %buf

	%200 = getelementptr inbounds [14 x i8], ptr @string19, i64 0, i64 0
	%201 = insertvalue { ptr, i64 } undef, ptr %200, 0
	%202 = insertvalue { ptr, i64 } %201, i64 13, 1       
	%203 = getelementptr inbounds i8, ptr %buf, i64 0
	%204 = load i8, ptr %203
	call void @print_byte({ ptr, i64 } %202, i8 %204)

	%205 = getelementptr inbounds [14 x i8], ptr @string20, i64 0, i64 0
	%206 = insertvalue { ptr, i64 } undef, ptr %205, 0
	%207 = insertvalue { ptr, i64 } %206, i64 13, 1       
	%208 = getelementptr inbounds i8, ptr %buf, i64 1
	%209 = load i8, ptr %208
	call void @print_byte({ ptr, i64 } %207, i8 %209)

	%210 = getelementptr inbounds [14 x i8], ptr @string21, i64 0, i64 0
	%211 = insertvalue { ptr, i64 } undef, ptr %210, 0
	%212 = insertvalue { ptr, i64 } %211, i64 13, 1       
	%213 = getelementptr inbounds i8, ptr %buf, i64 2
	%214 = load i8, ptr %213
	call void @print_byte({ ptr, i64 } %212, i8 %214)

	%215 = getelementptr inbounds [14 x i8], ptr @string22, i64 0, i64 0
	%216 = insertvalue { ptr, i64 } undef, ptr %215, 0
	%217 = insertvalue { ptr, i64 } %216, i64 13, 1       
	%218 = getelementptr inbounds i8, ptr %buf, i64 3
	%219 = load i8, ptr %218
	call void @print_byte({ ptr, i64 } %217, i8 %219)

	%220 = load %v2, ptr %v
	%221 = extractvalue %v2 %220, 1
	%222 = bitcast float %221 to i32
	%y = alloca i32
	store i32 %222, ptr %y

	%223 = load i32, ptr %y
	%224 = call [4 x i8] @dump_i32_2(i32 %223)
	store [4 x i8] %224, ptr %buf

	%225 = getelementptr inbounds [14 x i8], ptr @string23, i64 0, i64 0
	%226 = insertvalue { ptr, i64 } undef, ptr %225, 0
	%227 = insertvalue { ptr, i64 } %226, i64 13, 1       
	%228 = getelementptr inbounds i8, ptr %buf, i64 0
	%229 = load i8, ptr %228
	call void @print_byte({ ptr, i64 } %227, i8 %229)

	%230 = getelementptr inbounds [14 x i8], ptr @string24, i64 0, i64 0
	%231 = insertvalue { ptr, i64 } undef, ptr %230, 0
	%232 = insertvalue { ptr, i64 } %231, i64 13, 1       
	%233 = getelementptr inbounds i8, ptr %buf, i64 1
	%234 = load i8, ptr %233
	call void @print_byte({ ptr, i64 } %232, i8 %234)

	%235 = getelementptr inbounds [14 x i8], ptr @string25, i64 0, i64 0
	%236 = insertvalue { ptr, i64 } undef, ptr %235, 0
	%237 = insertvalue { ptr, i64 } %236, i64 13, 1       
	%238 = getelementptr inbounds i8, ptr %buf, i64 2
	%239 = load i8, ptr %238
	call void @print_byte({ ptr, i64 } %237, i8 %239)

	%240 = getelementptr inbounds [14 x i8], ptr @string26, i64 0, i64 0
	%241 = insertvalue { ptr, i64 } undef, ptr %240, 0
	%242 = insertvalue { ptr, i64 } %241, i64 13, 1       
	%243 = getelementptr inbounds i8, ptr %buf, i64 3
	%244 = load i8, ptr %243
	call void @print_byte({ ptr, i64 } %242, i8 %244)

	%245 = load ptr, ptr %data
	%246 = bitcast ptr %245 to ptr
	call void @free(ptr %246)

	%247 = load ptr, ptr %name
	%248 = bitcast ptr %247 to ptr
	call void @free(ptr %248)

	%249 = insertvalue %Color undef, i8 225, 0
	%250 = insertvalue %Color %249, i8 123, 1
	%251 = insertvalue %Color %250, i8 0, 2
	%252 = insertvalue %Color %251, i8 100, 3
	%colour = alloca %Color
	store %Color %252, ptr %colour

	%253 = load i32, ptr %colour
	%z = alloca i32
	store i32 %253, ptr %z

	%254 = load i32, ptr %z
	%255 = call [4 x i8] @dump_i32_2(i32 %254)
	store [4 x i8] %255, ptr %buf

	%256 = getelementptr inbounds [13 x i8], ptr @string27, i64 0, i64 0
	%257 = insertvalue { ptr, i64 } undef, ptr %256, 0
	%258 = insertvalue { ptr, i64 } %257, i64 12, 1       
	%259 = getelementptr inbounds i8, ptr %buf, i64 0
	%260 = load i8, ptr %259
	call void @print_byte({ ptr, i64 } %258, i8 %260)

	%261 = getelementptr inbounds [13 x i8], ptr @string28, i64 0, i64 0
	%262 = insertvalue { ptr, i64 } undef, ptr %261, 0
	%263 = insertvalue { ptr, i64 } %262, i64 12, 1       
	%264 = getelementptr inbounds i8, ptr %buf, i64 1
	%265 = load i8, ptr %264
	call void @print_byte({ ptr, i64 } %263, i8 %265)

	%266 = getelementptr inbounds [13 x i8], ptr @string29, i64 0, i64 0
	%267 = insertvalue { ptr, i64 } undef, ptr %266, 0
	%268 = insertvalue { ptr, i64 } %267, i64 12, 1       
	%269 = getelementptr inbounds i8, ptr %buf, i64 2
	%270 = load i8, ptr %269
	call void @print_byte({ ptr, i64 } %268, i8 %270)

	%271 = getelementptr inbounds [13 x i8], ptr @string30, i64 0, i64 0
	%272 = insertvalue { ptr, i64 } undef, ptr %271, 0
	%273 = insertvalue { ptr, i64 } %272, i64 12, 1       
	%274 = getelementptr inbounds i8, ptr %buf, i64 3
	%275 = load i8, ptr %274
	call void @print_byte({ ptr, i64 } %273, i8 %275)

	%276 = getelementptr inbounds i8, ptr %buf, i64 2
	%277 = load i8, ptr %276
	%278 = zext i8 %277 to i64
	ret i64 %278

}
