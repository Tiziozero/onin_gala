; ModuleID = '.gala_build/gala_785070.ll'
source_filename = ".gala_build/gala_785070.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%gala_785070.Allocator = type { ptr, ptr }
%gala_785070.RawSlice = type { ptr, i64 }
%gala_785070.Arena = type { ptr, i64, i64, i64, i1 }
%gala_785070.Pool = type { ptr, i64, i64, ptr }
%gala_785070.Tracking = type { %gala_785070.Allocator, i64, i64, i64, i64, i64 }

@gala_785070.NULL = global ptr null
@gala_785070.KB = global i64 0
@gala_785070.MB = global i64 0
@gala_785070.GB = global i64 0
@gala_785070.MODE_ALLOC = global i32 0
@gala_785070.MODE_FREE = global i32 0
@gala_785070.MODE_FREE_ALL = global i32 0
@gala_785070.MODE_RESIZE = global i32 0
@gala_785070.base_allocator = global %gala_785070.Allocator zeroinitializer
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
@string26 = private unnamed_addr constant [12 x i8] c"./core.gala\00", align 1
@string27 = private unnamed_addr constant [8 x i8] c"allocs:\00", align 1
@string28 = private unnamed_addr constant [7 x i8] c"frees:\00", align 1
@string29 = private unnamed_addr constant [12 x i8] c"live bytes:\00", align 1
@string30 = private unnamed_addr constant [6 x i8] c"peak:\00", align 1
@string31 = private unnamed_addr constant [7 x i8] c"total:\00", align 1

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

declare ptr @gala_120231.cstr({ ptr, i64 })

declare void @gala_120231.println({ ptr, i64 })

declare i1 @gala_120231.str_cmp({ ptr, i64 }, { ptr, i64 })

define i64 @gala_785070.addr(ptr %p) {
entry:
  %0 = ptrtoint ptr %p to i64
  ret i64 %0
}

define ptr @gala_785070.from_addr(i64 %a) {
entry:
  %0 = inttoptr i64 %a to ptr
  ret ptr %0
}

define i64 @gala_785070.align_forward(i64 %a, i64 %align) {
entry:
  %0 = icmp ule i64 %align, 1
  br i1 %0, label %base_block_label34, label %end_label34

base_block_label34:                               ; preds = %entry
  ret i64 %a

end_label34:                                      ; preds = %entry
  %1 = urem i64 %a, %align
  %2 = icmp eq i64 %1, 0
  br i1 %2, label %base_block_label37, label %end_label37

base_block_label37:                               ; preds = %end_label34
  ret i64 %a

end_label37:                                      ; preds = %end_label34
  %3 = add i64 %a, %align
  %4 = sub i64 %3, %1
  ret i64 %4
}

define i64 @gala_785070.min_u64(i64 %a, i64 %b) {
entry:
  %0 = icmp ult i64 %a, %b
  br i1 %0, label %base_block_label43, label %end_label43

base_block_label43:                               ; preds = %entry
  ret i64 %a

end_label43:                                      ; preds = %entry
  ret i64 %b
}

define void @gala_785070.mem_copy(ptr %dst, ptr %src, i64 %n) {
entry:
  %0 = call ptr @memmove(ptr %dst, ptr %src, i64 %n)
  ret void
}

define void @gala_785070.mem_zero(ptr %p, i64 %n) {
entry:
  %0 = call ptr @memset(ptr %p, i32 0, i64 %n)
  ret void
}

define void @gala_785070.mem_set(ptr %p, i32 %value, i64 %n) {
entry:
  %0 = call ptr @memset(ptr %p, i32 %value, i64 %n)
  ret void
}

define i1 @gala_785070.mem_equal(ptr %a, ptr %b, i64 %n) {
entry:
  %0 = call i32 @memcmp(ptr %a, ptr %b, i64 %n)
  %1 = icmp eq i32 %0, 0
  ret i1 %1
}

define { ptr, i64 } @gala_785070.bytes_from(ptr %p, i64 %n) {
entry:
  %slot53 = alloca %gala_785070.RawSlice, align 8
  %0 = insertvalue %gala_785070.RawSlice undef, ptr %p, 0
  %1 = insertvalue %gala_785070.RawSlice %0, i64 %n, 1
  store %gala_785070.RawSlice %1, ptr %slot53, align 8
  %2 = load { ptr, i64 }, ptr %slot53, align 8
  ret { ptr, i64 } %2
}

define void @gala_785070.set_allocator({ i64, i64 } %a.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %a.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  store %gala_785070.Allocator %1, ptr @gala_785070.base_allocator, align 8
  ret void
}

define i64 @gala_785070.__default_0() {
entry:
  ret i64 16
}

define { i64, i64 } @gala_785070.__default_1() {
entry:
  %slot58 = alloca %gala_785070.Allocator, align 8
  %0 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator, align 8
  store %gala_785070.Allocator %0, ptr %slot58, align 8
  %1 = load { i64, i64 }, ptr %slot58, align 8
  ret { i64, i64 } %1
}

define ptr @gala_785070.alloc(i64 %size, i64 %align, { i64, i64 } %a.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %a.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  %2 = extractvalue %gala_785070.Allocator %1, 0
  %3 = extractvalue %gala_785070.Allocator %1, 1
  %4 = load i32, ptr @gala_785070.MODE_ALLOC, align 4
  %5 = load ptr, ptr @gala_785070.NULL, align 8
  %6 = call ptr %2(ptr %3, i32 %4, i64 %size, i64 %align, ptr %5, i64 0)
  ret ptr %6
}

