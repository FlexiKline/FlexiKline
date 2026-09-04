import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../config/gesture_config/gesture_config.dart';
import '../config/tolerance_config/tolerance_config.dart';
import '../constant.dart';
import '../framework/chart/indicator.dart';
import '../framework/draw/overlay.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../utils/algorithm_util.dart';

abstract class GestureDetectorWidget extends StatefulWidget {
  const GestureDetectorWidget({
    super.key,
    required this.controller,
    this.onDoubleTap,
  });

  final FlexiKlineController controller;
  final GestureTapCallback? onDoubleTap;

  @override
  GestureDetectorState<GestureDetectorWidget> createState();
}

abstract class GestureDetectorState<T extends GestureDetectorWidget> extends State<T>
    with TickerProviderStateMixin, FlexiLog {
  AnimationController? animationController;

  FlexiKlineController get controller => widget.controller;

  GestureConfig get gestureConfig => widget.controller.gestureConfig;

  DrawState get drawState => controller.drawState;

  @override
  void initState() {
    super.initState();
    logger = controller.logger;
    controller.moveToPositionCallback = moveToPosition;
  }

  @override
  void dispose() {
    cancelPositionAnimation();
    controller.moveToPositionCallback = null;
    super.dispose();
  }

  /// 解析缩放的锚定位置：[ScalePosition.auto] 时按 [dx] 所在的横向三分区就近锚定，
  /// 已显式配置则原样返回。
  ///
  /// 只解析不缓存：一轮手势内能否重新解析是两端各自的策略。触摸端必须锁定，否则「双指
  /// 缩放抬起一指再张开」时锚点会从 middle 跳到 left（见 `CONTEXT.md` 的
  /// `Landed Gesture Ownership`）；非触摸端每个 signal 事件自成一段，不存在这个约束。
  @protected
  ScalePosition resolveScalePosition(double dx) {
    final configured = gestureConfig.scalePosition;
    if (configured != ScalePosition.auto) return configured;
    final third = controller.canvasRect.width / 3;
    if (dx < third) return ScalePosition.left;
    if (dx > third + third) return ScalePosition.right;
    return ScalePosition.middle;
  }

  /// 惯性平移的准入判定：够条件则返回预测的平移距离与时长，否则返回 null。
  ///
  /// [canceled] 为本轮是否出现过 `PointerCancel`。cancel 意味着系统接管了手势（来电、
  /// 应用切后台、父级抢占），指针并非被主动甩出，继续滚动是错的——这条判据与输入设备
  /// 无关，两端同源。
  ///
  /// 判定与后续流程分开：抬手后要不要复位光标、清哪个 session，是两端各自的事。
  @protected
  ({double distance, int duration})? resolveInertialPan(
    double velocity, {
    required bool canceled,
  }) {
    if (canceled || !gestureConfig.enableInertialPan) return null;
    if (controller.klineData.isEmpty) return null;
    if (velocity < 0 && !controller.canPanRTL) return null;
    if (velocity > 0 && !controller.canPanLTR) return null;

    final tolerance = gestureConfig.tolerance;
    final distance = velocity * tolerance.distanceFactor;
    final duration = calcuInertialPanDuration(distance, maxDuration: tolerance.maxDuration);
    // 平移距离为 0 或不足 1ms, 无需继续平移。
    if (distance.abs() < precisionError || duration <= 1) return null;
    return (distance: distance, duration: duration);
  }

  /// 取消当前的位置动画。
  @protected
  void cancelPositionAnimation() {
    final current = animationController;
    animationController = null;
    current?.dispose();
  }

  /// 打断进行中的位置动画（惯性平移或指定日期定位），并归位它写下的平移平滑因子。
  ///
  /// [animateToPosition] 的 `onCompleted` 只在动画自然跑完时执行，被打断时不会。而动画每帧
  /// 都经 [ChartBinding.onChartMove] 写入 `_panSmoothFactor`，不归位会让 Y 轴的 minMax 一直
  /// 走插值、且 `clipRect` 停在 `canvasRect` 而非 `mainRect`。
  @protected
  void stopPositionAnimation() {
    if (animationController == null) return;
    cancelPositionAnimation();
    controller.onPanEnd();
  }

  /// 以动画的形式从[begin]移动到[end].
  Future<bool> moveToPosition(double begin, double end) {
    if (!mounted || !controller.isMounted) return Future.value(false);

    return animateToPosition(
      begin,
      end,
      onCompleted: controller.onPanEnd,
    );
  }

  /// 以动画的形式从[begin]移动到[end]指定位置
  /// [panDuration] 移动时长, 单位毫秒; 如果未指定, 则根据[begin]和[end]的差值计算出合适的时长
  /// [tolerance] 惯性平移参数
  /// [onCompleted] 动画完成回调
  @protected
  Future<bool> animateToPosition(
    double begin,
    double end, {
    Duration? panDuration,
    ToleranceConfig? tolerance,
    FutureOr<void> Function()? onCompleted,
  }) async {
    cancelPositionAnimation();
    if (!mounted || !controller.isMounted) return false;

    if ((begin - end).abs() < precisionError) {
      logd('animateToPosition begin:$begin end:$end no need to move!');
      await onCompleted?.call();
      await WidgetsBinding.instance.endOfFrame;
      return mounted && controller.isMounted;
    }

    final effectiveTolerance = tolerance ?? gestureConfig.tolerance;
    final effectivePanDuration = panDuration ??
        Duration(
          milliseconds: calcuInertialPanDuration(
            (begin - end).abs(),
            maxDuration: effectiveTolerance.maxDuration,
          ),
        );

    final current = AnimationController(
      vsync: this,
      duration: effectivePanDuration,
    );
    animationController = current;

    logd('animateToPosition begin:$begin end:$end panDuration:${effectivePanDuration.inMilliseconds}');
    final animation = Tween(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: effectiveTolerance.curve)).animate(current);

    // 差分基准: 动画每帧把位移增量交给 [ChartBinding.onChartMove], 纵向恒为 0。
    var last = begin;
    animation.addListener(() {
      final value = animation.value;
      final delta = value - last;
      last = value;
      final progress = current.value;
      final sf = effectiveTolerance.effectivePanSmoothFactor;
      final tp = effectiveTolerance.effectiveConvergenceRatio;
      final smoothFactor = progress < tp ? sf : lerpDouble(sf, 1.0, (progress - tp) / (1.0 - tp))!;
      controller.onChartMove(Offset(delta, 0), smoothFactor: smoothFactor);
    });

    try {
      await current.forward().orCancel;
      await onCompleted?.call();
      await WidgetsBinding.instance.endOfFrame;
      return mounted && controller.isMounted;
    } on TickerCanceled {
      return false;
    } finally {
      if (identical(animationController, current)) {
        animationController = null;
        current.dispose();
      }
    }
  }
}
