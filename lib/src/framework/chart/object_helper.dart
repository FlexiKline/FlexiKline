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

  Color get longColor => theme.long;

  Color get shortColor => theme.short;

  /// 指标图 涨跌 bar/line 配置
  Color get longTintColor => longColor.withOpacity(settingConfig.opacity);
  Color get shortTintColor => shortColor.withOpacity(settingConfig.opacity);
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
        subRect.top + top + indicator.height,
      );
    }
    return _drawableRect!;
  }

  @override
  Rect get topRect {
    return _topRect ??= Rect.fromLTRB(
      drawableRect.left,
      drawableRect.top,
      drawableRect.right,
      drawableRect.top + padding.top,
    );
  }

  @override
  Rect get bottomRect {
    return _bottomRect ??= Rect.fromLTRB(
      drawableRect.left,
      drawableRect.bottom - padding.bottom,
      drawableRect.right,
      drawableRect.bottom,
    );
  }

  @override
  Rect get chartRect {
    if (_chartRect != null) return _chartRect!;
    final chartBottom = drawableRect.bottom - padding.bottom;
    double chartTop;
    if (indicator.paintMode == PaintMode.alone) {
      chartTop = chartBottom - indicator.height;
    } else {
      chartTop = drawableRect.top + padding.top;
    }
    return _chartRect = Rect.fromLTRB(
      drawableRect.left + padding.left,
      chartTop,
      drawableRect.right - padding.right,
      chartBottom,
    );
  }

  double get chartRectWidthHalf => chartRect.width / 2;

  double clampDxInChart(double dx) => dx.clamp(chartRect.left, chartRect.right);
  double clampDyInChart(double dy) => dy.clamp(chartRect.top, chartRect.bottom);

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
    return klineData.getCandle(index);
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
      showCompact: true,
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
      showCompact: true,
    );
  }
}

/// 绘制简易蜡烛图
/// 主要用于SubBoll图和SubSar图中
mixin PaintSimpleCandleMixin<T extends Indicator> on PaintObject<T> {
  void paintSimpleCandleChart(
    Canvas canvas,
    Size size, {
    double? lineWidth, // 简易蜡烛线宽.
  }) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;

    CandleModel m;
    for (var i = start; i < end; i++) {
      m = list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = m.close >= m.open;

      final linePaint = isLong ? defLongLinePaint : defShortLinePaint;

      if (lineWidth != null) linePaint.strokeWidth = lineWidth;

      final highOff = Offset(dx, valueToDy(m.high));
      final lowOff = Offset(dx, valueToDy(m.low));

      canvas.drawLine(
        highOff,
        lowOff,
        linePaint,
      );

      final openDy = valueToDy(m.open);
      canvas.drawLine(
        Offset(dx - candleWidthHalf, openDy),
        Offset(dx, openDy),
        linePaint,
      );

      final closeDy = valueToDy(m.close);
      canvas.drawLine(
        Offset(dx, closeDy),
        Offset(dx + candleWidthHalf, closeDy),
        linePaint,
      );
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
