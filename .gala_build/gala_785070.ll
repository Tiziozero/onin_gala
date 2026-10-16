; target info
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu" 
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
; decs from mod ./core.gala 1
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
; decs from mod ./cfunctions.gala 0
; exst already
%gala_785070.RawSlice = type {ptr,i64}
%gala_785070.Allocator = type {ptr,ptr}
%gala_785070.Arena = type {ptr,i64,i64,i64,i1}
%gala_785070.Pool = type {ptr,i64,i64,ptr}
%gala_785070.Tracking = type {%gala_785070.Allocator,i64,i64,i64,i64,i64}
@gala_785070.NULL = global ptr zeroinitializer
@gala_785070.KB = global i64 zeroinitializer
@gala_785070.MB = global i64 zeroinitializer
@gala_785070.GB = global i64 zeroinitializer
@gala_785070.MODE_ALLOC = global i32 zeroinitializer
@gala_785070.MODE_FREE = global i32 zeroinitializer
@gala_785070.MODE_FREE_ALL = global i32 zeroinitializer
@gala_785070.MODE_RESIZE = global i32 zeroinitializer
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

define i64 @gala_785070.addr (ptr %p) {
entry:
	%32 = ptrtoint ptr %p to i64
	ret i64 %32

}
define ptr @gala_785070.from_addr (i64 %a) {
entry:
	%33 = inttoptr i64 %a to ptr
	ret ptr %33

}
define i64 @gala_785070.align_forward (i64 %a, i64 %align) {
entry:
	%rem.370 = alloca i64
	%35 = icmp ule i64 %align, 1
	br i1 %35, label %base_block_label34, label %end_label34
base_block_label34:
	ret i64 %a

end_label34:

	%36 = urem i64 %a, %align
	store i64 %36, ptr %rem.370

	%38 = load i64, ptr %rem.370
	%39 = icmp eq i64 %38, 0
	br i1 %39, label %base_block_label37, label %end_label37
base_block_label37:
	ret i64 %a

end_label37:

	%40 = add i64 %a, %align
	%41 = load i64, ptr %rem.370
	%42 = sub i64 %40, %41
	ret i64 %42

}
define i64 @gala_785070.min_u64 (i64 %a, i64 %b) {
entry:
	%44 = icmp ult i64 %a, %b
	br i1 %44, label %base_block_label43, label %end_label43
base_block_label43:
	ret i64 %a

end_label43:

	ret i64 %b

}
define void @gala_785070.mem_copy (ptr %dst, ptr %src, i64 %n) {
entry:
	%45 = call ptr @memmove(ptr %dst, ptr %src, i64 %n)

	ret void
}
define void @gala_785070.mem_zero (ptr %p, i64 %n) {
entry:
	%46 = call ptr @memset(ptr %p, i32 0, i64 %n)

	ret void
}
define void @gala_785070.mem_set (ptr %p, i32 %value, i64 %n) {
entry:
	%47 = call ptr @memset(ptr %p, i32 %value, i64 %n)

	ret void
}
define i1 @gala_785070.mem_equal (ptr %a, ptr %b, i64 %n) {
entry:
	%48 = call i32 @memcmp(ptr %a, ptr %b, i64 %n)
	%49 = icmp eq i32 %48, 0
	ret i1 %49

}
define { ptr, i64 } @gala_785070.bytes_from (ptr %p, i64 %n) {
entry:
	%r.386 = alloca %gala_785070.RawSlice
	%slot53 = alloca %gala_785070.RawSlice
	%50 = insertvalue %gala_785070.RawSlice undef, ptr %p, 0
	%51 = insertvalue %gala_785070.RawSlice %50, i64 %n, 1
	store %gala_785070.RawSlice %51, ptr %r.386

	%52 = load %gala_785070.RawSlice, ptr %r.386
	store %gala_785070.RawSlice %52, ptr %slot53
	%54 = load { ptr, i64 }, ptr %slot53
	ret { ptr, i64 } %54

}
define void @gala_785070.set_allocator ({ i64, i64 } %a.abi) {
entry:
	%55 = alloca %gala_785070.Allocator
	store { i64, i64 } %a.abi, ptr %55
	%56 = load %gala_785070.Allocator, ptr %55
	store %gala_785070.Allocator %56, ptr @gala_785070.base_allocator

	ret void
}
define i64 @gala_785070.__default_0 () {
entry:
	ret i64 16

}
define { i64, i64 } @gala_785070.__default_1 () {
entry:
	%slot58 = alloca %gala_785070.Allocator
	%57 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator
	store %gala_785070.Allocator %57, ptr %slot58
	%59 = load { i64, i64 }, ptr %slot58
	ret { i64, i64 } %59

}
define ptr @gala_785070.alloc (i64 %size, i64 %align, { i64, i64 } %a.abi) {
entry:
	%60 = alloca %gala_785070.Allocator
	store { i64, i64 } %a.abi, ptr %60
	%61 = load %gala_785070.Allocator, ptr %60
	%cb.391 = alloca ptr
	%62 = extractvalue %gala_785070.Allocator %61, 0
	store ptr %62, ptr %cb.391

	%63 = load ptr, ptr %cb.391
	%64 = extractvalue %gala_785070.Allocator %61, 1
	%65 = load i32, ptr @gala_785070.MODE_ALLOC
	%66 = load ptr, ptr @gala_785070.NULL
	%67 = call ptr %63(ptr %64, i32 %65, i64 %size, i64 %align, ptr %66, i64 0)
	ret ptr %67

}
define i64 @gala_785070.__default_2 () {
entry:
	ret i64 0

}
define { i64, i64 } @gala_785070.__default_3 () {
entry:
	%slot69 = alloca %gala_785070.Allocator
	%68 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator
	store %gala_785070.Allocator %68, ptr %slot69
	%70 = load { i64, i64 }, ptr %slot69
	ret { i64, i64 } %70

}
define void @gala_785070.dealloc (ptr %p, i64 %size, { i64, i64 } %a.abi) {
entry:
	%71 = alloca %gala_785070.Allocator
	store { i64, i64 } %a.abi, ptr %71
	%72 = load %gala_785070.Allocator, ptr %71
	%cb.395 = alloca ptr
	%73 = extractvalue %gala_785070.Allocator %72, 0
	store ptr %73, ptr %cb.395

	%74 = load ptr, ptr %cb.395
	%75 = extractvalue %gala_785070.Allocator %72, 1
	%76 = load i32, ptr @gala_785070.MODE_FREE
	%77 = call ptr %74(ptr %75, i32 %76, i64 0, i64 0, ptr %p, i64 %size)

	ret void
}
define { i64, i64 } @gala_785070.__default_4 () {
entry:
	%slot79 = alloca %gala_785070.Allocator
	%78 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator
	store %gala_785070.Allocator %78, ptr %slot79
	%80 = load { i64, i64 }, ptr %slot79
	ret { i64, i64 } %80

}
define void @gala_785070.dealloc_all ({ i64, i64 } %a.abi) {
entry:
	%81 = alloca %gala_785070.Allocator
	store { i64, i64 } %a.abi, ptr %81
	%82 = load %gala_785070.Allocator, ptr %81
	%cb.397 = alloca ptr
	%83 = extractvalue %gala_785070.Allocator %82, 0
	store ptr %83, ptr %cb.397

	%84 = load ptr, ptr %cb.397
	%85 = extractvalue %gala_785070.Allocator %82, 1
	%86 = load i32, ptr @gala_785070.MODE_FREE_ALL
	%87 = load ptr, ptr @gala_785070.NULL
	%88 = call ptr %84(ptr %85, i32 %86, i64 0, i64 0, ptr %87, i64 0)

	ret void
}
define i64 @gala_785070.__default_5 () {
entry:
	ret i64 16

}
define { i64, i64 } @gala_785070.__default_6 () {
entry:
	%slot90 = alloca %gala_785070.Allocator
	%89 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator
	store %gala_785070.Allocator %89, ptr %slot90
	%91 = load { i64, i64 }, ptr %slot90
	ret { i64, i64 } %91

}
define ptr @gala_785070.resize (ptr %p, i64 %old_size, i64 %new_size, i64 %align, { i64, i64 } %a.abi) {
entry:
	%92 = alloca %gala_785070.Allocator
	store { i64, i64 } %a.abi, ptr %92
	%93 = load %gala_785070.Allocator, ptr %92
	%cb.403 = alloca ptr
	%94 = extractvalue %gala_785070.Allocator %93, 0
	store ptr %94, ptr %cb.403

	%95 = load ptr, ptr %cb.403
	%96 = extractvalue %gala_785070.Allocator %93, 1
	%97 = load i32, ptr @gala_785070.MODE_RESIZE
	%98 = call ptr %95(ptr %96, i32 %97, i64 %new_size, i64 %align, ptr %p, i64 %old_size)
	ret ptr %98

}
define { i64, i64 } @gala_785070.__default_7 () {
entry:
	%slot100 = alloca %gala_785070.Allocator
	%99 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator
	store %gala_785070.Allocator %99, ptr %slot100
	%101 = load { i64, i64 }, ptr %slot100
	ret { i64, i64 } %101

}
define { ptr, i64 } @gala_785070.alloc_bytes (i64 %n, { i64, i64 } %a.abi) {
entry:
	%102 = alloca %gala_785070.Allocator
	store { i64, i64 } %a.abi, ptr %102
	%103 = load %gala_785070.Allocator, ptr %102
	%slot105 = alloca %gala_785070.Allocator
	%p.406 = alloca ptr
	%104 = call i64 @gala_785070.__default_0()
	store %gala_785070.Allocator %103, ptr %slot105
	%106 = load { i64, i64 }, ptr %slot105
	%107 = call ptr @gala_785070.alloc(i64 %n, i64 %104, { i64, i64 } %106)
	store ptr %107, ptr %p.406

	%109 = load ptr, ptr %p.406
	%110 = ptrtoint ptr %109 to i64
	%111 = load ptr, ptr @gala_785070.NULL
	%112 = ptrtoint ptr %111 to i64
	%113 = icmp eq i64 %110, %112
	br i1 %113, label %base_block_label108, label %end_label108
base_block_label108:
	%114 = load ptr, ptr @gala_785070.NULL
	%115 = call { ptr, i64 } @gala_785070.bytes_from(ptr %114, i64 0)
	ret { ptr, i64 } %115

end_label108:

	%116 = load ptr, ptr %p.406
	%117 = call { ptr, i64 } @gala_785070.bytes_from(ptr %116, i64 %n)
	ret { ptr, i64 } %117

}
define { i64, i64 } @gala_785070.__default_8 () {
entry:
	%slot119 = alloca %gala_785070.Allocator
	%118 = load %gala_785070.Allocator, ptr @gala_785070.base_allocator
	store %gala_785070.Allocator %118, ptr %slot119
	%120 = load { i64, i64 }, ptr %slot119
	ret { i64, i64 } %120

}
define { ptr, i64 } @gala_785070.clone_string ({ ptr, i64 } %s, { i64, i64 } %a.abi) {
entry:
	%121 = alloca %gala_785070.Allocator
	store { i64, i64 } %a.abi, ptr %121
	%122 = load %gala_785070.Allocator, ptr %121
	%n.409 = alloca i64
	%slot128 = alloca %gala_785070.Allocator
	%buf.410 = alloca { ptr, i64 }
	%slot138 = alloca { ptr, i64 }
	%123 = extractvalue { ptr, i64 } %s, 1
	store i64 %123, ptr %n.409

	%125 = load i64, ptr %n.409
	%126 = icmp eq i64 %125, 0
	br i1 %126, label %base_block_label124, label %end_label124
base_block_label124:
	ret { ptr, i64 } %s

end_label124:

	%127 = load i64, ptr %n.409
	store %gala_785070.Allocator %122, ptr %slot128
	%129 = load { i64, i64 }, ptr %slot128
	%130 = call { ptr, i64 } @gala_785070.alloc_bytes(i64 %127, { i64, i64 } %129)
	store { ptr, i64 } %130, ptr %buf.410

	%131 = load { ptr, i64 }, ptr %buf.410
	%132 = extractvalue { ptr, i64 } %131, 0
	%133 = getelementptr inbounds i8, ptr %132, i64 0
	%134 = extractvalue { ptr, i64 } %s, 0
	%135 = getelementptr inbounds i8, ptr %134, i64 0
	%136 = load i64, ptr %n.409
	call void @gala_785070.mem_copy(ptr %133, ptr %135, i64 %136)

	%137 = load { ptr, i64 }, ptr %buf.410
	store { ptr, i64 } %137, ptr %slot138
	%139 = load { ptr, i64 }, ptr %slot138
	ret { ptr, i64 } %139

}
define ptr @gala_785070.heap_proc (ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
	%p.417 = alloca ptr
	%slot159 = alloca i1
	%141 = load i32, ptr @gala_785070.MODE_ALLOC
	%142 = icmp eq i32 %mode, %141
	br i1 %142, label %base_block_label140, label %end_label140
base_block_label140:
	%143 = call ptr @calloc(i64 1, i64 %size)
	ret ptr %143

end_label140:

	%145 = load i32, ptr @gala_785070.MODE_FREE
	%146 = icmp eq i32 %mode, %145
	br i1 %146, label %base_block_label144, label %end_label144
base_block_label144:
	call void @free(ptr %old)

	%147 = load ptr, ptr @gala_785070.NULL
	ret ptr %147

end_label144:

	%149 = load i32, ptr @gala_785070.MODE_RESIZE
	%150 = icmp eq i32 %mode, %149
	br i1 %150, label %base_block_label148, label %end_label148
base_block_label148:
	%152 = ptrtoint ptr %old to i64
	%153 = load ptr, ptr @gala_785070.NULL
	%154 = ptrtoint ptr %153 to i64
	%155 = icmp eq i64 %152, %154
	br i1 %155, label %base_block_label151, label %end_label151
base_block_label151:
	%156 = call ptr @calloc(i64 1, i64 %size)
	ret ptr %156

end_label151:

	%157 = call ptr @realloc(ptr %old, i64 %size)
	store ptr %157, ptr %p.417

	%161 = load ptr, ptr %p.417
	%162 = ptrtoint ptr %161 to i64
	%163 = load ptr, ptr @gala_785070.NULL
	%164 = ptrtoint ptr %163 to i64
	%165 = icmp ne i64 %162, %164
	store i1 %165, ptr %slot159
	br i1 %165, label %logic.rhs.160, label %logic.end.160
logic.rhs.160:
	%166 = icmp ugt i64 %size, %old_size
	store i1 %166, ptr %slot159
	br label %logic.end.160
logic.end.160:
	%167 = load i1, ptr %slot159
	br i1 %167, label %base_block_label158, label %end_label158
base_block_label158:
	%168 = load ptr, ptr %p.417
	%169 = call i64 @gala_785070.addr(ptr %168)
	%170 = add i64 %169, %old_size
	%171 = call ptr @gala_785070.from_addr(i64 %170)
	%172 = sub i64 %size, %old_size
	call void @gala_785070.mem_zero(ptr %171, i64 %172)

	br label %end_label158
end_label158:

	%173 = load ptr, ptr %p.417
	ret ptr %173

end_label148:

	%174 = load ptr, ptr @gala_785070.NULL
	ret ptr %174

}
define { i64, i64 } @gala_785070.heap_allocator () {
entry:
	%slot178 = alloca %gala_785070.Allocator
	%175 = load ptr, ptr @gala_785070.NULL
	%176 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.heap_proc, 0
	%177 = insertvalue %gala_785070.Allocator %176, ptr %175, 1
	store %gala_785070.Allocator %177, ptr %slot178
	%179 = load { i64, i64 }, ptr %slot178
	ret { i64, i64 } %179

}
define void @gala_785070.arena_init (ptr %a, ptr %buf, i64 %size) {
entry:
	%180 = insertvalue %gala_785070.Arena undef, ptr %buf, 0
	%181 = insertvalue %gala_785070.Arena %180, i64 %size, 1
	%182 = insertvalue %gala_785070.Arena %181, i64 0, 2
	%183 = insertvalue %gala_785070.Arena %182, i64 0, 3
	%184 = insertvalue %gala_785070.Arena %183, i1 0, 4
	store %gala_785070.Arena %184, ptr %a

	ret void
}
define void @gala_785070.arena_make (ptr sret(%gala_785070.Arena) align 8 %.sret, i64 %size) {
entry:
	%185 = call ptr @malloc(i64 %size)
	%186 = insertvalue %gala_785070.Arena undef, ptr %185, 0
	%187 = insertvalue %gala_785070.Arena %186, i64 %size, 1
	%188 = insertvalue %gala_785070.Arena %187, i64 0, 2
	%189 = insertvalue %gala_785070.Arena %188, i64 0, 3
	%190 = insertvalue %gala_785070.Arena %189, i1 1, 4
	store %gala_785070.Arena %190, ptr %.sret
	ret void

}
define void @gala_785070.arena_destroy (ptr %a) {
entry:
	%192 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 4
	%193 = load i1, ptr %192
	br i1 %193, label %base_block_label191, label %end_label191
base_block_label191:
	%194 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 0
	%195 = load ptr, ptr %194
	call void @free(ptr %195)

	br label %end_label191
end_label191:

	%196 = load ptr, ptr @gala_785070.NULL
	%197 = insertvalue %gala_785070.Arena undef, ptr %196, 0
	%198 = insertvalue %gala_785070.Arena %197, i64 0, 1
	%199 = insertvalue %gala_785070.Arena %198, i64 0, 2
	%200 = insertvalue %gala_785070.Arena %199, i64 0, 3
	%201 = insertvalue %gala_785070.Arena %200, i1 0, 4
	store %gala_785070.Arena %201, ptr %a

	ret void
}
define void @gala_785070.arena_reset (ptr %a) {
entry:
	%202 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 2
	store i64 0, ptr %202

	%203 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 3
	store i64 0, ptr %203

	ret void
}
define i64 @gala_785070.arena_mark (ptr %a) {
entry:
	%204 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 2
	%205 = load i64, ptr %204
	ret i64 %205

}
define void @gala_785070.arena_restore (ptr %a, i64 %mark) {
entry:
	%206 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 2
	store i64 %mark, ptr %206

	%207 = getelementptr inbounds %gala_785070.Arena, ptr %a, i32 0, i32 3
	store i64 %mark, ptr %207

	ret void
}
define ptr @gala_785070.arena_proc (ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
	%a.433 = alloca ptr
	%base.434 = alloca i64
	%start.435 = alloca i64
	%end.436 = alloca i64
	%p.437 = alloca ptr
	%slot263 = alloca i1
	%p.438 = alloca ptr
	store ptr %data, ptr %a.433

	%208 = load ptr, ptr %a.433
	%209 = getelementptr inbounds %gala_785070.Arena, ptr %208, i32 0, i32 0
	%210 = load ptr, ptr %209
	%211 = call i64 @gala_785070.addr(ptr %210)
	store i64 %211, ptr %base.434

	%213 = load i32, ptr @gala_785070.MODE_ALLOC
	%214 = icmp eq i32 %mode, %213
	br i1 %214, label %base_block_label212, label %end_label212
base_block_label212:
	%215 = load i64, ptr %base.434
	%216 = load ptr, ptr %a.433
	%217 = getelementptr inbounds %gala_785070.Arena, ptr %216, i32 0, i32 2
	%218 = load i64, ptr %217
	%219 = add i64 %215, %218
	%220 = call i64 @gala_785070.align_forward(i64 %219, i64 %align)
	store i64 %220, ptr %start.435

	%221 = load i64, ptr %start.435
	%222 = add i64 %221, %size
	store i64 %222, ptr %end.436

	%224 = load i64, ptr %end.436
	%225 = load i64, ptr %base.434
	%226 = load ptr, ptr %a.433
	%227 = getelementptr inbounds %gala_785070.Arena, ptr %226, i32 0, i32 1
	%228 = load i64, ptr %227
	%229 = add i64 %225, %228
	%230 = icmp ugt i64 %224, %229
	br i1 %230, label %base_block_label223, label %end_label223
base_block_label223:
	%231 = load ptr, ptr @gala_785070.NULL
	ret ptr %231

end_label223:

	%232 = load i64, ptr %end.436
	%233 = load i64, ptr %base.434
	%234 = sub i64 %232, %233
	%235 = load ptr, ptr %a.433
	%236 = getelementptr inbounds %gala_785070.Arena, ptr %235, i32 0, i32 2
	store i64 %234, ptr %236

	%237 = load i64, ptr %start.435
	%238 = load i64, ptr %base.434
	%239 = sub i64 %237, %238
	%240 = load ptr, ptr %a.433
	%241 = getelementptr inbounds %gala_785070.Arena, ptr %240, i32 0, i32 3
	store i64 %239, ptr %241

	%242 = load i64, ptr %start.435
	%243 = call ptr @gala_785070.from_addr(i64 %242)
	store ptr %243, ptr %p.437

	%244 = load ptr, ptr %p.437
	call void @gala_785070.mem_zero(ptr %244, i64 %size)

	%245 = load ptr, ptr %p.437
	ret ptr %245

end_label212:

	%247 = load i32, ptr @gala_785070.MODE_FREE_ALL
	%248 = icmp eq i32 %mode, %247
	br i1 %248, label %base_block_label246, label %end_label246
base_block_label246:
	%249 = load ptr, ptr %a.433
	call void @gala_785070.arena_reset(ptr %249)

	%250 = load ptr, ptr @gala_785070.NULL
	ret ptr %250

end_label246:

	%252 = load i32, ptr @gala_785070.MODE_RESIZE
	%253 = icmp eq i32 %mode, %252
	br i1 %253, label %base_block_label251, label %end_label251
base_block_label251:
	%255 = ptrtoint ptr %old to i64
	%256 = load ptr, ptr @gala_785070.NULL
	%257 = ptrtoint ptr %256 to i64
	%258 = icmp eq i64 %255, %257
	br i1 %258, label %base_block_label254, label %end_label254
base_block_label254:
	%259 = load i32, ptr @gala_785070.MODE_ALLOC
	%260 = load ptr, ptr @gala_785070.NULL
	%261 = call ptr @gala_785070.arena_proc(ptr %data, i32 %259, i64 %size, i64 %align, ptr %260, i64 0)
	ret ptr %261

end_label254:

	%265 = call i64 @gala_785070.addr(ptr %old)
	%266 = load i64, ptr %base.434
	%267 = load ptr, ptr %a.433
	%268 = getelementptr inbounds %gala_785070.Arena, ptr %267, i32 0, i32 3
	%269 = load i64, ptr %268
	%270 = add i64 %266, %269
	%271 = icmp eq i64 %265, %270
	store i1 %271, ptr %slot263
	br i1 %271, label %logic.rhs.264, label %logic.end.264
logic.rhs.264:
	%272 = load ptr, ptr %a.433
	%273 = getelementptr inbounds %gala_785070.Arena, ptr %272, i32 0, i32 3
	%274 = load i64, ptr %273
	%275 = add i64 %274, %size
	%276 = load ptr, ptr %a.433
	%277 = getelementptr inbounds %gala_785070.Arena, ptr %276, i32 0, i32 1
	%278 = load i64, ptr %277
	%279 = icmp ule i64 %275, %278
	store i1 %279, ptr %slot263
	br label %logic.end.264
logic.end.264:
	%280 = load i1, ptr %slot263
	br i1 %280, label %base_block_label262, label %end_label262
base_block_label262:
	%282 = icmp ugt i64 %size, %old_size
	br i1 %282, label %base_block_label281, label %end_label281
base_block_label281:
	%283 = call i64 @gala_785070.addr(ptr %old)
	%284 = add i64 %283, %old_size
	%285 = call ptr @gala_785070.from_addr(i64 %284)
	%286 = sub i64 %size, %old_size
	call void @gala_785070.mem_zero(ptr %285, i64 %286)

	br label %end_label281
end_label281:

	%287 = load ptr, ptr %a.433
	%288 = getelementptr inbounds %gala_785070.Arena, ptr %287, i32 0, i32 3
	%289 = load i64, ptr %288
	%290 = add i64 %289, %size
	%291 = load ptr, ptr %a.433
	%292 = getelementptr inbounds %gala_785070.Arena, ptr %291, i32 0, i32 2
	store i64 %290, ptr %292

	ret ptr %old

end_label262:

	%293 = load i32, ptr @gala_785070.MODE_ALLOC
	%294 = load ptr, ptr @gala_785070.NULL
	%295 = call ptr @gala_785070.arena_proc(ptr %data, i32 %293, i64 %size, i64 %align, ptr %294, i64 0)
	store ptr %295, ptr %p.438

	%297 = load ptr, ptr %p.438
	%298 = ptrtoint ptr %297 to i64
	%299 = load ptr, ptr @gala_785070.NULL
	%300 = ptrtoint ptr %299 to i64
	%301 = icmp eq i64 %298, %300
	br i1 %301, label %base_block_label296, label %end_label296
base_block_label296:
	%302 = load ptr, ptr @gala_785070.NULL
	ret ptr %302

end_label296:

	%303 = load ptr, ptr %p.438
	%304 = call i64 @gala_785070.min_u64(i64 %old_size, i64 %size)
	call void @gala_785070.mem_copy(ptr %303, ptr %old, i64 %304)

	%305 = load ptr, ptr %p.438
	ret ptr %305

end_label251:

	%306 = load ptr, ptr @gala_785070.NULL
	ret ptr %306

}
define { i64, i64 } @gala_785070.arena_allocator (ptr %a) {
entry:
	%slot309 = alloca %gala_785070.Allocator
	%307 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.arena_proc, 0
	%308 = insertvalue %gala_785070.Allocator %307, ptr %a, 1
	store %gala_785070.Allocator %308, ptr %slot309
	%310 = load { i64, i64 }, ptr %slot309
	ret { i64, i64 } %310

}
define void @gala_785070.pool_make (ptr sret(%gala_785070.Pool) align 8 %.sret, i64 %chunk_size, i64 %count) {
entry:
	%cs.442 = alloca i64
	%base.443 = alloca i64
	%i.444 = alloca i64
	%next.445 = alloca ptr
	%head.446 = alloca ptr
	%311 = call i64 @gala_785070.align_forward(i64 %chunk_size, i64 8)
	store i64 %311, ptr %cs.442

	%313 = load i64, ptr %cs.442
	%314 = icmp ult i64 %313, 8
	br i1 %314, label %base_block_label312, label %end_label312
base_block_label312:
	store i64 8, ptr %cs.442

	br label %end_label312
end_label312:

	%315 = load i64, ptr %cs.442
	%316 = mul i64 %315, %count
	%317 = call ptr @malloc(i64 %316)
	%318 = call i64 @gala_785070.addr(ptr %317)
	store i64 %318, ptr %base.443

	store i64 0, ptr %i.444

	br label %while_cond_label319
while_cond_label319:
	%320 = load i64, ptr %i.444
	%321 = icmp ult i64 %320, %count
	br i1 %321, label %while_body_label319, label %while_end_label319
while_body_label319:
	%322 = load ptr, ptr @gala_785070.NULL
	store ptr %322, ptr %next.445

	%324 = load i64, ptr %i.444
	%325 = add i64 %324, 1
	%326 = icmp ult i64 %325, %count
	br i1 %326, label %base_block_label323, label %end_label323
base_block_label323:
	%327 = load i64, ptr %base.443
	%328 = load i64, ptr %i.444
	%329 = add i64 %328, 1
	%330 = load i64, ptr %cs.442
	%331 = mul i64 %329, %330
	%332 = add i64 %327, %331
	%333 = call ptr @gala_785070.from_addr(i64 %332)
	store ptr %333, ptr %next.445

	br label %end_label323
end_label323:

	%334 = load ptr, ptr %next.445
	%335 = load i64, ptr %base.443
	%336 = load i64, ptr %i.444
	%337 = load i64, ptr %cs.442
	%338 = mul i64 %336, %337
	%339 = add i64 %335, %338
	%340 = call ptr @gala_785070.from_addr(i64 %339)
	store ptr %334, ptr %340

	%341 = load i64, ptr %i.444
	%342 = add i64 %341, 1
	store i64 %342, ptr %i.444

	br label %while_cond_label319
while_end_label319:

	%343 = load ptr, ptr @gala_785070.NULL
	store ptr %343, ptr %head.446

	%345 = icmp ugt i64 %count, 0
	br i1 %345, label %base_block_label344, label %end_label344
base_block_label344:
	%346 = load i64, ptr %base.443
	%347 = call ptr @gala_785070.from_addr(i64 %346)
	store ptr %347, ptr %head.446

	br label %end_label344
end_label344:

	%348 = load i64, ptr %base.443
	%349 = call ptr @gala_785070.from_addr(i64 %348)
	%350 = load i64, ptr %cs.442
	%351 = load ptr, ptr %head.446
	%352 = insertvalue %gala_785070.Pool undef, ptr %349, 0
	%353 = insertvalue %gala_785070.Pool %352, i64 %350, 1
	%354 = insertvalue %gala_785070.Pool %353, i64 %count, 2
	%355 = insertvalue %gala_785070.Pool %354, ptr %351, 3
	store %gala_785070.Pool %355, ptr %.sret
	ret void

}
define void @gala_785070.pool_destroy (ptr %p) {
entry:
	%356 = getelementptr inbounds %gala_785070.Pool, ptr %p, i32 0, i32 0
	%357 = load ptr, ptr %356
	call void @free(ptr %357)

	%358 = load ptr, ptr @gala_785070.NULL
	%359 = load ptr, ptr @gala_785070.NULL
	%360 = insertvalue %gala_785070.Pool undef, ptr %358, 0
	%361 = insertvalue %gala_785070.Pool %360, i64 0, 1
	%362 = insertvalue %gala_785070.Pool %361, i64 0, 2
	%363 = insertvalue %gala_785070.Pool %362, ptr %359, 3
	store %gala_785070.Pool %363, ptr %p

	ret void
}
define ptr @gala_785070.pool_proc (ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
	%p.454 = alloca ptr
	%slot368 = alloca i1
	%chunk.455 = alloca ptr
	%slot414 = alloca i1
	store ptr %data, ptr %p.454

	%365 = load i32, ptr @gala_785070.MODE_ALLOC
	%366 = icmp eq i32 %mode, %365
	br i1 %366, label %base_block_label364, label %end_label364
base_block_label364:
	%370 = load ptr, ptr %p.454
	%371 = getelementptr inbounds %gala_785070.Pool, ptr %370, i32 0, i32 1
	%372 = load i64, ptr %371
	%373 = icmp ugt i64 %size, %372
	store i1 %373, ptr %slot368
	br i1 %373, label %logic.end.369, label %logic.rhs.369
logic.rhs.369:
	%374 = load ptr, ptr %p.454
	%375 = getelementptr inbounds %gala_785070.Pool, ptr %374, i32 0, i32 3
	%376 = load ptr, ptr %375
	%377 = ptrtoint ptr %376 to i64
	%378 = load ptr, ptr @gala_785070.NULL
	%379 = ptrtoint ptr %378 to i64
	%380 = icmp eq i64 %377, %379
	store i1 %380, ptr %slot368
	br label %logic.end.369
logic.end.369:
	%381 = load i1, ptr %slot368
	br i1 %381, label %base_block_label367, label %end_label367
base_block_label367:
	%382 = load ptr, ptr @gala_785070.NULL
	ret ptr %382

end_label367:

	%383 = load ptr, ptr %p.454
	%384 = getelementptr inbounds %gala_785070.Pool, ptr %383, i32 0, i32 3
	%385 = load ptr, ptr %384
	store ptr %385, ptr %chunk.455

	%386 = load ptr, ptr %chunk.455
	%387 = load ptr, ptr %386
	%388 = load ptr, ptr %p.454
	%389 = getelementptr inbounds %gala_785070.Pool, ptr %388, i32 0, i32 3
	store ptr %387, ptr %389

	%390 = load ptr, ptr %chunk.455
	%391 = load ptr, ptr %p.454
	%392 = getelementptr inbounds %gala_785070.Pool, ptr %391, i32 0, i32 1
	%393 = load i64, ptr %392
	call void @gala_785070.mem_zero(ptr %390, i64 %393)

	%394 = load ptr, ptr %chunk.455
	ret ptr %394

end_label364:

	%396 = load i32, ptr @gala_785070.MODE_FREE
	%397 = icmp eq i32 %mode, %396
	br i1 %397, label %base_block_label395, label %end_label395
base_block_label395:
	%399 = ptrtoint ptr %old to i64
	%400 = load ptr, ptr @gala_785070.NULL
	%401 = ptrtoint ptr %400 to i64
	%402 = icmp eq i64 %399, %401
	br i1 %402, label %base_block_label398, label %end_label398
base_block_label398:
	%403 = load ptr, ptr @gala_785070.NULL
	ret ptr %403

end_label398:

	%404 = load ptr, ptr %p.454
	%405 = getelementptr inbounds %gala_785070.Pool, ptr %404, i32 0, i32 3
	%406 = load ptr, ptr %405
	store ptr %406, ptr %old

	%407 = load ptr, ptr %p.454
	%408 = getelementptr inbounds %gala_785070.Pool, ptr %407, i32 0, i32 3
	store ptr %old, ptr %408

	%409 = load ptr, ptr @gala_785070.NULL
	ret ptr %409

end_label395:

	%411 = load i32, ptr @gala_785070.MODE_RESIZE
	%412 = icmp eq i32 %mode, %411
	br i1 %412, label %base_block_label410, label %end_label410
base_block_label410:
	%416 = ptrtoint ptr %old to i64
	%417 = load ptr, ptr @gala_785070.NULL
	%418 = ptrtoint ptr %417 to i64
	%419 = icmp ne i64 %416, %418
	store i1 %419, ptr %slot414
	br i1 %419, label %logic.rhs.415, label %logic.end.415
logic.rhs.415:
	%420 = load ptr, ptr %p.454
	%421 = getelementptr inbounds %gala_785070.Pool, ptr %420, i32 0, i32 1
	%422 = load i64, ptr %421
	%423 = icmp ule i64 %size, %422
	store i1 %423, ptr %slot414
	br label %logic.end.415
logic.end.415:
	%424 = load i1, ptr %slot414
	br i1 %424, label %base_block_label413, label %end_label413
base_block_label413:
	ret ptr %old

end_label413:

	%425 = load ptr, ptr @gala_785070.NULL
	ret ptr %425

end_label410:

	%426 = load ptr, ptr @gala_785070.NULL
	ret ptr %426

}
define { i64, i64 } @gala_785070.pool_allocator (ptr %p) {
entry:
	%slot429 = alloca %gala_785070.Allocator
	%427 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.pool_proc, 0
	%428 = insertvalue %gala_785070.Allocator %427, ptr %p, 1
	store %gala_785070.Allocator %428, ptr %slot429
	%430 = load { i64, i64 }, ptr %slot429
	ret { i64, i64 } %430

}
define void @gala_785070.tracking_init (ptr %t, { i64, i64 } %backing.abi) {
entry:
	%431 = alloca %gala_785070.Allocator
	store { i64, i64 } %backing.abi, ptr %431
	%432 = load %gala_785070.Allocator, ptr %431
	%433 = insertvalue %gala_785070.Tracking undef, %gala_785070.Allocator %432, 0
	%434 = insertvalue %gala_785070.Tracking %433, i64 0, 1
	%435 = insertvalue %gala_785070.Tracking %434, i64 0, 2
	%436 = insertvalue %gala_785070.Tracking %435, i64 0, 3
	%437 = insertvalue %gala_785070.Tracking %436, i64 0, 4
	%438 = insertvalue %gala_785070.Tracking %437, i64 0, 5
	store %gala_785070.Tracking %438, ptr %t

	ret void
}
define ptr @gala_785070.tracking_proc (ptr %data, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size) {
entry:
	%t.465 = alloca ptr
	%b.466 = alloca %gala_785070.Allocator
	%cb.467 = alloca ptr
	%p.468 = alloca ptr
	store ptr %data, ptr %t.465

	%439 = load ptr, ptr %t.465
	%440 = getelementptr inbounds %gala_785070.Tracking, ptr %439, i32 0, i32 0
	%441 = load %gala_785070.Allocator, ptr %440
	store %gala_785070.Allocator %441, ptr %b.466

	%442 = getelementptr inbounds %gala_785070.Allocator, ptr %b.466, i32 0, i32 0
	%443 = load ptr, ptr %442
	store ptr %443, ptr %cb.467

	%444 = load ptr, ptr %cb.467
	%445 = getelementptr inbounds %gala_785070.Allocator, ptr %b.466, i32 0, i32 1
	%446 = load ptr, ptr %445
	%447 = call ptr %444(ptr %446, i32 %mode, i64 %size, i64 %align, ptr %old, i64 %old_size)
	store ptr %447, ptr %p.468

	%449 = load i32, ptr @gala_785070.MODE_ALLOC
	%450 = icmp eq i32 %mode, %449
	br i1 %450, label %base_block_label448, label %alt_cond_label448_0
base_block_label448:
	%452 = load ptr, ptr %p.468
	%453 = ptrtoint ptr %452 to i64
	%454 = load ptr, ptr @gala_785070.NULL
	%455 = ptrtoint ptr %454 to i64
	%456 = icmp ne i64 %453, %455
	br i1 %456, label %base_block_label451, label %end_label451
base_block_label451:
	%457 = load ptr, ptr %t.465
	%458 = getelementptr inbounds %gala_785070.Tracking, ptr %457, i32 0, i32 1
	%459 = load i64, ptr %458
	%460 = add i64 %459, 1
	store i64 %460, ptr %458

	%461 = load ptr, ptr %t.465
	%462 = getelementptr inbounds %gala_785070.Tracking, ptr %461, i32 0, i32 3
	%463 = load i64, ptr %462
	%464 = add i64 %463, %size
	store i64 %464, ptr %462

	%465 = load ptr, ptr %t.465
	%466 = getelementptr inbounds %gala_785070.Tracking, ptr %465, i32 0, i32 5
	%467 = load i64, ptr %466
	%468 = add i64 %467, %size
	store i64 %468, ptr %466

	br label %end_label451
end_label451:

	br label %end_label448
alt_cond_label448_0:
	%469 = load i32, ptr @gala_785070.MODE_FREE
	%470 = icmp eq i32 %mode, %469
	br i1 %470, label %alt_block_label448_0, label %alt_cond_label448_1
alt_block_label448_0:
	%471 = load ptr, ptr %t.465
	%472 = getelementptr inbounds %gala_785070.Tracking, ptr %471, i32 0, i32 2
	%473 = load i64, ptr %472
	%474 = add i64 %473, 1
	store i64 %474, ptr %472

	%475 = load ptr, ptr %t.465
	%476 = getelementptr inbounds %gala_785070.Tracking, ptr %475, i32 0, i32 3
	%477 = load i64, ptr %476
	%478 = sub i64 %477, %old_size
	store i64 %478, ptr %476

	br label %end_label448
alt_cond_label448_1:
	%479 = load i32, ptr @gala_785070.MODE_FREE_ALL
	%480 = icmp eq i32 %mode, %479
	br i1 %480, label %alt_block_label448_1, label %alt_cond_label448_2
alt_block_label448_1:
	%481 = load ptr, ptr %t.465
	%482 = getelementptr inbounds %gala_785070.Tracking, ptr %481, i32 0, i32 3
	store i64 0, ptr %482

	br label %end_label448
alt_cond_label448_2:
	%483 = load i32, ptr @gala_785070.MODE_RESIZE
	%484 = icmp eq i32 %mode, %483
	br i1 %484, label %alt_block_label448_2, label %end_label448
alt_block_label448_2:
	%486 = load ptr, ptr %p.468
	%487 = ptrtoint ptr %486 to i64
	%488 = load ptr, ptr @gala_785070.NULL
	%489 = ptrtoint ptr %488 to i64
	%490 = icmp ne i64 %487, %489
	br i1 %490, label %base_block_label485, label %end_label485
base_block_label485:
	%491 = load ptr, ptr %t.465
	%492 = getelementptr inbounds %gala_785070.Tracking, ptr %491, i32 0, i32 3
	%493 = load i64, ptr %492
	%494 = sub i64 %size, %old_size
	%495 = add i64 %493, %494
	store i64 %495, ptr %492

	%496 = load ptr, ptr %t.465
	%497 = getelementptr inbounds %gala_785070.Tracking, ptr %496, i32 0, i32 5
	%498 = load i64, ptr %497
	%499 = add i64 %498, %size
	store i64 %499, ptr %497

	br label %end_label485
end_label485:

	br label %end_label448
end_label448:

	%501 = load ptr, ptr %t.465
	%502 = getelementptr inbounds %gala_785070.Tracking, ptr %501, i32 0, i32 3
	%503 = load i64, ptr %502
	%504 = load ptr, ptr %t.465
	%505 = getelementptr inbounds %gala_785070.Tracking, ptr %504, i32 0, i32 4
	%506 = load i64, ptr %505
	%507 = icmp sgt i64 %503, %506
	br i1 %507, label %base_block_label500, label %end_label500
base_block_label500:
	%508 = load ptr, ptr %t.465
	%509 = getelementptr inbounds %gala_785070.Tracking, ptr %508, i32 0, i32 3
	%510 = load i64, ptr %509
	%511 = load ptr, ptr %t.465
	%512 = getelementptr inbounds %gala_785070.Tracking, ptr %511, i32 0, i32 4
	store i64 %510, ptr %512

	br label %end_label500
end_label500:

	%513 = load ptr, ptr %p.468
	ret ptr %513

}
define { i64, i64 } @gala_785070.tracking_allocator (ptr %t) {
entry:
	%slot516 = alloca %gala_785070.Allocator
	%514 = insertvalue %gala_785070.Allocator undef, ptr @gala_785070.tracking_proc, 0
	%515 = insertvalue %gala_785070.Allocator %514, ptr %t, 1
	store %gala_785070.Allocator %515, ptr %slot516
	%517 = load { i64, i64 }, ptr %slot516
	ret { i64, i64 } %517

}
define void @gala_785070.tracking_report (ptr %t) {
entry:
	%slot518 = alloca [4 x { ptr, i64 }]
	%slot522 = alloca { ptr, i64 }
	%slot528 = alloca i64
	%slot535 = alloca { ptr, i64 }
	%slot541 = alloca i64
	%slot547 = alloca [6 x { ptr, i64 }]
	%slot551 = alloca { ptr, i64 }
	%slot557 = alloca i64
	%slot564 = alloca { ptr, i64 }
	%slot570 = alloca i64
	%slot577 = alloca { ptr, i64 }
	%slot583 = alloca i64
	%519 = getelementptr inbounds [8 x i8], ptr @string27, i64 0, i64 0
	%520 = insertvalue { ptr, i64 } undef, ptr %519, 0
	%521 = insertvalue { ptr, i64 } %520, i64 7, 1
	store { ptr, i64 } %521, ptr %slot522
	%523 = insertvalue { ptr, i64 } undef, ptr %slot522, 0
	%524 = insertvalue { ptr, i64 } %523, i64 17, 1
	%525 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 0
	store { ptr, i64 } %524, ptr %525
	%526 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 1
	%527 = load i64, ptr %526
	store i64 %527, ptr %slot528
	%529 = insertvalue { ptr, i64 } undef, ptr %slot528, 0
	%530 = insertvalue { ptr, i64 } %529, i64 3, 1
	%531 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 1
	store { ptr, i64 } %530, ptr %531
	%532 = getelementptr inbounds [7 x i8], ptr @string28, i64 0, i64 0
	%533 = insertvalue { ptr, i64 } undef, ptr %532, 0
	%534 = insertvalue { ptr, i64 } %533, i64 6, 1
	store { ptr, i64 } %534, ptr %slot535
	%536 = insertvalue { ptr, i64 } undef, ptr %slot535, 0
	%537 = insertvalue { ptr, i64 } %536, i64 17, 1
	%538 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 2
	store { ptr, i64 } %537, ptr %538
	%539 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 2
	%540 = load i64, ptr %539
	store i64 %540, ptr %slot541
	%542 = insertvalue { ptr, i64 } undef, ptr %slot541, 0
	%543 = insertvalue { ptr, i64 } %542, i64 3, 1
	%544 = getelementptr inbounds [4 x { ptr, i64 }], ptr %slot518, i64 0, i64 3
	store { ptr, i64 } %543, ptr %544
	%545 = insertvalue { ptr, i64 } undef, ptr %slot518, 0
	%546 = insertvalue { ptr, i64 } %545, i64 4, 1
	call void @gala_120231.println({ ptr, i64 } %546)

	%548 = getelementptr inbounds [12 x i8], ptr @string29, i64 0, i64 0
	%549 = insertvalue { ptr, i64 } undef, ptr %548, 0
	%550 = insertvalue { ptr, i64 } %549, i64 11, 1
	store { ptr, i64 } %550, ptr %slot551
	%552 = insertvalue { ptr, i64 } undef, ptr %slot551, 0
	%553 = insertvalue { ptr, i64 } %552, i64 17, 1
	%554 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 0
	store { ptr, i64 } %553, ptr %554
	%555 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 3
	%556 = load i64, ptr %555
	store i64 %556, ptr %slot557
	%558 = insertvalue { ptr, i64 } undef, ptr %slot557, 0
	%559 = insertvalue { ptr, i64 } %558, i64 3, 1
	%560 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 1
	store { ptr, i64 } %559, ptr %560
	%561 = getelementptr inbounds [6 x i8], ptr @string30, i64 0, i64 0
	%562 = insertvalue { ptr, i64 } undef, ptr %561, 0
	%563 = insertvalue { ptr, i64 } %562, i64 5, 1
	store { ptr, i64 } %563, ptr %slot564
	%565 = insertvalue { ptr, i64 } undef, ptr %slot564, 0
	%566 = insertvalue { ptr, i64 } %565, i64 17, 1
	%567 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 2
	store { ptr, i64 } %566, ptr %567
	%568 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 4
	%569 = load i64, ptr %568
	store i64 %569, ptr %slot570
	%571 = insertvalue { ptr, i64 } undef, ptr %slot570, 0
	%572 = insertvalue { ptr, i64 } %571, i64 3, 1
	%573 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 3
	store { ptr, i64 } %572, ptr %573
	%574 = getelementptr inbounds [7 x i8], ptr @string31, i64 0, i64 0
	%575 = insertvalue { ptr, i64 } undef, ptr %574, 0
	%576 = insertvalue { ptr, i64 } %575, i64 6, 1
	store { ptr, i64 } %576, ptr %slot577
	%578 = insertvalue { ptr, i64 } undef, ptr %slot577, 0
	%579 = insertvalue { ptr, i64 } %578, i64 17, 1
	%580 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 4
	store { ptr, i64 } %579, ptr %580
	%581 = getelementptr inbounds %gala_785070.Tracking, ptr %t, i32 0, i32 5
	%582 = load i64, ptr %581
	store i64 %582, ptr %slot583
	%584 = insertvalue { ptr, i64 } undef, ptr %slot583, 0
	%585 = insertvalue { ptr, i64 } %584, i64 3, 1
	%586 = getelementptr inbounds [6 x { ptr, i64 }], ptr %slot547, i64 0, i64 5
	store { ptr, i64 } %585, ptr %586
	%587 = insertvalue { ptr, i64 } undef, ptr %slot547, 0
	%588 = insertvalue { ptr, i64 } %587, i64 6, 1
	call void @gala_120231.println({ ptr, i64 } %588)

	ret void
}
define void @gala_785070.__init_globals() {
entry:
	%589 = inttoptr i64 0 to ptr
	store ptr %589, ptr @gala_785070.NULL
	store i64 1024, ptr @gala_785070.KB
	store i64 1048576, ptr @gala_785070.MB
	store i64 1073741824, ptr @gala_785070.GB
	store i32 0, ptr @gala_785070.MODE_ALLOC
	store i32 1, ptr @gala_785070.MODE_FREE
	store i32 2, ptr @gala_785070.MODE_FREE_ALL
	store i32 3, ptr @gala_785070.MODE_RESIZE
	%590 = call { i64, i64 } @gala_785070.heap_allocator()
	%slot591 = alloca %gala_785070.Allocator
	store { i64, i64 } %590, ptr %slot591
	%592 = load %gala_785070.Allocator, ptr %slot591
	store %gala_785070.Allocator %592, ptr @gala_785070.base_allocator
	ret void
}

