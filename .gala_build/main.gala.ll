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

declare void @printf (ptr, ...)
declare ptr @calloc (i64, i64)
declare void @memcpy (ptr, ptr, i64)
declare void @free (ptr)
declare void @InitWindow (i64, i64, ptr)
declare void @CloseWindow ()
declare i1 @WindowShouldClose ()
declare void @BeginDrawing ()
declare void @EndDrawing ()
declare void @ClearBackground (i32)
declare i32 @GetColor (i32)
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
declare double @Vector2Add (double, double)
define i32 @dump_i32_2 (i32 %n) {
entry:
	%y = alloca i32
	store i32 %n, ptr %y

	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%55 = bitcast ptr %buf to ptr
	%56 = bitcast ptr %y to ptr
	call void @memcpy(ptr %55, ptr %56, i64 4)

	%57 = load [4 x i8], ptr %buf
	%58 = alloca [4 x i8]
	store [4 x i8] %57, ptr %58
	%59 = load i32, ptr %58
	ret i32 %59

}
define i32 @dump_i32 (i32 %n) {
entry:
	%buf = alloca [4 x i8]
	store [4 x i8] zeroinitializer, ptr %buf

	%y = alloca i32
	store i32 %n, ptr %y

	%60 = bitcast ptr %y to ptr
	%61 = load i8, ptr %60
	%s1 = alloca i8
	store i8 %61, ptr %s1

	%a = alloca i64
	store i64 1, ptr %a

	%62 = getelementptr inbounds [16 x i8], ptr @string1, i64 0, i64 0
	%63 = insertvalue { ptr, i64 } undef, ptr %62, 0
	%64 = insertvalue { ptr, i64 } %63, i64 15, 1       
	%65 = load i8, ptr %s1
	call void @print_byte({ ptr, i64 } %64, i8 %65)

	%66 = ptrtoint ptr %y to i64
	%67 = add i64 %66, 1
	%68 = inttoptr i64 %67 to ptr
	%69 = load i8, ptr %68
	%s2 = alloca i8
	store i8 %69, ptr %s2

	%70 = getelementptr inbounds [16 x i8], ptr @string2, i64 0, i64 0
	%71 = insertvalue { ptr, i64 } undef, ptr %70, 0
	%72 = insertvalue { ptr, i64 } %71, i64 15, 1       
	%73 = load i8, ptr %s2
	call void @print_byte({ ptr, i64 } %72, i8 %73)

	%74 = ptrtoint ptr %y to i64
	%75 = add i64 %74, 2
	%76 = inttoptr i64 %75 to ptr
	%77 = load i8, ptr %76
	%s3 = alloca i8
	store i8 %77, ptr %s3

	%78 = getelementptr inbounds [16 x i8], ptr @string3, i64 0, i64 0
	%79 = insertvalue { ptr, i64 } undef, ptr %78, 0
	%80 = insertvalue { ptr, i64 } %79, i64 15, 1       
	%81 = load i8, ptr %s3
	call void @print_byte({ ptr, i64 } %80, i8 %81)

	%82 = ptrtoint ptr %y to i64
	%83 = add i64 %82, 3
	%84 = inttoptr i64 %83 to ptr
	%85 = load i8, ptr %84
	%s4 = alloca i8
	store i8 %85, ptr %s4

	%86 = getelementptr inbounds [16 x i8], ptr @string4, i64 0, i64 0
	%87 = insertvalue { ptr, i64 } undef, ptr %86, 0
	%88 = insertvalue { ptr, i64 } %87, i64 15, 1       
	%89 = load i8, ptr %s4
	call void @print_byte({ ptr, i64 } %88, i8 %89)

	%90 = load i8, ptr %s1
	%91 = getelementptr inbounds i8, ptr %buf, i64 0
	store i8 %90, ptr %91

	%92 = load i8, ptr %s2
	%93 = getelementptr inbounds i8, ptr %buf, i64 1
	store i8 %92, ptr %93

	%94 = load i8, ptr %s3
	%95 = getelementptr inbounds i8, ptr %buf, i64 2
	store i8 %94, ptr %95

	%96 = load i8, ptr %s4
	%97 = getelementptr inbounds i8, ptr %buf, i64 3
	store i8 %96, ptr %97

	%98 = load [4 x i8], ptr %buf
	%99 = alloca [4 x i8]
	store [4 x i8] %98, ptr %99
	%100 = load i32, ptr %99
	ret i32 %100

}
define i64 @main () {
entry:
	%101 = getelementptr inbounds [18 x i8], ptr @string5, i64 0, i64 0
	%102 = insertvalue { ptr, i64 } undef, ptr %101, 0
	%103 = insertvalue { ptr, i64 } %102, i64 17, 1       
	%s = alloca { ptr, i64 }
	store { ptr, i64 } %103, ptr %s

	%104 = load { ptr, i64 }, ptr %s
	%105 = call ptr @to_cstr({ ptr, i64 } %104)
	%data = alloca ptr
	store ptr %105, ptr %data

	%106 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %106, i64 9)

	%107 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %107, i64 8)

	%108 = getelementptr inbounds [26 x i8], ptr @string6, i64 0, i64 0
	%109 = insertvalue { ptr, i64 } undef, ptr %108, 0
	%110 = insertvalue { ptr, i64 } %109, i64 25, 1       
	%111 = call ptr @to_cstr({ ptr, i64 } %110)
	%name = alloca ptr
	store ptr %111, ptr %name

	%112 = load ptr, ptr %name
	call void @InitWindow(i64 800, i64 600, ptr %112)

	%113 = insertvalue %Color undef, i8 123, 0
	%114 = insertvalue %Color %113, i8 222, 1
	%115 = insertvalue %Color %114, i8 255, 2
	%116 = insertvalue %Color %115, i8 255, 3
	%c = alloca %Color
	store %Color %116, ptr %c

	%118 = xor i1 1, true
	br i1 %118, label %base_block_label117, label %end_label117
