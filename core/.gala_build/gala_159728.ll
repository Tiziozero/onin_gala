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
%gala_159728.SockAddrIn = type {i16,i16,i32,[8 x i8]}
%gala_159728.TcpSocket = type {i32}
@gala_159728.AF_INET = global i32 zeroinitializer
@gala_159728.SOCK_STREAM = global i32 zeroinitializer
@gala_159728.IPPROTO_TCP = global i32 zeroinitializer
@gala_159728.SOL_SOCKET = global i32 zeroinitializer
@gala_159728.SO_REUSEADDR = global i32 zeroinitializer
@gala_159728.SHUT_RD = global i32 zeroinitializer
@gala_159728.SHUT_WR = global i32 zeroinitializer
@gala_159728.SHUT_RDWR = global i32 zeroinitializer
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

@string26 = private unnamed_addr constant [18 x i8] c"./cfunctions.gala\00", align 1

define { i64, i64 } @gala_159728.make_address ({ ptr, i64 } %address, i16 %port) {
entry:
	%a.287 = alloca %gala_159728.SockAddrIn
	%slot41 = alloca %gala_159728.SockAddrIn
	%27 = insertvalue %gala_159728.SockAddrIn undef, i16 0, 0
	%28 = insertvalue %gala_159728.SockAddrIn %27, i16 0, 1
	%29 = insertvalue %gala_159728.SockAddrIn %28, i32 0, 2
	%30 = insertvalue %gala_159728.SockAddrIn %29, [8 x i8] zeroinitializer, 3
	store %gala_159728.SockAddrIn %30, ptr %a.287

	%31 = load i32, ptr @gala_159728.AF_INET
	%32 = trunc i32 %31 to i16
	%33 = getelementptr inbounds %gala_159728.SockAddrIn, ptr %a.287, i32 0, i32 0
	store i16 %32, ptr %33

	%34 = call zeroext i16 @htons(i16 zeroext %port)
	%35 = getelementptr inbounds %gala_159728.SockAddrIn, ptr %a.287, i32 0, i32 1
	store i16 %34, ptr %35

	%36 = extractvalue { ptr, i64 } %address, 0
	%37 = getelementptr inbounds i8, ptr %36, i64 0
	%38 = call i32 @inet_addr(ptr %37)
	%39 = getelementptr inbounds %gala_159728.SockAddrIn, ptr %a.287, i32 0, i32 2
	store i32 %38, ptr %39

	%40 = load %gala_159728.SockAddrIn, ptr %a.287
	store %gala_159728.SockAddrIn %40, ptr %slot41
	%42 = load { i64, i64 }, ptr %slot41
	ret { i64, i64 } %42

}
define i32 @gala_159728.tcp_connect ({ ptr, i64 } %address, i16 %port) {
entry:
	%fd.290 = alloca i32
	%slot52 = alloca %gala_159728.TcpSocket
	%slot55 = alloca %gala_159728.SockAddrIn
	%addr.291 = alloca %gala_159728.SockAddrIn
	%result.292 = alloca i32
	%slot67 = alloca %gala_159728.TcpSocket
	%slot71 = alloca %gala_159728.TcpSocket
	%43 = load i32, ptr @gala_159728.AF_INET
	%44 = load i32, ptr @gala_159728.SOCK_STREAM
	%45 = load i32, ptr @gala_159728.IPPROTO_TCP
	%46 = call i32 @socket(i32 %43, i32 %44, i32 %45)
	store i32 %46, ptr %fd.290

	%48 = load i32, ptr %fd.290
	%49 = icmp slt i32 %48, 0
	br i1 %49, label %base_block_label47, label %end_label47
base_block_label47:
	%50 = sub i32 0, 1
	%51 = insertvalue %gala_159728.TcpSocket undef, i32 %50, 0
	store %gala_159728.TcpSocket %51, ptr %slot52
	%53 = load i32, ptr %slot52
	ret i32 %53

end_label47:

	%54 = call { i64, i64 } @gala_159728.make_address({ ptr, i64 } %address, i16 zeroext %port)
	store { i64, i64 } %54, ptr %slot55
	%56 = load %gala_159728.SockAddrIn, ptr %slot55
	store %gala_159728.SockAddrIn %56, ptr %addr.291

	%57 = load i32, ptr %fd.290
	%58 = bitcast ptr %addr.291 to ptr
	%59 = call i32 @connect(i32 %57, ptr %58, i32 16)
	store i32 %59, ptr %result.292

	%61 = load i32, ptr %result.292
	%62 = icmp slt i32 %61, 0
	br i1 %62, label %base_block_label60, label %end_label60
base_block_label60:
	%63 = load i32, ptr %fd.290
	%64 = call i32 @close(i32 %63)

	%65 = sub i32 0, 1
	%66 = insertvalue %gala_159728.TcpSocket undef, i32 %65, 0
	store %gala_159728.TcpSocket %66, ptr %slot67
	%68 = load i32, ptr %slot67
	ret i32 %68

end_label60:

	%69 = load i32, ptr %fd.290
	%70 = insertvalue %gala_159728.TcpSocket undef, i32 %69, 0
	store %gala_159728.TcpSocket %70, ptr %slot71
	%72 = load i32, ptr %slot71
	ret i32 %72

}
define i32 @gala_159728.tcp_listen (i16 %port, i32 %backlog) {
entry:
	%fd.295 = alloca i32
	%slot82 = alloca %gala_159728.TcpSocket
	%reuse.296 = alloca i32
	%result.297 = alloca i32
	%slot96 = alloca %gala_159728.TcpSocket
	%addr.298 = alloca %gala_159728.SockAddrIn
	%slot115 = alloca %gala_159728.TcpSocket
	%slot126 = alloca %gala_159728.TcpSocket
	%slot130 = alloca %gala_159728.TcpSocket
	%73 = load i32, ptr @gala_159728.AF_INET
	%74 = load i32, ptr @gala_159728.SOCK_STREAM
	%75 = load i32, ptr @gala_159728.IPPROTO_TCP
	%76 = call i32 @socket(i32 %73, i32 %74, i32 %75)
	store i32 %76, ptr %fd.295

	%78 = load i32, ptr %fd.295
	%79 = icmp slt i32 %78, 0
	br i1 %79, label %base_block_label77, label %end_label77
base_block_label77:
	%80 = sub i32 0, 1
	%81 = insertvalue %gala_159728.TcpSocket undef, i32 %80, 0
	store %gala_159728.TcpSocket %81, ptr %slot82
	%83 = load i32, ptr %slot82
	ret i32 %83

end_label77:

	store i32 1, ptr %reuse.296

	%84 = load i32, ptr %fd.295
	%85 = load i32, ptr @gala_159728.SOL_SOCKET
	%86 = load i32, ptr @gala_159728.SO_REUSEADDR
	%87 = bitcast ptr %reuse.296 to ptr
	%88 = call i32 @setsockopt(i32 %84, i32 %85, i32 %86, ptr %87, i32 4)
	store i32 %88, ptr %result.297

	%90 = load i32, ptr %result.297
	%91 = icmp slt i32 %90, 0
	br i1 %91, label %base_block_label89, label %end_label89
base_block_label89:
	%92 = load i32, ptr %fd.295
	%93 = call i32 @close(i32 %92)

	%94 = sub i32 0, 1
	%95 = insertvalue %gala_159728.TcpSocket undef, i32 %94, 0
	store %gala_159728.TcpSocket %95, ptr %slot96
	%97 = load i32, ptr %slot96
	ret i32 %97

end_label89:

	%98 = load i32, ptr @gala_159728.AF_INET
	%99 = trunc i32 %98 to i16
	%100 = call zeroext i16 @htons(i16 zeroext %port)
	%101 = insertvalue %gala_159728.SockAddrIn undef, i16 %99, 0
	%102 = insertvalue %gala_159728.SockAddrIn %101, i16 %100, 1
	%103 = insertvalue %gala_159728.SockAddrIn %102, i32 0, 2
	%104 = insertvalue %gala_159728.SockAddrIn %103, [8 x i8] zeroinitializer, 3
	store %gala_159728.SockAddrIn %104, ptr %addr.298

	%105 = load i32, ptr %fd.295
	%106 = bitcast ptr %addr.298 to ptr
	%107 = call i32 @bind(i32 %105, ptr %106, i32 16)
	store i32 %107, ptr %result.297

	%109 = load i32, ptr %result.297
	%110 = icmp slt i32 %109, 0
	br i1 %110, label %base_block_label108, label %end_label108
base_block_label108:
	%111 = load i32, ptr %fd.295
	%112 = call i32 @close(i32 %111)

	%113 = sub i32 0, 1
	%114 = insertvalue %gala_159728.TcpSocket undef, i32 %113, 0
	store %gala_159728.TcpSocket %114, ptr %slot115
	%116 = load i32, ptr %slot115
	ret i32 %116

end_label108:

	%117 = load i32, ptr %fd.295
	%118 = call i32 @listen(i32 %117, i32 %backlog)
	store i32 %118, ptr %result.297

	%120 = load i32, ptr %result.297
	%121 = icmp slt i32 %120, 0
	br i1 %121, label %base_block_label119, label %end_label119
base_block_label119:
	%122 = load i32, ptr %fd.295
	%123 = call i32 @close(i32 %122)

	%124 = sub i32 0, 1
	%125 = insertvalue %gala_159728.TcpSocket undef, i32 %124, 0
	store %gala_159728.TcpSocket %125, ptr %slot126
	%127 = load i32, ptr %slot126
	ret i32 %127

end_label119:

	%128 = load i32, ptr %fd.295
	%129 = insertvalue %gala_159728.TcpSocket undef, i32 %128, 0
	store %gala_159728.TcpSocket %129, ptr %slot130
	%131 = load i32, ptr %slot130
	ret i32 %131

}
define i32 @gala_159728.tcp_accept (i32 %server.abi) {
entry:
	%132 = alloca %gala_159728.TcpSocket
	store i32 %server.abi, ptr %132
	%133 = load %gala_159728.TcpSocket, ptr %132
	%fd.300 = alloca i32
	%slot140 = alloca %gala_159728.TcpSocket
	%134 = extractvalue %gala_159728.TcpSocket %133, 0
	%135 = inttoptr i64 0 to ptr
	%136 = inttoptr i64 0 to ptr
	%137 = call i32 @accept(i32 %134, ptr %135, ptr %136)
	store i32 %137, ptr %fd.300

	%138 = load i32, ptr %fd.300
	%139 = insertvalue %gala_159728.TcpSocket undef, i32 %138, 0
	store %gala_159728.TcpSocket %139, ptr %slot140
	%141 = load i32, ptr %slot140
	ret i32 %141

}
define i64 @gala_159728.tcp_send (i32 %_socket.abi, { ptr, i64 } %data) {
entry:
	%142 = alloca %gala_159728.TcpSocket
	store i32 %_socket.abi, ptr %142
	%143 = load %gala_159728.TcpSocket, ptr %142
	%144 = extractvalue %gala_159728.TcpSocket %143, 0
	%145 = extractvalue { ptr, i64 } %data, 0
	%146 = getelementptr inbounds i8, ptr %145, i64 0
	%147 = extractvalue { ptr, i64 } %data, 1
	%148 = call i64 @send(i32 %144, ptr %146, i64 %147, i32 0)
	ret i64 %148

}
define i64 @gala_159728.tcp_recv (i32 %_socket.abi, { ptr, i64 } %buffer) {
entry:
	%149 = alloca %gala_159728.TcpSocket
	store i32 %_socket.abi, ptr %149
	%150 = load %gala_159728.TcpSocket, ptr %149
	%151 = extractvalue %gala_159728.TcpSocket %150, 0
	%152 = extractvalue { ptr, i64 } %buffer, 0
	%153 = getelementptr inbounds i8, ptr %152, i64 0
	%154 = extractvalue { ptr, i64 } %buffer, 1
	%155 = call i64 @recv(i32 %151, ptr %153, i64 %154, i32 0)
	ret i64 %155

}
define void @gala_159728.tcp_close (i32 %_socket.abi) {
entry:
	%156 = alloca %gala_159728.TcpSocket
	store i32 %_socket.abi, ptr %156
	%157 = load %gala_159728.TcpSocket, ptr %156
	%159 = extractvalue %gala_159728.TcpSocket %157, 0
	%160 = icmp sge i32 %159, 0
	br i1 %160, label %base_block_label158, label %end_label158
base_block_label158:
	%161 = extractvalue %gala_159728.TcpSocket %157, 0
	%162 = call i32 @close(i32 %161)

	br label %end_label158
end_label158:

	ret void
}
define i32 @gala_159728.tcp_shutdown (i32 %_socket.abi, i32 %how) {
entry:
	%163 = alloca %gala_159728.TcpSocket
	store i32 %_socket.abi, ptr %163
	%164 = load %gala_159728.TcpSocket, ptr %163
	%165 = extractvalue %gala_159728.TcpSocket %164, 0
	%166 = call i32 @shutdown(i32 %165, i32 %how)
	ret i32 %166

}
define void @gala_159728.__init_globals() {
entry:
	store i32 2, ptr @gala_159728.AF_INET
	store i32 1, ptr @gala_159728.SOCK_STREAM
	store i32 6, ptr @gala_159728.IPPROTO_TCP
	store i32 1, ptr @gala_159728.SOL_SOCKET
	store i32 2, ptr @gala_159728.SO_REUSEADDR
	store i32 0, ptr @gala_159728.SHUT_RD
	store i32 1, ptr @gala_159728.SHUT_WR
	store i32 2, ptr @gala_159728.SHUT_RDWR
	ret void
}

