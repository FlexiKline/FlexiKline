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
    if (val.isInfinite && !checkOffsetInMainDraw(val)) {
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
  @protected
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
  @protected
  void handleMove(GestureData data) {
    if (!isCrossing) {
      return super.handleMove(data);
    }
    logd('handleMove cross > ${data.offset}');
    offset = data.offset;
    markRepaintCross();
  }

  @override
  void handleScale(GestureData data) {
    if (isCrossing) {
      logd('handleMove cross > ${data.offset}');
      // 注: 当前正在展示Cross, 不能缩放, 直接return拦截.
      return;
    }
    return super.handleScale(data);
  }

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

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  @protected
  void paintLastPriceMark(Canvas canvas, Size size) {
    if (!isDrawLastPriceMark) return;
    final data = curCandleData;
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
      ldx = clampDxInMain(startCandleDx - candleActualWidth);
      dy = mainDrawBottom - (model.close - data.min).toDouble() * dyFactor;
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

  void paintCrossLine(Canvas canvas, Size size) {
    if (!isCrossing) return;

    final offset = this.offset;
    if (offset == null || !checkOffsetInMainDraw(offset)) {
      return;
    }

    final path = Path()
      ..moveTo(mainDrawLeft, offset.dy)
      ..lineTo(mainDrawRight, offset.dy)
      ..moveTo(offset.dx, 0)
      ..lineTo(offset.dx, canvasHeight);

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

    if (showCrossYAxisPriceMark) {
      final val =
          curCandleData.max - ((offset.dy - mainPadding.top) / dyFactor).d;
      final text = formatPrice(
        val,
        instId: curCandleData.req.instId,
        precision: curCandleData.req.precision,
      );
      canvas.drawText(
        offset: Offset(
          mainDrawRight - crossPriceRectRigthMargin,
          offset.dy - crossPriceRectHeight / 2,
        ),
        drawDirection: DrawDirection.rtl,
        drawableSize: mainRectSize,
        text: text,
        style: crossPriceTextStyle,
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: crossPriceRectPadding,
        backgroundColor: crossPriceRectBackgroundColor,
        radius: crossPriceRectBorderRadius,
        borderWidth: crossPriceRectBorderWidth,
        borderColor: crossPriceRectBorderColor,
      );
    }

    if (showPopupCandleCard) {
      _paintPopupCandleCard(canvas, offset);
    }
  }

  /// 绘制Cross 命中的蜡烛数据弹窗
  void _paintPopupCandleCard(Canvas canvas, Offset offset) {
    final index = ((startCandleDx - offset.dx) / candleActualWidth).round();
    final model = curCandleData.getCandle(curCandleData.start + index - 1);
    logd('_paintCrossPopupWindow model:$model');
    if (model == null) return;

    /// 1. 准备数据
    // ['Time', 'Open', 'High', 'Low', 'Close', 'Chg', '%Chg', 'Amount']
    final keys = i18nCandleCardKeys;
    final keySpanList = <TextSpan>[];
    for (var i = 0; i < keys.length; i++) {
      final text = i < keys.length - 1 ? '${keys[i]}\n' : keys[i];
      keySpanList.add(TextSpan(text: text, style: candleCardTitleStyle));
    }

    final instId = curCandleData.instId;
    final p = curCandleData.precision;
    TextStyle changeStyle = candleCardTitleStyle;
    final chgrate = model.changeRate;
    if (chgrate > 0) {
      changeStyle = candleCardLongStyle;
    } else if (chgrate < 0) {
      changeStyle = candleCardShortStyle;
    }
    final valueSpan = <TextSpan>[
      TextSpan(
        text: '${formatDateTime(model.dateTime)}\n',
        style: candleCardTitleStyle,
      ),
      TextSpan(
        text: '${formatPrice(model.open, instId: instId, precision: p)}\n',
        style: candleCardTitleStyle,
      ),
      TextSpan(
        text: '${formatPrice(model.high, instId: instId, precision: p)}\n',
        style: candleCardTitleStyle,
      ),
      TextSpan(
        text: '${formatPrice(model.low, instId: instId, precision: p)}\n',
        style: candleCardTitleStyle,
      ),
      TextSpan(
        text: '${formatPrice(model.close, instId: instId, precision: p)}\n',
        style: candleCardTitleStyle,
      ),
      TextSpan(
        text: '${formatPrice(model.change, instId: instId, precision: p)}\n',
        style: changeStyle,
      ),
      TextSpan(
        text: '${formatPercentage(model.changeRate)}\n',
        style: changeStyle,
      ),
      TextSpan(
        text: model.vol.bigDecimalString,
        style: candleCardTitleStyle,
        // recognizer: _tapGestureRecognizer..onTap = () => ... // 点击事件处理?
      ),
    ];

    /// 2. 开始绘制.
    if (offset.dx > mainDrawWidthHalf) {
      // 点击区域在右边; 绘制在左边
      Offset drawOffset = Offset(
        mainDrawLeft + candleCardRectMargin.left,
        mainDrawTop + candleCardRectMargin.top,
      );

      final size = canvas.drawText(
        offset: drawOffset,
        drawDirection: DrawDirection.ltr,
        drawableSize: mainRectSize,
        textSpan: TextSpan(
          children: keySpanList,
          style: candleCardTitleStyle,
        ),
        style: candleCardTitleStyle,
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: candleCardRectPadding,
        backgroundColor: candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(candleCardRectBorderRadius),
          bottomLeft: Radius.circular(candleCardRectBorderRadius),
        ),
      );

      canvas.drawText(
        offset: Offset(
          drawOffset.dx + size.width,
          drawOffset.dy,
        ),
        drawDirection: DrawDirection.ltr,
        drawableSize: mainRectSize,
        textSpan: TextSpan(
          children: valueSpan,
          style: candleCardValueStyle,
        ),
        style: candleCardValueStyle,
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: candleCardRectPadding,
        backgroundColor: candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(candleCardRectBorderRadius),
          bottomRight: Radius.circular(candleCardRectBorderRadius),
        ),
      );
    } else {
      // 点击区域在左边; 绘制在右边
      Offset drawOffset = Offset(
        mainDrawRight - candleCardRectMargin.right,
        mainDrawTop + candleCardRectMargin.top,
      );

      final size = canvas.drawText(
        offset: drawOffset,
        drawDirection: DrawDirection.rtl,
        drawableSize: mainRectSize,
        textSpan: TextSpan(
          children: valueSpan,
          style: candleCardValueStyle,
        ),
        style: candleCardValueStyle,
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: candleCardRectPadding,
        backgroundColor: candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(candleCardRectBorderRadius),
          bottomRight: Radius.circular(candleCardRectBorderRadius),
        ),
      );

      canvas.drawText(
        offset: Offset(
          drawOffset.dx - size.width,
          drawOffset.dy,
        ),
        drawDirection: DrawDirection.rtl,
        drawableSize: mainRectSize,
        textSpan: TextSpan(
          children: keySpanList,
          style: candleCardTitleStyle,
        ),
        style: candleCardTitleStyle,
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: candleCardRectPadding,
        backgroundColor: candleCardRectBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(candleCardRectBorderRadius),
          bottomLeft: Radius.circular(candleCardRectBorderRadius),
        ),
      );
    }

    // canvas.drawRectBackground(
    //   offset: drawOffset,
    //   drawDirection: drawDirection,
    //   margin: candleCardRectMargin,
    //   drawableSize: drawableSize, // 必须矫正.
    //   size: size,
    //   backgroundColor: candleCardRectBackgroundColor,
    //   borderRadius: candleCardRectBorderRadius,
    // );
  }
}