define i64 @gala_785070.__default_2() {
entry:
  ret i64 0
}

define { i64, i64 } @gala_785070.__default_3() {
entry:
  %slot69 = alloca %gala_785070.Allocator, align 8
  %0 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator, align 8
  store %gala_785070.Allocator %0, ptr %slot69, align 8
  %1 = load { i64, i64 }, ptr %slot69, align 8
  ret { i64, i64 } %1
}

define void @gala_785070.dealloc(ptr %p, i64 %size, { i64, i64 } %a.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %a.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  %2 = extractvalue %gala_785070.Allocator %1, 0
  %3 = extractvalue %gala_785070.Allocator %1, 1
  %4 = load i32, ptr @gala_785070.MODE_FREE, align 4
  %5 = call ptr %2(ptr %3, i32 %4, i64 0, i64 0, ptr %p, i64 %size)
  ret void
}

define { i64, i64 } @gala_785070.__default_4() {
entry:
  %slot79 = alloca %gala_785070.Allocator, align 8
  %0 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator, align 8
  store %gala_785070.Allocator %0, ptr %slot79, align 8
  %1 = load { i64, i64 }, ptr %slot79, align 8
  ret { i64, i64 } %1
}

define void @gala_785070.dealloc_all({ i64, i64 } %a.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %a.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  %2 = extractvalue %gala_785070.Allocator %1, 0
  %3 = extractvalue %gala_785070.Allocator %1, 1
  %4 = load i32, ptr @gala_785070.MODE_FREE_ALL, align 4
  %5 = load ptr, ptr @gala_785070.NULL, align 8
  %6 = call ptr %2(ptr %3, i32 %4, i64 0, i64 0, ptr %5, i64 0)
  ret void
}

define i64 @gala_785070.__default_5() {
entry:
  ret i64 16
}

define { i64, i64 } @gala_785070.__default_6() {
entry:
  %slot90 = alloca %gala_785070.Allocator, align 8
  %0 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator, align 8
  store %gala_785070.Allocator %0, ptr %slot90, align 8
  %1 = load { i64, i64 }, ptr %slot90, align 8
  ret { i64, i64 } %1
}

define ptr @gala_785070.resize(ptr %p, i64 %old_size, i64 %new_size, i64 %align, { i64, i64 } %a.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %a.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  %2 = extractvalue %gala_785070.Allocator %1, 0
  %3 = extractvalue %gala_785070.Allocator %1, 1
  %4 = load i32, ptr @gala_785070.MODE_RESIZE, align 4
  %5 = call ptr %2(ptr %3, i32 %4, i64 %new_size, i64 %align, ptr %p, i64 %old_size)
  ret ptr %5
}

define { i64, i64 } @gala_785070.__default_7() {
entry:
  %slot100 = alloca %gala_785070.Allocator, align 8
  %0 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator, align 8
  store %gala_785070.Allocator %0, ptr %slot100, align 8
  %1 = load { i64, i64 }, ptr %slot100, align 8
  ret { i64, i64 } %1
}

define { ptr, i64 } @gala_785070.alloc_bytes(i64 %n, { i64, i64 } %a.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %a.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  %slot105 = alloca %gala_785070.Allocator, align 8
  %2 = call i64 @gala_785070.__default_0()
  store %gala_785070.Allocator %1, ptr %slot105, align 8
  %3 = load { i64, i64 }, ptr %slot105, align 8
  %4 = call ptr @gala_785070.alloc(i64 %n, i64 %2, { i64, i64 } %3)
  %5 = ptrtoint ptr %4 to i64
  %6 = load ptr, ptr @gala_785070.NULL, align 8
  %7 = ptrtoint ptr %6 to i64
  %8 = icmp eq i64 %5, %7
  br i1 %8, label %base_block_label108, label %end_label108

base_block_label108:                              ; preds = %entry
  %9 = load ptr, ptr @gala_785070.NULL, align 8
  %10 = call { ptr, i64 } @gala_785070.bytes_from(ptr %9, i64 0)
  ret { ptr, i64 } %10

end_label108:                                     ; preds = %entry
  %11 = call { ptr, i64 } @gala_785070.bytes_from(ptr %4, i64 %n)
  ret { ptr, i64 } %11
}

define { i64, i64 } @gala_785070.__default_8() {
entry:
  %slot119 = alloca %gala_785070.Allocator, align 8
  %0 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator, align 8
  store %gala_785070.Allocator %0, ptr %slot119, align 8
  %1 = load { i64, i64 }, ptr %slot119, align 8
  ret { i64, i64 } %1
}

define { ptr, i64 } @gala_785070.clone_string({ ptr, i64 } %s, { i64, i64 } %a.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %a.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  %slot128 = alloca %gala_785070.Allocator, align 8
  %2 = extractvalue { ptr, i64 } %s, 1
  %3 = icmp eq i64 %2, 0
  br i1 %3, label %base_block_label124, label %end_label124

base_block_label124:                              ; preds = %entry
  ret { ptr, i64 } %s

end_label124:                                     ; preds = %entry
  store %gala_785070.Allocator %1, ptr %slot128, align 8
  %4 = load { i64, i64 }, ptr %slot128, align 8
  %5 = call { ptr, i64 } @gala_785070.alloc_bytes(i64 %2, { i64, i64 } %4)
  %6 = extractvalue { ptr, i64 } %5, 0
  %7 = getelementptr inbounds i8, ptr %6, i64 0
  %8 = extractvalue { ptr, i64 } %s, 0
  %9 = getelementptr inbounds i8, ptr %8, i64 0
  call void @gala_785070.mem_copy(ptr %7, ptr %9, i64 %2)
  ret { ptr, i64 } %5
}

