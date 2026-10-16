; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu" 
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
; decs from mod core/core.gala 1
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
declare ptr @gala_120231.cstr ({ ptr, i64 })
declare void @gala_120231.println ({ ptr, i64 })
declare i1 @gala_120231.str_cmp ({ ptr, i64 }, { ptr, i64 })
; end
; decs from mod core/net.gala 2
; decs from mod ./cfunctions.gala 0
; exst already
%gala_179762.SockAddrIn = type {i16,i16,i32,[8 x i8]}
%gala_179762.TcpSocket = type {i32}
declare { i64, i64 } @gala_179762.make_address ({ ptr, i64 }, i16)
declare i32 @gala_179762.tcp_connect ({ ptr, i64 }, i16)
declare i32 @gala_179762.tcp_listen (i16, i32)
declare i32 @gala_179762.tcp_accept (i32)
declare i64 @gala_179762.tcp_send (i32, { ptr, i64 })
declare i64 @gala_179762.tcp_recv (i32, { ptr, i64 })
declare void @gala_179762.tcp_close (i32)
declare i32 @gala_179762.tcp_shutdown (i32, i32)
declare void @gala_179762.__init_globals()
; end
; decs from mod core/mem.gala 3
; decs from mod ./core.gala 1
; exst already
; decs from mod ./cfunctions.gala 0
; exst already
declare i64 @gala_785070.addr (ptr)
declare ptr @gala_785070.from_addr (i64)
declare i64 @gala_785070.align_forward (i64, i64)
declare i64 @gala_785070.min_u64 (i64, i64)
declare void @gala_785070.mem_copy (ptr, ptr, i64)
declare void @gala_785070.mem_zero (ptr, i64)
declare void @gala_785070.mem_set (ptr, i32, i64)
declare i1 @gala_785070.mem_equal (ptr, ptr, i64)
%gala_785070.RawSlice = type {ptr,i64}
declare { ptr, i64 } @gala_785070.bytes_from (ptr, i64)
%gala_785070.Allocator = type {ptr,ptr}
declare void @gala_785070.set_allocator ({ i64, i64 })
declare i64 @gala_785070.__default_0 ()
declare { i64, i64 } @gala_785070.__default_1 ()
declare ptr @gala_785070.alloc (i64, i64, { i64, i64 })
declare i64 @gala_785070.__default_2 ()
declare { i64, i64 } @gala_785070.__default_3 ()
declare void @gala_785070.dealloc (ptr, i64, { i64, i64 })
declare { i64, i64 } @gala_785070.__default_4 ()
declare void @gala_785070.dealloc_all ({ i64, i64 })
declare i64 @gala_785070.__default_5 ()
declare { i64, i64 } @gala_785070.__default_6 ()
declare ptr @gala_785070.resize (ptr, i64, i64, i64, { i64, i64 })
declare { i64, i64 } @gala_785070.__default_7 ()
declare { ptr, i64 } @gala_785070.alloc_bytes (i64, { i64, i64 })
declare { i64, i64 } @gala_785070.__default_8 ()
declare { ptr, i64 } @gala_785070.clone_string ({ ptr, i64 }, { i64, i64 })
declare ptr @gala_785070.heap_proc (ptr, i32, i64, i64, ptr, i64)
declare { i64, i64 } @gala_785070.heap_allocator ()
%gala_785070.Arena = type {ptr,i64,i64,i64,i1}
declare void @gala_785070.arena_init (ptr, ptr, i64)
declare void @gala_785070.arena_make (ptr sret(%gala_785070.Arena) align 8, i64)
declare void @gala_785070.arena_destroy (ptr)
declare void @gala_785070.arena_reset (ptr)
declare i64 @gala_785070.arena_mark (ptr)
declare void @gala_785070.arena_restore (ptr, i64)
declare ptr @gala_785070.arena_proc (ptr, i32, i64, i64, ptr, i64)
declare { i64, i64 } @gala_785070.arena_allocator (ptr)
%gala_785070.Pool = type {ptr,i64,i64,ptr}
declare void @gala_785070.pool_make (ptr sret(%gala_785070.Pool) align 8, i64, i64)
declare void @gala_785070.pool_destroy (ptr)
declare ptr @gala_785070.pool_proc (ptr, i32, i64, i64, ptr, i64)
declare { i64, i64 } @gala_785070.pool_allocator (ptr)
%gala_785070.Tracking = type {%gala_785070.Allocator,i64,i64,i64,i64,i64}
declare void @gala_785070.tracking_init (ptr, { i64, i64 })
declare ptr @gala_785070.tracking_proc (ptr, i32, i64, i64, ptr, i64)
declare { i64, i64 } @gala_785070.tracking_allocator (ptr)
declare void @gala_785070.tracking_report (ptr)
declare void @gala_785070.__init_globals()
; end
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

