import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/gesture_config/gesture_config.dart';
import '../config/tolerance_config/tolerance_config.dart';
import '../constant.dart';
import '../extension/functions_ext.dart';
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
    with TickerProviderStateMixin, KlineLog {
  AnimationController? animationController;

  FlexiKlineController get controller => widget.controller;

  GestureConfig get gestureConfig => widget.controller.gestureConfig;

  DrawState get drawState => controller.drawState;

  @override
  void initState() {
    super.initState();
    loggerDelegate = controller.loggerDelegate;
    controller.moveToInitialPositionCallback = moveToInitialPosition;
  }

  @override
  void dispose() {
    animationController?.dispose();
    controller.moveToInitialPositionCallback = null;
    super.dispose();
  }

  /// 以动画的形式返回到初始位置
  void moveToInitialPosition() {
    animateToPosition(
      controller.paintDxOffset,
      controller.getInitPaintDxOffset(),
    );
  }

  /// 以动画的形式从[begin]移动到[end]指定位置
  /// [panDuration] 移动时长, 单位毫秒; 如果未指定, 则根据[begin]和[end]的差值计算出合适的时长
  /// [tolerance] 惯性平移参数
  /// [onCompleted] 动画完成回调
  @protected
  void animateToPosition(
    double begin,
    double end, {
    Duration? panDuration,
    ToleranceConfig? tolerance,
    FutureOr<void> Function()? onCompleted,
  }) {
    if ((begin - end).abs() < precisionError) {
      logd('animateToPosition begin:$begin end:$end no need to move!');
      return;
    }

    tolerance ??= gestureConfig.tolerance;
    panDuration ??= Duration(
      milliseconds: calcuInertialPanDuration(
        (begin - end).abs(),
        maxDuration: tolerance.maxDuration,
      ),
    );

    animationController?.dispose();
    animationController = AnimationController(
      vsync: this,
      duration: panDuration,
    );

    logd('animateToPosition begin:$begin end:$end panDuration:${panDuration.inMilliseconds}');
    final gestureData = GestureData.pan(Offset(begin, 0.0));
    final animation = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: tolerance.curve))
        .animate(animationController!);

    animation.addListener(() {
      logd('animateToPosition move> ${DateTime.now().millisecond} value:${animation.value}');
      gestureData.update(Offset(
        animation.value,
        gestureData.offset.dy,
      ));
      controller.onChartMove(gestureData);
    }.throttleOnFps);

    animationController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onCompleted?.call();
      }
    });

    animationController?.forward();
  }
}
