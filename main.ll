; ModuleID = 'main.c'
source_filename = "main.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Vector2 = type { float, float }
%struct.Color = type { i8, i8, i8, i8 }

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main() #0 {
  %1 = alloca %struct.Vector2, align 4
  %2 = alloca %struct.Vector2, align 4
  %3 = alloca %struct.Vector2, align 4
  %4 = alloca %struct.Color, align 1
  %5 = getelementptr inbounds %struct.Vector2, ptr %1, i32 0, i32 0
  store float 1.000000e+00, ptr %5, align 4
  %6 = getelementptr inbounds %struct.Vector2, ptr %1, i32 0, i32 1
  store float 1.000000e+00, ptr %6, align 4
  %7 = getelementptr inbounds %struct.Vector2, ptr %2, i32 0, i32 0
  store float 1.000000e+00, ptr %7, align 4
  %8 = getelementptr inbounds %struct.Vector2, ptr %2, i32 0, i32 1
  store float 1.000000e+00, ptr %8, align 4
  %9 = getelementptr inbounds %struct.Vector2, ptr %3, i32 0, i32 0
  store float 1.000000e+00, ptr %9, align 4
  %10 = getelementptr inbounds %struct.Vector2, ptr %3, i32 0, i32 1
  store float 1.000000e+00, ptr %10, align 4
  %11 = getelementptr inbounds %struct.Color, ptr %4, i32 0, i32 0
  store i8 0, ptr %11, align 1
  %12 = getelementptr inbounds %struct.Color, ptr %4, i32 0, i32 1
  store i8 0, ptr %12, align 1
  %13 = getelementptr inbounds %struct.Color, ptr %4, i32 0, i32 2
  store i8 0, ptr %13, align 1
  %14 = getelementptr inbounds %struct.Color, ptr %4, i32 0, i32 3
  store i8 0, ptr %14, align 1
  %15 = load <2 x float>, ptr %1, align 4
  %16 = load <2 x float>, ptr %2, align 4
  %17 = load <2 x float>, ptr %3, align 4
  %18 = load i32, ptr %4, align 1
  call void @DrawTriangle(<2 x float> %15, <2 x float> %16, <2 x float> %17, i32 %18)
  ret i32 0
}

declare void @DrawTriangle(<2 x float>, <2 x float>, <2 x float>, i32) #1

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 18.1.3 (1ubuntu1)"}
