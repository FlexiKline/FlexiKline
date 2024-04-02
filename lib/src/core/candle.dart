import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../constant.dart';
import '../model/export.dart';
import '../render/export.dart';
import '../utils/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 绘制蜡烛图以及相关指标数据
mixin CandleBinding
    on KlineBindingBase, SettingBinding
    implements ICandle, IState {
  @override
  void initBinding() {
    super.initBinding();
    logd('init candle');
    startLastPriceCountDownTimer();
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose candle');
    _lastPriceCountDownTimer?.cancel();
    _lastPriceCountDownTimer = null;
  }

  final ValueNotifier<int> _repaintCandle = ValueNotifier(0);
  @override
  Listenable get repaintCandle => _repaintCandle;
  void _markRepaint() => _repaintCandle.value++;

  //// Last Price ////
  Timer? _lastPriceCountDownTimer;
  @override
  @protected
  void markRepaintLastPrice() => _markRepaint();

  /// 触发重绘蜡烛线.
  @override
  @protected
  void markRepaintCandle() => _markRepaint();

  @override
  @protected
  void startLastPriceCountDownTimer() {
    _lastPriceCountDownTimer?.cancel();
    markRepaintLastPrice();
    _lastPriceCountDownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        markRepaintLastPrice();
      },
    );
  }

  DateTime? _lastPaintTime;
  int get diffTime {
    // 计算两次绘制时间差
    return _lastPaintTime
            ?.difference(_lastPaintTime = DateTime.now())
            .inMilliseconds
            .abs() ??
        0;
  }

  @override
  void paintCandle(Canvas canvas, Size size) {
    logd('$diffTime paintCandle >>>>');

    calculateCandleIndexAndOffset();

    // canvas.drawPoints(
    //   PointMode.points,
    //   [Offset(startCandleDx, 100)],
    //   Paint()
    //     ..color = Colors.blue
    //     ..strokeWidth = 2
    //     ..style = PaintingStyle.stroke,
    // );

    /// 绘制蜡烛图
    paintCandleChart(canvas, size);

    /// 绘制Y轴价钱刻度数据
    paintYAxisPriceTick(canvas, size);

    /// 绘制X轴时间刻度数据. 在paintCandleChart调用
    // paintXAxisTimeTick(canvas);

    /// 绘制最新价刻度线与价钱标记
    paintLastPriceMark(canvas, size);
  }

  /// 绘制蜡烛图
  @protected
  void paintCandleChart(Canvas canvas, Size size) {
    final data = curKlineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    final offset = startCandleDx;
    final bar = data.timerBar;
    Offset? maxHihgOffset, minLowOffset;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = model.close >= model.open;

      final highOff = Offset(dx, priceToDy(model.high));
      final lowOff = Offset(dx, priceToDy(model.low));
      canvas.drawLine(
        highOff,
        lowOff,
        isLong ? candleLineLongPaint : candleLineShortPaint,
      );

      final openOff = Offset(dx, priceToDy(model.open));
      final closeOff = Offset(dx, priceToDy(model.close));
      canvas.drawLine(
        openOff,
        closeOff,
        isLong ? candleBarLongPaint : candleBarShortPaint,
      );

      if (bar != null && i % timeTickIntervalCandleCounts == 0) {
        // 绘制X轴时间刻度.
        paintXAxisTimeTick(
          canvas,
          bar: bar,
          model: model,
          offset: Offset(dx, mainDrawBottom),
        );
      }

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
  @protected
  void paintPriceMark(
    Canvas canvas,
    Offset offset,
    Decimal val,
  ) {
    final flag = offset.dx > mainDrawWidthHalf ? -1 : 1;
    Offset endOffset = Offset(
      offset.dx + priceMarkLineLength * flag,
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

    final text = formatPrice(
      val,
      instId: curKlineData.req.instId,
      precision: curKlineData.req.precision,
    );
    canvas.drawText(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      text: text,
      style: priceMarkTextStyle,
      maxLines: 1,
    );
  }

  /// 绘制X轴时间刻度 (paintCandleChart遍历时触发)
  @protected
  void paintXAxisTimeTick(
    Canvas canvas, {
    required TimeBar bar,
    required CandleModel model,
    required Offset offset,
  }) {
    // final data = curKlineData;
    // if (data.list.isEmpty) return;
    // int start = data.start;
    // int end = data.end;

    // final offset = startCandleDx;
    // final bar = data.timerBar;
    // for (var i = start; i < end; i++) {
    //   final model = data.list[i];
    //   final dx = offset - (i - start) * candleActualWidth;
    //   if (bar != null && i % timeTickIntervalCandleCounts == 0) {
    //     Offset(dx, mainDrawBottom);
    // 绘制X轴时间刻度.
    canvas.drawText(
      offset: offset,
      drawDirection: DrawDirection.center,
      text: model.formatDateTimeByTimeBar(bar),
      style: timeTickStyle,
      textAlign: TextAlign.center,
      textWidth: timeTickRectWidth,
    );
    //   }
    // }
  }

  /// 绘制Y轴价钱刻度数据
  @protected
  void paintYAxisPriceTick(Canvas canvas, Size size) {
    final yAxisStep = mainDrawBottom / gridCount;
    final dx = mainDrawRight;
    double dy = 0;
    for (int i = 1; i <= gridCount; i++) {
      dy = i * yAxisStep;
      final price = dyToPrice(dy);
      if (price == null) return;

      final text = formatPrice(
        price,
        instId: curKlineData.req.instId,
        precision: curKlineData.req.precision,
      );

      canvas.drawText(
        offset: Offset(dx, dy - priceTickRectHeight),
        drawDirection: DrawDirection.rtl,
        drawableSize: mainRectSize,
        text: text,
        style: priceTickStyle,
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: priceTickRectPadding,
        maxLines: 1,
      );
    }
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  @protected
  void paintLastPriceMark(Canvas canvas, Size size) {
    if (!isDrawLastPriceMark) return;
    final data = curKlineData;
    final model = data.latest;
    if (model == null) {
      logd('paintLastPriceMark > on data!');
      return;
    }

    double dx = mainDrawRight;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.
    double dy;
    double flag = -1; // 计算右边最新价钱文本时, dy增减的方向
    if (model.close >= data.max) {
      dy = mainDrawTop; // 画板顶部展示.
    } else if (model.close <= data.min) {
      dy = mainDrawBottom; // 画板底部展示.
      flag = 1;
    } else {
      // 计算最新价在当前画板中的X轴位置.
      ldx = clampDxInMain(startCandleDx);
      dy = clampDyInMain(priceToDy(model.close));
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
    String text = formatPrice(
      model.close,
      instId: curKlineData.req.instId,
      precision: curKlineData.req.precision,
    );
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
        dx - lastPriceRectRightMargin,
        dy + flag * textHeight / 2, // 计算最新价文本区域相对于刻度线的位置
      ),
      drawDirection: DrawDirection.rtl,
      drawableSize: mainRectSize,
      text: text,
      style: lastPriceTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: lastPriceRectPadding,
      backgroundColor: lastPriceRectBackgroundColor,
      radius: lastPriceRectBorderRadius,
      borderWidth: lastPriceRectBorderWidth,
      borderColor: lastPriceRectBorderColor,
    );
  }
}
