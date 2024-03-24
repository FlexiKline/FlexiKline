import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:kline/src/model/export.dart';

import '../utils/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';
import '../extension/export.dart';
import '../render/export.dart';

/// 绘制蜡烛图以及相关指标数据
///   Canvas 布局参数图
///                      mainRectWidth
///   |------------------mainRect.top-----------------------|
///   |------------------mainPadding.top--------------------|
///   |mainPadding.left---+----------------mainPadding.right|
///   |   |---------------+canvasWidth------------------|   |
///   |-------------------+------------------canvasRight|   |
///   |mainRectHeight     |canvasHeight                     |
///   |                   |                                 |
///   |canvasBottom------mainPadding.bottom-----------------|
///   |------------------mainRect.bottom--------------------|
mixin CandleBinding
    on KlineBindingBase, SettingBinding
    implements ICandlePainter, IDataSource {
  @override
  void initBinding() {
    super.initBinding();
    logd('init candle');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose candle');

    _lastPriceCountDownTimer?.cancel();
  }

  /// 触发重绘蜡烛线.
  @override
  void markRepaintCandle() => repaintCandle.value++;
  ValueNotifier<int> repaintCandle = ValueNotifier(0);

  @override
  void paintCandle(Canvas canvas, Size size) {
    /// 绘制Grid
    paintGrid(canvas, size);

    /// 绘制蜡烛图
    paintCandleChart(canvas, size);

    /// 绘制X轴刻度数据
    printXAisTickData(canvas, size);

    /// 绘制最新价刻度线与价钱标记
    paintLastPriceMark(canvas, size);
  }

  /// 绘制蜡烛图
  void paintCandleChart(Canvas canvas, Size size) {
    final data = curCandleData;
    int start = data.start;
    int end = data.end;

    final offset = canvasRight - data.offset - candleMargin + candleWidthHalf;

    Offset? maxHihgOffset, minLowOffset;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isRise = model.close >= model.open;
      final highOff = Offset(
        dx,
        canvasBottom - (model.high - data.min).toDouble() * dyFactor,
      );
      final lowOff = Offset(
        dx,
        canvasBottom - (model.low - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        highOff,
        lowOff,
        isRise ? riseLinePaint : downLinePaint,
      );
      final openOff = Offset(
        dx,
        canvasBottom - (model.open - data.min).toDouble() * dyFactor,
      );
      final closeOff = Offset(
        dx,
        canvasBottom - (model.close - data.min).toDouble() * dyFactor,
      );
      canvas.drawLine(
        openOff,
        closeOff,
        isRise ? riseBoldPaint : downBoldPaint,
      );

      if (isDrawPriceMark) {
        // 记录最大最小偏移量.
        if (model.high == data.max) {
          maxHihgOffset = highOff;
        }
        if (model.low == data.min) {
          minLowOffset = lowOff;
        }
      }
    }

    // 最后绘制在蜡烛图中的最大最小价钱标记
    if (isDrawPriceMark && maxHihgOffset != null && minLowOffset != null) {
      paintPriceMark(canvas, maxHihgOffset, data.max);
      paintPriceMark(canvas, minLowOffset, data.min);
    }
  }

  /// 绘制蜡烛图上最大最小值价钱标记.
  void paintPriceMark(
    Canvas canvas,
    Offset offset,
    Decimal val,
  ) {
    final flag = offset.dx > canvasWidthHalf ? -1 : 1;
    Offset endOffset = Offset(
      offset.dx + priceMarkLineWidth * flag,
      offset.dy,
    );
    canvas.drawLine(
      offset,
      endOffset,
      priceMarkLinePaint,
    );
    endOffset = Offset(
      endOffset.dx + flag * priceMarkMargin,
      endOffset.dy - priceMarkFontSize / 2,
    );

    final text = formatPrice(val, instId: curCandleData.req.instId);
    canvas.drawText(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      // canvasWidth: canvasRight,
      text: text,
      style: priceMarkTextStyle,
      maxLines: 1,
    );
  }

  /// 绘制X轴刻度数据
  void printXAisTickData(Canvas canvas, Size size) {
    final data = curCandleData;
    final min = data.min;
    final yAxisStep = mainRectHeight / gridCount;
    final dx = mainRectWidth - tickTextWidth - tickTextPadding.horizontal;
    double dy = 0;
    for (int i = 1; i <= gridCount; i++) {
      dy = i * yAxisStep - tickTextFontSize;

      // final val = min.toDouble() + (i * yAxisStep - mainRect.top) / canvasHeight * data.dataHeight.toDouble();
      final val = min + ((i * yAxisStep - mainRect.top) / dyFactor).d;
      final text = formatPrice(val, instId: curCandleData.req.instId);

      canvas.drawText(
        offset: Offset(dx, dy),
        drawableSize: drawableSize,
        text: text,
        style: tickTextStyle,
        textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: tickTextPadding,
        maxLines: 1,
      );
    }
  }

  /// 绘制Grid
  void paintGrid(Canvas canvas, Size size) {
    final yAxisStep = mainRectWidth / gridCount;
    final xAxisStep = mainRectHeight / gridCount;
    final paintX = gridXAxisLinePaint;
    final paintY = gridYAxisLinePaint;
    double dx = 0;
    double dy = 0;
    canvas.drawLine(
      Offset(0, dy),
      Offset(mainRectWidth, dy),
      paintX,
    );
    for (int i = 1; i < gridCount; i++) {
      dx = i * yAxisStep;
      dy = i * xAxisStep;
      // 绘制xAsix线
      canvas.drawLine(
        Offset(0, dy),
        Offset(mainRectWidth, dy),
        paintX,
      );
      // 绘制YAsix线
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, mainRectHeight),
        paintY,
      );
    }
    canvas.drawLine(
      Offset(0, mainRectHeight),
      Offset(mainRectWidth, mainRectHeight),
      paintX,
    );
  }

  //// 以下是最新价绘制逻辑.(暂)

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

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLastPriceMark(Canvas canvas, Size size) {
    if (!isDrawLastPriceMark) return;
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
    String text = formatPrice(model.close, instId: curCandleData.req.instId);
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
