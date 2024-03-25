import 'package:flutter/material.dart';

import '../model/export.dart';
import 'candle_data.dart';

/// Gesture 事件处理接口
abstract interface class IGestureEvent {
  /// 点击
  void onTapUp(TapUpDetails details);

  /// 移动, 缩放
  void onScaleStart(ScaleStartDetails details);
  void onScaleUpdate(ScaleUpdateDetails details);
  void onScaleEnd(ScaleEndDetails details);

  /// 长按
  void onLongPressStart(LongPressStartDetails details);
  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details);
  void onLongPressEnd(LongPressEndDetails details);
}

/// 手势事件的处理接口
/// 注: 必须首页调用super.handlexxx(); 向其他绘制模块传递手势数据.
/// 否则, 此事件的处理仅限出当前绘制模块.
/// 调用顺序参看kline_controller.dart的mixin倒序.
abstract interface class IGestureHandler {
  @mustCallSuper
  bool handleTap(GestureData data);

  @mustCallSuper
  void handleMove(GestureData data);
  @mustCallSuper
  void handleScale(GestureData data);

  @mustCallSuper
  void handleLongPress(GestureData data);
  @mustCallSuper
  void handleLongMove(GestureData data);
}

mixin GestureHanderImpl implements IGestureHandler {
  @override
  bool handleTap(GestureData data) => false;
  @override
  void handleMove(GestureData data) {}
  @override
  void handleScale(GestureData data) {}
  @override
  void handleLongPress(GestureData data) {}
  @override
  void handleLongMove(GestureData data) {}
}

//////// DataSource ///////

/// 数据源更新
abstract interface class IDataSource {
  void setCandleData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  });

  void appendCandleData(CandleReq req, List<CandleModel> list);

  CandleData get curCandleData;

  double get dyFactor;
}

//// 蜡烛图绘制接口
abstract interface class ICandlePainter {
  void paintCandle(Canvas canvas, Size size);

  void markRepaintCandle();
}

//// 最新价与十字线绘制API
abstract interface class IPriceCrossPainter {
  void paintPriceCross(Canvas canvas, Size size);
  void startLastPriceCountDownTimer();
  void markRepaintLastPrice();
  void markRepaintCross();
}
