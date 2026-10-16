; ModuleID = '.gala_build/gala_120231.ll'
source_filename = ".gala_build/gala_120231.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%gala_120231.Any = type { ptr, i64 }

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

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #0

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg) #0

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #1

declare i32 @socket(i32, i32, i32)

declare i32 @connect(i32, ptr, i32)

declare i32 @bind(i32, ptr, i32)

declare i32 @listen(i32, i32)

declare i32 @accept(i32, ptr, ptr)

declare i64 @send(i32, ptr, i64, i32)

declare i64 @recv(i32, ptr, i64, i32)

declare i32 @shutdown(i32, i32)

declare i32 @close(i32)

declare i32 @setsockopt(i32, i32, i32, ptr, i32)

declare i16 @htons(i16)

declare i16 @ntohs(i16)

declare i32 @htonl(i32)

declare i32 @ntohl(i32)

declare i32 @inet_addr(ptr)

declare i32 @printf(ptr, ...)

declare i32 @fprintf(ptr, ptr, ...)

declare i32 @snprintf(ptr, i64, ptr, ...)

declare ptr @fopen(ptr, ptr)

declare i32 @fclose(ptr)

declare i32 @fputs(ptr, ptr)

declare i64 @fwrite(ptr, i64, i64, ptr)

declare i64 @fread(ptr, i64, i64, ptr)

declare i32 @fflush(ptr)

declare ptr @malloc(i64)

declare ptr @calloc(i64, i64)

declare ptr @realloc(ptr, i64)

declare void @free(ptr)

declare ptr @memcpy(ptr, ptr, i64)

declare ptr @memmove(ptr, ptr, i64)

declare ptr @memset(ptr, i32, i64)

declare i32 @memcmp(ptr, ptr, i64)

declare i64 @strlen(ptr)

declare i32 @strcmp(ptr, ptr)

declare i32 @strncmp(ptr, ptr, i64)

declare ptr @strcpy(ptr, ptr)

declare ptr @strncpy(ptr, ptr, i64)

declare ptr @strcat(ptr, ptr)

declare ptr @strncat(ptr, ptr, i64)

declare ptr @strchr(ptr, i32)

declare ptr @strrchr(ptr, i32)

declare i32 @atoi(ptr)

declare i64 @atol(ptr)

declare i64 @atoll(ptr)

declare i64 @strtol(ptr, ptr, i32)

declare i64 @strtoll(ptr, ptr, i32)

declare i64 @strtoul(ptr, ptr, i32)

declare i64 @strtoull(ptr, ptr, i32)

declare float @strtof(ptr, ptr)

declare double @strtod(ptr, ptr)

declare i32 @rand()

declare void @srand(i32)

declare i64 @time(ptr)

declare void @exit(i32)

declare void @abort()

declare i32 @atexit(ptr)

declare ptr @getenv(ptr)

declare double @sqrt(double)

declare double @pow(double, double)

declare double @sin(double)

declare double @cos(double)

declare double @tan(double)

declare double @asin(double)

declare double @acos(double)

declare double @atan(double)

declare double @atan2(double, double)

declare double @sinh(double)

declare double @cosh(double)

declare double @tanh(double)

declare double @log(double)

declare double @log10(double)

declare double @exp(double)

declare double @floor(double)

declare double @ceil(double)

declare double @round(double)

declare double @fabs(double)

declare float @sqrtf(float)

declare float @sinf(float)

declare float @cosf(float)

declare float @tanf(float)

declare float @asinf(float)

declare float @acosf(float)

declare float @atanf(float)

declare float @atan2f(float, float)

declare float @sinhf(float)

declare float @coshf(float)

declare float @tanhf(float)

declare float @logf(float)

declare float @log10f(float)

declare float @expf(float)

declare float @floorf(float)

declare float @ceilf(float)

declare float @roundf(float)

declare float @fabsf(float)

define ptr @gala_120231.cstr({ ptr, i64 } %s) {
entry:
  %0 = extractvalue { ptr, i64 } %s, 0
  %1 = getelementptr inbounds i8, ptr %0, i64 0
  ret ptr %1
}

