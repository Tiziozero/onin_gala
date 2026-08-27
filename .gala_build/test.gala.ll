; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu" 
%S1 = type {i8}
%S2 = type {i16}
%S3 = type {i8,i16}
%S4 = type {i32}
%S5 = type {i32,i32}
%S8 = type {i64}
%S12 = type {i64,i32}
%S16 = type {i64,i64}
%Int3 = type {i64,i64,i64}
%Int4 = type {i64,i64,i64,i64}
%F1 = type {float}
%F2 = type {float,float}
%F3 = type {float,float,float}
%F4 = type {float,float,float,float}
%D1 = type {double}
%D2 = type {double,double}
%D3 = type {double,double,double}
%IntFloat = type {i32,float}
%FloatInt = type {float,i32}
%IntDouble = type {i32,double}
%DoubleInt = type {double,i32}
%LongFloat = type {i64,float}
%FloatLong = type {float,i64}
%LongDouble_ = type {i64,double}
%DoubleLong = type {double,i64}
%NestedInt = type {%S8,%S8}
%NestedFloat = type {%F2,%F2}
%NestedMixed = type {%IntFloat,%IntFloat}
%NestedLarge = type {%S16,%S16}
%ArrayInt2 = type {[2 x i32]}
%ArrayInt3 = type {[3 x i32]}
%ArrayDouble2 = type {[2 x double]}
%ArrayFloat4 = type {[4 x float]}
declare void @printf (ptr, ...)
define i32 @f_int (i32 %a) {
entry:
	%1 = add i32 %a, 1
	ret i32 %1

}
define i64 @f_long (i64 %a, i64 %b) {
entry:
	%2 = mul i64 %a, %b
	ret i64 %2

}
define double @f_double (double %a, double %b) {
entry:
	%3 = fadd double %a, %b
	ret double %3

}
define float @f_float (float %a, float %b) {
entry:
	%4 = fmul float %a, %b
	ret float %4

}
define i8 @ret_s1 (i8 %x) {
entry:
	%5 = insertvalue %S1 undef, i8 %x, 0
	%6 = alloca %S1
	store %S1 %5, ptr %6
	%7 = load i8, ptr %6
	ret i8 %7

}
define i64 @ret_s5 (i32 %a, i32 %b) {
entry:
	%8 = insertvalue %S5 undef, i32 %a, 0
	%9 = insertvalue %S5 %8, i32 %b, 1
	%10 = alloca %S5
	store %S5 %9, ptr %10
	%11 = load i64, ptr %10
	ret i64 %11

}
define i64 @ret_s8 (i64 %x) {
entry:
	%12 = insertvalue %S8 undef, i64 %x, 0
	%13 = alloca %S8
	store %S8 %12, ptr %13
	%14 = load i64, ptr %13
	ret i64 %14

}
define { i64, i32 } @ret_s12 (i64 %a, i32 %b) {
entry:
	%15 = insertvalue %S12 undef, i64 %a, 0
	%16 = insertvalue %S12 %15, i32 %b, 1
	%17 = alloca %S12
	store %S12 %16, ptr %17
	%18 = load { i64, i32 }, ptr %17
	ret { i64, i32 } %18

}
define { i64, i64 } @ret_s16 (i64 %a, i64 %b) {
entry:
	%19 = insertvalue %S16 undef, i64 %a, 0
	%20 = insertvalue %S16 %19, i64 %b, 1
	%21 = alloca %S16
	store %S16 %20, ptr %21
	%22 = load { i64, i64 }, ptr %21
	ret { i64, i64 } %22

}
define void @ret_int3 (ptr sret(%Int3) align 8 %.sret, i64 %a, i64 %b, i64 %c) {
entry:
	%23 = insertvalue %Int3 undef, i64 %a, 0
	%24 = insertvalue %Int3 %23, i64 %b, 1
	%25 = insertvalue %Int3 %24, i64 %c, 2
	store %Int3 %25, ptr %.sret
	ret void

}
define float @ret_f1 (float %a) {
entry:
	%26 = insertvalue %F1 undef, float %a, 0
	%27 = alloca %F1
	store %F1 %26, ptr %27
	%28 = load float, ptr %27
	ret float %28

}
define double @ret_f2 (float %a, float %b) {
entry:
	%29 = insertvalue %F2 undef, float %a, 0
	%30 = insertvalue %F2 %29, float %b, 1
	%31 = alloca %F2
	store %F2 %30, ptr %31
	%32 = load double, ptr %31
	ret double %32

}
define { double, double } @ret_f4 (float %a, float %b, float %c, float %d) {
entry:
	%33 = insertvalue %F4 undef, float %a, 0
	%34 = insertvalue %F4 %33, float %b, 1
	%35 = insertvalue %F4 %34, float %c, 2
	%36 = insertvalue %F4 %35, float %d, 3
	%37 = alloca %F4
	store %F4 %36, ptr %37
	%38 = load { double, double }, ptr %37
	ret { double, double } %38

}
define double @ret_d1 (double %a) {
entry:
	%39 = insertvalue %D1 undef, double %a, 0
	%40 = alloca %D1
	store %D1 %39, ptr %40
	%41 = load double, ptr %40
	ret double %41

}
define { double, double } @ret_d2 (double %a, double %b) {
entry:
	%42 = insertvalue %D2 undef, double %a, 0
	%43 = insertvalue %D2 %42, double %b, 1
	%44 = alloca %D2
	store %D2 %43, ptr %44
	%45 = load { double, double }, ptr %44
	ret { double, double } %45

}
define i64 @ret_int_float (i32 %a, float %b) {
entry:
	%46 = insertvalue %IntFloat undef, i32 %a, 0
	%47 = insertvalue %IntFloat %46, float %b, 1
	%48 = alloca %IntFloat
	store %IntFloat %47, ptr %48
	%49 = load i64, ptr %48
	ret i64 %49

}
define i64 @ret_float_int (float %a, i32 %b) {
entry:
	%50 = insertvalue %FloatInt undef, float %a, 0
	%51 = insertvalue %FloatInt %50, i32 %b, 1
	%52 = alloca %FloatInt
	store %FloatInt %51, ptr %52
	%53 = load i64, ptr %52
	ret i64 %53

}
define { i32, double } @ret_int_double (i32 %a, double %b) {
entry:
	%54 = insertvalue %IntDouble undef, i32 %a, 0
	%55 = insertvalue %IntDouble %54, double %b, 1
	%56 = alloca %IntDouble
	store %IntDouble %55, ptr %56
	%57 = load { i32, double }, ptr %56
	ret { i32, double } %57

}
define { double, i32 } @ret_double_int (double %a, i32 %b) {
entry:
	%58 = insertvalue %DoubleInt undef, double %a, 0
	%59 = insertvalue %DoubleInt %58, i32 %b, 1
	%60 = alloca %DoubleInt
	store %DoubleInt %59, ptr %60
	%61 = load { double, i32 }, ptr %60
	ret { double, i32 } %61

}
define { i64, float } @ret_long_float (i64 %a, float %b) {
entry:
	%62 = insertvalue %LongFloat undef, i64 %a, 0
	%63 = insertvalue %LongFloat %62, float %b, 1
	%64 = alloca %LongFloat
	store %LongFloat %63, ptr %64
	%65 = load { i64, float }, ptr %64
	ret { i64, float } %65

}
define { float, i64 } @ret_float_long (float %a, i64 %b) {
entry:
	%66 = insertvalue %FloatLong undef, float %a, 0
	%67 = insertvalue %FloatLong %66, i64 %b, 1
	%68 = alloca %FloatLong
	store %FloatLong %67, ptr %68
	%69 = load { float, i64 }, ptr %68
	ret { float, i64 } %69

}
define i64 @arg_s1 (i8 %x.abi) {
entry:
	%70 = alloca %S1
	store i8 %x.abi, ptr %70
	%71 = load %S1, ptr %70
	%72 = extractvalue %S1 %71, 0
	%73 = zext i8 %72 to i64
	ret i64 %73

}
define i64 @arg_s5 (i64 %x.abi) {
entry:
	%74 = alloca %S5
	store i64 %x.abi, ptr %74
	%75 = load %S5, ptr %74
	%76 = extractvalue %S5 %75, 0
	%77 = sext i32 %76 to i64
	%78 = extractvalue %S5 %75, 1
	%79 = sext i32 %78 to i64
	%80 = add i64 %77, %79
	ret i64 %80

}
define i64 @arg_s8 (i64 %x.abi) {
entry:
	%81 = alloca %S8
	store i64 %x.abi, ptr %81
	%82 = load %S8, ptr %81
	%83 = extractvalue %S8 %82, 0
	ret i64 %83

}
define i64 @arg_s12 ({ i64, i32 } %x.abi) {
entry:
	%84 = alloca %S12
	store { i64, i32 } %x.abi, ptr %84
	%85 = load %S12, ptr %84
	%86 = extractvalue %S12 %85, 0
	%87 = extractvalue %S12 %85, 1
	%88 = sext i32 %87 to i64
	%89 = add i64 %86, %88
	ret i64 %89

}
define i64 @arg_s16 ({ i64, i64 } %x.abi) {
entry:
	%90 = alloca %S16
	store { i64, i64 } %x.abi, ptr %90
	%91 = load %S16, ptr %90
	%92 = extractvalue %S16 %91, 0
	%93 = extractvalue %S16 %91, 1
	%94 = add i64 %92, %93
	ret i64 %94

}
define i64 @arg_int3 (ptr byval(%Int3) align 8 %x) {
entry:
	%95 = load %Int3, ptr %x
	%96 = extractvalue %Int3 %95, 0
	%97 = load %Int3, ptr %x
	%98 = extractvalue %Int3 %97, 1
	%99 = add i64 %96, %98
	%100 = load %Int3, ptr %x
	%101 = extractvalue %Int3 %100, 2
	%102 = add i64 %99, %101
	ret i64 %102

}
define i64 @arg_f1 (float %x.abi) {
entry:
	%103 = alloca %F1
	store float %x.abi, ptr %103
	%104 = load %F1, ptr %103
	%105 = extractvalue %F1 %104, 0
	%106 = fptosi float %105 to i64
	ret i64 %106

}
define i64 @arg_f2 (double %x.abi) {
entry:
	%107 = alloca %F2
	store double %x.abi, ptr %107
	%108 = load %F2, ptr %107
	%109 = extractvalue %F2 %108, 0
	%110 = extractvalue %F2 %108, 1
	%111 = fadd float %109, %110
	%112 = fptosi float %111 to i64
	ret i64 %112

}
define i64 @arg_f4 ({ double, double } %x.abi) {
entry:
	%113 = alloca %F4
	store { double, double } %x.abi, ptr %113
	%114 = load %F4, ptr %113
	%115 = extractvalue %F4 %114, 0
	%116 = extractvalue %F4 %114, 1
	%117 = fadd float %115, %116
	%118 = extractvalue %F4 %114, 2
	%119 = fadd float %117, %118
	%120 = extractvalue %F4 %114, 3
	%121 = fadd float %119, %120
	%122 = fptosi float %121 to i64
	ret i64 %122

}
define i64 @arg_d1 (double %x.abi) {
entry:
	%123 = alloca %D1
	store double %x.abi, ptr %123
	%124 = load %D1, ptr %123
	%125 = extractvalue %D1 %124, 0
	%126 = fptosi double %125 to i64
	ret i64 %126

}
define i64 @arg_d2 ({ double, double } %x.abi) {
entry:
	%127 = alloca %D2
	store { double, double } %x.abi, ptr %127
	%128 = load %D2, ptr %127
	%129 = extractvalue %D2 %128, 0
	%130 = extractvalue %D2 %128, 1
	%131 = fadd double %129, %130
	%132 = fptosi double %131 to i64
	ret i64 %132

}
define i64 @arg_int_float (i64 %x.abi) {
entry:
	%133 = alloca %IntFloat
	store i64 %x.abi, ptr %133
	%134 = load %IntFloat, ptr %133
	%135 = extractvalue %IntFloat %134, 0
	%136 = sext i32 %135 to i64
	%137 = extractvalue %IntFloat %134, 1
	%138 = fptosi float %137 to i64
	%139 = add i64 %136, %138
	ret i64 %139

}
define i64 @arg_float_int (i64 %x.abi) {
entry:
	%140 = alloca %FloatInt
	store i64 %x.abi, ptr %140
	%141 = load %FloatInt, ptr %140
	%142 = extractvalue %FloatInt %141, 0
	%143 = fptosi float %142 to i64
	%144 = extractvalue %FloatInt %141, 1
	%145 = sext i32 %144 to i64
	%146 = add i64 %143, %145
	ret i64 %146

}
define i64 @arg_int_double ({ i32, double } %x.abi) {
entry:
	%147 = alloca %IntDouble
	store { i32, double } %x.abi, ptr %147
	%148 = load %IntDouble, ptr %147
	%149 = extractvalue %IntDouble %148, 0
	%150 = sext i32 %149 to i64
	%151 = extractvalue %IntDouble %148, 1
	%152 = fptosi double %151 to i64
	%153 = add i64 %150, %152
	ret i64 %153

}
define i64 @arg_double_int ({ double, i32 } %x.abi) {
entry:
	%154 = alloca %DoubleInt
	store { double, i32 } %x.abi, ptr %154
	%155 = load %DoubleInt, ptr %154
	%156 = extractvalue %DoubleInt %155, 0
	%157 = fptosi double %156 to i64
	%158 = extractvalue %DoubleInt %155, 1
	%159 = sext i32 %158 to i64
	%160 = add i64 %157, %159
	ret i64 %160

}
define i64 @arg_long_float ({ i64, float } %x.abi) {
entry:
	%161 = alloca %LongFloat
	store { i64, float } %x.abi, ptr %161
	%162 = load %LongFloat, ptr %161
	%163 = extractvalue %LongFloat %162, 0
	%164 = extractvalue %LongFloat %162, 1
	%165 = fptosi float %164 to i64
	%166 = add i64 %163, %165
	ret i64 %166

}
define i64 @arg_float_long ({ float, i64 } %x.abi) {
entry:
	%167 = alloca %FloatLong
	store { float, i64 } %x.abi, ptr %167
	%168 = load %FloatLong, ptr %167
	%169 = extractvalue %FloatLong %168, 0
	%170 = fptosi float %169 to i64
	%171 = extractvalue %FloatLong %168, 1
	%172 = add i64 %170, %171
	ret i64 %172

}
define i64 @many_integer_structs (i64 %a.abi, i64 %b.abi, i64 %c.abi, i64 %d.abi, i64 %e.abi, i64 %f.abi, i64 %g.abi) {
entry:
	%173 = alloca %S8
	store i64 %a.abi, ptr %173
	%174 = load %S8, ptr %173
	%175 = alloca %S8
	store i64 %b.abi, ptr %175
	%176 = load %S8, ptr %175
	%177 = alloca %S8
	store i64 %c.abi, ptr %177
	%178 = load %S8, ptr %177
	%179 = alloca %S8
	store i64 %d.abi, ptr %179
	%180 = load %S8, ptr %179
	%181 = alloca %S8
	store i64 %e.abi, ptr %181
	%182 = load %S8, ptr %181
	%183 = alloca %S8
	store i64 %f.abi, ptr %183
	%184 = load %S8, ptr %183
	%185 = alloca %S8
	store i64 %g.abi, ptr %185
	%186 = load %S8, ptr %185
	%187 = extractvalue %S8 %174, 0
	%188 = extractvalue %S8 %176, 0
	%189 = add i64 %187, %188
	%190 = extractvalue %S8 %178, 0
	%191 = add i64 %189, %190
	%192 = extractvalue %S8 %180, 0
	%193 = add i64 %191, %192
	%194 = extractvalue %S8 %182, 0
	%195 = add i64 %193, %194
	%196 = extractvalue %S8 %184, 0
	%197 = add i64 %195, %196
	%198 = extractvalue %S8 %186, 0
	%199 = add i64 %197, %198
	ret i64 %199

}
define i64 @many_sse_structs (double %a.abi, double %b.abi, double %c.abi, double %d.abi, double %e.abi, double %f.abi, double %g.abi, double %h.abi, double %i.abi) {
entry:
	%200 = alloca %D1
	store double %a.abi, ptr %200
	%201 = load %D1, ptr %200
	%202 = alloca %D1
	store double %b.abi, ptr %202
	%203 = load %D1, ptr %202
	%204 = alloca %D1
	store double %c.abi, ptr %204
	%205 = load %D1, ptr %204
	%206 = alloca %D1
	store double %d.abi, ptr %206
	%207 = load %D1, ptr %206
	%208 = alloca %D1
	store double %e.abi, ptr %208
	%209 = load %D1, ptr %208
	%210 = alloca %D1
	store double %f.abi, ptr %210
	%211 = load %D1, ptr %210
	%212 = alloca %D1
	store double %g.abi, ptr %212
	%213 = load %D1, ptr %212
	%214 = alloca %D1
	store double %h.abi, ptr %214
	%215 = load %D1, ptr %214
	%216 = alloca %D1
	store double %i.abi, ptr %216
	%217 = load %D1, ptr %216
	%218 = extractvalue %D1 %201, 0
	%219 = extractvalue %D1 %203, 0
	%220 = fadd double %218, %219
	%221 = extractvalue %D1 %205, 0
	%222 = fadd double %220, %221
	%223 = extractvalue %D1 %207, 0
	%224 = fadd double %222, %223
	%225 = extractvalue %D1 %209, 0
	%226 = fadd double %224, %225
	%227 = extractvalue %D1 %211, 0
	%228 = fadd double %226, %227
	%229 = extractvalue %D1 %213, 0
	%230 = fadd double %228, %229
	%231 = extractvalue %D1 %215, 0
	%232 = fadd double %230, %231
	%233 = extractvalue %D1 %217, 0
	%234 = fadd double %232, %233
	%235 = fptosi double %234 to i64
	ret i64 %235

}
define i64 @mixed_args1 (i32 %a, { i64, i64 } %b.abi, double %c, double %d.abi, i64 %e) {
entry:
	%236 = alloca %S16
	store { i64, i64 } %b.abi, ptr %236
	%237 = load %S16, ptr %236
	%238 = alloca %F2
	store double %d.abi, ptr %238
	%239 = load %F2, ptr %238
	%240 = sext i32 %a to i64
	%241 = extractvalue %S16 %237, 0
	%242 = add i64 %240, %241
	%243 = extractvalue %S16 %237, 1
	%244 = add i64 %242, %243
	%245 = fptosi double %c to i64
	%246 = add i64 %244, %245
	%247 = extractvalue %F2 %239, 0
	%248 = fptosi float %247 to i64
	%249 = add i64 %246, %248
	%250 = extractvalue %F2 %239, 1
	%251 = fptosi float %250 to i64
	%252 = add i64 %249, %251
	%253 = add i64 %252, %e
	ret i64 %253

}
define i64 @mixed_args2 ({ i32, double } %a.abi, i32 %b, { double, i32 } %c.abi, double %d, i64 %e.abi) {
entry:
	%254 = alloca %IntDouble
	store { i32, double } %a.abi, ptr %254
	%255 = load %IntDouble, ptr %254
	%256 = alloca %DoubleInt
	store { double, i32 } %c.abi, ptr %256
	%257 = load %DoubleInt, ptr %256
	%258 = alloca %S8
	store i64 %e.abi, ptr %258
	%259 = load %S8, ptr %258
	%260 = extractvalue %IntDouble %255, 0
	%261 = sext i32 %260 to i64
	%262 = extractvalue %IntDouble %255, 1
	%263 = fptosi double %262 to i64
	%264 = add i64 %261, %263
	%265 = sext i32 %b to i64
	%266 = add i64 %264, %265
	%267 = extractvalue %DoubleInt %257, 0
	%268 = fptosi double %267 to i64
	%269 = add i64 %266, %268
	%270 = extractvalue %DoubleInt %257, 1
	%271 = sext i32 %270 to i64
	%272 = add i64 %269, %271
	%273 = fptosi double %d to i64
	%274 = add i64 %272, %273
	%275 = extractvalue %S8 %259, 0
	%276 = add i64 %274, %275
	ret i64 %276

}
define void @large_return (ptr sret(%Int3) align 8 %.sret, ptr byval(%Int3) align 8 %x) {
entry:
	%277 = load %Int3, ptr %x
	%278 = extractvalue %Int3 %277, 0
	%279 = add i64 %278, 1
	%280 = getelementptr inbounds %Int3, ptr %x, i32 0, i32 0
	store i64 %279, ptr %280

	%281 = load %Int3, ptr %x
	%282 = extractvalue %Int3 %281, 1
	%283 = add i64 %282, 2
	%284 = getelementptr inbounds %Int3, ptr %x, i32 0, i32 1
	store i64 %283, ptr %284

	%285 = load %Int3, ptr %x
	%286 = extractvalue %Int3 %285, 2
	%287 = add i64 %286, 3
	%288 = getelementptr inbounds %Int3, ptr %x, i32 0, i32 2
	store i64 %287, ptr %288

	%289 = load %Int3, ptr %x
	store %Int3 %289, ptr %.sret
	ret void

}
define void @huge_return (ptr sret(%Int4) align 8 %.sret, ptr byval(%Int4) align 8 %x) {
entry:
	%290 = load %Int4, ptr %x
	%291 = extractvalue %Int4 %290, 0
	%292 = add i64 %291, 1
	%293 = getelementptr inbounds %Int4, ptr %x, i32 0, i32 0
	store i64 %292, ptr %293

	%294 = load %Int4, ptr %x
	%295 = extractvalue %Int4 %294, 1
	%296 = add i64 %295, 2
	%297 = getelementptr inbounds %Int4, ptr %x, i32 0, i32 1
	store i64 %296, ptr %297

	%298 = load %Int4, ptr %x
	%299 = extractvalue %Int4 %298, 2
	%300 = add i64 %299, 3
	%301 = getelementptr inbounds %Int4, ptr %x, i32 0, i32 2
	store i64 %300, ptr %301

	%302 = load %Int4, ptr %x
	%303 = extractvalue %Int4 %302, 3
	%304 = add i64 %303, 4
	%305 = getelementptr inbounds %Int4, ptr %x, i32 0, i32 3
	store i64 %304, ptr %305

	%306 = load %Int4, ptr %x
	store %Int4 %306, ptr %.sret
	ret void

}
define i64 @test_calls () {
entry:
	%sink = alloca i64
	store i64 0, ptr %sink

	%307 = insertvalue %S1 undef, i8 1, 0
	%s1 = alloca %S1
	store %S1 %307, ptr %s1

	%308 = insertvalue %S5 undef, i32 2, 0
	%309 = insertvalue %S5 %308, i32 3, 1
	%s5 = alloca %S5
	store %S5 %309, ptr %s5

	%310 = insertvalue %S8 undef, i64 4, 0
	%s8 = alloca %S8
	store %S8 %310, ptr %s8

	%311 = insertvalue %S12 undef, i64 5, 0
	%312 = insertvalue %S12 %311, i32 6, 1
	%s12 = alloca %S12
	store %S12 %312, ptr %s12

	%313 = insertvalue %S16 undef, i64 7, 0
	%314 = insertvalue %S16 %313, i64 8, 1
	%s16 = alloca %S16
	store %S16 %314, ptr %s16

	%315 = insertvalue %Int3 undef, i64 10, 0
	%316 = insertvalue %Int3 %315, i64 11, 1
	%317 = insertvalue %Int3 %316, i64 12, 2
	%i3 = alloca %Int3
	store %Int3 %317, ptr %i3

	%318 = insertvalue %F1 undef, float 0x3FF0000000000000, 0
	%f1 = alloca %F1
	store %F1 %318, ptr %f1

	%319 = insertvalue %F2 undef, float 0x4000000000000000, 0
	%320 = insertvalue %F2 %319, float 0x4008000000000000, 1
	%f2 = alloca %F2
	store %F2 %320, ptr %f2

	%321 = insertvalue %F4 undef, float 0x4010000000000000, 0
	%322 = insertvalue %F4 %321, float 0x4014000000000000, 1
	%323 = insertvalue %F4 %322, float 0x4018000000000000, 2
	%324 = insertvalue %F4 %323, float 0x401C000000000000, 3
	%f4 = alloca %F4
	store %F4 %324, ptr %f4

	%325 = insertvalue %D1 undef, double 0x3FF0000000000000, 0
	%d1 = alloca %D1
	store %D1 %325, ptr %d1

	%326 = insertvalue %D2 undef, double 0x4000000000000000, 0
	%327 = insertvalue %D2 %326, double 0x4008000000000000, 1
	%d2 = alloca %D2
	store %D2 %327, ptr %d2

	%328 = insertvalue %IntFloat undef, i32 1, 0
	%329 = insertvalue %IntFloat %328, float 0x4000000000000000, 1
	%int_float = alloca %IntFloat
	store %IntFloat %329, ptr %int_float

	%330 = insertvalue %FloatInt undef, float 0x4008000000000000, 0
	%331 = insertvalue %FloatInt %330, i32 4, 1
	%float_int = alloca %FloatInt
	store %FloatInt %331, ptr %float_int

	%332 = insertvalue %IntDouble undef, i32 5, 0
	%333 = insertvalue %IntDouble %332, double 0x4018000000000000, 1
	%int_double = alloca %IntDouble
	store %IntDouble %333, ptr %int_double

	%334 = insertvalue %DoubleInt undef, double 0x401C000000000000, 0
	%335 = insertvalue %DoubleInt %334, i32 8, 1
	%double_int = alloca %DoubleInt
	store %DoubleInt %335, ptr %double_int

	%336 = insertvalue %LongFloat undef, i64 9, 0
	%337 = insertvalue %LongFloat %336, float 0x4024000000000000, 1
	%long_float = alloca %LongFloat
	store %LongFloat %337, ptr %long_float

	%338 = insertvalue %FloatLong undef, float 0x4026000000000000, 0
	%339 = insertvalue %FloatLong %338, i64 12, 1
	%float_long = alloca %FloatLong
	store %FloatLong %339, ptr %float_long

	%340 = load i64, ptr %sink
	%341 = load %S1, ptr %s1
	%342 = alloca %S1
	store %S1 %341, ptr %342
	%343 = load i8, ptr %342
	%344 = call i64 @arg_s1(i8 %343)
	%345 = add i64 %340, %344
	store i64 %345, ptr %sink

	%346 = load i64, ptr %sink
	%347 = load %S5, ptr %s5
	%348 = alloca %S5
	store %S5 %347, ptr %348
	%349 = load i64, ptr %348
	%350 = call i64 @arg_s5(i64 %349)
	%351 = add i64 %346, %350
	store i64 %351, ptr %sink

	%352 = load i64, ptr %sink
	%353 = load %S8, ptr %s8
	%354 = alloca %S8
	store %S8 %353, ptr %354
	%355 = load i64, ptr %354
	%356 = call i64 @arg_s8(i64 %355)
	%357 = add i64 %352, %356
	store i64 %357, ptr %sink

	%358 = load i64, ptr %sink
	%359 = load %S12, ptr %s12
	%360 = alloca %S12
	store %S12 %359, ptr %360
	%361 = load { i64, i32 }, ptr %360
	%362 = call i64 @arg_s12({ i64, i32 } %361)
	%363 = add i64 %358, %362
	store i64 %363, ptr %sink

	%364 = load i64, ptr %sink
	%365 = load %S16, ptr %s16
	%366 = alloca %S16
	store %S16 %365, ptr %366
	%367 = load { i64, i64 }, ptr %366
	%368 = call i64 @arg_s16({ i64, i64 } %367)
	%369 = add i64 %364, %368
	store i64 %369, ptr %sink

	%370 = load i64, ptr %sink
	%371 = load %Int3, ptr %i3
	%372 = alloca %Int3
	store %Int3 %371, ptr %372
	%373 = call i64 @arg_int3(ptr byval(%Int3) align 8 %372)
	%374 = add i64 %370, %373
	store i64 %374, ptr %sink

	%375 = load i64, ptr %sink
	%376 = load %F1, ptr %f1
	%377 = alloca %F1
	store %F1 %376, ptr %377
	%378 = load float, ptr %377
	%379 = call i64 @arg_f1(float %378)
	%380 = add i64 %375, %379
	store i64 %380, ptr %sink

	%381 = load i64, ptr %sink
	%382 = load %F2, ptr %f2
	%383 = alloca %F2
	store %F2 %382, ptr %383
	%384 = load double, ptr %383
	%385 = call i64 @arg_f2(double %384)
	%386 = add i64 %381, %385
	store i64 %386, ptr %sink

	%387 = load i64, ptr %sink
	%388 = load %F4, ptr %f4
	%389 = alloca %F4
	store %F4 %388, ptr %389
	%390 = load { double, double }, ptr %389
	%391 = call i64 @arg_f4({ double, double } %390)
	%392 = add i64 %387, %391
	store i64 %392, ptr %sink

	%393 = load i64, ptr %sink
	%394 = load %D1, ptr %d1
	%395 = alloca %D1
	store %D1 %394, ptr %395
	%396 = load double, ptr %395
	%397 = call i64 @arg_d1(double %396)
	%398 = add i64 %393, %397
	store i64 %398, ptr %sink

	%399 = load i64, ptr %sink
	%400 = load %D2, ptr %d2
	%401 = alloca %D2
	store %D2 %400, ptr %401
	%402 = load { double, double }, ptr %401
	%403 = call i64 @arg_d2({ double, double } %402)
	%404 = add i64 %399, %403
	store i64 %404, ptr %sink

	%405 = load i64, ptr %sink
	%406 = load %IntFloat, ptr %int_float
	%407 = alloca %IntFloat
	store %IntFloat %406, ptr %407
	%408 = load i64, ptr %407
	%409 = call i64 @arg_int_float(i64 %408)
	%410 = add i64 %405, %409
	store i64 %410, ptr %sink

	%411 = load i64, ptr %sink
	%412 = load %FloatInt, ptr %float_int
	%413 = alloca %FloatInt
	store %FloatInt %412, ptr %413
	%414 = load i64, ptr %413
	%415 = call i64 @arg_float_int(i64 %414)
	%416 = add i64 %411, %415
	store i64 %416, ptr %sink

	%417 = load i64, ptr %sink
	%418 = load %IntDouble, ptr %int_double
	%419 = alloca %IntDouble
	store %IntDouble %418, ptr %419
	%420 = load { i32, double }, ptr %419
	%421 = call i64 @arg_int_double({ i32, double } %420)
	%422 = add i64 %417, %421
	store i64 %422, ptr %sink

	%423 = load i64, ptr %sink
	%424 = load %DoubleInt, ptr %double_int
	%425 = alloca %DoubleInt
	store %DoubleInt %424, ptr %425
	%426 = load { double, i32 }, ptr %425
	%427 = call i64 @arg_double_int({ double, i32 } %426)
	%428 = add i64 %423, %427
	store i64 %428, ptr %sink

	%429 = load i64, ptr %sink
	%430 = load %LongFloat, ptr %long_float
	%431 = alloca %LongFloat
	store %LongFloat %430, ptr %431
	%432 = load { i64, float }, ptr %431
	%433 = call i64 @arg_long_float({ i64, float } %432)
	%434 = add i64 %429, %433
	store i64 %434, ptr %sink

	%435 = load i64, ptr %sink
	%436 = load %FloatLong, ptr %float_long
	%437 = alloca %FloatLong
	store %FloatLong %436, ptr %437
	%438 = load { float, i64 }, ptr %437
	%439 = call i64 @arg_float_long({ float, i64 } %438)
	%440 = add i64 %435, %439
	store i64 %440, ptr %sink

	%441 = call i8 @ret_s1(i8 20)
	%442 = alloca %S1
	store i8 %441, ptr %442
	%443 = load %S1, ptr %442
	store %S1 %443, ptr %s1

	%444 = call i64 @ret_s5(i32 21, i32 22)
	%445 = alloca %S5
	store i64 %444, ptr %445
	%446 = load %S5, ptr %445
	store %S5 %446, ptr %s5

	%447 = call i64 @ret_s8(i64 23)
	%448 = alloca %S8
	store i64 %447, ptr %448
	%449 = load %S8, ptr %448
	store %S8 %449, ptr %s8

	%450 = call { i64, i32 } @ret_s12(i64 24, i32 25)
	%451 = alloca %S12
	store { i64, i32 } %450, ptr %451
	%452 = load %S12, ptr %451
	store %S12 %452, ptr %s12

	%453 = call { i64, i64 } @ret_s16(i64 26, i64 27)
	%454 = alloca %S16
	store { i64, i64 } %453, ptr %454
	%455 = load %S16, ptr %454
	store %S16 %455, ptr %s16

	%456 = alloca %Int3
	call void @ret_int3(ptr sret(%Int3) align 8 %456, i64 28, i64 29, i64 30)
	%457 = load %Int3, ptr %456
	store %Int3 %457, ptr %i3

	%458 = call float @ret_f1(float 0x403F000000000000)
	%459 = alloca %F1
	store float %458, ptr %459
	%460 = load %F1, ptr %459
	store %F1 %460, ptr %f1

	%461 = call double @ret_f2(float 0x4040000000000000, float 0x4040800000000000)
	%462 = alloca %F2
	store double %461, ptr %462
	%463 = load %F2, ptr %462
	store %F2 %463, ptr %f2

	%464 = call { double, double } @ret_f4(float 0x4041000000000000, float 0x4041800000000000, float 0x4042000000000000, float 0x4042800000000000)
	%465 = alloca %F4
	store { double, double } %464, ptr %465
	%466 = load %F4, ptr %465
	store %F4 %466, ptr %f4

	%467 = call double @ret_d1(double 0x4043000000000000)
	%468 = alloca %D1
	store double %467, ptr %468
	%469 = load %D1, ptr %468
	store %D1 %469, ptr %d1

	%470 = call { double, double } @ret_d2(double 0x4043800000000000, double 0x4044000000000000)
	%471 = alloca %D2
	store { double, double } %470, ptr %471
	%472 = load %D2, ptr %471
	store %D2 %472, ptr %d2

	%473 = call i64 @ret_int_float(i32 41, float 0x4045000000000000)
	%474 = alloca %IntFloat
	store i64 %473, ptr %474
	%475 = load %IntFloat, ptr %474
	store %IntFloat %475, ptr %int_float

	%476 = call i64 @ret_float_int(float 0x4045800000000000, i32 44)
	%477 = alloca %FloatInt
	store i64 %476, ptr %477
	%478 = load %FloatInt, ptr %477
	store %FloatInt %478, ptr %float_int

	%479 = call { i32, double } @ret_int_double(i32 45, double 0x4047000000000000)
	%480 = alloca %IntDouble
	store { i32, double } %479, ptr %480
	%481 = load %IntDouble, ptr %480
	store %IntDouble %481, ptr %int_double

	%482 = call { double, i32 } @ret_double_int(double 0x4047800000000000, i32 48)
	%483 = alloca %DoubleInt
	store { double, i32 } %482, ptr %483
	%484 = load %DoubleInt, ptr %483
	store %DoubleInt %484, ptr %double_int

	%485 = call { i64, float } @ret_long_float(i64 49, float 0x4049000000000000)
	%486 = alloca %LongFloat
	store { i64, float } %485, ptr %486
	%487 = load %LongFloat, ptr %486
	store %LongFloat %487, ptr %long_float

	%488 = call { float, i64 } @ret_float_long(float 0x4049800000000000, i64 52)
	%489 = alloca %FloatLong
	store { float, i64 } %488, ptr %489
	%490 = load %FloatLong, ptr %489
	store %FloatLong %490, ptr %float_long

	%491 = load i64, ptr %sink
	%492 = insertvalue %S8 undef, i64 1, 0
	%493 = alloca %S8
	store %S8 %492, ptr %493
	%494 = load i64, ptr %493
	%495 = insertvalue %S8 undef, i64 2, 0
	%496 = alloca %S8
	store %S8 %495, ptr %496
	%497 = load i64, ptr %496
	%498 = insertvalue %S8 undef, i64 3, 0
	%499 = alloca %S8
	store %S8 %498, ptr %499
	%500 = load i64, ptr %499
	%501 = insertvalue %S8 undef, i64 4, 0
	%502 = alloca %S8
	store %S8 %501, ptr %502
	%503 = load i64, ptr %502
	%504 = insertvalue %S8 undef, i64 5, 0
	%505 = alloca %S8
	store %S8 %504, ptr %505
	%506 = load i64, ptr %505
	%507 = insertvalue %S8 undef, i64 6, 0
	%508 = alloca %S8
	store %S8 %507, ptr %508
	%509 = load i64, ptr %508
	%510 = insertvalue %S8 undef, i64 7, 0
	%511 = alloca %S8
	store %S8 %510, ptr %511
	%512 = load i64, ptr %511
	%513 = call i64 @many_integer_structs(i64 %494, i64 %497, i64 %500, i64 %503, i64 %506, i64 %509, i64 %512)
	%514 = add i64 %491, %513
	store i64 %514, ptr %sink

	%515 = load i64, ptr %sink
	%516 = insertvalue %D1 undef, double 0x3FF0000000000000, 0
	%517 = alloca %D1
	store %D1 %516, ptr %517
	%518 = load double, ptr %517
	%519 = insertvalue %D1 undef, double 0x4000000000000000, 0
	%520 = alloca %D1
	store %D1 %519, ptr %520
	%521 = load double, ptr %520
	%522 = insertvalue %D1 undef, double 0x4008000000000000, 0
	%523 = alloca %D1
	store %D1 %522, ptr %523
	%524 = load double, ptr %523
	%525 = insertvalue %D1 undef, double 0x4010000000000000, 0
	%526 = alloca %D1
	store %D1 %525, ptr %526
	%527 = load double, ptr %526
	%528 = insertvalue %D1 undef, double 0x4014000000000000, 0
	%529 = alloca %D1
	store %D1 %528, ptr %529
	%530 = load double, ptr %529
	%531 = insertvalue %D1 undef, double 0x4018000000000000, 0
	%532 = alloca %D1
	store %D1 %531, ptr %532
	%533 = load double, ptr %532
	%534 = insertvalue %D1 undef, double 0x401C000000000000, 0
	%535 = alloca %D1
	store %D1 %534, ptr %535
	%536 = load double, ptr %535
	%537 = insertvalue %D1 undef, double 0x4020000000000000, 0
	%538 = alloca %D1
	store %D1 %537, ptr %538
	%539 = load double, ptr %538
	%540 = insertvalue %D1 undef, double 0x4022000000000000, 0
	%541 = alloca %D1
	store %D1 %540, ptr %541
	%542 = load double, ptr %541
	%543 = call i64 @many_sse_structs(double %518, double %521, double %524, double %527, double %530, double %533, double %536, double %539, double %542)
	%544 = add i64 %515, %543
	store i64 %544, ptr %sink

	%545 = load i64, ptr %sink
	%546 = insertvalue %S16 undef, i64 2, 0
	%547 = insertvalue %S16 %546, i64 3, 1
	%548 = alloca %S16
	store %S16 %547, ptr %548
	%549 = load { i64, i64 }, ptr %548
	%550 = insertvalue %F2 undef, float 0x4014000000000000, 0
	%551 = insertvalue %F2 %550, float 0x4018000000000000, 1
	%552 = alloca %F2
	store %F2 %551, ptr %552
	%553 = load double, ptr %552
	%554 = call i64 @mixed_args1(i32 1, { i64, i64 } %549, double 0x4010000000000000, double %553, i64 7)
	%555 = add i64 %545, %554
	store i64 %555, ptr %sink

	%556 = load i64, ptr %sink
	%557 = insertvalue %IntDouble undef, i32 1, 0
	%558 = insertvalue %IntDouble %557, double 0x4000000000000000, 1
	%559 = alloca %IntDouble
	store %IntDouble %558, ptr %559
	%560 = load { i32, double }, ptr %559
	%561 = insertvalue %DoubleInt undef, double 0x4010000000000000, 0
	%562 = insertvalue %DoubleInt %561, i32 5, 1
	%563 = alloca %DoubleInt
	store %DoubleInt %562, ptr %563
	%564 = load { double, i32 }, ptr %563
	%565 = insertvalue %S8 undef, i64 7, 0
	%566 = alloca %S8
	store %S8 %565, ptr %566
	%567 = load i64, ptr %566
	%568 = call i64 @mixed_args2({ i32, double } %560, i32 3, { double, i32 } %564, double 0x4018000000000000, i64 %567)
	%569 = add i64 %556, %568
	store i64 %569, ptr %sink

	%570 = alloca %Int3
	%571 = load %Int3, ptr %i3
	%572 = alloca %Int3
	store %Int3 %571, ptr %572
	call void @large_return(ptr sret(%Int3) align 8 %570, ptr byval(%Int3) align 8 %572)
	%573 = load %Int3, ptr %570
	store %Int3 %573, ptr %i3

	%574 = insertvalue %Int4 undef, i64 1, 0
	%575 = insertvalue %Int4 %574, i64 2, 1
	%576 = insertvalue %Int4 %575, i64 3, 2
	%577 = insertvalue %Int4 %576, i64 4, 3
	%i4 = alloca %Int4
	store %Int4 %577, ptr %i4

	%578 = alloca %Int4
	%579 = load %Int4, ptr %i4
	%580 = alloca %Int4
	store %Int4 %579, ptr %580
	call void @huge_return(ptr sret(%Int4) align 8 %578, ptr byval(%Int4) align 8 %580)
	%581 = load %Int4, ptr %578
	store %Int4 %581, ptr %i4

	%582 = load i64, ptr %sink
	%583 = load %S1, ptr %s1
	%584 = extractvalue %S1 %583, 0
	%585 = zext i8 %584 to i64
	%586 = add i64 %582, %585
	%587 = load %S5, ptr %s5
	%588 = extractvalue %S5 %587, 0
	%589 = sext i32 %588 to i64
	%590 = add i64 %586, %589
	%591 = load %S5, ptr %s5
	%592 = extractvalue %S5 %591, 1
	%593 = sext i32 %592 to i64
	%594 = add i64 %590, %593
	%595 = load %S8, ptr %s8
	%596 = extractvalue %S8 %595, 0
	%597 = add i64 %594, %596
	%598 = load %S12, ptr %s12
	%599 = extractvalue %S12 %598, 0
	%600 = add i64 %597, %599
	%601 = load %S12, ptr %s12
	%602 = extractvalue %S12 %601, 1
	%603 = sext i32 %602 to i64
	%604 = add i64 %600, %603
	%605 = load %S16, ptr %s16
	%606 = extractvalue %S16 %605, 0
	%607 = add i64 %604, %606
	%608 = load %S16, ptr %s16
	%609 = extractvalue %S16 %608, 1
	%610 = add i64 %607, %609
	store i64 %610, ptr %sink

	%611 = load i64, ptr %sink
	%612 = load %Int3, ptr %i3
	%613 = extractvalue %Int3 %612, 0
	%614 = add i64 %611, %613
	%615 = load %Int3, ptr %i3
	%616 = extractvalue %Int3 %615, 1
	%617 = add i64 %614, %616
	%618 = load %Int3, ptr %i3
	%619 = extractvalue %Int3 %618, 2
	%620 = add i64 %617, %619
	store i64 %620, ptr %sink

	%621 = load i64, ptr %sink
	%622 = load %F1, ptr %f1
	%623 = extractvalue %F1 %622, 0
	%624 = fptosi float %623 to i64
	%625 = add i64 %621, %624
	%626 = load %F2, ptr %f2
	%627 = extractvalue %F2 %626, 0
	%628 = fptosi float %627 to i64
	%629 = add i64 %625, %628
	%630 = load %F2, ptr %f2
	%631 = extractvalue %F2 %630, 1
	%632 = fptosi float %631 to i64
	%633 = add i64 %629, %632
	%634 = load %D1, ptr %d1
	%635 = extractvalue %D1 %634, 0
	%636 = fptosi double %635 to i64
	%637 = add i64 %633, %636
	%638 = load %D2, ptr %d2
	%639 = extractvalue %D2 %638, 0
	%640 = fptosi double %639 to i64
	%641 = add i64 %637, %640
	%642 = load %D2, ptr %d2
	%643 = extractvalue %D2 %642, 1
	%644 = fptosi double %643 to i64
	%645 = add i64 %641, %644
	store i64 %645, ptr %sink

	%646 = load i64, ptr %sink
	%647 = load %Int4, ptr %i4
	%648 = extractvalue %Int4 %647, 0
	%649 = add i64 %646, %648
	%650 = load %Int4, ptr %i4
	%651 = extractvalue %Int4 %650, 1
	%652 = add i64 %649, %651
	%653 = load %Int4, ptr %i4
	%654 = extractvalue %Int4 %653, 2
	%655 = add i64 %652, %654
	%656 = load %Int4, ptr %i4
	%657 = extractvalue %Int4 %656, 3
	%658 = add i64 %655, %657
	store i64 %658, ptr %sink

	%659 = load i64, ptr %sink
	ret i64 %659

}
define i64 @main () {
entry:
	%660 = call i64 @test_calls()
	ret i64 %660

}
