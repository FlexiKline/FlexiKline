import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin GestureBinding
    on KlineBindingBase, SettingBinding
    implements IGestureEvent, IDataSource {
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
  @protected
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
  @protected
  void onScaleStart(ScaleStartDetails details) {
    logd("onScaleStart localFocalPoint:${details.localFocalPoint} >>>>");

    _tapData?.end();
    _tapData = null;
    _longData?.end();
    _longData = null;
    _panScaleData = GestureData.pan(details.localFocalPoint);
  }

  @override
  @protected
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
  @protected
  void onScaleEnd(ScaleEndDetails details) {
    if (_panScaleData == null || ticker == null) {
      logd("onScaleEnd panScaledata and ticker is empty! > details:$details");
      return;
    }

    // <0: 负数代表从右向左滑动.
    // >0: 正数代表从左向右滑动.
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity == 0 ||
        curCandleData.isEmpty ||
        (velocity < 0 && !canPanRTL) ||
        (velocity > 0 && !canPanLTR)) {
      logd("onScaleEnd current not move! > details:$details");
      return;
    }

    /// 确认继续平移时间 (利用log指数函数特点: 随着自变量velocity的增大，函数值的增长速度逐渐减慢)
    /// 测试当限定参数panMaxDurationWhenPanEnd等于1000(1秒时), velocity代入变化为:
    /// 100000 > 1151.29; 10000 > 921.03; 9000 > 910.49; 5000 > 851.71; 2000 > 760.09; 800 > 668.46; 100 > 460.51
    final duration = (math.log(velocity.abs()) * panMaxDurationWhenPanEnd / 10)
        .round()
        .clamp(0, panMaxDurationWhenPanEnd);

    /// 当动画执行时每一帧继续平移的最大偏移量.
    final distance = velocity.clamp(
      -panMaxOffsetPreFrameWhenPanEnd,
      panMaxOffsetPreFrameWhenPanEnd,
    );
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
  @protected
  void onLongPressStart(LongPressStartDetails details) {
    logd("onLongPressStart details:$details");
    _tapData?.end();
    _tapData = null;
    _panScaleData?.end();
    _panScaleData = null;
    _longData = GestureData.long(details.localPosition);
  }

  @override
  @protected
  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_longData == null) {
      logd("onLongPressMoveUpdate details:$details");
      return;
    }
    _longData!.update(details.localPosition);
    handleLongMove(_longData!);
  }

  @override
  @protected
  void onLongPressEnd(LongPressEndDetails details) {
    if (_longData == null) {
      logd("onLongPressEnd details:$details");
      return;
    }
    _longData?.end();
    _longData = null;
  }
}
