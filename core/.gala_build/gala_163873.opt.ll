; ModuleID = '.gala_build/gala_163873.ll'
source_filename = ".gala_build/gala_163873.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@string1 = private unnamed_addr constant [10 x i8] c"core.gala\00", align 1
@string2 = private unnamed_addr constant [9 x i8] c"net.gala\00", align 1
@string3 = private unnamed_addr constant [9 x i8] c"mem.gala\00", align 1
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
@string14 = private unnamed_addr constant [16 x i8] c"cfunctions.gala\00", align 1
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

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
