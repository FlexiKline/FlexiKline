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

part of 'indicator.dart';

/// FlexiKlineController 状态/配置/接口代理
extension IndicatorObjectExt on IndicatorObject {
  bool get isAllowUpdateHeight {
    // return _context.layoutMode is NormalLayoutMode || _context.layoutMode is AdaptLayoutMode;
    return _context.isAllowUpdateLayoutHeight;
  }

  /// Config
  SettingConfig get settingConfig => _context.settingConfig;

  GridConfig get gridConfig => _context.gridConfig;

  CrossConfig get crossConfig => _context.crossConfig;

  KlineData get klineData => _context.curKlineData;

  bool get isCrossing => _context.isCrossing;

  double get paintDxOffset => _context.paintDxOffset;

  double get startCandleDx => _context.startCandleDx;

  double get candleWidth => _context.candleWidth;

  double get candleSpacing => _context.candleSpacing;

  double get candleActualWidth => _context.candleActualWidth;

  double get candleWidthHalf => _context.candleWidthHalf;

  double get candleLineWidth => settingConfig.candleLineWidth;

  /// Theme Color
  IFlexiKlineTheme get theme => _context.theme;

  /// 全局默认的刻度值文本配置.
  TextAreaConfig get defTicksTextConfig => gridConfig.ticksText.of(
        textColor: theme.ticksTextColor,
      );

  /// 指标图 涨跌 bar/line 配置
  Color get longTintColor => longColor.withAlpha(settingConfig.opacity.alpha);
  Color get shortTintColor => shortColor.withAlpha(settingConfig.opacity.alpha);
  // 实心
  Paint get defLongBarPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get defShortBarPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  // 实心, 浅色
  Paint get defLongTintBarPaint => Paint()
    ..color = longTintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get defShortTintBarPaint => Paint()
    ..color = shortTintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  // 空心
  Paint get defLongHollowBarPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = settingConfig.candleHollowBarBorderWidth;
  Paint get defShortHollowBarPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = settingConfig.candleHollowBarBorderWidth;
  // 线
  Paint get defLongLinePaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;
  Paint get defShortLinePaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;
}

/// 绘制对象混入边界计算的通用扩展
mixin PaintObjectBoundingMixin on IndicatorObject implements IPaintBoundingBox {
  bool get drawInMain => slot == mainIndicatorSlot;
  bool get drawInSub => slot > mainIndicatorSlot;

  int _slot = mainIndicatorSlot;

  /// 当前指标所在位置索引
  /// <0 代表在主图绘制
  /// >=0 代表在副图绘制
  int get slot => _slot;

  Rect? _drawableRect;
  Rect? _chartRect;
  Rect? _topRect;
  Rect? _bottomRect;

  @nonVirtual
  @override
  void resetPaintBounding({int? slot}) {
    if (slot != null) _slot = slot;
    _drawableRect = null;
    _chartRect = null;
    _topRect = null;
    _bottomRect = null;
  }

  @override
  Rect get drawableRect {
    if (_drawableRect != null) return _drawableRect!;
    if (drawInMain) {
      _drawableRect = _context.mainRect;
    } else {
      final top = _context.calculateIndicatorTop(slot);
      final subRect = _context.subRect;
      _drawableRect = Rect.fromLTRB(
        subRect.left,
        subRect.top + top,
        subRect.right,
        subRect.top + top + height,
      );
    }
    return _drawableRect!;
  }

  @override
  Rect get topRect {
    return _topRect ??= Rect.fromLTRB(
      drawableRect.left + padding.left,
      drawableRect.top,
      drawableRect.right - padding.right,
      drawableRect.top + padding.top,
    );
  }

  @override
  Rect get bottomRect {
    return _bottomRect ??= Rect.fromLTRB(
      drawableRect.left + padding.left,
      drawableRect.bottom - padding.bottom,
      drawableRect.right - padding.right,
      drawableRect.bottom,
    );
  }

  @override
  Rect get chartRect {
    if (_chartRect != null) return _chartRect!;
    final chartBottom = bottomRect.top;
    double chartTop;
    if (paintMode == PaintMode.alone) {
      chartTop = math.max(chartBottom - height, topRect.bottom);
    } else {
      chartTop = topRect.bottom;
    }
    return _chartRect = Rect.fromLTRB(
      drawableRect.left + padding.left,
      chartTop,
      drawableRect.right - padding.right,
      chartBottom,
    );
  }

  double get chartRectWidthHalf => chartRect.width / 2;

  double clampDxInChart(double dx) => dx.clamp(
        chartRect.left,
        math.max(chartRect.left, chartRect.right),
      );
  double clampDyInChart(double dy) => dy.clamp(
        chartRect.top,
        math.max(chartRect.top, chartRect.bottom),
      );

  // Tips区域向下移动height.
  Rect shiftNextTipsRect(double height) {
    return drawableRect.shiftYAxis(height);
  }
}

