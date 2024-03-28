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
    if (_panScaleData == null || ticker == null) {
      logd("onScaleEnd panScaledata and ticker is empty! > details:$details");
      return;
    }

    // <0: 负数代表从右向左滑动.
    // >0: 正数代表从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;
    final data = curCandleData;
    final len = data.list.length;
    if (len <= 0 ||
        (velocity < 0 && data.start == 0) ||
        (velocity > 0 && data.end >= len - 1)) {
      // TODO: 待优化
      logd("onScaleEnd current not move! > details:$details");
      return;
    }

    final duration = (velocity / 1.7).abs().round().clamp(0, 1000);
    final distance = (velocity * 0.125).clamp(-20.0, 20.0); // TODO: 待优化.
    logd(
      'onScaleEnd >>> velocity:${details.velocity.pixelsPerSecond.dx} duration:$duration, distance:$distance, curOffset:${_panScaleData!.offset.dx}',
    );
    animationController?.dispose();
    animationController = AnimationController(
      value: 0,
      vsync: ticker!,
      duration: Duration(milliseconds: duration),
    );
    Animation<double> curve = CurvedAnimation(
      parent: animationController!,
      curve: Curves.decelerate,
    );
    Animation<double> animation = Tween<double>(
      begin: distance,
      end: 0,
    ).animate(curve);
    animation.addListener(() {
      // logd('onScaleEnd val:${animation.value}');
      _panScaleData!.update(Offset(
        _panScaleData!.offset.dx + animation.value,
        _panScaleData!.offset.dy,
      ));
      handleMove(_panScaleData!);
    });
    animationController!.forward();
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