define void @gala_507430.printlen ({ ptr, i64 } %data) {
entry:
	%slot32 = alloca [2 x { ptr, i64 }]
	%slot36 = alloca { ptr, i64 }
	%slot41 = alloca i64
	%33 = getelementptr inbounds [10 x i8], ptr @string4, i64 0, i64 0
	%34 = insertvalue { ptr, i64 } undef, ptr %33, 0
	%35 = insertvalue { ptr, i64 } %34, i64 9, 1
	store { ptr, i64 } %35, ptr %slot36
	%37 = insertvalue { ptr, i64 } undef, ptr %slot36, 0
	%38 = insertvalue { ptr, i64 } %37, i64 17, 1
	%39 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot32, i64 0, i64 0
	store { ptr, i64 } %38, ptr %39
	%40 = extractvalue { ptr, i64 } %data, 1
	store i64 %40, ptr %slot41
	%42 = insertvalue { ptr, i64 } undef, ptr %slot41, 0
	%43 = insertvalue { ptr, i64 } %42, i64 3, 1
	%44 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot32, i64 0, i64 1
	store { ptr, i64 } %43, ptr %44
	%45 = insertvalue { ptr, i64 } undef, ptr %slot32, 0
	%46 = insertvalue { ptr, i64 } %45, i64 2, 1
	call void @gala_120231.println({ ptr, i64 } %46)

	ret void
}
define void @gala_507430.main () {
entry:
	%slot48 = alloca %gala_179762.TcpSocket
	%server.474 = alloca %gala_179762.TcpSocket
	%slot54 = alloca [1 x { ptr, i64 }]
	%slot58 = alloca { ptr, i64 }
	%slot64 = alloca [1 x { ptr, i64 }]
	%slot68 = alloca { ptr, i64 }
	%slot76 = alloca %gala_179762.TcpSocket
	%slot79 = alloca %gala_179762.TcpSocket
	%client.475 = alloca %gala_179762.TcpSocket
	%slot85 = alloca [1 x { ptr, i64 }]
	%slot89 = alloca { ptr, i64 }
	%slot95 = alloca [1 x { ptr, i64 }]
	%slot99 = alloca { ptr, i64 }
	%buffer.476 = alloca [1024 x i8]
	%slot107 = alloca %gala_179762.TcpSocket
	%n.477 = alloca i64
	%slot117 = alloca [2 x { ptr, i64 }]
	%slot121 = alloca { ptr, i64 }
	%slot130 = alloca { ptr, i64 }
	%slot132 = alloca { ptr, i64 }
	%slot139 = alloca %gala_179762.TcpSocket
	%__for_iter1.479 = alloca { ptr, i64 }
	%__for_idx1.480 = alloca i64
	%c.478 = alloca i8
	%slot164 = alloca [2 x { ptr, i64 }]
	%slot168 = alloca { ptr, i64 }
	%slot174 = alloca i64
	%slot180 = alloca [1 x { ptr, i64 }]
	%slot184 = alloca { ptr, i64 }
	%slot191 = alloca %gala_179762.TcpSocket
	%slot194 = alloca %gala_179762.TcpSocket
	%47 = call i32 @gala_179762.tcp_listen(i16 zeroext 9000, i32 16)
	store i32 %47, ptr %slot48
	%49 = load %gala_179762.TcpSocket, ptr %slot48
	store %gala_179762.TcpSocket %49, ptr %server.474

	%51 = getelementptr inbounds %gala_179762.TcpSocket, ptr %server.474, i32 0, i32 0
	%52 = load i32, ptr %51
	%53 = icmp slt i32 %52, 0
	br i1 %53, label %base_block_label50, label %end_label50
base_block_label50:
	%55 = getelementptr inbounds [23 x i8], ptr @string5, i64 0, i64 0
	%56 = insertvalue { ptr, i64 } undef, ptr %55, 0
	%57 = insertvalue { ptr, i64 } %56, i64 22, 1
	store { ptr, i64 } %57, ptr %slot58
	%59 = insertvalue { ptr, i64 } undef, ptr %slot58, 0
	%60 = insertvalue { ptr, i64 } %59, i64 17, 1
	%61 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot54, i64 0, i64 0
	store { ptr, i64 } %60, ptr %61
	%62 = insertvalue { ptr, i64 } undef, ptr %slot54, 0
	%63 = insertvalue { ptr, i64 } %62, i64 1, 1
	call void @gala_120231.println({ ptr, i64 } %63)

	ret void

end_label50:

	%65 = getelementptr inbounds [35 x i8], ptr @string6, i64 0, i64 0
	%66 = insertvalue { ptr, i64 } undef, ptr %65, 0
	%67 = insertvalue { ptr, i64 } %66, i64 34, 1
	store { ptr, i64 } %67, ptr %slot68
	%69 = insertvalue { ptr, i64 } undef, ptr %slot68, 0
	%70 = insertvalue { ptr, i64 } %69, i64 17, 1
	%71 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot64, i64 0, i64 0
	store { ptr, i64 } %70, ptr %71
	%72 = insertvalue { ptr, i64 } undef, ptr %slot64, 0
	%73 = insertvalue { ptr, i64 } %72, i64 1, 1
	call void @gala_120231.println({ ptr, i64 } %73)

	br label %while_cond_label74
while_cond_label74:
	br i1 1, label %while_body_label74, label %while_end_label74
while_body_label74:
	%75 = load %gala_179762.TcpSocket, ptr %server.474
	store %gala_179762.TcpSocket %75, ptr %slot76
	%77 = load i32, ptr %slot76
	%78 = call i32 @gala_179762.tcp_accept(i32 %77)
	store i32 %78, ptr %slot79
	%80 = load %gala_179762.TcpSocket, ptr %slot79
	store %gala_179762.TcpSocket %80, ptr %client.475

	%82 = getelementptr inbounds %gala_179762.TcpSocket, ptr %client.475, i32 0, i32 0
	%83 = load i32, ptr %82
	%84 = icmp slt i32 %83, 0
	br i1 %84, label %base_block_label81, label %end_label81
base_block_label81:
	%86 = getelementptr inbounds [14 x i8], ptr @string7, i64 0, i64 0
	%87 = insertvalue { ptr, i64 } undef, ptr %86, 0
	%88 = insertvalue { ptr, i64 } %87, i64 13, 1
	store { ptr, i64 } %88, ptr %slot89
	%90 = insertvalue { ptr, i64 } undef, ptr %slot89, 0
	%91 = insertvalue { ptr, i64 } %90, i64 17, 1
	%92 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot85, i64 0, i64 0
	store { ptr, i64 } %91, ptr %92
	%93 = insertvalue { ptr, i64 } undef, ptr %slot85, 0
	%94 = insertvalue { ptr, i64 } %93, i64 1, 1
	call void @gala_120231.println({ ptr, i64 } %94)

	br label %while_cond_label74

end_label81:

	%96 = getelementptr inbounds [17 x i8], ptr @string8, i64 0, i64 0
	%97 = insertvalue { ptr, i64 } undef, ptr %96, 0
	%98 = insertvalue { ptr, i64 } %97, i64 16, 1
	store { ptr, i64 } %98, ptr %slot99
	%100 = insertvalue { ptr, i64 } undef, ptr %slot99, 0
	%101 = insertvalue { ptr, i64 } %100, i64 17, 1
	%102 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot95, i64 0, i64 0
	store { ptr, i64 } %101, ptr %102
	%103 = insertvalue { ptr, i64 } undef, ptr %slot95, 0
	%104 = insertvalue { ptr, i64 } %103, i64 1, 1
	call void @gala_120231.println({ ptr, i64 } %104)

	call void @llvm.memset.p0.i64(ptr %buffer.476, i8 0, i64 1024, i1 false)

	br label %while_cond_label105
while_cond_label105:
	br i1 1, label %while_body_label105, label %while_end_label105
while_body_label105:
	%106 = load %gala_179762.TcpSocket, ptr %client.475
	store %gala_179762.TcpSocket %106, ptr %slot107
	%108 = load i32, ptr %slot107
	%109 = sub nsw nuw i64 1024, 0
	%110 = getelementptr inbounds i8, ptr %buffer.476, i64 0
	%111 = insertvalue { ptr, i64 } undef, ptr %110, 0
	%112 = insertvalue { ptr, i64 } %111, i64 %109, 1
	%113 = call i64 @gala_179762.tcp_recv(i32 %108, { ptr, i64 } %112)
	store i64 %113, ptr %n.477

	%115 = load i64, ptr %n.477
	%116 = icmp sle i64 %115, 0
	br i1 %116, label %base_block_label114, label %end_label114
base_block_label114:
	br label %while_end_label105

end_label114:

	%118 = getelementptr inbounds [5 x i8], ptr @string9, i64 0, i64 0
	%119 = insertvalue { ptr, i64 } undef, ptr %118, 0
	%120 = insertvalue { ptr, i64 } %119, i64 4, 1
	store { ptr, i64 } %120, ptr %slot121
	%122 = insertvalue { ptr, i64 } undef, ptr %slot121, 0
	%123 = insertvalue { ptr, i64 } %122, i64 17, 1
	%124 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot117, i64 0, i64 0
	store { ptr, i64 } %123, ptr %124
	%125 = load i64, ptr %n.477
	%126 = sub nsw nuw i64 %125, 0
	%127 = getelementptr inbounds i8, ptr %buffer.476, i64 0
	%128 = insertvalue { ptr, i64 } undef, ptr %127, 0
	%129 = insertvalue { ptr, i64 } %128, i64 %126, 1
	store { ptr, i64 } %129, ptr %slot130
	%131 = load { ptr, i64 }, ptr %slot130
	store { ptr, i64 } %131, ptr %slot132
	%133 = insertvalue { ptr, i64 } undef, ptr %slot132, 0
	%134 = insertvalue { ptr, i64 } %133, i64 17, 1
	%135 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot117, i64 0, i64 1
	store { ptr, i64 } %134, ptr %135
	%136 = insertvalue { ptr, i64 } undef, ptr %slot117, 0
	%137 = insertvalue { ptr, i64 } %136, i64 2, 1
	call void @gala_120231.println({ ptr, i64 } %137)

	%138 = load %gala_179762.TcpSocket, ptr %client.475
	store %gala_179762.TcpSocket %138, ptr %slot139
	%140 = load i32, ptr %slot139
	%141 = load i64, ptr %n.477
	%142 = sub nsw nuw i64 %141, 0
	%143 = getelementptr inbounds i8, ptr %buffer.476, i64 0
	%144 = insertvalue { ptr, i64 } undef, ptr %143, 0
	%145 = insertvalue { ptr, i64 } %144, i64 %142, 1
	%146 = call i64 @gala_179762.tcp_send(i32 %140, { ptr, i64 } %145)

	%147 = load i64, ptr %n.477
	%148 = sub nsw nuw i64 %147, 0
	%149 = getelementptr inbounds i8, ptr %buffer.476, i64 0
	%150 = insertvalue { ptr, i64 } undef, ptr %149, 0
	%151 = insertvalue { ptr, i64 } %150, i64 %148, 1
	store { ptr, i64 } %151, ptr %__for_iter1.479

	store i64 0, ptr %__for_idx1.480

	br label %while_cond_label152
while_cond_label152:
	%153 = load i64, ptr %__for_idx1.480
	%154 = load { ptr, i64 }, ptr %__for_iter1.479
	%155 = extractvalue { ptr, i64 } %154, 1
	%156 = icmp slt i64 %153, %155
	br i1 %156, label %while_body_label152, label %while_end_label152
while_body_label152:
	%157 = load { ptr, i64 }, ptr %__for_iter1.479
	%158 = extractvalue { ptr, i64 } %157, 0
	%159 = load i64, ptr %__for_idx1.480
	%160 = getelementptr inbounds i8, ptr %158, i64 %159
	%161 = load i8, ptr %160
	store i8 %161, ptr %c.478

	%162 = load i64, ptr %__for_idx1.480
	%163 = add i64 %162, 1
	store i64 %163, ptr %__for_idx1.480

	%165 = getelementptr inbounds [6 x i8], ptr @string10, i64 0, i64 0
	%166 = insertvalue { ptr, i64 } undef, ptr %165, 0
	%167 = insertvalue { ptr, i64 } %166, i64 5, 1
	store { ptr, i64 } %167, ptr %slot168
	%169 = insertvalue { ptr, i64 } undef, ptr %slot168, 0
	%170 = insertvalue { ptr, i64 } %169, i64 17, 1
	%171 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot164, i64 0, i64 0
	store { ptr, i64 } %170, ptr %171
	%172 = load i8, ptr %c.478
	%173 = zext i8 %172 to i64
	store i64 %173, ptr %slot174
	%175 = insertvalue { ptr, i64 } undef, ptr %slot174, 0
	%176 = insertvalue { ptr, i64 } %175, i64 3, 1
	%177 = getelementptr inbounds [2 x { ptr, i64 }], ptr %slot164, i64 0, i64 1
	store { ptr, i64 } %176, ptr %177
	%178 = insertvalue { ptr, i64 } undef, ptr %slot164, 0
	%179 = insertvalue { ptr, i64 } %178, i64 2, 1
	call void @gala_120231.println({ ptr, i64 } %179)

	br label %while_cond_label152
while_end_label152:

	br label %while_cond_label105
while_end_label105:

	%181 = getelementptr inbounds [20 x i8], ptr @string11, i64 0, i64 0
	%182 = insertvalue { ptr, i64 } undef, ptr %181, 0
	%183 = insertvalue { ptr, i64 } %182, i64 19, 1
	store { ptr, i64 } %183, ptr %slot184
	%185 = insertvalue { ptr, i64 } undef, ptr %slot184, 0
	%186 = insertvalue { ptr, i64 } %185, i64 17, 1
	%187 = getelementptr inbounds [1 x { ptr, i64 }], ptr %slot180, i64 0, i64 0
	store { ptr, i64 } %186, ptr %187
	%188 = insertvalue { ptr, i64 } undef, ptr %slot180, 0
	%189 = insertvalue { ptr, i64 } %188, i64 1, 1
	call void @gala_120231.println({ ptr, i64 } %189)

	%190 = load %gala_179762.TcpSocket, ptr %client.475
	store %gala_179762.TcpSocket %190, ptr %slot191
	%192 = load i32, ptr %slot191
	call void @gala_179762.tcp_close(i32 %192)

	br label %while_cond_label74
while_end_label74:

	%193 = load %gala_179762.TcpSocket, ptr %server.474
	store %gala_179762.TcpSocket %193, ptr %slot194
	%195 = load i32, ptr %slot194
	call void @gala_179762.tcp_close(i32 %195)

	ret void
}
define i32 @main(i32 %argc, ptr %argv) {
	call void @gala_179762.__init_globals()
	call void @gala_785070.__init_globals()
	call void @gala_507430.main()
	ret i32 0
}