define void @gala_120231.println({ ptr, i64 } %data.gala_variadic) {
entry:
  %slot50 = alloca { ptr, i64 }, align 8
  %a.261 = alloca %gala_120231.Any, align 8
  br label %while_cond_label28

while_cond_label28:                               ; preds = %end_label54, %entry
  %__for_idx0.268.0 = phi i64 [ 0, %entry ], [ %5, %end_label54 ]
  %i.259.0 = phi i64 [ 0, %entry ], [ %156, %end_label54 ]
  %0 = extractvalue { ptr, i64 } %data.gala_variadic, 1
  %1 = icmp slt i64 %__for_idx0.268.0, %0
  br i1 %1, label %while_body_label28, label %while_end_label28

while_body_label28:                               ; preds = %while_cond_label28
  %2 = extractvalue { ptr, i64 } %data.gala_variadic, 0
  %3 = getelementptr inbounds { ptr, i64 }, ptr %2, i64 %__for_idx0.268.0
  %4 = load { ptr, i64 }, ptr %3, align 8
  %5 = add i64 %__for_idx0.268.0, 1
  %6 = icmp sgt i64 %i.259.0, 0
  br i1 %6, label %base_block_label40, label %end_label40

base_block_label40:                               ; preds = %while_body_label28
  %7 = getelementptr inbounds [2 x i8], ptr @string15, i64 0, i64 0
  %8 = insertvalue { ptr, i64 } undef, ptr %7, 0
  %9 = insertvalue { ptr, i64 } %8, i64 1, 1
  %10 = extractvalue { ptr, i64 } %9, 0
  %11 = getelementptr inbounds i8, ptr %10, i64 0
  %12 = call i32 (ptr, ...) @printf(ptr %11)
  br label %end_label40

end_label40:                                      ; preds = %base_block_label40, %while_body_label28
  store { ptr, i64 } %4, ptr %slot50, align 8
  %13 = load %gala_120231.Any, ptr %slot50, align 8
  store %gala_120231.Any %13, ptr %a.261, align 8
  %14 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 1
  %15 = load i64, ptr %14, align 8
  %16 = icmp eq i64 %15, 17
  br i1 %16, label %base_block_label54, label %alt_cond_label54_0

base_block_label54:                               ; preds = %end_label40
  %17 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %18 = load ptr, ptr %17, align 8
  %19 = load { ptr, i64 }, ptr %18, align 8
  %20 = getelementptr inbounds [5 x i8], ptr @string16, i64 0, i64 0
  %21 = insertvalue { ptr, i64 } undef, ptr %20, 0
  %22 = insertvalue { ptr, i64 } %21, i64 4, 1
  %23 = extractvalue { ptr, i64 } %22, 0
  %24 = getelementptr inbounds i8, ptr %23, i64 0
  %25 = extractvalue { ptr, i64 } %19, 1
  %26 = extractvalue { ptr, i64 } %19, 0
  %27 = getelementptr inbounds i8, ptr %26, i64 0
  %28 = call i32 (ptr, ...) @printf(ptr %24, i64 %25, ptr %27)
  br label %end_label54

alt_cond_label54_0:                               ; preds = %end_label40
  %29 = icmp eq i64 %15, 3
  br i1 %29, label %alt_block_label54_0, label %alt_cond_label54_1

alt_block_label54_0:                              ; preds = %alt_cond_label54_0
  %30 = getelementptr inbounds [5 x i8], ptr @string17, i64 0, i64 0
  %31 = insertvalue { ptr, i64 } undef, ptr %30, 0
  %32 = insertvalue { ptr, i64 } %31, i64 4, 1
  %33 = extractvalue { ptr, i64 } %32, 0
  %34 = getelementptr inbounds i8, ptr %33, i64 0
  %35 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %36 = load ptr, ptr %35, align 8
  %37 = load i64, ptr %36, align 8
  %38 = call i32 (ptr, ...) @printf(ptr %34, i64 %37)
  br label %end_label54

alt_cond_label54_1:                               ; preds = %alt_cond_label54_0
  %39 = icmp eq i64 %15, 7
  br i1 %39, label %alt_block_label54_1, label %alt_cond_label54_2

alt_block_label54_1:                              ; preds = %alt_cond_label54_1
  %40 = getelementptr inbounds [5 x i8], ptr @string18, i64 0, i64 0
  %41 = insertvalue { ptr, i64 } undef, ptr %40, 0
  %42 = insertvalue { ptr, i64 } %41, i64 4, 1
  %43 = extractvalue { ptr, i64 } %42, 0
  %44 = getelementptr inbounds i8, ptr %43, i64 0
  %45 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %46 = load ptr, ptr %45, align 8
  %47 = load i64, ptr %46, align 8
  %48 = call i32 (ptr, ...) @printf(ptr %44, i64 %47)
  br label %end_label54

alt_cond_label54_2:                               ; preds = %alt_cond_label54_1
  %49 = icmp eq i64 %15, 2
  br i1 %49, label %alt_block_label54_2, label %alt_cond_label54_3

alt_block_label54_2:                              ; preds = %alt_cond_label54_2
  %50 = getelementptr inbounds [3 x i8], ptr @string19, i64 0, i64 0
  %51 = insertvalue { ptr, i64 } undef, ptr %50, 0
  %52 = insertvalue { ptr, i64 } %51, i64 2, 1
  %53 = extractvalue { ptr, i64 } %52, 0
  %54 = getelementptr inbounds i8, ptr %53, i64 0
  %55 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %56 = load ptr, ptr %55, align 8
  %57 = load i32, ptr %56, align 4
  %58 = call i32 (ptr, ...) @printf(ptr %54, i32 %57)
  br label %end_label54

alt_cond_label54_3:                               ; preds = %alt_cond_label54_2
  %59 = icmp eq i64 %15, 6
  br i1 %59, label %alt_block_label54_3, label %alt_cond_label54_4

alt_block_label54_3:                              ; preds = %alt_cond_label54_3
  %60 = getelementptr inbounds [3 x i8], ptr @string20, i64 0, i64 0
  %61 = insertvalue { ptr, i64 } undef, ptr %60, 0
  %62 = insertvalue { ptr, i64 } %61, i64 2, 1
  %63 = extractvalue { ptr, i64 } %62, 0
  %64 = getelementptr inbounds i8, ptr %63, i64 0
  %65 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %66 = load ptr, ptr %65, align 8
  %67 = load i32, ptr %66, align 4
  %68 = call i32 (ptr, ...) @printf(ptr %64, i32 %67)
  br label %end_label54

alt_cond_label54_4:                               ; preds = %alt_cond_label54_3
  %69 = icmp eq i64 %15, 1
  br i1 %69, label %alt_block_label54_4, label %alt_cond_label54_5

alt_block_label54_4:                              ; preds = %alt_cond_label54_4
  %70 = getelementptr inbounds [3 x i8], ptr @string19, i64 0, i64 0
  %71 = insertvalue { ptr, i64 } undef, ptr %70, 0
  %72 = insertvalue { ptr, i64 } %71, i64 2, 1
  %73 = extractvalue { ptr, i64 } %72, 0
  %74 = getelementptr inbounds i8, ptr %73, i64 0
  %75 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %76 = load ptr, ptr %75, align 8
  %77 = load i16, ptr %76, align 2
  %78 = sext i16 %77 to i32
  %79 = call i32 (ptr, ...) @printf(ptr %74, i32 %78)
  br label %end_label54

alt_cond_label54_5:                               ; preds = %alt_cond_label54_4
  %80 = icmp eq i64 %15, 5
  br i1 %80, label %alt_block_label54_5, label %alt_cond_label54_6

alt_block_label54_5:                              ; preds = %alt_cond_label54_5
  %81 = getelementptr inbounds [3 x i8], ptr @string20, i64 0, i64 0
  %82 = insertvalue { ptr, i64 } undef, ptr %81, 0
  %83 = insertvalue { ptr, i64 } %82, i64 2, 1
  %84 = extractvalue { ptr, i64 } %83, 0
  %85 = getelementptr inbounds i8, ptr %84, i64 0
  %86 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %87 = load ptr, ptr %86, align 8
  %88 = load i16, ptr %87, align 2
  %89 = zext i16 %88 to i32
  %90 = call i32 (ptr, ...) @printf(ptr %85, i32 %89)
  br label %end_label54

alt_cond_label54_6:                               ; preds = %alt_cond_label54_5
  %91 = icmp eq i64 %15, 0
  br i1 %91, label %alt_block_label54_6, label %alt_cond_label54_7

alt_block_label54_6:                              ; preds = %alt_cond_label54_6
  %92 = getelementptr inbounds [3 x i8], ptr @string19, i64 0, i64 0
  %93 = insertvalue { ptr, i64 } undef, ptr %92, 0
  %94 = insertvalue { ptr, i64 } %93, i64 2, 1
  %95 = extractvalue { ptr, i64 } %94, 0
  %96 = getelementptr inbounds i8, ptr %95, i64 0
  %97 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %98 = load ptr, ptr %97, align 8
  %99 = load i8, ptr %98, align 1
  %100 = sext i8 %99 to i32
  %101 = call i32 (ptr, ...) @printf(ptr %96, i32 %100)
  br label %end_label54

alt_cond_label54_7:                               ; preds = %alt_cond_label54_6
  %102 = icmp eq i64 %15, 4
  br i1 %102, label %alt_block_label54_7, label %alt_cond_label54_8

alt_block_label54_7:                              ; preds = %alt_cond_label54_7
  %103 = getelementptr inbounds [3 x i8], ptr @string20, i64 0, i64 0
  %104 = insertvalue { ptr, i64 } undef, ptr %103, 0
  %105 = insertvalue { ptr, i64 } %104, i64 2, 1
  %106 = extractvalue { ptr, i64 } %105, 0
  %107 = getelementptr inbounds i8, ptr %106, i64 0
  %108 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %109 = load ptr, ptr %108, align 8
  %110 = load i8, ptr %109, align 1
  %111 = zext i8 %110 to i32
  %112 = call i32 (ptr, ...) @printf(ptr %107, i32 %111)
  br label %end_label54

alt_cond_label54_8:                               ; preds = %alt_cond_label54_7
  %113 = icmp eq i64 %15, 11
  br i1 %113, label %alt_block_label54_8, label %alt_cond_label54_9

alt_block_label54_8:                              ; preds = %alt_cond_label54_8
  %114 = getelementptr inbounds [3 x i8], ptr @string21, i64 0, i64 0
  %115 = insertvalue { ptr, i64 } undef, ptr %114, 0
  %116 = insertvalue { ptr, i64 } %115, i64 2, 1
  %117 = extractvalue { ptr, i64 } %116, 0
  %118 = getelementptr inbounds i8, ptr %117, i64 0
  %119 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %120 = load ptr, ptr %119, align 8
  %121 = load double, ptr %120, align 8
  %122 = call i32 (ptr, ...) @printf(ptr %118, double %121)
  br label %end_label54

alt_cond_label54_9:                               ; preds = %alt_cond_label54_8
  %123 = icmp eq i64 %15, 10
  br i1 %123, label %alt_block_label54_9, label %alt_cond_label54_10

alt_block_label54_9:                              ; preds = %alt_cond_label54_9
  %124 = getelementptr inbounds [3 x i8], ptr @string21, i64 0, i64 0
  %125 = insertvalue { ptr, i64 } undef, ptr %124, 0
  %126 = insertvalue { ptr, i64 } %125, i64 2, 1
  %127 = extractvalue { ptr, i64 } %126, 0
  %128 = getelementptr inbounds i8, ptr %127, i64 0
  %129 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %130 = load ptr, ptr %129, align 8
  %131 = load float, ptr %130, align 4
  %132 = fpext float %131 to double
  %133 = call i32 (ptr, ...) @printf(ptr %128, double %132)
  br label %end_label54

alt_cond_label54_10:                              ; preds = %alt_cond_label54_9
  %134 = icmp eq i64 %15, 14
  br i1 %134, label %alt_block_label54_10, label %else_block_label54

alt_block_label54_10:                             ; preds = %alt_cond_label54_10
  %135 = getelementptr inbounds %gala_120231.Any, ptr %a.261, i32 0, i32 0
  %136 = load ptr, ptr %135, align 8
  %137 = load i1, ptr %136, align 1
  br i1 %137, label %base_block_label188, label %else_block_label188

base_block_label188:                              ; preds = %alt_block_label54_10
  %138 = getelementptr inbounds [5 x i8], ptr @string22, i64 0, i64 0
  %139 = insertvalue { ptr, i64 } undef, ptr %138, 0
  %140 = insertvalue { ptr, i64 } %139, i64 4, 1
  %141 = extractvalue { ptr, i64 } %140, 0
  %142 = getelementptr inbounds i8, ptr %141, i64 0
  %143 = call i32 (ptr, ...) @printf(ptr %142)
  br label %end_label188

else_block_label188:                              ; preds = %alt_block_label54_10
  %144 = getelementptr inbounds [6 x i8], ptr @string23, i64 0, i64 0
  %145 = insertvalue { ptr, i64 } undef, ptr %144, 0
  %146 = insertvalue { ptr, i64 } %145, i64 5, 1
  %147 = extractvalue { ptr, i64 } %146, 0
  %148 = getelementptr inbounds i8, ptr %147, i64 0
  %149 = call i32 (ptr, ...) @printf(ptr %148)
  br label %end_label188

end_label188:                                     ; preds = %else_block_label188, %base_block_label188
  br label %end_label54

else_block_label54:                               ; preds = %alt_cond_label54_10
  %150 = getelementptr inbounds [4 x i8], ptr @string24, i64 0, i64 0
  %151 = insertvalue { ptr, i64 } undef, ptr %150, 0
  %152 = insertvalue { ptr, i64 } %151, i64 3, 1
  %153 = extractvalue { ptr, i64 } %152, 0
  %154 = getelementptr inbounds i8, ptr %153, i64 0
  %155 = call i32 (ptr, ...) @printf(ptr %154)
  br label %end_label54

end_label54:                                      ; preds = %else_block_label54, %end_label188, %alt_block_label54_9, %alt_block_label54_8, %alt_block_label54_7, %alt_block_label54_6, %alt_block_label54_5, %alt_block_label54_4, %alt_block_label54_3, %alt_block_label54_2, %alt_block_label54_1, %alt_block_label54_0, %base_block_label54
  %156 = add i64 %i.259.0, 1
  br label %while_cond_label28

while_end_label28:                                ; preds = %while_cond_label28
  %157 = getelementptr inbounds [2 x i8], ptr @string25, i64 0, i64 0
  %158 = insertvalue { ptr, i64 } undef, ptr %157, 0
  %159 = insertvalue { ptr, i64 } %158, i64 1, 1
  %160 = extractvalue { ptr, i64 } %159, 0
  %161 = getelementptr inbounds i8, ptr %160, i64 0
  %162 = call i32 (ptr, ...) @printf(ptr %161)
  ret void
}