define ptr @gala_785070.heap_proc(ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
  %0 = load i32, ptr @gala_785070.MODE_ALLOC, align 4
  %1 = icmp eq i32 %mode, %0
  br i1 %1, label %base_block_label140, label %end_label140

base_block_label140:                              ; preds = %entry
  %2 = call ptr @calloc(i64 1, i64 %size)
  ret ptr %2

end_label140:                                     ; preds = %entry
  %3 = load i32, ptr @gala_785070.MODE_FREE, align 4
  %4 = icmp eq i32 %mode, %3
  br i1 %4, label %base_block_label144, label %end_label144

base_block_label144:                              ; preds = %end_label140
  call void @free(ptr %old)
  %5 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %5

end_label144:                                     ; preds = %end_label140
  %6 = load i32, ptr @gala_785070.MODE_RESIZE, align 4
  %7 = icmp eq i32 %mode, %6
  br i1 %7, label %base_block_label148, label %end_label148

base_block_label148:                              ; preds = %end_label144
  %8 = ptrtoint ptr %old to i64
  %9 = load ptr, ptr @gala_785070.NULL, align 8
  %10 = ptrtoint ptr %9 to i64
  %11 = icmp eq i64 %8, %10
  br i1 %11, label %base_block_label151, label %end_label151

base_block_label151:                              ; preds = %base_block_label148
  %12 = call ptr @calloc(i64 1, i64 %size)
  ret ptr %12

end_label151:                                     ; preds = %base_block_label148
  %13 = call ptr @realloc(ptr %old, i64 %size)
  %14 = ptrtoint ptr %13 to i64
  %15 = load ptr, ptr @gala_785070.NULL, align 8
  %16 = ptrtoint ptr %15 to i64
  %17 = icmp ne i64 %14, %16
  br i1 %17, label %logic.rhs.160, label %logic.end.160

logic.rhs.160:                                    ; preds = %end_label151
  %18 = icmp ugt i64 %size, %old_size
  br label %logic.end.160

logic.end.160:                                    ; preds = %logic.rhs.160, %end_label151
  %slot159.0 = phi i1 [ %18, %logic.rhs.160 ], [ %17, %end_label151 ]
  br i1 %slot159.0, label %base_block_label158, label %end_label158

base_block_label158:                              ; preds = %logic.end.160
  %19 = call i64 @gala_785070.addr(ptr %13)
  %20 = add i64 %19, %old_size
  %21 = call ptr @gala_785070.from_addr(i64 %20)
  %22 = sub i64 %size, %old_size
  call void @gala_785070.mem_zero(ptr %21, i64 %22)
  br label %end_label158

end_label158:                                     ; preds = %base_block_label158, %logic.end.160
  ret ptr %13

end_label148:                                     ; preds = %end_label144
  %23 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %23
}

define { i64, i64 } @gala_785070.heap_allocator() {
entry:
  %slot178 = alloca %gala_785070.Allocator, align 8
  %0 = load ptr, ptr @gala_785070.NULL, align 8
  %1 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.heap_proc, 0
  %2 = insertvalue %gala_785070.Allocator %1, ptr %0, 1
  store %gala_785070.Allocator %2, ptr %slot178, align 8
  %3 = load { i64, i64 }, ptr %slot178, align 8
  ret { i64, i64 } %3
}

define void @gala_785070.arena_init(ptr %a, ptr %buf, i64 %size) {
entry:
  %0 = insertvalue %gala_785070.Arena undef, ptr %buf, 0
  %1 = insertvalue %gala_785070.Arena %0, i64 %size, 1
  %2 = insertvalue %gala_785070.Arena %1, i64 0, 2
  %3 = insertvalue %gala_785070.Arena %2, i64 0, 3
  %4 = insertvalue %gala_785070.Arena %3, i1 false, 4
  store %gala_785070.Arena %4, ptr %a, align 8
  ret void
}

define void @gala_785070.arena_make(ptr sret(%gala_785070.Arena) align 8 %.sret, i64 %size) {
entry:
  %0 = call ptr @malloc(i64 %size)
  %1 = insertvalue %gala_785070.Arena undef, ptr %0, 0
  %2 = insertvalue %gala_785070.Arena %1, i64 %size, 1
  %3 = insertvalue %gala_785070.Arena %2, i64 0, 2
  %4 = insertvalue %gala_785070.Arena %3, i64 0, 3
  %5 = insertvalue %gala_785070.Arena %4, i1 true, 4
  store %gala_785070.Arena %5, ptr %.sret, align 8
  ret void
}

define void @gala_785070.arena_destroy(ptr %a) {
entry:
  %0 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 4
  %1 = load i1, ptr %0, align 1
  br i1 %1, label %base_block_label191, label %end_label191

base_block_label191:                              ; preds = %entry
  %2 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 0
  %3 = load ptr, ptr %2, align 8
  call void @free(ptr %3)
  br label %end_label191

end_label191:                                     ; preds = %base_block_label191, %entry
  %4 = load ptr, ptr @gala_785070.NULL, align 8
  %5 = insertvalue %gala_785070.Arena undef, ptr %4, 0
  %6 = insertvalue %gala_785070.Arena %5, i64 0, 1
  %7 = insertvalue %gala_785070.Arena %6, i64 0, 2
  %8 = insertvalue %gala_785070.Arena %7, i64 0, 3
  %9 = insertvalue %gala_785070.Arena %8, i1 false, 4
  store %gala_785070.Arena %9, ptr %a, align 8
  ret void
}

