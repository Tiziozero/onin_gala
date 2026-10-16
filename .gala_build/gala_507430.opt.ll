; ModuleID = '.gala_build/gala_507430.ll'
source_filename = ".gala_build/gala_507430.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%gala_785070.Allocator = type { ptr, ptr }
%gala_785070.Arena = type { ptr, i64, i64, i64, i1 }
%gala_785070.Pool = type { ptr, i64, i64, ptr }
%gala_179762.TcpSocket = type { i32 }

@gala_179762.AF_INET = external global i32
@gala_179762.SOCK_STREAM = external global i32
@gala_179762.IPPROTO_TCP = external global i32
@gala_179762.SOL_SOCKET = external global i32
@gala_179762.SO_REUSEADDR = external global i32
@gala_179762.SHUT_RD = external global i32
@gala_179762.SHUT_WR = external global i32
@gala_179762.SHUT_RDWR = external global i32
@gala_785070.NULL = external global ptr
@gala_785070.KB = external global i64
@gala_785070.MB = external global i64
@gala_785070.GB = external global i64
@gala_785070.MODE_ALLOC = external global i32
@gala_785070.MODE_FREE = external global i32
@gala_785070.MODE_FREE_ALL = external global i32
@gala_785070.MODE_RESIZE = external global i32
@gala_785070.base_allocator = external global %gala_785070.Allocator
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

declare { i64, i64 } @gala_179762.make_address({ ptr, i64 }, i16)

declare i32 @gala_179762.tcp_connect({ ptr, i64 }, i16)

declare i32 @gala_179762.tcp_listen(i16, i32)

declare i32 @gala_179762.tcp_accept(i32)

declare i64 @gala_179762.tcp_send(i32, { ptr, i64 })

declare i64 @gala_179762.tcp_recv(i32, { ptr, i64 })

declare void @gala_179762.tcp_close(i32)

declare i32 @gala_179762.tcp_shutdown(i32, i32)

declare void @gala_179762.__init_globals()

declare i64 @gala_785070.addr(ptr)

declare ptr @gala_785070.from_addr(i64)

declare i64 @gala_785070.align_forward(i64, i64)

declare i64 @gala_785070.min_u64(i64, i64)

declare void @gala_785070.mem_copy(ptr, ptr, i64)

declare void @gala_785070.mem_zero(ptr, i64)

declare void @gala_785070.mem_set(ptr, i32, i64)

declare i1 @gala_785070.mem_equal(ptr, ptr, i64)

declare { ptr, i64 } @gala_785070.bytes_from(ptr, i64)

declare void @gala_785070.set_allocator({ i64, i64 })

declare i64 @gala_785070.__default_0()

declare { i64, i64 } @gala_785070.__default_1()

declare ptr @gala_785070.alloc(i64, i64, { i64, i64 })

declare i64 @gala_785070.__default_2()

declare { i64, i64 } @gala_785070.__default_3()

declare void @gala_785070.dealloc(ptr, i64, { i64, i64 })

declare { i64, i64 } @gala_785070.__default_4()

declare void @gala_785070.dealloc_all({ i64, i64 })

declare i64 @gala_785070.__default_5()

declare { i64, i64 } @gala_785070.__default_6()

declare ptr @gala_785070.resize(ptr, i64, i64, i64, { i64, i64 })

declare { i64, i64 } @gala_785070.__default_7()

declare { ptr, i64 } @gala_785070.alloc_bytes(i64, { i64, i64 })

declare { i64, i64 } @gala_785070.__default_8()

declare { ptr, i64 } @gala_785070.clone_string({ ptr, i64 }, { i64, i64 })

declare ptr @gala_785070.heap_proc(ptr, i32, i64, i64, ptr, i64)

declare { i64, i64 } @gala_785070.heap_allocator()

declare void @gala_785070.arena_init(ptr, ptr, i64)

declare void @gala_785070.arena_make(ptr sret(%gala_785070.Arena) align 8, i64)

declare void @gala_785070.arena_destroy(ptr)

declare void @gala_785070.arena_reset(ptr)

declare i64 @gala_785070.arena_mark(ptr)