define i1 @gala_120231.str_cmp({ ptr, i64 } %a, { ptr, i64 } %b) {
entry:
  %0 = extractvalue { ptr, i64 } %a, 1
  %1 = extractvalue { ptr, i64 } %b, 1
  %2 = icmp ne i64 %0, %1
  br i1 %2, label %base_block_label218, label %end_label218

base_block_label218:                              ; preds = %entry
  ret i1 false

end_label218:                                     ; preds = %entry
  br label %while_cond_label222

while_cond_label222:                              ; preds = %end_label226, %end_label218
  %3 = extractvalue { ptr, i64 } %a, 1
  %4 = icmp slt i64 0, %3
  br i1 %4, label %while_body_label222, label %while_end_label222

while_body_label222:                              ; preds = %while_cond_label222
  %5 = extractvalue { ptr, i64 } %a, 0
  %6 = getelementptr inbounds i8, ptr %5, i64 0
  %7 = load i8, ptr %6, align 1
  %8 = extractvalue { ptr, i64 } %b, 0
  %9 = getelementptr inbounds i8, ptr %8, i64 0
  %10 = load i8, ptr %9, align 1
  %11 = icmp ne i8 %7, %10
  br i1 %11, label %base_block_label226, label %end_label226

base_block_label226:                              ; preds = %while_body_label222
  ret i1 false

end_label226:                                     ; preds = %while_body_label222
  br label %while_cond_label222

while_end_label222:                               ; preds = %while_cond_label222
  ret i1 true
}

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