define void @gala_785070.arena_reset(ptr %a) {
entry:
  %0 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 2
  store i64 0, ptr %0, align 8
  %1 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 3
  store i64 0, ptr %1, align 8
  ret void
}

define i64 @gala_785070.arena_mark(ptr %a) {
entry:
  %0 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 2
  %1 = load i64, ptr %0, align 8
  ret i64 %1
}

define void @gala_785070.arena_restore(ptr %a, i64 %mark) {
entry:
  %0 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 2
  store i64 %mark, ptr %0, align 8
  %1 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 3
  store i64 %mark, ptr %1, align 8
  ret void
}

define ptr @gala_785070.arena_proc(ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
  %0 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 0
  %1 = load ptr, ptr %0, align 8
  %2 = call i64 @gala_785070.addr(ptr %1)
  %3 = load i32, ptr @gala_785070.MODE_ALLOC, align 4
  %4 = icmp eq i32 %mode, %3
  br i1 %4, label %base_block_label212, label %end_label212

base_block_label212:                              ; preds = %entry
  %5 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 2
  %6 = load i64, ptr %5, align 8
  %7 = add i64 %2, %6
  %8 = call i64 @gala_785070.align_forward(i64 %7, i64 %align)
  %9 = add i64 %8, %size
  %10 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 1
  %11 = load i64, ptr %10, align 8
  %12 = add i64 %2, %11
  %13 = icmp ugt i64 %9, %12
  br i1 %13, label %base_block_label223, label %end_label223

base_block_label223:                              ; preds = %base_block_label212
  %14 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %14

end_label223:                                     ; preds = %base_block_label212
  %15 = sub i64 %9, %2
  %16 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 2
  store i64 %15, ptr %16, align 8
  %17 = sub i64 %8, %2
  %18 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 3
  store i64 %17, ptr %18, align 8
  %19 = call ptr @gala_785070.from_addr(i64 %8)
  call void @gala_785070.mem_zero(ptr %19, i64 %size)
  ret ptr %19

end_label212:                                     ; preds = %entry
  %20 = load i32, ptr @gala_785070.MODE_FREE_ALL, align 4
  %21 = icmp eq i32 %mode, %20
  br i1 %21, label %base_block_label246, label %end_label246

base_block_label246:                              ; preds = %end_label212
  call void @gala_785070.arena_reset(ptr %data)
  %22 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %22

end_label246:                                     ; preds = %end_label212
  %23 = load i32, ptr @gala_785070.MODE_RESIZE, align 4
  %24 = icmp eq i32 %mode, %23
  br i1 %24, label %base_block_label251, label %end_label251

base_block_label251:                              ; preds = %end_label246
  %25 = ptrtoint ptr %old to i64
  %26 = load ptr, ptr @gala_785070.NULL, align 8
  %27 = ptrtoint ptr %26 to i64
  %28 = icmp eq i64 %25, %27
  br i1 %28, label %base_block_label254, label %end_label254

base_block_label254:                              ; preds = %base_block_label251
  %29 = load i32, ptr @gala_785070.MODE_ALLOC, align 4
  %30 = load ptr, ptr @gala_785070.NULL, align 8
  %31 = call ptr @gala_785070.arena_proc(ptr %data, i32 %29, i64 %size, i64 %align, ptr %30, i64 0)
  ret ptr %31

end_label254:                                     ; preds = %base_block_label251
  %32 = call i64 @gala_785070.addr(ptr %old)
  %33 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 3
  %34 = load i64, ptr %33, align 8
  %35 = add i64 %2, %34
  %36 = icmp eq i64 %32, %35
  br i1 %36, label %logic.rhs.264, label %logic.end.264

logic.rhs.264:                                    ; preds = %end_label254
  %37 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 3
  %38 = load i64, ptr %37, align 8
  %39 = add i64 %38, %size
  %40 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 1
  %41 = load i64, ptr %40, align 8
  %42 = icmp ule i64 %39, %41
  br label %logic.end.264

logic.end.264:                                    ; preds = %logic.rhs.264, %end_label254
  %slot263.0 = phi i1 [ %42, %logic.rhs.264 ], [ %36, %end_label254 ]
  br i1 %slot263.0, label %base_block_label262, label %end_label262

base_block_label262:                              ; preds = %logic.end.264
  %43 = icmp ugt i64 %size, %old_size
  br i1 %43, label %base_block_label281, label %end_label281

base_block_label281:                              ; preds = %base_block_label262
  %44 = call i64 @gala_785070.addr(ptr %old)
  %45 = add i64 %44, %old_size
  %46 = call ptr @gala_785070.from_addr(i64 %45)
  %47 = sub i64 %size, %old_size
  call void @gala_785070.mem_zero(ptr %46, i64 %47)
  br label %end_label281

end_label281:                                     ; preds = %base_block_label281, %base_block_label262
  %48 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 3
  %49 = load i64, ptr %48, align 8
  %50 = add i64 %49, %size
  %51 = getelementptr inbounds %gala_785070.Arena, ptr %data, i32 0, i32 2
  store i64 %50, ptr %51, align 8
  ret ptr %old

end_label262:                                     ; preds = %logic.end.264
  %52 = load i32, ptr @gala_785070.MODE_ALLOC, align 4
  %53 = load ptr, ptr @gala_785070.NULL, align 8
  %54 = call ptr @gala_785070.arena_proc(ptr %data, i32 %52, i64 %size, i64 %align, ptr %53, i64 0)
  %55 = ptrtoint ptr %54 to i64
  %56 = load ptr, ptr @gala_785070.NULL, align 8
  %57 = ptrtoint ptr %56 to i64
  %58 = icmp eq i64 %55, %57
  br i1 %58, label %base_block_label296, label %end_label296

base_block_label296:                              ; preds = %end_label262
  %59 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %59

end_label296:                                     ; preds = %end_label262
  %60 = call i64 @gala_785070.min_u64(i64 %old_size, i64 %size)
  call void @gala_785070.mem_copy(ptr %54, ptr %old, i64 %60)
  ret ptr %54

end_label251:                                     ; preds = %end_label246
  %61 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %61
}

