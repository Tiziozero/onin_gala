; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu" 
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
; decs from mod ./cfunctions.gala 0
declare i32 @socket (i32, i32, i32)
declare i32 @connect (i32, ptr, i32)
declare i32 @bind (i32, ptr, i32)
declare i32 @listen (i32, i32)
declare i32 @accept (i32, ptr, ptr)
declare i64 @send (i32, ptr, i64, i32)
declare i64 @recv (i32, ptr, i64, i32)
declare i32 @shutdown (i32, i32)
declare i32 @close (i32)
declare i32 @setsockopt (i32, i32, i32, ptr, i32)
declare i16 @htons (i16)
declare i16 @ntohs (i16)
declare i32 @htonl (i32)
declare i32 @ntohl (i32)
declare i32 @inet_addr (ptr)
declare i32 @printf (ptr, ...)
declare i32 @fprintf (ptr, ptr, ...)
declare i32 @snprintf (ptr, i64, ptr, ...)
declare ptr @fopen (ptr, ptr)
declare i32 @fclose (ptr)
declare i32 @fputs (ptr, ptr)
declare i64 @fwrite (ptr, i64, i64, ptr)
declare i64 @fread (ptr, i64, i64, ptr)
declare i32 @fflush (ptr)
declare ptr @malloc (i64)
declare ptr @calloc (i64, i64)
declare ptr @realloc (ptr, i64)
declare void @free (ptr)
declare ptr @memcpy (ptr, ptr, i64)
declare ptr @memmove (ptr, ptr, i64)
declare ptr @memset (ptr, i32, i64)
declare i32 @memcmp (ptr, ptr, i64)
declare i64 @strlen (ptr)
declare i32 @strcmp (ptr, ptr)
declare i32 @strncmp (ptr, ptr, i64)
declare ptr @strcpy (ptr, ptr)
declare ptr @strncpy (ptr, ptr, i64)
declare ptr @strcat (ptr, ptr)
declare ptr @strncat (ptr, ptr, i64)
declare ptr @strchr (ptr, i32)
declare ptr @strrchr (ptr, i32)
declare i32 @atoi (ptr)
declare i64 @atol (ptr)
declare i64 @atoll (ptr)
declare i64 @strtol (ptr, ptr, i32)
declare i64 @strtoll (ptr, ptr, i32)
declare i64 @strtoul (ptr, ptr, i32)
declare i64 @strtoull (ptr, ptr, i32)
declare float @strtof (ptr, ptr)
declare double @strtod (ptr, ptr)
declare i32 @rand ()
declare void @srand (i32)
declare i64 @time (ptr)
declare void @exit (i32)
declare void @abort ()
declare i32 @atexit (ptr)
declare ptr @getenv (ptr)
declare double @sqrt (double)
declare double @pow (double, double)
declare double @sin (double)
declare double @cos (double)
declare double @tan (double)
declare double @asin (double)
declare double @acos (double)
declare double @atan (double)
declare double @atan2 (double, double)
declare double @sinh (double)
declare double @cosh (double)
declare double @tanh (double)
declare double @log (double)
declare double @log10 (double)
declare double @exp (double)
declare double @floor (double)
declare double @ceil (double)
declare double @round (double)
declare double @fabs (double)
declare float @sqrtf (float)
declare float @sinf (float)
declare float @cosf (float)
declare float @tanf (float)
declare float @asinf (float)
declare float @acosf (float)
declare float @atanf (float)
declare float @atan2f (float, float)
declare float @sinhf (float)
declare float @coshf (float)
declare float @tanhf (float)
declare float @logf (float)
declare float @log10f (float)
declare float @expf (float)
declare float @floorf (float)
declare float @ceilf (float)
declare float @roundf (float)
declare float @fabsf (float)
; end
%gala_120231.Any = type {ptr,i64}
@string1 = private unnamed_addr constant [15 x i8] c"core/core.gala\00", align 1

@string2 = private unnamed_addr constant [14 x i8] c"core/net.gala\00", align 1

@string3 = private unnamed_addr constant [14 x i8] c"core/mem.gala\00", align 1

@string4 = private unnamed_addr constant [10 x i8] c"Len data:\00", align 1

@string5 = private unnamed_addr constant [23 x i8] c"failed to start server\00", align 1

@string6 = private unnamed_addr constant [35 x i8] c"echo server listening on port 9000\00", align 1

@string7 = private unnamed_addr constant [14 x i8] c"accept failed\00", align 1