/// 绘制对象混入数据初始化的通用扩展
mixin PaintObjectDataInitMixin on IndicatorObject implements IPaintDataInit {
  int? _start;
  int? _end;

  MinMax? _minMax;

  @override
  MinMax get minMax => _minMax ?? MinMax.zero;

  @override
  void setMinMax(MinMax val) {
    _minMax = val;
  }

  double? _dyFactor;
  double get dyFactor {
    if (_dyFactor != null) return _dyFactor!;
    if (chartRect.height == 0) return _dyFactor = 1;
    return _dyFactor = chartRect.height / (minMax.diffDivisor).toDouble();
  }

  double valueToDy(BagNum value, {bool correct = true}) {
    if (correct) value = value.clamp(minMax.min, minMax.max);
    return chartRect.bottom - (value - minMax.min).toDouble() * dyFactor;
  }

  BagNum? dyToValue(double dy, {bool check = true}) {
    if (check && !drawableRect.includeDy(dy)) return null;
    return minMax.max - ((dy - chartRect.top) / dyFactor).toBagNum();
  }

  double? indexToDx(num index, {bool check = true}) {
    final indexDx = index * candleActualWidth;
    double dx = chartRect.right + paintDxOffset - indexDx;
    if (!check) return dx;
    return chartRect.includeDx(dx) ? dx : null;
  }

  double dxToIndex(double dx) {
    final dxPaintOffset = chartRect.right + paintDxOffset - dx;
    return dxPaintOffset / candleActualWidth;
  }

  CandleModel? dxToCandle(double dx) {
    final index = dxToIndex(dx).toInt();
    return klineData.get(index);
  }

  CandleModel? offsetToCandle(Offset? offset) {
    if (offset != null) return dxToCandle(offset.dx);
    return null;
  }
}

/// 绘制当前图表在Y轴上的刻度值
mixin PaintYAxisTicksMixin<T extends Indicator> on PaintObject<T> {
  /// 为副区的指标图绘制Y轴上的刻度信息
  @protected
  void paintYAxisTicks(
    Canvas canvas,
    Size size, {
    required int tickCount, // 刻度数量.
    required int precision,
  }) {
    if (minMax.isZero) return;
    if (tickCount <= 0) return;

    double dyStep = 0;
    double drawTop;
    if (tickCount == 1) {
      drawTop = chartRect.top + chartRect.height / 2;
    } else {
      drawTop = chartRect.top;
      dyStep = chartRect.height / (tickCount - 1);
    }

    final dx = chartRect.right;
    double dy = 0.0;
    for (int i = 0; i < tickCount; i++) {
      dy = drawTop + i * dyStep;
      final value = dyToValue(dy);
      if (value == null) continue;

      final text = fromatTicksValue(value, precision: precision);

      final ticksText = defTicksTextConfig;

      canvas.drawTextArea(
        offset: Offset(
          dx,
          dy - ticksText.areaHeight, // 绘制在刻度线之上
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: text,
        textConfig: ticksText,
      );
    }
  }

  /// 如果要定制格式化刻度值. 在PaintObject中覆写此方法.
  @protected
  String fromatTicksValue(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      enableCompact: true,
    );
  }
}

/// 当Cross事件发生时, 在Y轴上的绘制crossing相应的刻度值
mixin PaintYAxisTicksOnCrossMixin<T extends Indicator> on PaintObject<T> {
  /// onCross时, 绘制Y轴上的刻度值
  @protected
  void paintYAxisTicksOnCross(
    Canvas canvas,
    Offset offset, {
    required int precision,
  }) {
    final value = dyToValue(offset.dy);
    if (value == null) return;

    final text = formatTicksValueOnCross(value, precision: precision);

    final ticksText = crossConfig.ticksText.of(
      textColor: theme.crossTextColor,
      background: theme.crossTextBg,
    );

    canvas.drawTextArea(
      offset: Offset(
        chartRect.right - crossConfig.spacing,
        offset.dy - ticksText.areaHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawableRect,
      text: text,
      textConfig: ticksText,
    );
  }

  @protected
  String formatTicksValueOnCross(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      enableCompact: true,
    );
  }
}