define { i64, i64 } @gala_785070.arena_allocator(ptr %a) {
entry:
  %slot309 = alloca %gala_785070.Allocator, align 8
  %0 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.arena_proc, 0
  %1 = insertvalue %gala_785070.Allocator %0, ptr %a, 1
  store %gala_785070.Allocator %1, ptr %slot309, align 8
  %2 = load { i64, i64 }, ptr %slot309, align 8
  ret { i64, i64 } %2
}

define void @gala_785070.pool_make(ptr sret(%gala_785070.Pool) align 8 %.sret, i64 %chunk_size, i64 %count) {
entry:
  %0 = call i64 @gala_785070.align_forward(i64 %chunk_size, i64 8)
  %1 = icmp ult i64 %0, 8
  br i1 %1, label %base_block_label312, label %end_label312

base_block_label312:                              ; preds = %entry
  br label %end_label312

end_label312:                                     ; preds = %base_block_label312, %entry
  %cs.442.0 = phi i64 [ 8, %base_block_label312 ], [ %0, %entry ]
  %2 = mul i64 %cs.442.0, %count
  %3 = call ptr @malloc(i64 %2)
  %4 = call i64 @gala_785070.addr(ptr %3)
  br label %while_cond_label319

while_cond_label319:                              ; preds = %end_label323, %end_label312
  %i.444.0 = phi i64 [ 0, %end_label312 ], [ %16, %end_label323 ]
  %5 = icmp ult i64 %i.444.0, %count
  br i1 %5, label %while_body_label319, label %while_end_label319

while_body_label319:                              ; preds = %while_cond_label319
  %6 = load ptr, ptr @gala_785070.NULL, align 8
  %7 = add i64 %i.444.0, 1
  %8 = icmp ult i64 %7, %count
  br i1 %8, label %base_block_label323, label %end_label323

base_block_label323:                              ; preds = %while_body_label319
  %9 = add i64 %i.444.0, 1
  %10 = mul i64 %9, %cs.442.0
  %11 = add i64 %4, %10
  %12 = call ptr @gala_785070.from_addr(i64 %11)
  br label %end_label323

end_label323:                                     ; preds = %base_block_label323, %while_body_label319
  %next.445.0 = phi ptr [ %12, %base_block_label323 ], [ %6, %while_body_label319 ]
  %13 = mul i64 %i.444.0, %cs.442.0
  %14 = add i64 %4, %13
  %15 = call ptr @gala_785070.from_addr(i64 %14)
  store ptr %next.445.0, ptr %15, align 8
  %16 = add i64 %i.444.0, 1
  br label %while_cond_label319

while_end_label319:                               ; preds = %while_cond_label319
  %17 = load ptr, ptr @gala_785070.NULL, align 8
  %18 = icmp ugt i64 %count, 0
  br i1 %18, label %base_block_label344, label %end_label344

base_block_label344:                              ; preds = %while_end_label319
  %19 = call ptr @gala_785070.from_addr(i64 %4)
  br label %end_label344

end_label344:                                     ; preds = %base_block_label344, %while_end_label319
  %head.446.0 = phi ptr [ %19, %base_block_label344 ], [ %17, %while_end_label319 ]
  %20 = call ptr @gala_785070.from_addr(i64 %4)
  %21 = insertvalue %gala_785070.Pool undef, ptr %20, 0
  %22 = insertvalue %gala_785070.Pool %21, i64 %cs.442.0, 1
  %23 = insertvalue %gala_785070.Pool %22, i64 %count, 2
  %24 = insertvalue %gala_785070.Pool %23, ptr %head.446.0, 3
  store %gala_785070.Pool %24, ptr %.sret, align 8
  ret void
}

define void @gala_785070.pool_destroy(ptr %p) {
entry:
  %0 = getelementptr inbounds %gala_785070.Pool, ptr %p, i32 0, i32 0
  %1 = load ptr, ptr %0, align 8
  call void @free(ptr %1)
  %2 = load ptr, ptr @gala_785070.NULL, align 8
  %3 = load ptr, ptr @gala_785070.NULL, align 8
  %4 = insertvalue %gala_785070.Pool undef, ptr %2, 0
  %5 = insertvalue %gala_785070.Pool %4, i64 0, 1
  %6 = insertvalue %gala_785070.Pool %5, i64 0, 2
  %7 = insertvalue %gala_785070.Pool %6, ptr %3, 3
  store %gala_785070.Pool %7, ptr %p, align 8
  ret void
}