declare void @gala_785070.arena_restore(ptr, i64)

declare ptr @gala_785070.arena_proc(ptr, i32, i64, i64, ptr, i64)

declare { i64, i64 } @gala_785070.arena_allocator(ptr)

declare void @gala_785070.pool_make(ptr sret(%gala_785070.Pool) align 8, i64, i64)

declare void @gala_785070.pool_destroy(ptr)

declare ptr @gala_785070.pool_proc(ptr, i32, i64, i64, ptr, i64)

declare { i64, i64 } @gala_785070.pool_allocator(ptr)

declare void @gala_785070.tracking_init(ptr, { i64, i64 })

declare ptr @gala_785070.tracking_proc(ptr, i32, i64, i64, ptr, i64)

declare { i64, i64 } @gala_785070.tracking_allocator(ptr)

declare void @gala_785070.tracking_report(ptr)

declare void @gala_785070.__init_globals()

define void @gala_507430.printlen({ ptr, i64 } %data) {
entry:
  %slot32 = alloca [2 x { ptr, i64 }], align 8
  %slot36 = alloca { ptr, i64 }, align 8
  %slot41 = alloca i64, align 8
  %0 = getelementptr inbounds [10 x i8], ptr @string4, i64 0, i64 0
  %1 = insertvalue { ptr, i64 } undef, ptr %0, 0
  %2 = insertvalue { ptr, i64 } %1, i64 9, 1
  store { ptr, i64 } %2, ptr %slot36, align 8
  %3 = insertvalue { ptr, i64 } undef, ptr %slot36, 0
  %4 = insertvalue { ptr, i64 } %3, i64 17, 1
  %5 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot32, i64 0, i64 0
  store { ptr, i64 } %4, ptr %5, align 8
  %6 = extractvalue { ptr, i64 } %data, 1
  store i64 %6, ptr %slot41, align 8
  %7 = insertvalue { ptr, i64 } undef, ptr %slot41, 0
  %8 = insertvalue { ptr, i64 } %7, i64 3, 1
  %9 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot32, i64 0, i64 1
  store { ptr, i64 } %8, ptr %9, align 8
  %10 = insertvalue { ptr, i64 } undef, ptr %slot32, 0
  %11 = insertvalue { ptr, i64 } %10, i64 2, 1
  call void @gala_120231.println({ ptr, i64 } %11)
  ret void
}

