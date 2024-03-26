import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kline/src/extension/export.dart';

import '../model/export.dart';
import '../render/export.dart';
import '../utils/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin PriceCrossBinding
    on KlineBindingBase, SettingBinding
    implements IPriceCrossPainter, IDataSource {
  @override
  void initBinding() {
    super.initBinding();
    logd('init priceOrder');
    startLastPriceCountDownTimer();
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose priceOrder');
    _lastPriceCountDownTimer?.cancel();
    _lastPriceCountDownTimer = null;
  }

  ValueNotifier<int> repaintPriceCross = ValueNotifier(0);
  void _markRepaint() => repaintPriceCross.value++;

  //// Last Price ////
  @override
  void markRepaintLastPrice() => _markRepaint();
  Timer? _lastPriceCountDownTimer;

  //// Cross ////
  @override
  void markRepaintCross() => _markRepaint();
  // 是否正在绘制Cross
  @override
  bool get isCrossing => offset?.isFinite == true;
  // 当前Cross焦点.
  Offset? _offset;
  Offset? get offset => _offset;
  set offset(Offset? val) {
    if (val != null) {
      _offset = correctCrossOffset(val);
    } else {
      _offset = null;
    }
  }

  /// 矫正Cross
  Offset? correctCrossOffset(Offset val) {
    if (val.isInfinite && !checkOffsetInCanvas(val)) {
      return null;
    }
    final startDx = startCandleDx;
    final index = ((startDx - val.dx) / candleActualWidth).round();
    final dx = startDx - index * candleActualWidth;
    return Offset(dx, val.dy);
  }

  /// 绘制最新价与十字线
  @override
  void paintPriceCross(Canvas canvas, Size size) {
    /// 绘制最新价刻度线与价钱标记
    paintLastPriceMark(canvas, size);

    /// 绘制Cross
    paintCrossLine(canvas, size);
  }

  @override
  bool handleTap(GestureData data) {
    if (isCrossing) {
      offset = null;
      markRepaintCross();
      return super.handleTap(data); // 不处理, 向上传递事件.
    }
    logd('handleTap cross > ${data.offset}');
    // 更新并校正起始焦点.
    offset = data.offset;
    markRepaintCross();
    return true;
  }

  @override
  void handleMove(GestureData data) {
    if (!isCrossing) {
      return super.handleMove(data);
    }
    logd('handleMove cross > ${data.offset}');
    offset = data.offset;
    markRepaintCross();
  }

  @override
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

    double dx = canvasRight;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.
    double dy;
    double flag = -1; // 计算右边最新价钱文本时, dy增减的方向
    if (model.close >= data.max) {
      dy = canvasTop; // 画板顶部展示.
    } else if (model.close <= data.min) {
      dy = canvasBottom; // 画板底部展示.
      flag = 1;
    } else {
      // 计算最新价在当前画板中的X轴位置.
      ldx = clampDxInCanvas(startCandleDx - candleActualWidth);
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
    String text = formatPrice(
      model.close,
      instId: curCandleData.req.instId,
      precision: curCandleData.req.precision,
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

  void paintCrossLine(Canvas canvas, Size size) {
    if (!isCrossing) return;

    final offset = this.offset;
    if (offset == null || !checkOffsetInCanvas(offset)) {
      return;
    }

    final path = Path()
      ..moveTo(canvasLeft, offset.dy)
      ..lineTo(canvasRight, offset.dy)
      ..moveTo(offset.dx, 0)
      ..lineTo(offset.dx, mainRectHeight);

    canvas
      ..drawDashPath(
        path,
        crossLinePaint,
        dashes: crossLineDashes,
      )
      ..drawCircle(
        offset,
        crossPointRadius,
        crossPointPaint,
      );

    if (isDrawCrossPriceMark) {
      final val =
          curCandleData.max - ((offset.dy - mainPadding.top) / dyFactor).d;
      final text = formatPrice(
        val,
        instId: curCandleData.req.instId,
        precision: curCandleData.req.precision,
      );
      canvas.drawText(
        offset: Offset(
          canvasRight,
          offset.dy - crossPriceRectHeight / 2,
        ),
        drawDirection: DrawDirection.ltr,
        margin: crossPriceRectMargin,
        drawableSize: drawableSize,
        text: text,
        style: crossPriceTextStyle,
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: crossPriceRectPadding,
        backgroundColor: crossPriceRectBackgroundColor,
        borderRadius: crossPriceRectBorderRadius,
        borderWidth: crossPriceRectBorderWidth,
        borderColor: crossPriceRectBorderColor,
      );
    }
  }
}