base_block_label117:
	%119 = load ptr, ptr %data
	call void (ptr, ...)@printf(ptr %119, i64 7)

	br label %end_label117
end_label117:

	%120 = getelementptr inbounds [7 x i8], ptr @string7, i64 0, i64 0
	%121 = insertvalue { ptr, i64 } undef, ptr %120, 0
	%122 = insertvalue { ptr, i64 } %121, i64 6, 1       
	%123 = load %Color, ptr %c
	%124 = extractvalue %Color %123, 0
	%125 = zext i8 %124 to i64
	call void @print_int({ ptr, i64 } %122, i64 %125)

	%126 = getelementptr inbounds [7 x i8], ptr @string8, i64 0, i64 0
	%127 = insertvalue { ptr, i64 } undef, ptr %126, 0
	%128 = insertvalue { ptr, i64 } %127, i64 6, 1       
	%129 = load %Color, ptr %c
	%130 = extractvalue %Color %129, 1
	%131 = zext i8 %130 to i64
	call void @print_int({ ptr, i64 } %128, i64 %131)

	%132 = getelementptr inbounds [7 x i8], ptr @string9, i64 0, i64 0
	%133 = insertvalue { ptr, i64 } undef, ptr %132, 0
	%134 = insertvalue { ptr, i64 } %133, i64 6, 1       
	%135 = load %Color, ptr %c
	%136 = extractvalue %Color %135, 2
	%137 = zext i8 %136 to i64
	call void @print_int({ ptr, i64 } %134, i64 %137)

	%138 = getelementptr inbounds [7 x i8], ptr @string10, i64 0, i64 0
	%139 = insertvalue { ptr, i64 } undef, ptr %138, 0
	%140 = insertvalue { ptr, i64 } %139, i64 6, 1       
	%141 = load %Color, ptr %c
	%142 = extractvalue %Color %141, 3
	%143 = zext i8 %142 to i64
	call void @print_int({ ptr, i64 } %140, i64 %143)

	%144 = call i32 @GetColor(i32 4278190335)
	%145 = alloca %Color
	store i32 %144, ptr %145
	%146 = load %Color, ptr %145
	%from_int = alloca %Color
	store %Color %146, ptr %from_int

	%147 = getelementptr inbounds [11 x i8], ptr @string11, i64 0, i64 0
	%148 = insertvalue { ptr, i64 } undef, ptr %147, 0
	%149 = insertvalue { ptr, i64 } %148, i64 10, 1       
	call void @print_int({ ptr, i64 } %149, i64 0)

	%150 = getelementptr inbounds [8 x i8], ptr @string12, i64 0, i64 0
	%151 = insertvalue { ptr, i64 } undef, ptr %150, 0
	%152 = insertvalue { ptr, i64 } %151, i64 7, 1       
	%153 = load %Color, ptr %from_int
	%154 = extractvalue %Color %153, 0
	%155 = zext i8 %154 to i64
	call void @print_int({ ptr, i64 } %152, i64 %155)

	%156 = getelementptr inbounds [8 x i8], ptr @string13, i64 0, i64 0
	%157 = insertvalue { ptr, i64 } undef, ptr %156, 0
	%158 = insertvalue { ptr, i64 } %157, i64 7, 1       
	%159 = load %Color, ptr %from_int
	%160 = extractvalue %Color %159, 1
	%161 = zext i8 %160 to i64
	call void @print_int({ ptr, i64 } %158, i64 %161)

	%162 = getelementptr inbounds [8 x i8], ptr @string14, i64 0, i64 0
	%163 = insertvalue { ptr, i64 } undef, ptr %162, 0
	%164 = insertvalue { ptr, i64 } %163, i64 7, 1       
	%165 = load %Color, ptr %from_int
	%166 = extractvalue %Color %165, 2
	%167 = zext i8 %166 to i64
	call void @print_int({ ptr, i64 } %164, i64 %167)

	%168 = getelementptr inbounds [8 x i8], ptr @string15, i64 0, i64 0
	%169 = insertvalue { ptr, i64 } undef, ptr %168, 0
	%170 = insertvalue { ptr, i64 } %169, i64 7, 1       
	%171 = load %Color, ptr %from_int
	%172 = extractvalue %Color %171, 3
	%173 = zext i8 %172 to i64
	call void @print_int({ ptr, i64 } %170, i64 %173)

	%174 = getelementptr inbounds [10 x i8], ptr @string16, i64 0, i64 0
	%175 = insertvalue { ptr, i64 } undef, ptr %174, 0
	%176 = insertvalue { ptr, i64 } %175, i64 9, 1       
	call void @print_flt({ ptr, i64 } %176, float 0x400921FF20000000)

	br label %while_cond_label177