define void @gala_507430.main() {
entry:
  %slot48 = alloca %gala_179762.TcpSocket, align 8
  %server.474 = alloca %gala_179762.TcpSocket, align 8
  %slot54 = alloca [1 x { ptr, i64 }], align 8
  %slot58 = alloca { ptr, i64 }, align 8
  %slot64 = alloca [1 x { ptr, i64 }], align 8
  %slot68 = alloca { ptr, i64 }, align 8
  %slot76 = alloca %gala_179762.TcpSocket, align 8
  %slot79 = alloca %gala_179762.TcpSocket, align 8
  %client.475 = alloca %gala_179762.TcpSocket, align 8
  %slot85 = alloca [1 x { ptr, i64 }], align 8
  %slot89 = alloca { ptr, i64 }, align 8
  %slot95 = alloca [1 x { ptr, i64 }], align 8
  %slot99 = alloca { ptr, i64 }, align 8
  %buffer.476 = alloca [1024 x i8], align 1
  %slot107 = alloca %gala_179762.TcpSocket, align 8
  %slot117 = alloca [2 x { ptr, i64 }], align 8
  %slot121 = alloca { ptr, i64 }, align 8
  %slot132 = alloca { ptr, i64 }, align 8
  %slot139 = alloca %gala_179762.TcpSocket, align 8
  %slot164 = alloca [2 x { ptr, i64 }], align 8
  %slot168 = alloca { ptr, i64 }, align 8
  %slot174 = alloca i64, align 8
  %slot180 = alloca [1 x { ptr, i64 }], align 8
  %slot184 = alloca { ptr, i64 }, align 8
  %slot191 = alloca %gala_179762.TcpSocket, align 8
  %slot194 = alloca %gala_179762.TcpSocket, align 8
  %0 = call i32 @gala_179762.tcp_listen(i16 zeroext 9000, i32 16)
  store i32 %0, ptr %slot48, align 4
  %1 = load %gala_179762.TcpSocket, ptr %slot48, align 4
  store %gala_179762.TcpSocket %1, ptr %server.474, align 4
  %2 = getelementptr inbounds %gala_179762.TcpSocket, ptr %server.474, i32 0, i32 0
  %3 = load i32, ptr %2, align 4
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %base_block_label50, label %end_label50

base_block_label50:                               ; preds = %entry
  %5 = getelementptr inbounds [23 x i8], ptr @string5, i64 0, i64 0
  %6 = insertvalue { ptr, i64 } undef, ptr %5, 0
  %7 = insertvalue { ptr, i64 } %6, i64 22, 1
  store { ptr, i64 } %7, ptr %slot58, align 8
  %8 = insertvalue { ptr, i64 } undef, ptr %slot58, 0
  %9 = insertvalue { ptr, i64 } %8, i64 17, 1
  %10 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot54, i64 0, i64 0
  store { ptr, i64 } %9, ptr %10, align 8
  %11 = insertvalue { ptr, i64 } undef, ptr %slot54, 0
  %12 = insertvalue { ptr, i64 } %11, i64 1, 1
  call void @gala_120231.println({ ptr, i64 } %12)
  ret void

end_label50:                                      ; preds = %entry
  %13 = getelementptr inbounds [35 x i8], ptr @string6, i64 0, i64 0
  %14 = insertvalue { ptr, i64 } undef, ptr %13, 0
  %15 = insertvalue { ptr, i64 } %14, i64 34, 1
  store { ptr, i64 } %15, ptr %slot68, align 8
  %16 = insertvalue { ptr, i64 } undef, ptr %slot68, 0
  %17 = insertvalue { ptr, i64 } %16, i64 17, 1
  %18 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot64, i64 0, i64 0
  store { ptr, i64 } %17, ptr %18, align 8
  %19 = insertvalue { ptr, i64 } undef, ptr %slot64, 0
  %20 = insertvalue { ptr, i64 } %19, i64 1, 1
  call void @gala_120231.println({ ptr, i64 } %20)
  br label %while_cond_label74

while_cond_label74:                               ; preds = %while_end_label105, %base_block_label81, %end_label50
  br i1 true, label %while_body_label74, label %while_end_label74

while_body_label74:                               ; preds = %while_cond_label74
  %21 = load %gala_179762.TcpSocket, ptr %server.474, align 4
  store %gala_179762.TcpSocket %21, ptr %slot76, align 4
  %22 = load i32, ptr %slot76, align 4
  %23 = call i32 @gala_179762.tcp_accept(i32 %22)
  store i32 %23, ptr %slot79, align 4
  %24 = load %gala_179762.TcpSocket, ptr %slot79, align 4
  store %gala_179762.TcpSocket %24, ptr %client.475, align 4
  %25 = getelementptr inbounds %gala_179762.TcpSocket, ptr %client.475, i32 0, i32 0
  %26 = load i32, ptr %25, align 4
  %27 = icmp slt i32 %26, 0
  br i1 %27, label %base_block_label81, label %end_label81

base_block_label81:                               ; preds = %while_body_label74
  %28 = getelementptr inbounds [14 x i8], ptr @string7, i64 0, i64 0
  %29 = insertvalue { ptr, i64 } undef, ptr %28, 0
  %30 = insertvalue { ptr, i64 } %29, i64 13, 1
  store { ptr, i64 } %30, ptr %slot89, align 8
  %31 = insertvalue { ptr, i64 } undef, ptr %slot89, 0
  %32 = insertvalue { ptr, i64 } %31, i64 17, 1
  %33 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot85, i64 0, i64 0
  store { ptr, i64 } %32, ptr %33, align 8
  %34 = insertvalue { ptr, i64 } undef, ptr %slot85, 0
  %35 = insertvalue { ptr, i64 } %34, i64 1, 1
  call void @gala_120231.println({ ptr, i64 } %35)
  br label %while_cond_label74

end_label81:                                      ; preds = %while_body_label74
  %36 = getelementptr inbounds [17 x i8], ptr @string8, i64 0, i64 0
  %37 = insertvalue { ptr, i64 } undef, ptr %36, 0
  %38 = insertvalue { ptr, i64 } %37, i64 16, 1
  store { ptr, i64 } %38, ptr %slot99, align 8
  %39 = insertvalue { ptr, i64 } undef, ptr %slot99, 0
  %40 = insertvalue { ptr, i64 } %39, i64 17, 1
  %41 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot95, i64 0, i64 0
  store { ptr, i64 } %40, ptr %41, align 8
  %42 = insertvalue { ptr, i64 } undef, ptr %slot95, 0
  %43 = insertvalue { ptr, i64 } %42, i64 1, 1
  call void @gala_120231.println({ ptr, i64 } %43)
  call void @llvm.memset.p0.i64(ptr %buffer.476, i8 0, i64 1024, i1 false)
  br label %while_cond_label105

while_cond_label105:                              ; preds = %while_end_label152, %end_label81
  br i1 true, label %while_body_label105, label %while_end_label105

while_body_label105:                              ; preds = %while_cond_label105
  %44 = load %gala_179762.TcpSocket, ptr %client.475, align 4
  store %gala_179762.TcpSocket %44, ptr %slot107, align 4
  %45 = load i32, ptr %slot107, align 4
  %46 = sub nuw nsw i64 1024, 0
  %47 = getelementptr inbounds i8, ptr %buffer.476, i64 0
  %48 = insertvalue { ptr, i64 } undef, ptr %47, 0
  %49 = insertvalue { ptr, i64 } %48, i64 %46, 1
  %50 = call i64 @gala_179762.tcp_recv(i32 %45, { ptr, i64 } %49)
  %51 = icmp sle i64 %50, 0
  br i1 %51, label %base_block_label114, label %end_label114

base_block_label114:                              ; preds = %while_body_label105
  br label %while_end_label105

end_label114:                                     ; preds = %while_body_label105
  %52 = getelementptr inbounds [5 x i8], ptr @string9, i64 0, i64 0
  %53 = insertvalue { ptr, i64 } undef, ptr %52, 0
  %54 = insertvalue { ptr, i64 } %53, i64 4, 1
  store { ptr, i64 } %54, ptr %slot121, align 8
  %55 = insertvalue { ptr, i64 } undef, ptr %slot121, 0
  %56 = insertvalue { ptr, i64 } %55, i64 17, 1
  %57 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot117, i64 0, i64 0
  store { ptr, i64 } %56, ptr %57, align 8
  %58 = sub nuw nsw i64 %50, 0
  %59 = getelementptr inbounds i8, ptr %buffer.476, i64 0
  %60 = insertvalue { ptr, i64 } undef, ptr %59, 0
  %61 = insertvalue { ptr, i64 } %60, i64 %58, 1
  store { ptr, i64 } %61, ptr %slot132, align 8
  %62 = insertvalue { ptr, i64 } undef, ptr %slot132, 0
  %63 = insertvalue { ptr, i64 } %62, i64 17, 1
  %64 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot117, i64 0, i64 1
  store { ptr, i64 } %63, ptr %64, align 8
  %65 = insertvalue { ptr, i64 } undef, ptr %slot117, 0
  %66 = insertvalue { ptr, i64 } %65, i64 2, 1
  call void @gala_120231.println({ ptr, i64 } %66)
  %67 = load %gala_179762.TcpSocket, ptr %client.475, align 4
  store %gala_179762.TcpSocket %67, ptr %slot139, align 4
  %68 = load i32, ptr %slot139, align 4
  %69 = sub nuw nsw i64 %50, 0
  %70 = getelementptr inbounds i8, ptr %buffer.476, i64 0
  %71 = insertvalue { ptr, i64 } undef, ptr %70, 0
  %72 = insertvalue { ptr, i64 } %71, i64 %69, 1
  %73 = call i64 @gala_179762.tcp_send(i32 %68, { ptr, i64 } %72)
  %74 = sub nuw nsw i64 %50, 0
  %75 = getelementptr inbounds i8, ptr %buffer.476, i64 0
  %76 = insertvalue { ptr, i64 } undef, ptr %75, 0
  %77 = insertvalue { ptr, i64 } %76, i64 %74, 1
  br label %while_cond_label152

while_cond_label152:                              ; preds = %while_body_label152, %end_label114
  %__for_idx1.480.0 = phi i64 [ 0, %end_label114 ], [ %83, %while_body_label152 ]
  %78 = extractvalue { ptr, i64 } %77, 1
  %79 = icmp slt i64 %__for_idx1.480.0, %78
  br i1 %79, label %while_body_label152, label %while_end_label152

while_body_label152:                              ; preds = %while_cond_label152
  %80 = extractvalue { ptr, i64 } %77, 0
  %81 = getelementptr inbounds i8, ptr %80, i64 %__for_idx1.480.0
  %82 = load i8, ptr %81, align 1
  %83 = add i64 %__for_idx1.480.0, 1
  %84 = getelementptr inbounds [6 x i8], ptr @string10, i64 0, i64 0
  %85 = insertvalue { ptr, i64 } undef, ptr %84, 0
  %86 = insertvalue { ptr, i64 } %85, i64 5, 1
  store { ptr, i64 } %86, ptr %slot168, align 8
  %87 = insertvalue { ptr, i64 } undef, ptr %slot168, 0
  %88 = insertvalue { ptr, i64 } %87, i64 17, 1
  %89 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot164, i64 0, i64 0
  store { ptr, i64 } %88, ptr %89, align 8
  %90 = zext i8 %82 to i64
  store i64 %90, ptr %slot174, align 8
  %91 = insertvalue { ptr, i64 } undef, ptr %slot174, 0
  %92 = insertvalue { ptr, i64 } %91, i64 3, 1
  %93 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot164, i64 0, i64 1
  store { ptr, i64 } %92, ptr %93, align 8
  %94 = insertvalue { ptr, i64 } undef, ptr %slot164, 0
  %95 = insertvalue { ptr, i64 } %94, i64 2, 1
  call void @gala_120231.println({ ptr, i64 } %95)
  br label %while_cond_label152

while_end_label152:                               ; preds = %while_cond_label152
  br label %while_cond_label105

while_end_label105:                               ; preds = %base_block_label114, %while_cond_label105
  %96 = getelementptr inbounds [20 x i8], ptr @string11, i64 0, i64 0
  %97 = insertvalue { ptr, i64 } undef, ptr %96, 0
  %98 = insertvalue { ptr, i64 } %97, i64 19, 1
  store { ptr, i64 } %98, ptr %slot184, align 8
  %99 = insertvalue { ptr, i64 } undef, ptr %slot184, 0
  %100 = insertvalue { ptr, i64 } %99, i64 17, 1
  %101 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot180, i64 0, i64 0
  store { ptr, i64 } %100, ptr %101, align 8
  %102 = insertvalue { ptr, i64 } undef, ptr %slot180, 0
  %103 = insertvalue { ptr, i64 } %102, i64 1, 1
  call void @gala_120231.println({ ptr, i64 } %103)
  %104 = load %gala_179762.TcpSocket, ptr %client.475, align 4
  store %gala_179762.TcpSocket %104, ptr %slot191, align 4
  %105 = load i32, ptr %slot191, align 4
  call void @gala_179762.tcp_close(i32 %105)
  br label %while_cond_label74

while_end_label74:                                ; preds = %while_cond_label74
  %106 = load %gala_179762.TcpSocket, ptr %server.474, align 4
  store %gala_179762.TcpSocket %106, ptr %slot194, align 4
  %107 = load i32, ptr %slot194, align 4
  call void @gala_179762.tcp_close(i32 %107)
  ret void
}

define i32 @main(i32 %argc, ptr %argv) {
  call void @gala_179762.__init_globals()
  call void @gala_785070.__init_globals()
  call void @gala_507430.main()
  ret i32 0
}

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