@string8 = private unnamed_addr constant [17 x i8] c"client connected\00", align 1

@string9 = private unnamed_addr constant [5 x i8] c"Got:\00", align 1

@string10 = private unnamed_addr constant [6 x i8] c"char:\00", align 1

@string11 = private unnamed_addr constant [20 x i8] c"client disconnected\00", align 1

@string12 = private unnamed_addr constant [32 x i8] c"/lib/x86_64-linux-gnu/libc.so.6\00", align 1

@string13 = private unnamed_addr constant [32 x i8] c"/lib/x86_64-linux-gnu/libm.so.6\00", align 1

@string14 = private unnamed_addr constant [18 x i8] c"./cfunctions.gala\00", align 1

@string15 = private unnamed_addr constant [2 x i8] c" \00", align 1

@string16 = private unnamed_addr constant [5 x i8] c"%.*s\00", align 1

@string17 = private unnamed_addr constant [5 x i8] c"%lld\00", align 1

@string18 = private unnamed_addr constant [5 x i8] c"%llu\00", align 1

@string19 = private unnamed_addr constant [3 x i8] c"%d\00", align 1

@string20 = private unnamed_addr constant [3 x i8] c"%u\00", align 1

@string21 = private unnamed_addr constant [3 x i8] c"%g\00", align 1

@string22 = private unnamed_addr constant [5 x i8] c"true\00", align 1

@string23 = private unnamed_addr constant [6 x i8] c"false\00", align 1

@string24 = private unnamed_addr constant [4 x i8] c"<?>\00", align 1

@string25 = private unnamed_addr constant [2 x i8] c"\0A\00", align 1