/// 绘制蜡烛图辅助Mixin
mixin PaintCandleHelperMixin<T extends Indicator> on PaintObject<T> {
  /// 主要用于SubBoll图和SubSar图中
  void paintSimpleCandleChart(
    Canvas canvas,
    Size size, {
    double? lineWidth, // 简易蜡烛线宽.
  }) {
    if (!klineData.canPaintChart) return;
    final start = klineData.start;
    final end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final barWidthHalf = candleWidthHalf;
    for (var i = start; i < end; i++) {
      paintSimpleCandleBar(
        canvas,
        klineData[i],
        dx: offset - (i - start) * candleActualWidth,
        barWidthHalf: barWidthHalf,
      );
    }
  }

  /// 绘制单根简易蜡烛柱
  void paintSimpleCandleBar(
    Canvas canvas,
    CandleModel m, {
    required double dx,
    double? high,
    double? low,
    double? open,
    double? close,
    double? barWidthHalf,
  }) {
    barWidthHalf ??= candleWidthHalf - candleSpacing;
    final isLong = m.close >= m.open;
    high ??= valueToDy(m.high);
    low ??= valueToDy(m.low);
    open ??= valueToDy(m.open);
    close ??= valueToDy(m.close);
    final barPath = Path();
    barPath.moveTo(dx, high);
    barPath.lineTo(dx, low);
    barPath.moveTo(dx - barWidthHalf, open);
    barPath.lineTo(dx, open);
    barPath.moveTo(dx + barWidthHalf, close);
    barPath.lineTo(dx, close);
    canvas.drawPath(
      barPath,
      isLong ? defLongLinePaint : defShortLinePaint,
    );
  }

  /// 绘制单根蜡烛柱(支持上涨下跌柱为空心或实心)
  /// [open], [close], [low], [high]为蜡烛[m]在当前图表中转换后的坐标值, 若不传, 则实时计算.
  /// [barWidthHalf]为蜡烛柱的宽度的一半, 若不传, 则实时计算.
  /// [longCandleUseHollow]为上涨蜡烛柱是否使用空心绘制, 默认为false.
  /// [shortCandleUseHollow]为下跌蜡烛柱是否使用空心绘制, 默认为false.
  void paintCandleBar(
    Canvas canvas,
    CandleModel m, {
    required double dx,
    double? high,
    double? low,
    double? open,
    double? close,
    double? barWidthHalf,
    bool longCandleUseHollow = false,
    bool shortCandleUseHollow = false,
  }) {
    barWidthHalf ??= candleWidthHalf - candleSpacing;
    final isLong = m.close >= m.open;
    high ??= valueToDy(m.high);
    low ??= valueToDy(m.low);
    (open, close) = ensureMinDistance(
      open ?? valueToDy(m.open),
      close ?? valueToDy(m.close),
    );
    final barPath = Path();
    barPath.moveTo(dx, high);
    if (isLong) {
      if (longCandleUseHollow) {
        barPath.lineTo(dx, close);
        barPath.addRect(Rect.fromPoints(
          Offset(dx - barWidthHalf, close),
          Offset(dx + barWidthHalf, open),
        ));
        if (low > open) {
          barPath.moveTo(dx, low);
          barPath.lineTo(dx, open);
        }
        canvas.drawPath(barPath, defLongLinePaint);
      } else {
        barPath.lineTo(dx, low);
        canvas.drawPath(barPath, defLongLinePaint);
        canvas.drawLine(
          Offset(dx, open),
          Offset(dx, close),
          defLongBarPaint,
        );
      }
    } else {
      if (shortCandleUseHollow) {
        barPath.lineTo(dx, open);
        barPath.addRect(Rect.fromPoints(
          Offset(dx - barWidthHalf, open),
          Offset(dx + barWidthHalf, close),
        ));
        if (low > close) {
          barPath.moveTo(dx, low);
          barPath.lineTo(dx, close);
        }
        canvas.drawPath(barPath, defShortHollowBarPaint);
      } else {
        barPath.lineTo(dx, low);
        canvas.drawPath(barPath, defShortLinePaint);
        canvas.drawLine(
          Offset(dx, open),
          Offset(dx, close),
          defShortBarPaint,
        );
      }
    }
  }
}

extension PaintObjectExt on PaintObject {
  /// 获取当前指标计算参数
  Map<IIndicatorKey, dynamic> getCalcParams() {
    if (calcParams != null) {
      return {key: calcParams};
    }
    return const <IIndicatorKey, dynamic>{};
  }
}

extension MultiPaintObjectExt on MainPaintObject {
  /// 收集[MainPaintObject]中子指标的计算参数
  Map<IIndicatorKey, dynamic> getCalcParams() {
    final params = <IIndicatorKey, dynamic>{};
    for (var object in children) {
      if (object.calcParams != null) {
        params[object.key] = object.calcParams;
      }
    }
    return params;
  }
}
