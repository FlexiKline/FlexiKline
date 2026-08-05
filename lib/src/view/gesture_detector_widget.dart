import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../config/gesture_config/gesture_config.dart';
import '../config/tolerance_config/tolerance_config.dart';
import '../constant.dart';
import '../framework/draw/overlay.dart';
import '../framework/logger.dart';
import '../kline_controller.dart';
import '../model/gesture_data.dart';
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

  /// 取消当前的位置动画。
  @protected
  void cancelPositionAnimation() {
    final current = animationController;
    animationController = null;
    current?.dispose();
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
    final gestureData = GestureData.pan(Offset(begin, 0.0));
    final animation = Tween(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: effectiveTolerance.curve)).animate(current);

    animation.addListener(() {
      gestureData.update(Offset(
        animation.value,
        gestureData.offset.dy,
      ));
      final progress = current.value;
      final sf = effectiveTolerance.effectivePanSmoothFactor;
      final tp = effectiveTolerance.effectiveConvergenceRatio;
      final smoothFactor = progress < tp ? sf : lerpDouble(sf, 1.0, (progress - tp) / (1.0 - tp))!;
      controller.onChartMove(gestureData, smoothFactor);
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
