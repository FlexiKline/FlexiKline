// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';

import '../extension/export.dart';
import '../model/export.dart';
import '../render/export.dart';
import '../utils/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin CrossBinding
    on KlineBindingBase, SettingBinding
    implements ICross, IState {
  @override
  void initBinding() {
    super.initBinding();
    logd('init cross');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose cross');
  }

  final ValueNotifier<int> _repaintCross = ValueNotifier(0);
  @override
  Listenable get repaintCross => _repaintCross;
  void _markRepaint() => _repaintCross.value++;

  //// Cross ////
  @override
  void markRepaintCross() => _markRepaint();

  // 是否正在绘制Cross
  @override
  bool get isCrossing => offset?.isFinite == true;
  // 当前Cross焦点.
  @override
  Offset? get crossingOffset => _offset;
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
  Offset? correctCrossOffset(Offset offset) {
    if (offset.isInfinite) return null;

    if (canvasRect.contains(offset)) {
      final diff = (startCandleDx - offset.dx) % candleActualWidth;
      final dx = offset.dx + diff - candleWidthHalf;
      return Offset(dx, offset.dy);
    } else {
      return offset.clamp(canvasRect);
    }
  }

  /// 绘制最新价与十字线
  @override
  void paintCross(Canvas canvas, Size size) {
    if (isCrossing) {
      final offset = this.offset;
      if (offset == null || offset.isInfinite) {
        return;
      }

      /// 绘制Cross Line
      paintCrossLine(canvas, offset);

      if (showCrossYAxisPriceMark) {
        /// 绘制Cross Y轴价钱刻度
        paintCrossYAxisPriceMark(canvas, offset);
      }

      if (showCrossXAxisTimeMark) {
        /// 绘制Cross X轴时间刻度
        paintCrossXAxisTimeMark(canvas, offset);
      }

      if (showPopupCandleCard) {
        /// 绘制Cross 命中的蜡烛数据弹窗
        paintPopupCandleCard(canvas, offset);
      }
    }
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
    offset = data.offset;
    markRepaintCross();
  }

  @override
  @protected
  void handleScale(GestureData data) {
    if (isCrossing) {
      logd('handleMove cross > ${data.offset}');
      // 注: 当前正在展示Cross, 不能缩放, 直接return拦截.
      return;
    }
    return super.handleScale(data);
  }

  /// 绘制Cross Line
  @protected
  void paintCrossLine(Canvas canvas, Offset offset) {
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
  }

  /// 绘制Cross Y轴价钱刻度
  @protected
  void paintCrossYAxisPriceMark(Canvas canvas, Offset offset) {
    final price = offsetToPrice(offset);
    if (price == null) return;

    final text = formatPrice(
      price,
      instId: curKlineData.req.instId,
      precision: curKlineData.req.precision,
      cutInvalidZero: false,
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

  /// 绘制Cross X轴时间刻度
  @protected
  void paintCrossXAxisTimeMark(Canvas canvas, Offset offset) {
    final index = offsetToIndex(offset);
    final model = curKlineData.getCandle(index);
    final timeBar = curKlineData.timerBar;
    if (model == null || timeBar == null) return;

    // final time = model.formatDateTimeByTimeBar(timeBar);
    final time = formatDateTime(model.dateTime);

    final dyCenterOffset = (mainPadding.bottom - crossTimeRectHeight) / 2;
    canvas.drawText(
      offset: Offset(
        offset.dx,
        mainDrawBottom + dyCenterOffset,
      ),
      drawDirection: DrawDirection.center,
      // drawableSize: mainRectSize,
      text: time,
      style: crossTimeTextStyle,
      textAlign: TextAlign.center,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: crossTimeRectPadding,
      backgroundColor: crossTimeRectBackgroundColor,
      radius: crossTimeRectBorderRadius,
      borderWidth: crossTimeRectBorderWidth,
      borderColor: crossTimeRectBorderColor,
    );
  }

  /// 绘制Cross 命中的蜡烛数据弹窗
  @protected
  void paintPopupCandleCard(Canvas canvas, Offset offset) {
    final model = offsetToCandle(offset);
    final timeBar = curKlineData.timerBar;
    if (model == null || timeBar == null) return;

    /// 1. 准备数据
    // ['Time', 'Open', 'High', 'Low', 'Close', 'Chg', '%Chg', 'Amount']
    final keys = i18nCandleCardKeys;
    final keySpanList = <TextSpan>[];
    for (var i = 0; i < keys.length; i++) {
      final text = i < keys.length - 1 ? '${keys[i]}\n' : keys[i];
      keySpanList.add(TextSpan(text: text, style: candleCardTitleStyle));
    }

    final instId = curKlineData.instId;
    final p = curKlineData.precision;
    TextStyle changeStyle = candleCardTitleStyle;
    final chgrate = model.changeRate;
    if (chgrate > 0) {
      changeStyle = candleCardLongStyle;
    } else if (chgrate < 0) {
      changeStyle = candleCardShortStyle;
    }
    final valueSpan = <TextSpan>[
      TextSpan(
        text: '${model.formatDateTimeByTimeBar(timeBar)}\n',
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
        text: formatNumber(
          model.vol,
          precision: 2,
          cutInvalidZero: true,
          showCompact: true,
          prefix: 'Vol:',
        ),
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
