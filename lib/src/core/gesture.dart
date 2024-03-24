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

    if (_panScaleData!.isScale) {
      scale(_panScaleData!);
    } else {
      move(_panScaleData!);
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
    longMove(_longData!);
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