define ptr @gala_785070.pool_proc(ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
  %0 = load i32, ptr @gala_785070.MODE_ALLOC, align 4
  %1 = icmp eq i32 %mode, %0
  br i1 %1, label %base_block_label364, label %end_label364

base_block_label364:                              ; preds = %entry
  %2 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 1
  %3 = load i64, ptr %2, align 8
  %4 = icmp ugt i64 %size, %3
  br i1 %4, label %logic.end.369, label %logic.rhs.369

logic.rhs.369:                                    ; preds = %base_block_label364
  %5 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 3
  %6 = load ptr, ptr %5, align 8
  %7 = ptrtoint ptr %6 to i64
  %8 = load ptr, ptr @gala_785070.NULL, align 8
  %9 = ptrtoint ptr %8 to i64
  %10 = icmp eq i64 %7, %9
  br label %logic.end.369

logic.end.369:                                    ; preds = %logic.rhs.369, %base_block_label364
  %slot368.0 = phi i1 [ %4, %base_block_label364 ], [ %10, %logic.rhs.369 ]
  br i1 %slot368.0, label %base_block_label367, label %end_label367

base_block_label367:                              ; preds = %logic.end.369
  %11 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %11

end_label367:                                     ; preds = %logic.end.369
  %12 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 3
  %13 = load ptr, ptr %12, align 8
  %14 = load ptr, ptr %13, align 8
  %15 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 3
  store ptr %14, ptr %15, align 8
  %16 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 1
  %17 = load i64, ptr %16, align 8
  call void @gala_785070.mem_zero(ptr %13, i64 %17)
  ret ptr %13

end_label364:                                     ; preds = %entry
  %18 = load i32, ptr @gala_785070.MODE_FREE, align 4
  %19 = icmp eq i32 %mode, %18
  br i1 %19, label %base_block_label395, label %end_label395

base_block_label395:                              ; preds = %end_label364
  %20 = ptrtoint ptr %old to i64
  %21 = load ptr, ptr @gala_785070.NULL, align 8
  %22 = ptrtoint ptr %21 to i64
  %23 = icmp eq i64 %20, %22
  br i1 %23, label %base_block_label398, label %end_label398

base_block_label398:                              ; preds = %base_block_label395
  %24 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %24

end_label398:                                     ; preds = %base_block_label395
  %25 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 3
  %26 = load ptr, ptr %25, align 8
  store ptr %26, ptr %old, align 8
  %27 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 3
  store ptr %old, ptr %27, align 8
  %28 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %28

end_label395:                                     ; preds = %end_label364
  %29 = load i32, ptr @gala_785070.MODE_RESIZE, align 4
  %30 = icmp eq i32 %mode, %29
  br i1 %30, label %base_block_label410, label %end_label410

base_block_label410:                              ; preds = %end_label395
  %31 = ptrtoint ptr %old to i64
  %32 = load ptr, ptr @gala_785070.NULL, align 8
  %33 = ptrtoint ptr %32 to i64
  %34 = icmp ne i64 %31, %33
  br i1 %34, label %logic.rhs.415, label %logic.end.415

logic.rhs.415:                                    ; preds = %base_block_label410
  %35 = getelementptr inbounds %gala_785070.Pool, ptr %data, i32 0, i32 1
  %36 = load i64, ptr %35, align 8
  %37 = icmp ule i64 %size, %36
  br label %logic.end.415

logic.end.415:                                    ; preds = %logic.rhs.415, %base_block_label410
  %slot414.0 = phi i1 [ %37, %logic.rhs.415 ], [ %34, %base_block_label410 ]
  br i1 %slot414.0, label %base_block_label413, label %end_label413

base_block_label413:                              ; preds = %logic.end.415
  ret ptr %old

end_label413:                                     ; preds = %logic.end.415
  %38 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %38

end_label410:                                     ; preds = %end_label395
  %39 = load ptr, ptr @gala_785070.NULL, align 8
  ret ptr %39
}

define { i64, i64 } @gala_785070.pool_allocator(ptr %p) {
entry:
  %slot429 = alloca %gala_785070.Allocator, align 8
  %0 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.pool_proc, 0
  %1 = insertvalue %gala_785070.Allocator %0, ptr %p, 1
  store %gala_785070.Allocator %1, ptr %slot429, align 8
  %2 = load { i64, i64 }, ptr %slot429, align 8
  ret { i64, i64 } %2
}

define void @gala_785070.tracking_init(ptr %t, { i64, i64 } %backing.abi) {
entry:
  %0 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %backing.abi, ptr %0, align 8
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  %2 = insertvalue %gala_785070.Tracking undef, %gala_785070.Allocator %1, 0
  %3 = insertvalue %gala_785070.Tracking %2, i64 0, 1
  %4 = insertvalue %gala_785070.Tracking %3, i64 0, 2
  %5 = insertvalue %gala_785070.Tracking %4, i64 0, 3
  %6 = insertvalue %gala_785070.Tracking %5, i64 0, 4
  %7 = insertvalue %gala_785070.Tracking %6, i64 0, 5
  store %gala_785070.Tracking %7, ptr %t, align 8
  ret void
}

