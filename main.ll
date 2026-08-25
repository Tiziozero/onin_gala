; ModuleID = 'main.c'
source_filename = "main.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Vector2 = type { float, float }

@__const.main.a = private unnamed_addr constant %struct.Vector2 { float 1.000000e+00, float 2.000000e+00 }, align 4
@__const.main.b = private unnamed_addr constant %struct.Vector2 { float 5.000000e+00, float 7.000000e+00 }, align 4
@.str = private unnamed_addr constant [10 x i8] c"c: %f %f\0A\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca %struct.Vector2, align 4
  %3 = alloca %struct.Vector2, align 4
  %4 = alloca %struct.Vector2, align 4
  store i32 0, ptr %1, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %2, ptr align 4 @__const.main.a, i64 8, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %3, ptr align 4 @__const.main.b, i64 8, i1 false)
  %5 = load <2 x float>, ptr %2, align 4
  %6 = load <2 x float>, ptr %3, align 4
  %7 = call <2 x float> @Vector2Add(<2 x float> %5, <2 x float> %6)
  store <2 x float> %7, ptr %4, align 4
  %8 = getelementptr inbounds %struct.Vector2, ptr %4, i32 0, i32 0
  %9 = load float, ptr %8, align 4
  %10 = fpext float %9 to double
  %11 = getelementptr inbounds %struct.Vector2, ptr %4, i32 0, i32 1
  %12 = load float, ptr %11, align 4
  %13 = fpext float %12 to double
  %14 = call i32 (ptr, ...) @printf(ptr noundef @.str, double noundef %10, double noundef %13)
  ret i32 0
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #1

declare <2 x float> @Vector2Add(<2 x float>, <2 x float>) #2

declare i32 @printf(ptr noundef, ...) #2

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