while_cond_label177:
	%178 = call i1 @WindowShouldClose()
	%179 = xor i1 %178, true
	br i1 %179, label %while_body_label177, label %while_end_label177
while_body_label177:
	call void @BeginDrawing()

	%180 = insertvalue %Color undef, i8 255, 0
	%181 = insertvalue %Color %180, i8 255, 1
	%182 = insertvalue %Color %181, i8 0, 2
	%183 = insertvalue %Color %182, i8 255, 3
	%184 = alloca %Color
	store %Color %183, ptr %184
	%185 = load i32, ptr %184
	call void @ClearBackground(i32 %185)

	call void @EndDrawing()

	br label %while_cond_label177
while_end_label177:

	%186 = insertvalue %v2 undef, float 0x3FF3333340000000, 0
	%187 = insertvalue %v2 %186, float 0x40019999A0000000, 1
	%a = alloca %v2
	store %v2 %187, ptr %a

	%188 = insertvalue %v2 undef, float 0x3FF0000000000000, 0
	%189 = insertvalue %v2 %188, float 0x4000000000000000, 1
	%b = alloca %v2
	store %v2 %189, ptr %b

	%190 = load %v2, ptr %a
	%191 = alloca %v2
	store %v2 %190, ptr %191
	%192 = load double, ptr %191
	%193 = load %v2, ptr %b
	%194 = alloca %v2
	store %v2 %193, ptr %194
	%195 = load double, ptr %194
	%196 = call double @Vector2Add(double %192, double %195)
	%197 = alloca %v2
	store double %196, ptr %197
	%198 = load %v2, ptr %197
	%v = alloca %v2
	store %v2 %198, ptr %v

	%199 = getelementptr inbounds [8 x i8], ptr @string17, i64 0, i64 0
	%200 = insertvalue { ptr, i64 } undef, ptr %199, 0
	%201 = insertvalue { ptr, i64 } %200, i64 7, 1       
	%202 = load %v2, ptr %v
	%203 = extractvalue %v2 %202, 0
	call void @print_flt({ ptr, i64 } %201, float %203)

	%204 = getelementptr inbounds [8 x i8], ptr @string18, i64 0, i64 0
	%205 = insertvalue { ptr, i64 } undef, ptr %204, 0
	%206 = insertvalue { ptr, i64 } %205, i64 7, 1       
	%207 = load %v2, ptr %v
	%208 = extractvalue %v2 %207, 1
	call void @print_flt({ ptr, i64 } %206, float %208)

	%209 = load %v2, ptr %v
	%210 = extractvalue %v2 %209, 0
	%211 = bitcast float %210 to i32
	%x = alloca i32
	store i32 %211, ptr %x

	%212 = load i32, ptr %x
	%213 = call i32 @dump_i32_2(i32 %212)
	%214 = alloca [4 x i8]
	store i32 %213, ptr %214
	%215 = load [4 x i8], ptr %214
	%buf = alloca [4 x i8]
	store [4 x i8] %215, ptr %buf

	%216 = getelementptr inbounds [14 x i8], ptr @string19, i64 0, i64 0
	%217 = insertvalue { ptr, i64 } undef, ptr %216, 0
	%218 = insertvalue { ptr, i64 } %217, i64 13, 1       
	%219 = getelementptr inbounds i8, ptr %buf, i64 0
	%220 = load i8, ptr %219
	call void @print_byte({ ptr, i64 } %218, i8 %220)

	%221 = getelementptr inbounds [14 x i8], ptr @string20, i64 0, i64 0
	%222 = insertvalue { ptr, i64 } undef, ptr %221, 0
	%223 = insertvalue { ptr, i64 } %222, i64 13, 1       
	%224 = getelementptr inbounds i8, ptr %buf, i64 1
	%225 = load i8, ptr %224
	call void @print_byte({ ptr, i64 } %223, i8 %225)

	%226 = getelementptr inbounds [14 x i8], ptr @string21, i64 0, i64 0
	%227 = insertvalue { ptr, i64 } undef, ptr %226, 0
	%228 = insertvalue { ptr, i64 } %227, i64 13, 1       
	%229 = getelementptr inbounds i8, ptr %buf, i64 2
	%230 = load i8, ptr %229
	call void @print_byte({ ptr, i64 } %228, i8 %230)

	%231 = getelementptr inbounds [14 x i8], ptr @string22, i64 0, i64 0
	%232 = insertvalue { ptr, i64 } undef, ptr %231, 0
	%233 = insertvalue { ptr, i64 } %232, i64 13, 1       
	%234 = getelementptr inbounds i8, ptr %buf, i64 3
	%235 = load i8, ptr %234
	call void @print_byte({ ptr, i64 } %233, i8 %235)

	%236 = load %v2, ptr %v
	%237 = extractvalue %v2 %236, 1
	%238 = bitcast float %237 to i32
	%y = alloca i32
	store i32 %238, ptr %y

	%239 = load i32, ptr %y
	%240 = call i32 @dump_i32_2(i32 %239)
	%241 = alloca [4 x i8]
	store i32 %240, ptr %241
	%242 = load [4 x i8], ptr %241
	store [4 x i8] %242, ptr %buf

	%243 = getelementptr inbounds [14 x i8], ptr @string23, i64 0, i64 0
	%244 = insertvalue { ptr, i64 } undef, ptr %243, 0
	%245 = insertvalue { ptr, i64 } %244, i64 13, 1       
	%246 = getelementptr inbounds i8, ptr %buf, i64 0
	%247 = load i8, ptr %246
	call void @print_byte({ ptr, i64 } %245, i8 %247)

	%248 = getelementptr inbounds [14 x i8], ptr @string24, i64 0, i64 0
	%249 = insertvalue { ptr, i64 } undef, ptr %248, 0
	%250 = insertvalue { ptr, i64 } %249, i64 13, 1       
	%251 = getelementptr inbounds i8, ptr %buf, i64 1
	%252 = load i8, ptr %251
	call void @print_byte({ ptr, i64 } %250, i8 %252)

	%253 = getelementptr inbounds [14 x i8], ptr @string25, i64 0, i64 0
	%254 = insertvalue { ptr, i64 } undef, ptr %253, 0
	%255 = insertvalue { ptr, i64 } %254, i64 13, 1       
	%256 = getelementptr inbounds i8, ptr %buf, i64 2
	%257 = load i8, ptr %256
	call void @print_byte({ ptr, i64 } %255, i8 %257)

	%258 = getelementptr inbounds [14 x i8], ptr @string26, i64 0, i64 0
	%259 = insertvalue { ptr, i64 } undef, ptr %258, 0
	%260 = insertvalue { ptr, i64 } %259, i64 13, 1       
	%261 = getelementptr inbounds i8, ptr %buf, i64 3
	%262 = load i8, ptr %261
	call void @print_byte({ ptr, i64 } %260, i8 %262)

	%263 = load ptr, ptr %data
	%264 = bitcast ptr %263 to ptr
	call void @free(ptr %264)

	%265 = load ptr, ptr %name
	%266 = bitcast ptr %265 to ptr
	call void @free(ptr %266)

	%267 = insertvalue %Color undef, i8 225, 0
	%268 = insertvalue %Color %267, i8 123, 1
	%269 = insertvalue %Color %268, i8 0, 2
	%270 = insertvalue %Color %269, i8 100, 3
	%colour = alloca %Color
	store %Color %270, ptr %colour

	%271 = load i32, ptr %colour
	%z = alloca i32
	store i32 %271, ptr %z

	%272 = load i32, ptr %z
	%273 = call i32 @dump_i32_2(i32 %272)
	%274 = alloca [4 x i8]
	store i32 %273, ptr %274
	%275 = load [4 x i8], ptr %274
	store [4 x i8] %275, ptr %buf

	%276 = getelementptr inbounds [13 x i8], ptr @string27, i64 0, i64 0
	%277 = insertvalue { ptr, i64 } undef, ptr %276, 0
	%278 = insertvalue { ptr, i64 } %277, i64 12, 1       
	%279 = getelementptr inbounds i8, ptr %buf, i64 0
	%280 = load i8, ptr %279
	call void @print_byte({ ptr, i64 } %278, i8 %280)

	%281 = getelementptr inbounds [13 x i8], ptr @string28, i64 0, i64 0
	%282 = insertvalue { ptr, i64 } undef, ptr %281, 0
	%283 = insertvalue { ptr, i64 } %282, i64 12, 1       
	%284 = getelementptr inbounds i8, ptr %buf, i64 1
	%285 = load i8, ptr %284
	call void @print_byte({ ptr, i64 } %283, i8 %285)

	%286 = getelementptr inbounds [13 x i8], ptr @string29, i64 0, i64 0
	%287 = insertvalue { ptr, i64 } undef, ptr %286, 0
	%288 = insertvalue { ptr, i64 } %287, i64 12, 1       
	%289 = getelementptr inbounds i8, ptr %buf, i64 2
	%290 = load i8, ptr %289
	call void @print_byte({ ptr, i64 } %288, i8 %290)

	%291 = getelementptr inbounds [13 x i8], ptr @string30, i64 0, i64 0
	%292 = insertvalue { ptr, i64 } undef, ptr %291, 0
	%293 = insertvalue { ptr, i64 } %292, i64 12, 1       
	%294 = getelementptr inbounds i8, ptr %buf, i64 3
	%295 = load i8, ptr %294
	call void @print_byte({ ptr, i64 } %293, i8 %295)

	%296 = getelementptr inbounds i8, ptr %buf, i64 2
	%297 = load i8, ptr %296
	%298 = zext i8 %297 to i64
	ret i64 %298

}