define ptr @gala_785070.tracking_proc(ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
  %b.466 = alloca %gala_785070.Allocator, align 8
  %0 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 0
  %1 = load %gala_785070.Allocator, ptr %0, align 8
  store %gala_785070.Allocator %1, ptr %b.466, align 8
  %2 = getelementptr inbounds %gala_785070.Allocator, ptr %b.466, i32 0, i32 0
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds %gala_785070.Allocator, ptr %b.466, i32 0, i32 1
  %5 = load ptr, ptr %4, align 8
  %6 = call ptr %3(ptr %5, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size)
  %7 = load i32, ptr @gala_785070.MODE_ALLOC, align 4
  %8 = icmp eq i32 %mode, %7
  br i1 %8, label %base_block_label448, label %alt_cond_label448_0

base_block_label448:                              ; preds = %entry
  %9 = ptrtoint ptr %6 to i64
  %10 = load ptr, ptr @gala_785070.NULL, align 8
  %11 = ptrtoint ptr %10 to i64
  %12 = icmp ne i64 %9, %11
  br i1 %12, label %base_block_label451, label %end_label451

base_block_label451:                              ; preds = %base_block_label448
  %13 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 1
  %14 = load i64, ptr %13, align 8
  %15 = add i64 %14, 1
  store i64 %15, ptr %13, align 8
  %16 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 3
  %17 = load i64, ptr %16, align 8
  %18 = add i64 %17, %size
  store i64 %18, ptr %16, align 8
  %19 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 5
  %20 = load i64, ptr %19, align 8
  %21 = add i64 %20, %size
  store i64 %21, ptr %19, align 8
  br label %end_label451

end_label451:                                     ; preds = %base_block_label451, %base_block_label448
  br label %end_label448

alt_cond_label448_0:                              ; preds = %entry
  %22 = load i32, ptr @gala_785070.MODE_FREE, align 4
  %23 = icmp eq i32 %mode, %22
  br i1 %23, label %alt_block_label448_0, label %alt_cond_label448_1

alt_block_label448_0:                             ; preds = %alt_cond_label448_0
  %24 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 2
  %25 = load i64, ptr %24, align 8
  %26 = add i64 %25, 1
  store i64 %26, ptr %24, align 8
  %27 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 3
  %28 = load i64, ptr %27, align 8
  %29 = sub i64 %28, %old_size
  store i64 %29, ptr %27, align 8
  br label %end_label448

alt_cond_label448_1:                              ; preds = %alt_cond_label448_0
  %30 = load i32, ptr @gala_785070.MODE_FREE_ALL, align 4
  %31 = icmp eq i32 %mode, %30
  br i1 %31, label %alt_block_label448_1, label %alt_cond_label448_2

alt_block_label448_1:                             ; preds = %alt_cond_label448_1
  %32 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 3
  store i64 0, ptr %32, align 8
  br label %end_label448

alt_cond_label448_2:                              ; preds = %alt_cond_label448_1
  %33 = load i32, ptr @gala_785070.MODE_RESIZE, align 4
  %34 = icmp eq i32 %mode, %33
  br i1 %34, label %alt_block_label448_2, label %end_label448

alt_block_label448_2:                             ; preds = %alt_cond_label448_2
  %35 = ptrtoint ptr %6 to i64
  %36 = load ptr, ptr @gala_785070.NULL, align 8
  %37 = ptrtoint ptr %36 to i64
  %38 = icmp ne i64 %35, %37
  br i1 %38, label %base_block_label485, label %end_label485

base_block_label485:                              ; preds = %alt_block_label448_2
  %39 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 3
  %40 = load i64, ptr %39, align 8
  %41 = sub i64 %size, %old_size
  %42 = add i64 %40, %41
  store i64 %42, ptr %39, align 8
  %43 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 5
  %44 = load i64, ptr %43, align 8
  %45 = add i64 %44, %size
  store i64 %45, ptr %43, align 8
  br label %end_label485

end_label485:                                     ; preds = %base_block_label485, %alt_block_label448_2
  br label %end_label448

end_label448:                                     ; preds = %end_label485, %alt_cond_label448_2, %alt_block_label448_1, %alt_block_label448_0, %end_label451
  %46 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 3
  %47 = load i64, ptr %46, align 8
  %48 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 4
  %49 = load i64, ptr %48, align 8
  %50 = icmp sgt i64 %47, %49
  br i1 %50, label %base_block_label500, label %end_label500

base_block_label500:                              ; preds = %end_label448
  %51 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 3
  %52 = load i64, ptr %51, align 8
  %53 = getelementptr inbounds %gala_785070.Tracking, ptr %data, i32 0, i32 4
  store i64 %52, ptr %53, align 8
  br label %end_label500

end_label500:                                     ; preds = %base_block_label500, %end_label448
  ret ptr %6
}

define { i64, i64 } @gala_785070.tracking_allocator(ptr %t) {
entry:
  %slot516 = alloca %gala_785070.Allocator, align 8
  %0 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.tracking_proc, 0
  %1 = insertvalue %gala_785070.Allocator %0, ptr %t, 1
  store %gala_785070.Allocator %1, ptr %slot516, align 8
  %2 = load { i64, i64 }, ptr %slot516, align 8
  ret { i64, i64 } %2
}

