; ModuleID = 'main.c'
source_filename = "main.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "bpf"

%struct.xdp_md = type { i32, i32, i32, i32, i32, i32 }
%struct.ethhdr = type { [6 x i8], [6 x i8], i16 }

@alb.____fmt = internal constant [13 x i8] c"IP source %x\00", align 1
@alb.____fmt.1 = internal constant [18 x i8] c"IP destination %x\00", align 1
@_license = dso_local global [4 x i8] c"GPL\00", section "license", align 1
@llvm.compiler.used = appending global [2 x i8*] [i8* getelementptr inbounds ([4 x i8], [4 x i8]* @_license, i32 0, i32 0), i8* bitcast (i32 (%struct.xdp_md*)* @alb to i8*)], section "llvm.metadata"

; Function Attrs: nounwind
define dso_local i32 @alb(%struct.xdp_md* nocapture noundef readonly %0) #0 section "xdp" {
  %2 = getelementptr inbounds %struct.xdp_md, %struct.xdp_md* %0, i64 0, i32 0
  %3 = load i32, i32* %2, align 4, !tbaa !3
  %4 = zext i32 %3 to i64
  %5 = inttoptr i64 %4 to i8*
  %6 = getelementptr inbounds %struct.xdp_md, %struct.xdp_md* %0, i64 0, i32 1
  %7 = load i32, i32* %6, align 4, !tbaa !8
  %8 = zext i32 %7 to i64
  %9 = inttoptr i64 %8 to i8*
  %10 = inttoptr i64 %4 to %struct.ethhdr*
  %11 = getelementptr i8, i8* %5, i64 14
  %12 = icmp ugt i8* %11, %9
  br i1 %12, label %63, label %13

13:                                               ; preds = %1
  %14 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 0, i32 2
  %15 = load i16, i16* %14, align 1, !tbaa !9
  %16 = icmp eq i16 %15, 8
  br i1 %16, label %17, label %63

17:                                               ; preds = %13
  %18 = getelementptr i8, i8* %5, i64 34
  %19 = icmp ugt i8* %18, %9
  br i1 %19, label %63, label %20

20:                                               ; preds = %17
  %21 = getelementptr i8, i8* %5, i64 23
  %22 = load i8, i8* %21, align 1, !tbaa !12
  %23 = icmp eq i8 %22, 6
  br i1 %23, label %24, label %63

24:                                               ; preds = %20
  %25 = load i8, i8* %11, align 4
  %26 = and i8 %25, 15
  %27 = icmp eq i8 %26, 5
  br i1 %27, label %28, label %63

28:                                               ; preds = %24
  %29 = getelementptr i8, i8* %5, i64 26
  %30 = bitcast i8* %29 to i32*
  %31 = load i32, i32* %30, align 4, !tbaa !14
  %32 = tail call i64 (i8*, i32, ...) inttoptr (i64 6 to i64 (i8*, i32, ...)*)(i8* noundef getelementptr inbounds ([13 x i8], [13 x i8]* @alb.____fmt, i64 0, i64 0), i32 noundef 13, i32 noundef %31) #1
  %33 = getelementptr i8, i8* %5, i64 30
  %34 = bitcast i8* %33 to i32*
  %35 = load i32, i32* %34, align 4, !tbaa !14
  %36 = tail call i64 (i8*, i32, ...) inttoptr (i64 6 to i64 (i8*, i32, ...)*)(i8* noundef getelementptr inbounds ([18 x i8], [18 x i8]* @alb.____fmt.1, i64 0, i64 0), i32 noundef 18, i32 noundef %35) #1
  store i32 33558956, i32* %34, align 4, !tbaa !14
  %37 = getelementptr inbounds %struct.ethhdr, %struct.ethhdr* %10, i64 0, i32 0, i64 5
  store i8 2, i8* %37, align 1, !tbaa !14
  %38 = getelementptr i8, i8* %5, i64 24
  %39 = bitcast i8* %38 to i16*
  store i16 0, i16* %39, align 2, !tbaa !15
  %40 = bitcast i8* %11 to i32*
  %41 = tail call i64 inttoptr (i64 28 to i64 (i32*, i32, i32*, i32, i32)*)(i32* noundef null, i32 noundef 0, i32* noundef nonnull %40, i32 noundef 20, i32 noundef 0) #1
  %42 = icmp ult i64 %41, 65536
  %43 = lshr i64 %41, 16
  %44 = and i64 %41, 65535
  %45 = add nuw nsw i64 %44, %43
  %46 = select i1 %42, i64 %41, i64 %45
  %47 = icmp ult i64 %46, 65536
  %48 = lshr i64 %46, 16
  %49 = and i64 %46, 65535
  %50 = add nuw nsw i64 %49, %48
  %51 = select i1 %47, i64 %46, i64 %50
  %52 = icmp ult i64 %51, 65536
  %53 = lshr i64 %51, 16
  %54 = and i64 %51, 65535
  %55 = add nuw nsw i64 %54, %53
  %56 = select i1 %52, i64 %51, i64 %55
  %57 = icmp ult i64 %56, 65536
  %58 = lshr i64 %56, 16
  %59 = select i1 %57, i64 65536, i64 %58
  %60 = add nuw nsw i64 %59, %56
  %61 = trunc i64 %60 to i16
  %62 = xor i16 %61, -1
  store i16 %62, i16* %39, align 2, !tbaa !15
  br label %63

63:                                               ; preds = %28, %17, %20, %24, %13, %1
  %64 = phi i32 [ 1, %1 ], [ 2, %13 ], [ 3, %28 ], [ 1, %17 ], [ 2, %20 ], [ 2, %24 ]
  ret i32 %64
}

attributes #0 = { nounwind "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #1 = { nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{!"Ubuntu clang version 14.0.0-1ubuntu1"}
!3 = !{!4, !5, i64 0}
!4 = !{!"xdp_md", !5, i64 0, !5, i64 4, !5, i64 8, !5, i64 12, !5, i64 16, !5, i64 20}
!5 = !{!"int", !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C/C++ TBAA"}
!8 = !{!4, !5, i64 4}
!9 = !{!10, !11, i64 12}
!10 = !{!"ethhdr", !6, i64 0, !6, i64 6, !11, i64 12}
!11 = !{!"short", !6, i64 0}
!12 = !{!13, !6, i64 9}
!13 = !{!"iphdr", !6, i64 0, !6, i64 0, !6, i64 1, !11, i64 2, !11, i64 4, !11, i64 6, !6, i64 8, !6, i64 9, !11, i64 10, !6, i64 12}
!14 = !{!6, !6, i64 0}
!15 = !{!13, !11, i64 10}
