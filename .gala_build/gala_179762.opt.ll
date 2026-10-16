; ModuleID = '.gala_build/gala_179762.ll'
source_filename = ".gala_build/gala_179762.ll"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%gala_179762.SockAddrIn = type { i16, i16, i32, [8 x i8] }
%gala_179762.TcpSocket = type { i32 }

@gala_179762.AF_INET = global i32 0
@gala_179762.SOCK_STREAM = global i32 0
@gala_179762.IPPROTO_TCP = global i32 0
@gala_179762.SOL_SOCKET = global i32 0
@gala_179762.SO_REUSEADDR = global i32 0
@gala_179762.SHUT_RD = global i32 0
@gala_179762.SHUT_WR = global i32 0
@gala_179762.SHUT_RDWR = global i32 0
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

define { i64, i64 } @gala_179762.make_address({ ptr, i64 } %address, i16 %port) {
entry:
  %a.287 = alloca %gala_179762.SockAddrIn, align 8
  %slot40 = alloca %gala_179762.SockAddrIn, align 8
  %0 = insertvalue %gala_179762.SockAddrIn undef, i16 0, 0
  %1 = insertvalue %gala_179762.SockAddrIn %0, i16 0, 1
  %2 = insertvalue %gala_179762.SockAddrIn %1, i32 0, 2
  %3 = insertvalue %gala_179762.SockAddrIn %2, [8 x i8] zeroinitializer, 3
  store %gala_179762.SockAddrIn %3, ptr %a.287, align 4
  %4 = load i32, ptr @gala_179762.AF_INET, align 4
  %5 = trunc i32 %4 to i16
  %6 = getelementptr inbounds %gala_179762.SockAddrIn, ptr %a.287, i32 0, i32 0
  store i16 %5, ptr %6, align 2
  %7 = call zeroext i16 @htons(i16 zeroext %port)
  %8 = getelementptr inbounds %gala_179762.SockAddrIn, ptr %a.287, i32 0, i32 1
  store i16 %7, ptr %8, align 2
  %9 = extractvalue { ptr, i64 } %address, 0
  %10 = getelementptr inbounds i8, ptr %9, i64 0
  %11 = call i32 @inet_addr(ptr %10)
  %12 = getelementptr inbounds %gala_179762.SockAddrIn, ptr %a.287, i32 0, i32 2
  store i32 %11, ptr %12, align 4
  %13 = load %gala_179762.SockAddrIn, ptr %a.287, align 4
  store %gala_179762.SockAddrIn %13, ptr %slot40, align 4
  %14 = load { i64, i64 }, ptr %slot40, align 8
  ret { i64, i64 } %14
}

define i32 @gala_179762.tcp_connect({ ptr, i64 } %address, i16 %port) {
entry:
  %slot51 = alloca %gala_179762.TcpSocket, align 8
  %slot54 = alloca %gala_179762.SockAddrIn, align 8
  %addr.291 = alloca %gala_179762.SockAddrIn, align 8
  %slot66 = alloca %gala_179762.TcpSocket, align 8
  %slot70 = alloca %gala_179762.TcpSocket, align 8
  %0 = load i32, ptr @gala_179762.AF_INET, align 4
  %1 = load i32, ptr @gala_179762.SOCK_STREAM, align 4
  %2 = load i32, ptr @gala_179762.IPPROTO_TCP, align 4
  %3 = call i32 @socket(i32 %0, i32 %1, i32 %2)
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %base_block_label46, label %end_label46

base_block_label46:                               ; preds = %entry
  %5 = sub i32 0, 1
  %6 = insertvalue %gala_179762.TcpSocket undef, i32 %5, 0
  store %gala_179762.TcpSocket %6, ptr %slot51, align 4
  %7 = load i32, ptr %slot51, align 4
  ret i32 %7

end_label46:                                      ; preds = %entry
  %8 = call { i64, i64 } @gala_179762.make_address({ ptr, i64 } %address, i16 zeroext %port)
  store { i64, i64 } %8, ptr %slot54, align 8
  %9 = load %gala_179762.SockAddrIn, ptr %slot54, align 4
  store %gala_179762.SockAddrIn %9, ptr %addr.291, align 4
  %10 = bitcast ptr %addr.291 to ptr
  %11 = call i32 @connect(i32 %3, ptr %10, i32 16)
  %12 = icmp slt i32 %11, 0
  br i1 %12, label %base_block_label59, label %end_label59

base_block_label59:                               ; preds = %end_label46
  %13 = call i32 @close(i32 %3)
  %14 = sub i32 0, 1
  %15 = insertvalue %gala_179762.TcpSocket undef, i32 %14, 0
  store %gala_179762.TcpSocket %15, ptr %slot66, align 4
  %16 = load i32, ptr %slot66, align 4
  ret i32 %16

end_label59:                                      ; preds = %end_label46
  %17 = insertvalue %gala_179762.TcpSocket undef, i32 %3, 0
  store %gala_179762.TcpSocket %17, ptr %slot70, align 4
  %18 = load i32, ptr %slot70, align 4
  ret i32 %18
}

