import 'package:flutter/material.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';

mixin GestureBinding on KlineBindingBase
    implements ITapGesture, IPanScaleGesture, ILongPressGesture, IGestureData {
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

  AnimationController? _animationController;

  GestureData? _panScaleData; // 移动缩放监听数据
  GestureData? longData; // 长按监听数据

  ///
  /// 点击
  ///
  @override
  void onTapUp(TapUpDetails details) {
    logd("onTapUp details:$details");
  }

  ///
  /// 移动 缩放
  ///
  @override
  void onScaleStart(ScaleStartDetails details) {
    logd("onScaleStart localFocalPoint:${details.localFocalPoint} >>>>");

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

    final data = _panScaleData!;
    data.update(details.localFocalPoint, scale: details.scale);

    if (data.isScale) {
      scale(data);
    } else {
      move(data);
    }
  }

  @override
  void onScaleEnd(ScaleEndDetails details) {
    if (_panScaleData == null) return;
    logd("onScaleEnd velocity:$details <<<<");

    // ClampingScrollSimulation clampingScrollSimulation =
    //         ClampingScrollSimulation(
    //             position: widget.config.translateX,
    //             velocity: details.velocity.pixelsPerSecond.dx,
    //             friction: 0.09);
  }

  ///
  /// 长按
  ///
  @override
  void onLongPressStart(LongPressStartDetails details) {
    logd("onLongPressStart details:$details");
  }

  @override
  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    logd("onLongPressMoveUpdate details:$details");
  }

  @override
  void onLongPressEnd(LongPressEndDetails details) {
    logd("onLongPressEnd details:$details");
  }
}
