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
%gala_179762.SockAddrIn = type {i16,i16,i32,[8 x i8]}
%gala_179762.TcpSocket = type {i32}
@gala_179762.AF_INET = global i32 zeroinitializer
@gala_179762.SOCK_STREAM = global i32 zeroinitializer
@gala_179762.IPPROTO_TCP = global i32 zeroinitializer
@gala_179762.SOL_SOCKET = global i32 zeroinitializer
@gala_179762.SO_REUSEADDR = global i32 zeroinitializer
@gala_179762.SHUT_RD = global i32 zeroinitializer
@gala_179762.SHUT_WR = global i32 zeroinitializer
@gala_179762.SHUT_RDWR = global i32 zeroinitializer
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

define { i64, i64 } @gala_179762.make_address ({ ptr, i64 } %address, i16 %port) {
entry:
	%a.287 = alloca %gala_179762.SockAddrIn
	%slot40 = alloca %gala_179762.SockAddrIn
	%26 = insertvalue %gala_179762.SockAddrIn undef, i16 0, 0
	%27 = insertvalue %gala_179762.SockAddrIn %26, i16 0, 1
	%28 = insertvalue %gala_179762.SockAddrIn %27, i32 0, 2
	%29 = insertvalue %gala_179762.SockAddrIn %28, [8 x i8] zeroinitializer, 3
	store %gala_179762.SockAddrIn %29, ptr %a.287

	%30 = load i32, ptr @gala_179762.AF_INET
	%31 = trunc i32 %30 to i16
	%32 = getelementptr inbounds %gala_179762.SockAddrIn, ptr %a.287, i32 0, i32 0
	store i16 %31, ptr %32

	%33 = call zeroext i16 @htons(i16 zeroext %port)
	%34 = getelementptr inbounds %gala_179762.SockAddrIn, ptr %a.287, i32 0, i32 1
	store i16 %33, ptr %34

	%35 = extractvalue { ptr, i64 } %address, 0
	%36 = getelementptr inbounds i8, ptr %35, i64 0
	%37 = call i32 @inet_addr(ptr %36)
	%38 = getelementptr inbounds %gala_179762.SockAddrIn, ptr %a.287, i32 0, i32 2
	store i32 %37, ptr %38

	%39 = load %gala_179762.SockAddrIn, ptr %a.287
	store %gala_179762.SockAddrIn %39, ptr %slot40
	%41 = load { i64, i64 }, ptr %slot40
	ret { i64, i64 } %41

}
define i32 @gala_179762.tcp_connect ({ ptr, i64 } %address, i16 %port) {
entry:
	%fd.290 = alloca i32
	%slot51 = alloca %gala_179762.TcpSocket
	%slot54 = alloca %gala_179762.SockAddrIn
	%addr.291 = alloca %gala_179762.SockAddrIn
	%result.292 = alloca i32
	%slot66 = alloca %gala_179762.TcpSocket
	%slot70 = alloca %gala_179762.TcpSocket
	%42 = load i32, ptr @gala_179762.AF_INET
	%43 = load i32, ptr @gala_179762.SOCK_STREAM
	%44 = load i32, ptr @gala_179762.IPPROTO_TCP
	%45 = call i32 @socket(i32 %42, i32 %43, i32 %44)
	store i32 %45, ptr %fd.290

	%47 = load i32, ptr %fd.290
	%48 = icmp slt i32 %47, 0
	br i1 %48, label %base_block_label46, label %end_label46
base_block_label46:
	%49 = sub i32 0, 1
	%50 = insertvalue %gala_179762.TcpSocket undef, i32 %49, 0
	store %gala_179762.TcpSocket %50, ptr %slot51
	%52 = load i32, ptr %slot51
	ret i32 %52

end_label46:

	%53 = call { i64, i64 } @gala_179762.make_address({ ptr, i64 } %address, i16 zeroext %port)
	store { i64, i64 } %53, ptr %slot54
	%55 = load %gala_179762.SockAddrIn, ptr %slot54
	store %gala_179762.SockAddrIn %55, ptr %addr.291

	%56 = load i32, ptr %fd.290
	%57 = bitcast ptr %addr.291 to ptr
	%58 = call i32 @connect(i32 %56, ptr %57, i32 16)
	store i32 %58, ptr %result.292

	%60 = load i32, ptr %result.292
	%61 = icmp slt i32 %60, 0
	br i1 %61, label %base_block_label59, label %end_label59
base_block_label59:
	%62 = load i32, ptr %fd.290
	%63 = call i32 @close(i32 %62)

	%64 = sub i32 0, 1
	%65 = insertvalue %gala_179762.TcpSocket undef, i32 %64, 0
	store %gala_179762.TcpSocket %65, ptr %slot66
	%67 = load i32, ptr %slot66
	ret i32 %67

end_label59:

	%68 = load i32, ptr %fd.290
	%69 = insertvalue %gala_179762.TcpSocket undef, i32 %68, 0
	store %gala_179762.TcpSocket %69, ptr %slot70
	%71 = load i32, ptr %slot70
	ret i32 %71

}
define i32 @gala_179762.tcp_listen (i16 %port, i32 %backlog) {
entry:
	%fd.295 = alloca i32
	%slot81 = alloca %gala_179762.TcpSocket
	%reuse.296 = alloca i32
	%result.297 = alloca i32
	%slot95 = alloca %gala_179762.TcpSocket
	%addr.298 = alloca %gala_179762.SockAddrIn
	%slot114 = alloca %gala_179762.TcpSocket
	%slot125 = alloca %gala_179762.TcpSocket
	%slot129 = alloca %gala_179762.TcpSocket
	%72 = load i32, ptr @gala_179762.AF_INET
	%73 = load i32, ptr @gala_179762.SOCK_STREAM
	%74 = load i32, ptr @gala_179762.IPPROTO_TCP
	%75 = call i32 @socket(i32 %72, i32 %73, i32 %74)
	store i32 %75, ptr %fd.295

	%77 = load i32, ptr %fd.295
	%78 = icmp slt i32 %77, 0
	br i1 %78, label %base_block_label76, label %end_label76
base_block_label76:
	%79 = sub i32 0, 1
	%80 = insertvalue %gala_179762.TcpSocket undef, i32 %79, 0
	store %gala_179762.TcpSocket %80, ptr %slot81
	%82 = load i32, ptr %slot81
	ret i32 %82

end_label76:

	store i32 1, ptr %reuse.296

	%83 = load i32, ptr %fd.295
	%84 = load i32, ptr @gala_179762.SOL_SOCKET
	%85 = load i32, ptr @gala_179762.SO_REUSEADDR
	%86 = bitcast ptr %reuse.296 to ptr
	%87 = call i32 @setsockopt(i32 %83, i32 %84, i32 %85, ptr %86, i32 4)
	store i32 %87, ptr %result.297

	%89 = load i32, ptr %result.297
	%90 = icmp slt i32 %89, 0
	br i1 %90, label %base_block_label88, label %end_label88
base_block_label88:
	%91 = load i32, ptr %fd.295
	%92 = call i32 @close(i32 %91)

	%93 = sub i32 0, 1
	%94 = insertvalue %gala_179762.TcpSocket undef, i32 %93, 0
	store %gala_179762.TcpSocket %94, ptr %slot95
	%96 = load i32, ptr %slot95
	ret i32 %96

end_label88:

	%97 = load i32, ptr @gala_179762.AF_INET
	%98 = trunc i32 %97 to i16
	%99 = call zeroext i16 @htons(i16 zeroext %port)
	%100 = insertvalue %gala_179762.SockAddrIn undef, i16 %98, 0
	%101 = insertvalue %gala_179762.SockAddrIn %100, i16 %99, 1
	%102 = insertvalue %gala_179762.SockAddrIn %101, i32 0, 2
	%103 = insertvalue %gala_179762.SockAddrIn %102, [8 x i8] zeroinitializer, 3
	store %gala_179762.SockAddrIn %103, ptr %addr.298

	%104 = load i32, ptr %fd.295
	%105 = bitcast ptr %addr.298 to ptr
	%106 = call i32 @bind(i32 %104, ptr %105, i32 16)
	store i32 %106, ptr %result.297

	%108 = load i32, ptr %result.297
	%109 = icmp slt i32 %108, 0
	br i1 %109, label %base_block_label107, label %end_label107
base_block_label107:
	%110 = load i32, ptr %fd.295
	%111 = call i32 @close(i32 %110)

	%112 = sub i32 0, 1
	%113 = insertvalue %gala_179762.TcpSocket undef, i32 %112, 0
	store %gala_179762.TcpSocket %113, ptr %slot114
	%115 = load i32, ptr %slot114
	ret i32 %115

end_label107:

	%116 = load i32, ptr %fd.295
	%117 = call i32 @listen(i32 %116, i32 %backlog)
	store i32 %117, ptr %result.297

	%119 = load i32, ptr %result.297
	%120 = icmp slt i32 %119, 0
	br i1 %120, label %base_block_label118, label %end_label118
base_block_label118:
	%121 = load i32, ptr %fd.295
	%122 = call i32 @close(i32 %121)

	%123 = sub i32 0, 1
	%124 = insertvalue %gala_179762.TcpSocket undef, i32 %123, 0
	store %gala_179762.TcpSocket %124, ptr %slot125
	%126 = load i32, ptr %slot125
	ret i32 %126

end_label118:

	%127 = load i32, ptr %fd.295
	%128 = insertvalue %gala_179762.TcpSocket undef, i32 %127, 0
	store %gala_179762.TcpSocket %128, ptr %slot129
	%130 = load i32, ptr %slot129
	ret i32 %130

}
define i32 @gala_179762.tcp_accept (i32 %server.abi) {
entry:
	%131 = alloca %gala_179762.TcpSocket
	store i32 %server.abi, ptr %131
	%132 = load %gala_179762.TcpSocket, ptr %131
	%fd.300 = alloca i32
	%slot139 = alloca %gala_179762.TcpSocket
	%133 = extractvalue %gala_179762.TcpSocket %132, 0
	%134 = inttoptr i64 0 to ptr
	%135 = inttoptr i64 0 to ptr
	%136 = call i32 @accept(i32 %133, ptr %134, ptr %135)
	store i32 %136, ptr %fd.300

	%137 = load i32, ptr %fd.300
	%138 = insertvalue %gala_179762.TcpSocket undef, i32 %137, 0
	store %gala_179762.TcpSocket %138, ptr %slot139
	%140 = load i32, ptr %slot139
	ret i32 %140

}
define i64 @gala_179762.tcp_send (i32 %_socket.abi, { ptr, i64 } %data) {
entry:
	%141 = alloca %gala_179762.TcpSocket
	store i32 %_socket.abi, ptr %141
	%142 = load %gala_179762.TcpSocket, ptr %141
	%143 = extractvalue %gala_179762.TcpSocket %142, 0
	%144 = extractvalue { ptr, i64 } %data, 0
	%145 = getelementptr inbounds i8, ptr %144, i64 0
	%146 = extractvalue { ptr, i64 } %data, 1
	%147 = call i64 @send(i32 %143, ptr %145, i64 %146, i32 0)
	ret i64 %147

}
define i64 @gala_179762.tcp_recv (i32 %_socket.abi, { ptr, i64 } %buffer) {
entry:
	%148 = alloca %gala_179762.TcpSocket
	store i32 %_socket.abi, ptr %148
	%149 = load %gala_179762.TcpSocket, ptr %148
	%150 = extractvalue %gala_179762.TcpSocket %149, 0
	%151 = extractvalue { ptr, i64 } %buffer, 0
	%152 = getelementptr inbounds i8, ptr %151, i64 0
	%153 = extractvalue { ptr, i64 } %buffer, 1
	%154 = call i64 @recv(i32 %150, ptr %152, i64 %153, i32 0)
	ret i64 %154

}
define void @gala_179762.tcp_close (i32 %_socket.abi) {
entry:
	%155 = alloca %gala_179762.TcpSocket
	store i32 %_socket.abi, ptr %155
	%156 = load %gala_179762.TcpSocket, ptr %155
	%158 = extractvalue %gala_179762.TcpSocket %156, 0
	%159 = icmp sge i32 %158, 0
	br i1 %159, label %base_block_label157, label %end_label157
base_block_label157:
	%160 = extractvalue %gala_179762.TcpSocket %156, 0
	%161 = call i32 @close(i32 %160)

	br label %end_label157
end_label157:

	ret void
}
define i32 @gala_179762.tcp_shutdown (i32 %_socket.abi, i32 %how) {
entry:
	%162 = alloca %gala_179762.TcpSocket
	store i32 %_socket.abi, ptr %162
	%163 = load %gala_179762.TcpSocket, ptr %162
	%164 = extractvalue %gala_179762.TcpSocket %163, 0
	%165 = call i32 @shutdown(i32 %164, i32 %how)
	ret i32 %165

}
define void @gala_179762.__init_globals() {
entry:
	store i32 2, ptr @gala_179762.AF_INET
	store i32 1, ptr @gala_179762.SOCK_STREAM
	store i32 6, ptr @gala_179762.IPPROTO_TCP
	store i32 1, ptr @gala_179762.SOL_SOCKET
	store i32 2, ptr @gala_179762.SO_REUSEADDR
	store i32 0, ptr @gala_179762.SHUT_RD
	store i32 1, ptr @gala_179762.SHUT_WR
	store i32 2, ptr @gala_179762.SHUT_RDWR
	ret void
}