define i32 @gala_179762.tcp_listen(i16 %port, i32 %backlog) {
entry:
  %slot81 = alloca %gala_179762.TcpSocket, align 8
  %reuse.296 = alloca i32, align 4
  %slot95 = alloca %gala_179762.TcpSocket, align 8
  %addr.298 = alloca %gala_179762.SockAddrIn, align 8
  %slot114 = alloca %gala_179762.TcpSocket, align 8
  %slot125 = alloca %gala_179762.TcpSocket, align 8
  %slot129 = alloca %gala_179762.TcpSocket, align 8
  %0 = load i32, ptr @gala_179762.AF_INET, align 4
  %1 = load i32, ptr @gala_179762.SOCK_STREAM, align 4
  %2 = load i32, ptr @gala_179762.IPPROTO_TCP, align 4
  %3 = call i32 @socket(i32 %0, i32 %1, i32 %2)
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %base_block_label76, label %end_label76

base_block_label76:                               ; preds = %entry
  %5 = sub i32 0, 1
  %6 = insertvalue %gala_179762.TcpSocket undef, i32 %5, 0
  store %gala_179762.TcpSocket %6, ptr %slot81, align 4
  %7 = load i32, ptr %slot81, align 4
  ret i32 %7

end_label76:                                      ; preds = %entry
  store i32 1, ptr %reuse.296, align 4
  %8 = load i32, ptr @gala_179762.SOL_SOCKET, align 4
  %9 = load i32, ptr @gala_179762.SO_REUSEADDR, align 4
  %10 = bitcast ptr %reuse.296 to ptr
  %11 = call i32 @setsockopt(i32 %3, i32 %8, i32 %9, ptr %10, i32 4)
  %12 = icmp slt i32 %11, 0
  br i1 %12, label %base_block_label88, label %end_label88

base_block_label88:                               ; preds = %end_label76
  %13 = call i32 @close(i32 %3)
  %14 = sub i32 0, 1
  %15 = insertvalue %gala_179762.TcpSocket undef, i32 %14, 0
  store %gala_179762.TcpSocket %15, ptr %slot95, align 4
  %16 = load i32, ptr %slot95, align 4
  ret i32 %16

end_label88:                                      ; preds = %end_label76
  %17 = load i32, ptr @gala_179762.AF_INET, align 4
  %18 = trunc i32 %17 to i16
  %19 = call zeroext i16 @htons(i16 zeroext %port)
  %20 = insertvalue %gala_179762.SockAddrIn undef, i16 %18, 0
  %21 = insertvalue %gala_179762.SockAddrIn %20, i16 %19, 1
  %22 = insertvalue %gala_179762.SockAddrIn %21, i32 0, 2
  %23 = insertvalue %gala_179762.SockAddrIn %22, [8 x i8] zeroinitializer, 3
  store %gala_179762.SockAddrIn %23, ptr %addr.298, align 4
  %24 = bitcast ptr %addr.298 to ptr
  %25 = call i32 @bind(i32 %3, ptr %24, i32 16)
  %26 = icmp slt i32 %25, 0
  br i1 %26, label %base_block_label107, label %end_label107

base_block_label107:                              ; preds = %end_label88
  %27 = call i32 @close(i32 %3)
  %28 = sub i32 0, 1
  %29 = insertvalue %gala_179762.TcpSocket undef, i32 %28, 0
  store %gala_179762.TcpSocket %29, ptr %slot114, align 4
  %30 = load i32, ptr %slot114, align 4
  ret i32 %30

end_label107:                                     ; preds = %end_label88
  %31 = call i32 @listen(i32 %3, i32 %backlog)
  %32 = icmp slt i32 %31, 0
  br i1 %32, label %base_block_label118, label %end_label118

base_block_label118:                              ; preds = %end_label107
  %33 = call i32 @close(i32 %3)
  %34 = sub i32 0, 1
  %35 = insertvalue %gala_179762.TcpSocket undef, i32 %34, 0
  store %gala_179762.TcpSocket %35, ptr %slot125, align 4
  %36 = load i32, ptr %slot125, align 4
  ret i32 %36

end_label118:                                     ; preds = %end_label107
  %37 = insertvalue %gala_179762.TcpSocket undef, i32 %3, 0
  store %gala_179762.TcpSocket %37, ptr %slot129, align 4
  %38 = load i32, ptr %slot129, align 4
  ret i32 %38
}

