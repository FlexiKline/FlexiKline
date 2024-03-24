import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../model/export.dart';
import 'candle_data.dart';

///// Gesture  ////
/// 点击
abstract interface class ITapGesture {
  void onTapUp(TapUpDetails details);
}

/// 移动, 缩放
abstract interface class IPanScaleGesture {
  void onScaleStart(ScaleStartDetails details);
  void onScaleUpdate(ScaleUpdateDetails details);
  void onScaleEnd(ScaleEndDetails details);
}

/// 长按
abstract interface class ILongPressGesture {
  void onLongPressStart(LongPressStartDetails details);
  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details);
  void onLongPressEnd(LongPressEndDetails details);
}

/// 手势更新数据
abstract interface class IGestureData {
  void move(GestureData data);
  void scale(GestureData data);
  void longMove(GestureData data);
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

abstract interface class IDataConvert {
  String formatPrice(Decimal val, {int? precision});

  String? calculateTimeDiff(DateTime nextUpdateDateTime);
}

///// PriceOrder /////
abstract interface class IPriceOrder {
  void paintPriceOrder(Canvas canvas, Size size);

  void startLastPriceCountDownTimer();

  /// 检查最新价倒计时刷新时间是否发生变化, 如有变化, 重新启动倒时器.
  void checkAndRestartLastPriceCountDownTimer();
}
