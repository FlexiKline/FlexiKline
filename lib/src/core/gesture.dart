import 'package:flutter/material.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';

mixin GestureBinding on KlineBindingBase implements IGestureEvent, IDataSource {
  @override
  void initBinding() {
    super.initBinding();
    logd('init gesture');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose gesture');
    _ticker = null;
  }

  TickerProvider? _ticker;
  TickerProvider? get ticker => _ticker;
  void setTicker(TickerProvider ticker) {
    /// 仅能设置一次.
    _ticker ??= ticker;
  }

  AnimationController? animationController;

  GestureData? _panScaleData; // 移动缩放监听数据
  GestureData? _longData; // 长按监听数据
  GestureData? _tapData;

  ///
  /// 点击
  ///
  @override
  void onTapUp(TapUpDetails details) {
    logd("onTapUp details:$details");
    _panScaleData?.end();
    _panScaleData = null;
    _longData?.end();
    _longData = null;

    _tapData = GestureData.tap(details.localPosition);

    handleTap(_tapData!);
  }

  ///
  /// 移动 缩放
  ///
  @override
  void onScaleStart(ScaleStartDetails details) {
    logd("onScaleStart localFocalPoint:${details.localFocalPoint} >>>>");

    _tapData?.end();
    _tapData = null;
    _longData?.end();
    _longData = null;
    _panScaleData = GestureData.pan(details.localFocalPoint);
  }

  @override
  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_panScaleData == null) {
      logd(
        "onScaleUpdate localFocalPoint:${details.localFocalPoint}, scale:${details.scale}",
      );
      return;
    }

    _panScaleData!.update(details.localFocalPoint, scale: details.scale);

    if (details.pointerCount > 1 /*_panScaleData!.isScale*/) {
      handleScale(_panScaleData!);
    } else {
      handleMove(_panScaleData!);
    }
  }

  double translateX = double.nan;
  double updateTranslate(double val) {
    return val.clamp(-1000, 0);
  }

  @override
  void onScaleEnd(ScaleEndDetails details) {
    final dataLen = curCandleData.list.length;
    if (_panScaleData == null || ticker == null || dataLen <= 0) {
      logd("onScaleEnd data and ticker is empty! > details:$details");
      return;
    }
    // logd("onScaleEnd  details:$details");

    // final Tolerance tolerance = Tolerance(
    //   velocity: 1.0 /
    //       (0.050 *
    //           WidgetsBinding.instance.window
    //               .devicePixelRatio), // logical pixels per second
    //   distance: 1.0 /
    //       WidgetsBinding.instance.window.devicePixelRatio, // logical pixels
    // );
    // double start = paintDxOffset;
    // ClampingScrollSimulation clampingScrollSimulation =
    //     ClampingScrollSimulation(
    //   position: start,
    //   velocity: -details.velocity.pixelsPerSecond.dx,
    //   tolerance: tolerance,
    // );
    // animationController = AnimationController(
    //   vsync: ticker!,
    //   value: 0,
    //   lowerBound: double.negativeInfinity,
    //   upperBound: double.infinity,
    // );
    // animationController!.reset();
    // animationController!.addListener(() {
    //   // scrollController.jumpTo(animationController.value);
    //   handleMove(_panScaleData!
    //     ..update(Offset(
    //       animationController!.value,
    //       _panScaleData!.offset.dy,
    //     )));
    // });
    // animationController!.animateWith(clampingScrollSimulation);

    // final clampingScrollSimulation = ClampingScrollSimulation(
    //   position: 0.0, //?
    //   velocity: details.velocity.pixelsPerSecond.dx,
    //   friction: 0.09,
    // );

    // double distanceOffset = 0;
    // animationController?.addListener(() {
    //   double tempValue = animationController?.value ?? 0.0;
    //   if (!tempValue.isInfinite && tempValue != translateX) {
    //     translateX = updateTranslate(tempValue);
    //     handleMove(_panScaleData!
    //       ..update(Offset(
    //         tempValue - distanceOffset,
    //         _panScaleData!.offset.dy,
    //       )));
    //     distanceOffset = tempValue;
    //   }
    // });

    // stateListener(status) {
    //   if (status == AnimationStatus.completed) {
    //     animationController?.removeStatusListener(stateListener);
    //   }
    // }

    // animationController?.addStatusListener(stateListener);
    // animationController?.animateWith(clampingScrollSimulation);
  }

  ///
  /// 长按
  ///
  @override
  void onLongPressStart(LongPressStartDetails details) {
    logd("onLongPressStart details:$details");
    _tapData?.end();
    _tapData = null;
    _panScaleData?.end();
    _panScaleData = null;
    _longData = GestureData.long(details.localPosition);
  }

  @override
  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_longData == null) {
      logd("onLongPressMoveUpdate details:$details");
      return;
    }
    _longData!.update(details.localPosition);
    handleLongMove(_longData!);
  }

  @override
  void onLongPressEnd(LongPressEndDetails details) {
    if (_longData == null) {
      logd("onLongPressEnd details:$details");
      return;
    }
    _longData?.end();
    _longData = null;
  }
}
