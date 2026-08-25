; ModuleID = 'main.c'
source_filename = "main.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Vector2 = type { float, float }
%struct.SmallAgg = type { i32, i32, i32, i64 }
%struct.Something = type { %struct.Vector2, %struct.Vector2, %struct.Texture, %struct.Rectangle, ptr, i8, i64 }
%struct.Texture = type { i32, i32, i32, i32, i32 }
%struct.Rectangle = type { float, float, float, float }
%struct.non_agregate_thing = type { i32, float, i8, i64, ptr, i32, double }

@__const.main.a = private unnamed_addr constant %struct.Vector2 { float 1.000000e+00, float 2.000000e+00 }, align 4
@__const.main.b = private unnamed_addr constant %struct.Vector2 { float 5.000000e+00, float 7.000000e+00 }, align 4
@.str = private unnamed_addr constant [10 x i8] c"c: %f %f\0A\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca %struct.SmallAgg, align 8
  %3 = alloca %struct.Vector2, align 4
  %4 = alloca %struct.Vector2, align 4
  %5 = alloca %struct.Vector2, align 4
  %6 = alloca %struct.Something, align 8
  %7 = alloca %struct.non_agregate_thing, align 8
  store i32 0, ptr %1, align 4
  call void @f(ptr noundef byval(%struct.SmallAgg) align 8 %2)
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %3, ptr align 4 @__const.main.a, i64 8, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %4, ptr align 4 @__const.main.b, i64 8, i1 false)
  %8 = load <2 x float>, ptr %3, align 4
  %9 = load <2 x float>, ptr %4, align 4
  %10 = call <2 x float> @Vector2Add(<2 x float> %8, <2 x float> %9)
  store <2 x float> %10, ptr %5, align 4
  %11 = getelementptr inbounds %struct.Vector2, ptr %5, i32 0, i32 0
  %12 = load float, ptr %11, align 4
  %13 = fpext float %12 to double
  %14 = getelementptr inbounds %struct.Vector2, ptr %5, i32 0, i32 1
  %15 = load float, ptr %14, align 4
  %16 = fpext float %15 to double
  %17 = call i32 (ptr, ...) @printf(ptr noundef @.str, double noundef %13, double noundef %16)
  %18 = getelementptr inbounds %struct.non_agregate_thing, ptr %7, i32 0, i32 0
  %19 = load i32, ptr %18, align 8
  ret i32 %19
}

declare void @f(ptr noundef byval(%struct.SmallAgg) align 8) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare <2 x float> @Vector2Add(<2 x float>, <2 x float>) #1

declare i32 @printf(ptr noundef, ...) #1

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