define ptr @gala_120231.cstr ({ ptr, i64 } %s) {
entry:
	%26 = extractvalue { ptr, i64 } %s, 0
	%27 = getelementptr inbounds i8, ptr %26, i64 0
	ret ptr %27

}
define void @gala_120231.println ({ ptr, i64 } %data.gala_variadic) {
entry:
	%i.259 = alloca i64
	%__for_iter0.267 = alloca { ptr, i64 }
	%__for_idx0.268 = alloca i64
	%v.260 = alloca { ptr, i64 }
	%slot50 = alloca { ptr, i64 }
	%a.261 = alloca %gala_120231.Any
	%id.262 = alloca i64
	%s.263 = alloca { ptr, i64 }
	store i64 0, ptr %i.259

	store { ptr, i64 } %data.gala_variadic, ptr %__for_iter0.267

	store i64 0, ptr %__for_idx0.268

	br label %while_cond_label28
while_cond_label28:
	%29 = load i64, ptr %__for_idx0.268
	%30 = load { ptr, i64 }, ptr %__for_iter0.267
	%31 = extractvalue { ptr, i64 } %30, 1
	%32 = icmp slt i64 %29, %31
	br i1 %32, label %while_body_label28, label %while_end_label28
while_body_label28:
	%33 = load { ptr, i64 }, ptr %__for_iter0.267
	%34 = extractvalue { ptr, i64 } %33, 0
	%35 = load i64, ptr %__for_idx0.268
	%36 = getelementptr inbounds { ptr, i64 }, ptr %34, i64 %35
	%37 = load { ptr, i64 }, ptr %36
	store { ptr, i64 } %37, ptr %v.260

	%38 = load i64, ptr %__for_idx0.268
	%39 = add i64 %38, 1
	store i64 %39, ptr %__for_idx0.268

	%41 = load i64, ptr %i.259
	%42 = icmp sgt i64 %41, 0
	br i1 %42, label %base_block_label40, label %end_label40
base_block_label40:
	%43 = getelementptr inbounds [2 x i8], ptr @string15, i64 0, i64 0
	%44 = insertvalue { ptr, i64 } undef, ptr %43, 0
	%45 = insertvalue { ptr, i64 } %44, i64 1, 1
	%46 = extractvalue { ptr, i64 } %45, 0
	%47 = getelementptr inbounds i8, ptr %46, i64 0
	%48 = call i32 (ptr, ...)@printf(ptr %47)

	br label %end_label40
end_label40:

	%49 = load { ptr, i64 }, ptr %v.260
	store { ptr, i64 } %49, ptr %slot50
	%51 = load %gala_120231.Any, ptr %slot50
	store %gala_120231.Any %51, ptr %a.261

	%52 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 1
	%53 = load i64, ptr %52
	store i64 %53, ptr %id.262

	%55 = load i64, ptr %id.262
	%56 = icmp eq i64 %55, 17
	br i1 %56, label %base_block_label54, label %alt_cond_label54_0
base_block_label54:
	%57 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%58 = load ptr, ptr %57
	%59 = load { ptr, i64 }, ptr %58
	store { ptr, i64 } %59, ptr %s.263

	%60 = getelementptr inbounds [5 x i8], ptr @string16, i64 0, i64 0
	%61 = insertvalue { ptr, i64 } undef, ptr %60, 0
	%62 = insertvalue { ptr, i64 } %61, i64 4, 1
	%63 = extractvalue { ptr, i64 } %62, 0
	%64 = getelementptr inbounds i8, ptr %63, i64 0
	%65 = load { ptr, i64 }, ptr %s.263
	%66 = extractvalue { ptr, i64 } %65, 1
	%67 = load { ptr, i64 }, ptr %s.263
	%68 = extractvalue { ptr, i64 } %67, 0
	%69 = getelementptr inbounds i8, ptr %68, i64 0
	%70 = call i32 (ptr, ...)@printf(ptr %64, i64 %66, ptr %69)

	br label %end_label54
alt_cond_label54_0:
	%71 = load i64, ptr %id.262
	%72 = icmp eq i64 %71, 3
	br i1 %72, label %alt_block_label54_0, label %alt_cond_label54_1
alt_block_label54_0:
	%73 = getelementptr inbounds [5 x i8], ptr @string17, i64 0, i64 0
	%74 = insertvalue { ptr, i64 } undef, ptr %73, 0
	%75 = insertvalue { ptr, i64 } %74, i64 4, 1
	%76 = extractvalue { ptr, i64 } %75, 0
	%77 = getelementptr inbounds i8, ptr %76, i64 0
	%78 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%79 = load ptr, ptr %78
	%80 = load i64, ptr %79
	%81 = call i32 (ptr, ...)@printf(ptr %77, i64 %80)

	br label %end_label54
alt_cond_label54_1:
	%82 = load i64, ptr %id.262
	%83 = icmp eq i64 %82, 7
	br i1 %83, label %alt_block_label54_1, label %alt_cond_label54_2
alt_block_label54_1:
	%84 = getelementptr inbounds [5 x i8], ptr @string18, i64 0, i64 0
	%85 = insertvalue { ptr, i64 } undef, ptr %84, 0
	%86 = insertvalue { ptr, i64 } %85, i64 4, 1
	%87 = extractvalue { ptr, i64 } %86, 0
	%88 = getelementptr inbounds i8, ptr %87, i64 0
	%89 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%90 = load ptr, ptr %89
	%91 = load i64, ptr %90
	%92 = call i32 (ptr, ...)@printf(ptr %88, i64 %91)

	br label %end_label54
alt_cond_label54_2:
	%93 = load i64, ptr %id.262
	%94 = icmp eq i64 %93, 2
	br i1 %94, label %alt_block_label54_2, label %alt_cond_label54_3
alt_block_label54_2:
	%95 = getelementptr inbounds [3 x i8], ptr @string19, i64 0, i64 0
	%96 = insertvalue { ptr, i64 } undef, ptr %95, 0
	%97 = insertvalue { ptr, i64 } %96, i64 2, 1
	%98 = extractvalue { ptr, i64 } %97, 0
	%99 = getelementptr inbounds i8, ptr %98, i64 0
	%100 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%101 = load ptr, ptr %100
	%102 = load i32, ptr %101
	%103 = call i32 (ptr, ...)@printf(ptr %99, i32 %102)

	br label %end_label54
alt_cond_label54_3:
	%104 = load i64, ptr %id.262
	%105 = icmp eq i64 %104, 6
	br i1 %105, label %alt_block_label54_3, label %alt_cond_label54_4
alt_block_label54_3:
	%106 = getelementptr inbounds [3 x i8], ptr @string20, i64 0, i64 0
	%107 = insertvalue { ptr, i64 } undef, ptr %106, 0
	%108 = insertvalue { ptr, i64 } %107, i64 2, 1
	%109 = extractvalue { ptr, i64 } %108, 0
	%110 = getelementptr inbounds i8, ptr %109, i64 0
	%111 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%112 = load ptr, ptr %111
	%113 = load i32, ptr %112
	%114 = call i32 (ptr, ...)@printf(ptr %110, i32 %113)

	br label %end_label54
alt_cond_label54_4:
	%115 = load i64, ptr %id.262
	%116 = icmp eq i64 %115, 1
	br i1 %116, label %alt_block_label54_4, label %alt_cond_label54_5
alt_block_label54_4:
	%117 = getelementptr inbounds [3 x i8], ptr @string19, i64 0, i64 0
	%118 = insertvalue { ptr, i64 } undef, ptr %117, 0
	%119 = insertvalue { ptr, i64 } %118, i64 2, 1
	%120 = extractvalue { ptr, i64 } %119, 0
	%121 = getelementptr inbounds i8, ptr %120, i64 0
	%122 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%123 = load ptr, ptr %122
	%124 = load i16, ptr %123
	%125 = sext i16 %124 to i32
	%126 = call i32 (ptr, ...)@printf(ptr %121, i32 %125)

	br label %end_label54
alt_cond_label54_5:
	%127 = load i64, ptr %id.262
	%128 = icmp eq i64 %127, 5
	br i1 %128, label %alt_block_label54_5, label %alt_cond_label54_6
alt_block_label54_5:
	%129 = getelementptr inbounds [3 x i8], ptr @string20, i64 0, i64 0
	%130 = insertvalue { ptr, i64 } undef, ptr %129, 0
	%131 = insertvalue { ptr, i64 } %130, i64 2, 1
	%132 = extractvalue { ptr, i64 } %131, 0
	%133 = getelementptr inbounds i8, ptr %132, i64 0
	%134 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%135 = load ptr, ptr %134
	%136 = load i16, ptr %135
	%137 = zext i16 %136 to i32
	%138 = call i32 (ptr, ...)@printf(ptr %133, i32 %137)

	br label %end_label54
alt_cond_label54_6:
	%139 = load i64, ptr %id.262
	%140 = icmp eq i64 %139, 0
	br i1 %140, label %alt_block_label54_6, label %alt_cond_label54_7
alt_block_label54_6:
	%141 = getelementptr inbounds [3 x i8], ptr @string19, i64 0, i64 0
	%142 = insertvalue { ptr, i64 } undef, ptr %141, 0
	%143 = insertvalue { ptr, i64 } %142, i64 2, 1
	%144 = extractvalue { ptr, i64 } %143, 0
	%145 = getelementptr inbounds i8, ptr %144, i64 0
	%146 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%147 = load ptr, ptr %146
	%148 = load i8, ptr %147
	%149 = sext i8 %148 to i32
	%150 = call i32 (ptr, ...)@printf(ptr %145, i32 %149)

	br label %end_label54
alt_cond_label54_7:
	%151 = load i64, ptr %id.262
	%152 = icmp eq i64 %151, 4
	br i1 %152, label %alt_block_label54_7, label %alt_cond_label54_8
alt_block_label54_7:
	%153 = getelementptr inbounds [3 x i8], ptr @string20, i64 0, i64 0
	%154 = insertvalue { ptr, i64 } undef, ptr %153, 0
	%155 = insertvalue { ptr, i64 } %154, i64 2, 1
	%156 = extractvalue { ptr, i64 } %155, 0
	%157 = getelementptr inbounds i8, ptr %156, i64 0
	%158 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%159 = load ptr, ptr %158
	%160 = load i8, ptr %159
	%161 = zext i8 %160 to i32
	%162 = call i32 (ptr, ...)@printf(ptr %157, i32 %161)

	br label %end_label54
alt_cond_label54_8:
	%163 = load i64, ptr %id.262
	%164 = icmp eq i64 %163, 11
	br i1 %164, label %alt_block_label54_8, label %alt_cond_label54_9
alt_block_label54_8:
	%165 = getelementptr inbounds [3 x i8], ptr @string21, i64 0, i64 0
	%166 = insertvalue { ptr, i64 } undef, ptr %165, 0
	%167 = insertvalue { ptr, i64 } %166, i64 2, 1
	%168 = extractvalue { ptr, i64 } %167, 0
	%169 = getelementptr inbounds i8, ptr %168, i64 0
	%170 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%171 = load ptr, ptr %170
	%172 = load double, ptr %171
	%173 = call i32 (ptr, ...)@printf(ptr %169, double %172)

	br label %end_label54
alt_cond_label54_9:
	%174 = load i64, ptr %id.262
	%175 = icmp eq i64 %174, 10
	br i1 %175, label %alt_block_label54_9, label %alt_cond_label54_10
alt_block_label54_9:
	%176 = getelementptr inbounds [3 x i8], ptr @string21, i64 0, i64 0
	%177 = insertvalue { ptr, i64 } undef, ptr %176, 0
	%178 = insertvalue { ptr, i64 } %177, i64 2, 1
	%179 = extractvalue { ptr, i64 } %178, 0
	%180 = getelementptr inbounds i8, ptr %179, i64 0
	%181 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%182 = load ptr, ptr %181
	%183 = load float, ptr %182
	%184 = fpext float %183 to double
	%185 = call i32 (ptr, ...)@printf(ptr %180, double %184)

	br label %end_label54
alt_cond_label54_10:
	%186 = load i64, ptr %id.262
	%187 = icmp eq i64 %186, 14
	br i1 %187, label %alt_block_label54_10, label %else_block_label54
alt_block_label54_10:
	%189 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
	%190 = load ptr, ptr %189
	%191 = load i1, ptr %190
	br i1 %191, label %base_block_label188, label %else_block_label188
base_block_label188:
	%192 = getelementptr inbounds [5 x i8], ptr @string22, i64 0, i64 0
	%193 = insertvalue { ptr, i64 } undef, ptr %192, 0
	%194 = insertvalue { ptr, i64 } %193, i64 4, 1
	%195 = extractvalue { ptr, i64 } %194, 0
	%196 = getelementptr inbounds i8, ptr %195, i64 0
	%197 = call i32 (ptr, ...)@printf(ptr %196)

	br label %end_label188
else_block_label188:
	%198 = getelementptr inbounds [6 x i8], ptr @string23, i64 0, i64 0
	%199 = insertvalue { ptr, i64 } undef, ptr %198, 0
	%200 = insertvalue { ptr, i64 } %199, i64 5, 1
	%201 = extractvalue { ptr, i64 } %200, 0
	%202 = getelementptr inbounds i8, ptr %201, i64 0
	%203 = call i32 (ptr, ...)@printf(ptr %202)

	br label %end_label188
end_label188:

	br label %end_label54
else_block_label54:
	%204 = getelementptr inbounds [4 x i8], ptr @string24, i64 0, i64 0
	%205 = insertvalue { ptr, i64 } undef, ptr %204, 0
	%206 = insertvalue { ptr, i64 } %205, i64 3, 1
	%207 = extractvalue { ptr, i64 } %206, 0
	%208 = getelementptr inbounds i8, ptr %207, i64 0
	%209 = call i32 (ptr, ...)@printf(ptr %208)

	br label %end_label54
end_label54:

	%210 = load i64, ptr %i.259
	%211 = add i64 %210, 1
	store i64 %211, ptr %i.259

	br label %while_cond_label28
while_end_label28:

	%212 = getelementptr inbounds [2 x i8], ptr @string25, i64 0, i64 0
	%213 = insertvalue { ptr, i64 } undef, ptr %212, 0
	%214 = insertvalue { ptr, i64 } %213, i64 1, 1
	%215 = extractvalue { ptr, i64 } %214, 0
	%216 = getelementptr inbounds i8, ptr %215, i64 0
	%217 = call i32 (ptr, ...)@printf(ptr %216)

	ret void
}
define i1 @gala_120231.str_cmp ({ ptr, i64 } %a, { ptr, i64 } %b) {
entry:
	%i.266 = alloca i64
	%219 = extractvalue { ptr, i64 } %a, 1
	%220 = extractvalue { ptr, i64 } %b, 1
	%221 = icmp ne i64 %219, %220
	br i1 %221, label %base_block_label218, label %end_label218
base_block_label218:
	ret i1 0

end_label218:

	store i64 0, ptr %i.266

	br label %while_cond_label222
while_cond_label222:
	%223 = load i64, ptr %i.266
	%224 = extractvalue { ptr, i64 } %a, 1
	%225 = icmp slt i64 %223, %224
	br i1 %225, label %while_body_label222, label %while_end_label222
while_body_label222:
	%227 = extractvalue { ptr, i64 } %a, 0
	%228 = load i64, ptr %i.266
	%229 = getelementptr inbounds i8, ptr %227, i64 %228
	%230 = load i8, ptr %229
	%231 = extractvalue { ptr, i64 } %b, 0
	%232 = load i64, ptr %i.266
	%233 = getelementptr inbounds i8, ptr %231, i64 %232
	%234 = load i8, ptr %233
	%235 = icmp ne i8 %230, %234
	br i1 %235, label %base_block_label226, label %end_label226
base_block_label226:
	ret i1 0

end_label226:

	br label %while_cond_label222
while_end_label222:

	ret i1 1

}