define void @gala_785070.tracking_report(ptr %t) {
entry:
  %slot518 = alloca [4 x { ptr, i64 }], align 8
  %slot522 = alloca { ptr, i64 }, align 8
  %slot528 = alloca i64, align 8
  %slot535 = alloca { ptr, i64 }, align 8
  %slot541 = alloca i64, align 8
  %slot547 = alloca [6 x { ptr, i64 }], align 8
  %slot551 = alloca { ptr, i64 }, align 8
  %slot557 = alloca i64, align 8
  %slot564 = alloca { ptr, i64 }, align 8
  %slot570 = alloca i64, align 8
  %slot577 = alloca { ptr, i64 }, align 8
  %slot583 = alloca i64, align 8
  %0 = getelementptr inbounds [8 x i8], ptr @string27, i64 0, i64 0
  %1 = insertvalue { ptr, i64 } undef, ptr %0, 0
  %2 = insertvalue { ptr, i64 } %1, i64 7, 1
  store { ptr, i64 } %2, ptr %slot522, align 8
  %3 = insertvalue { ptr, i64 } undef, ptr %slot522, 0
  %4 = insertvalue { ptr, i64 } %3, i64 17, 1
  %5 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 0
  store { ptr, i64 } %4, ptr %5, align 8
  %6 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 1
  %7 = load i64, ptr %6, align 8
  store i64 %7, ptr %slot528, align 8
  %8 = insertvalue { ptr, i64 } undef, ptr %slot528, 0
  %9 = insertvalue { ptr, i64 } %8, i64 3, 1
  %10 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 1
  store { ptr, i64 } %9, ptr %10, align 8
  %11 = getelementptr inbounds [7 x i8], ptr @string28, i64 0, i64 0
  %12 = insertvalue { ptr, i64 } undef, ptr %11, 0
  %13 = insertvalue { ptr, i64 } %12, i64 6, 1
  store { ptr, i64 } %13, ptr %slot535, align 8
  %14 = insertvalue { ptr, i64 } undef, ptr %slot535, 0
  %15 = insertvalue { ptr, i64 } %14, i64 17, 1
  %16 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 2
  store { ptr, i64 } %15, ptr %16, align 8
  %17 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 2
  %18 = load i64, ptr %17, align 8
  store i64 %18, ptr %slot541, align 8
  %19 = insertvalue { ptr, i64 } undef, ptr %slot541, 0
  %20 = insertvalue { ptr, i64 } %19, i64 3, 1
  %21 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 3
  store { ptr, i64 } %20, ptr %21, align 8
  %22 = insertvalue { ptr, i64 } undef, ptr %slot518, 0
  %23 = insertvalue { ptr, i64 } %22, i64 4, 1
  call void @gala_120231.println({ ptr, i64 } %23)
  %24 = getelementptr inbounds [12 x i8], ptr @string29, i64 0, i64 0
  %25 = insertvalue { ptr, i64 } undef, ptr %24, 0
  %26 = insertvalue { ptr, i64 } %25, i64 11, 1
  store { ptr, i64 } %26, ptr %slot551, align 8
  %27 = insertvalue { ptr, i64 } undef, ptr %slot551, 0
  %28 = insertvalue { ptr, i64 } %27, i64 17, 1
  %29 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 0
  store { ptr, i64 } %28, ptr %29, align 8
  %30 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 3
  %31 = load i64, ptr %30, align 8
  store i64 %31, ptr %slot557, align 8
  %32 = insertvalue { ptr, i64 } undef, ptr %slot557, 0
  %33 = insertvalue { ptr, i64 } %32, i64 3, 1
  %34 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 1
  store { ptr, i64 } %33, ptr %34, align 8
  %35 = getelementptr inbounds [6 x i8], ptr @string30, i64 0, i64 0
  %36 = insertvalue { ptr, i64 } undef, ptr %35, 0
  %37 = insertvalue { ptr, i64 } %36, i64 5, 1
  store { ptr, i64 } %37, ptr %slot564, align 8
  %38 = insertvalue { ptr, i64 } undef, ptr %slot564, 0
  %39 = insertvalue { ptr, i64 } %38, i64 17, 1
  %40 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 2
  store { ptr, i64 } %39, ptr %40, align 8
  %41 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 4
  %42 = load i64, ptr %41, align 8
  store i64 %42, ptr %slot570, align 8
  %43 = insertvalue { ptr, i64 } undef, ptr %slot570, 0
  %44 = insertvalue { ptr, i64 } %43, i64 3, 1
  %45 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 3
  store { ptr, i64 } %44, ptr %45, align 8
  %46 = getelementptr inbounds [7 x i8], ptr @string31, i64 0, i64 0
  %47 = insertvalue { ptr, i64 } undef, ptr %46, 0
  %48 = insertvalue { ptr, i64 } %47, i64 6, 1
  store { ptr, i64 } %48, ptr %slot577, align 8
  %49 = insertvalue { ptr, i64 } undef, ptr %slot577, 0
  %50 = insertvalue { ptr, i64 } %49, i64 17, 1
  %51 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 4
  store { ptr, i64 } %50, ptr %51, align 8
  %52 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 5
  %53 = load i64, ptr %52, align 8
  store i64 %53, ptr %slot583, align 8
  %54 = insertvalue { ptr, i64 } undef, ptr %slot583, 0
  %55 = insertvalue { ptr, i64 } %54, i64 3, 1
  %56 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 5
  store { ptr, i64 } %55, ptr %56, align 8
  %57 = insertvalue { ptr, i64 } undef, ptr %slot547, 0
  %58 = insertvalue { ptr, i64 } %57, i64 6, 1
  call void @gala_120231.println({ ptr, i64 } %58)
  ret void
}

define void @gala_785070.__init_globals() {
entry:
  %0 = inttoptr i64 0 to ptr
  store ptr %0, ptr @gala_785070.NULL, align 8
  store i64 1024, ptr @gala_785070.KB, align 8
  store i64 1048576, ptr @gala_785070.MB, align 8
  store i64 1073741824, ptr @gala_785070.GB, align 8
  store i32 0, ptr @gala_785070.MODE_ALLOC, align 4
  store i32 1, ptr @gala_785070.MODE_FREE, align 4
  store i32 2, ptr @gala_785070.MODE_FREE_ALL, align 4
  store i32 3, ptr @gala_785070.MODE_RESIZE, align 4
  %1 = call { i64, i64 } @gala_785070.heap_allocator()
  %slot591 = alloca %gala_785070.Allocator, align 8
  store { i64, i64 } %1, ptr %slot591, align 8
  %2 = load %gala_785070.Allocator, ptr %slot591, align 8
  store %gala_785070.Allocator %2, ptr @gala_785070.base_allocator, align 8
  ret void
}

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