define i32 @gala_179762.tcp_accept(i32 %server.abi) {
entry:
  %0 = alloca %gala_179762.TcpSocket, align 8
  store i32 %server.abi, ptr %0, align 4
  %1 = load %gala_179762.TcpSocket, ptr %0, align 4
  %slot139 = alloca %gala_179762.TcpSocket, align 8
  %2 = extractvalue %gala_179762.TcpSocket %1, 0
  %3 = inttoptr i64 0 to ptr
  %4 = inttoptr i64 0 to ptr
  %5 = call i32 @accept(i32 %2, ptr %3, ptr %4)
  %6 = insertvalue %gala_179762.TcpSocket undef, i32 %5, 0
  store %gala_179762.TcpSocket %6, ptr %slot139, align 4
  %7 = load i32, ptr %slot139, align 4
  ret i32 %7
}

define i64 @gala_179762.tcp_send(i32 %_socket.abi, { ptr, i64 } %data) {
entry:
  %0 = alloca %gala_179762.TcpSocket, align 8
  store i32 %_socket.abi, ptr %0, align 4
  %1 = load %gala_179762.TcpSocket, ptr %0, align 4
  %2 = extractvalue %gala_179762.TcpSocket %1, 0
  %3 = extractvalue { ptr, i64 } %data, 0
  %4 = getelementptr inbounds i8, ptr %3, i64 0
  %5 = extractvalue { ptr, i64 } %data, 1
  %6 = call i64 @send(i32 %2, ptr %4, i64 %5, i32 0)
  ret i64 %6
}

define i64 @gala_179762.tcp_recv(i32 %_socket.abi, { ptr, i64 } %buffer) {
entry:
  %0 = alloca %gala_179762.TcpSocket, align 8
  store i32 %_socket.abi, ptr %0, align 4
  %1 = load %gala_179762.TcpSocket, ptr %0, align 4
  %2 = extractvalue %gala_179762.TcpSocket %1, 0
  %3 = extractvalue { ptr, i64 } %buffer, 0
  %4 = getelementptr inbounds i8, ptr %3, i64 0
  %5 = extractvalue { ptr, i64 } %buffer, 1
  %6 = call i64 @recv(i32 %2, ptr %4, i64 %5, i32 0)
  ret i64 %6
}

define void @gala_179762.tcp_close(i32 %_socket.abi) {
entry:
  %0 = alloca %gala_179762.TcpSocket, align 8
  store i32 %_socket.abi, ptr %0, align 4
  %1 = load %gala_179762.TcpSocket, ptr %0, align 4
  %2 = extractvalue %gala_179762.TcpSocket %1, 0
  %3 = icmp sge i32 %2, 0
  br i1 %3, label %base_block_label157, label %end_label157

base_block_label157:                              ; preds = %entry
  %4 = extractvalue %gala_179762.TcpSocket %1, 0
  %5 = call i32 @close(i32 %4)
  br label %end_label157

end_label157:                                     ; preds = %base_block_label157, %entry
  ret void
}

define i32 @gala_179762.tcp_shutdown(i32 %_socket.abi, i32 %how) {
entry:
  %0 = alloca %gala_179762.TcpSocket, align 8
  store i32 %_socket.abi, ptr %0, align 4
  %1 = load %gala_179762.TcpSocket, ptr %0, align 4
  %2 = extractvalue %gala_179762.TcpSocket %1, 0
  %3 = call i32 @shutdown(i32 %2, i32 %how)
  ret i32 %3
}

define void @gala_179762.__init_globals() {
entry:
  store i32 2, ptr @gala_179762.AF_INET, align 4
  store i32 1, ptr @gala_179762.SOCK_STREAM, align 4
  store i32 6, ptr @gala_179762.IPPROTO_TCP, align 4
  store i32 1, ptr @gala_179762.SOL_SOCKET, align 4
  store i32 2, ptr @gala_179762.SO_REUSEADDR, align 4
  store i32 0, ptr @gala_179762.SHUT_RD, align 4
  store i32 1, ptr @gala_179762.SHUT_WR, align 4
  store i32 2, ptr @gala_179762.SHUT_RDWR, align 4
  ret void
}

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
