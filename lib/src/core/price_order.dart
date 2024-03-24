import 'dart:async';

import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';
import '../model/export.dart';
import '../render/export.dart';

mixin PriceOrderBinding
    on KlineBindingBase, SettingBinding
    implements IPriceOrder, IDataSource, IDataConvert {
  @override
  void initBinding() {
    super.initBinding();
    logd('init priceOrder');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose priceOrder');
    _lastPriceCountDownTimer?.cancel();
  }

  CandleModel? _oldLastPriceModel;
  int _lastPriceRefreshSceonds = 1;
  Timer? _lastPriceCountDownTimer;
  ValueNotifier<int> repaintPriceOrder = ValueNotifier(0);
  // 重新绘制最新价, 或订单信息.
  void markRepaintPriceOrder() => repaintPriceOrder.value++;

  int calcuateRefreshIntervalTime() {
    int refreshIntervalSeconds = -1;
    final nextUpdateDateTime = curCandleData.nextUpdateDateTime;
    if (nextUpdateDateTime != null) {
      final timeLag = nextUpdateDateTime.difference(DateTime.now());
      if (!timeLag.isNegative) {
        final dayLag = timeLag.inDays;
        if (dayLag >= 1) {
          // 如果间隔时间大于一天, 则每小时刷新下.
          refreshIntervalSeconds = Duration.secondsPerHour;
        } else {
          // 如果小于一天, 则每秒刷新下.
          refreshIntervalSeconds = 1;
        }
      }
    }
    return refreshIntervalSeconds;
  }

  /// 检查最新价倒计时刷新时间是否发生变化, 如有变化, 重新启动倒时器.
  @override
  void checkAndRestartLastPriceCountDownTimer() {
    if (_oldLastPriceModel != curCandleData.latest) {
      markRepaintPriceOrder();
    }
    final newVal = calcuateRefreshIntervalTime();
    if (newVal != _lastPriceRefreshSceonds) {
      startLastPriceCountDownTimer();
    }
  }

  @override
  void startLastPriceCountDownTimer() {
    _lastPriceCountDownTimer?.cancel();
    _lastPriceRefreshSceonds = calcuateRefreshIntervalTime();
    if (_lastPriceRefreshSceonds > 0) {
      markRepaintPriceOrder();
      _lastPriceCountDownTimer = Timer.periodic(
        Duration(seconds: _lastPriceRefreshSceonds),
        (timer) => markRepaintPriceOrder(),
      );
    }
  }

  @override
  void paintPriceOrder(Canvas canvas, Size size) {
    if (isDrawLastPriceMark) {
      /// 绘制最新价刻度线与价钱标记
      paintLastPriceMark(canvas, size);
    }
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLastPriceMark(Canvas canvas, Size size) {
    final data = curCandleData;
    final model = data.latest;
    if (model == null) {
      logd('paintLastPriceMark > on data!');
      return;
    }

    _oldLastPriceModel = model;

    double dx = canvasRight;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.
    double dy;
    double flag = -1; // 计算右边最新价钱文本时, dy增减的方向
    if (model.close > data.max) {
      dy = canvasTop; // 画板顶部展示.
    } else if (model.close < data.min) {
      dy = canvasBottom; // 画板底部展示.
      flag = 1;
    } else {
      // 计算最新价在当前画板中的X轴位置.
      ldx = canvasRight - data.offset - candleMargin + candleWidthHalf;
      dy = canvasBottom - (model.close - data.min).toDouble() * dyFactor;
    }

    // 画最新价在画板中的刻度线.
    final path = Path();
    path.moveTo(dx, dy);
    path.lineTo(ldx, dy);
    canvas.drawDashPath(
      path,
      lastPriceMarkLinePaint,
      dashes: lastPriceMarkLineDashes,
    );

    // 画最新价文本区域.
    double textHeight = lastPriceRectPadding.vertical + lastPriceFontSize;
    String text = formatPrice(model.close);
    if (showLastPriceUpdateTime) {
      final nextUpdateDateTime = model.nextUpdateDateTime(data.req.bar);
      // logd(
      //   'paintLastPriceMark lastModelTime:${model.dateTime}, nextUpdateDateTime:$nextUpdateDateTime',
      // );
      if (nextUpdateDateTime != null) {
        final timeDiff = calculateTimeDiff(nextUpdateDateTime);
        if (timeDiff != null) {
          text += "\n$timeDiff";
          textHeight += lastPriceFontSize;
        }
      }
    }
    canvas.drawText(
      offset: Offset(
        dx,
        dy + flag * textHeight / 2, // 计算最新价文本区域相对于刻度线的位置
      ),
      drawDirection: DrawDirection.ltr,
      margin: lastPriceRectMargin,
      drawableSize: drawableSize,
      text: text,
      style: lastPriceTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: lastPriceRectPadding,
      backgroundColor: lastPriceRectBackgroundColor,
      borderRadius: lastPriceRectBorderRadius,
      borderWidth: lastPriceRectBorderWidth,
      borderColor: lastPriceRectBorderColor,
    );
  }
}
