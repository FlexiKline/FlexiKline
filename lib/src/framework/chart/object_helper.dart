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

  GestureConfig get gestureConfig => _context.gestureConfig;

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
  TextAreaConfig get defTicksTextConfig => gridConfig.ticksText;

  /// 指标图 涨跌 bar/line 配置
  /// 涨跌浅色
  Color get longTintColor => longColor.withAlpha(settingConfig.opacity.alpha);
  Color get shortTintColor => shortColor.withAlpha(settingConfig.opacity.alpha);

  /// 涨跌色实心柱画笔
  Paint get defLongBarPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get defShortBarPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;

  /// 涨跌浅色实心柱画笔
  Paint get defLongTintBarPaint => Paint()
    ..color = longTintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;
  Paint get defShortTintBarPaint => Paint()
    ..color = shortTintColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleWidth;

  /// 涨跌色空心柱画笔
  Paint get defLongHollowBarPaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = settingConfig.candleHollowBarBorderWidth;
  Paint get defShortHollowBarPaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = settingConfig.candleHollowBarBorderWidth;

  /// 涨跌色线画笔
  Paint get defLongLinePaint => Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;
  Paint get defShortLinePaint => Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;

  /// 定制线画笔
  Paint getLinePaint({Color? color, double? strokeWidth}) => Paint()
    ..color = color ?? theme.lineChartColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth ?? candleLineWidth;
}

/// 绘制对象混入边界计算的通用扩展
mixin PaintObjectBoundingMixin<T extends Indicator<IIndicatorKey>> on IndicatorObject<T> implements IPaintBounding {
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

/// 绘制对象混入状态管理的通用扩展
///
/// 提供 minMax 管理、坐标转换等功能。
mixin PaintObjectStateMixin<T extends Indicator<IIndicatorKey>> on IndicatorObject<T> implements IPaintState {
  int? _start;
  int? _end;

  MinMax? _minMax;

  /// 用于平移过程中 Y 轴边界平滑过渡的缓存
  MinMax? _smoothMinMax;

  @override
  MinMax get minMax => _minMax ?? MinMax.zero;

  @override
  void setMinMax(MinMax val) {
    if (val.isSame) val.expandByRatios(settingConfig.expandRatiosOfSameMinmax);
    _minMax = val;
    _dyFactor = null;
  }

  /// 对 minMax 做平滑插值, 减少平移过程中 Y 轴坐标系的跳变
  /// [smoothFactor] 控制平滑程度: 值越小越平滑(但响应越慢), 建议 0.1~0.25
  /// 当 factor=1.0 时, lerp 直接返回精确值, 无需特殊处理
  void smoothMinMax({double smoothFactor = 1.0}) {
    if (_minMax == null) return;
    if (smoothFactor >= 1.0) {
      _smoothMinMax = null;
    } else {
      _smoothMinMax = MinMax.lerp(_smoothMinMax ?? _minMax!, _minMax!, smoothFactor);
      setMinMax(_smoothMinMax!);
    }
  }

  double? _dyFactor;
  @override
  double get dyFactor {
    if (_dyFactor != null) return _dyFactor!;
    if (chartRect.height == 0) return _dyFactor = 1;
    return _dyFactor = chartRect.height / minMax.diffDivisor.toDouble();
  }

  double valueToDy(FlexiNum value, {bool correct = true}) {
    if (correct) value = value.clamp(minMax.min, minMax.max);
    return chartRect.bottom - (value - minMax.min).toDouble() * dyFactor;
  }

  FlexiNum? dyToValue(double dy, {bool check = true}) {
    if (check && !drawableRect.includeDy(dy)) return null;
    return minMax.max - ((dy - chartRect.top) / dyFactor).toFlexiNum();
  }

  double? indexToDx(num index, {bool check = true}) {
    final indexDx = index * candleActualWidth;
    final dx = chartRect.right + paintDxOffset - indexDx;
    if (!check) return dx;
    return chartRect.includeDx(dx) ? dx : null;
  }

  double? tsToDx(int ts, {bool check = true}) {
    final index = klineData.tsToIndex(ts);
    if (index == null) return null;
    return indexToDx(index, check: check);
  }

  double dxToIndex(double dx) {
    final dxPaintOffset = chartRect.right + paintDxOffset - dx;
    return dxPaintOffset / candleActualWidth;
  }

  FlexiCandleModel? dxToCandle(double dx) {
    final index = dxToIndex(dx).toInt();
    return klineData.get(index);
  }

  FlexiCandleModel? offsetToCandle(Offset? offset) {
    if (offset != null) return dxToCandle(offset.dx);
    return null;
  }

  double valueToDyOnCandle(FlexiNum value, {bool correct = false}) {
    return _context.valueToDyOnCandle(value, correct: correct);
  }

  FlexiNum? dyToValueOnCandle(double dy, {bool check = false}) {
    return _context.dyToValueOnCandle(dy, check: check);
  }

  @override
  MinMax? initState(int start, int end) {
    // 默认实现返回 null，表示使用当前 minMax
    // 子类可以 override 此方法提供自定义实现
    return null;
  }
}

/// 绘制对象混入数据预计算的扩展
///
/// 提供数据预计算能力，仅用于 DataPaintObject。
mixin PaintObjectComputableMixin<T extends DataIndicator> on PaintObject<T> {
  /// 判断是否需要重新预计算
  ///
  /// 当指标配置参数发生变化时，判断是否需要重新计算。
  bool shouldPrecompute(covariant T oldIndicator) {
    return oldIndicator.calcParam != indicator.calcParam && indicator.calcParam != null;
  }

  /// 数据预计算（空实现，供子类 override）
  void precompute(Range range, {bool reset = false}) {
    // 空实现
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

      final text = formatTicksValue(value, precision: precision);

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
        themeTextColor: theme.ticksTextColor,
      );
    }
  }

  /// 如果要定制格式化刻度值. 在PaintObject中覆写此方法.
  @protected
  String formatTicksValue(FlexiNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      cutInvalidZero: false,
      defIfZero: '0.00',
    );
  }
}

/// 当Cross事件发生时, 在Y轴上的绘制crossing相应的刻度值
mixin PaintYAxisTicksOnCrossMixin<T extends Indicator> on PaintObject<T> {
  /// onCross时, 绘制Y轴上的刻度值
  @protected
  Size? paintYAxisTicksOnCross(
    Canvas canvas,
    Offset offset, {
    required int precision,
    Color? textColor,
    Color? bgColor,
    Color? borderColor,
  }) {
    final value = dyToValue(offset.dy);
    if (value == null) return null;

    final text = formatTicksValueOnCross(value, precision: precision);

    final ticksText = crossConfig.ticksText;

    return canvas.drawTextArea(
      offset: Offset(
        chartRect.right - crossConfig.spacing,
        offset.dy - ticksText.areaHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawableRect,
      text: text,
      textConfig: ticksText,
      themeTextColor: textColor ?? theme.crossTextColor,
      themeBackgroundColor: bgColor ?? theme.crossTextBg,
      themeBorderColor: borderColor,
    );
  }

  @protected
  String formatTicksValueOnCross(FlexiNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      cutInvalidZero: false,
      defIfZero: '0.00',
    );
  }
}

/// 绘制蜡烛图辅助Mixin
mixin PaintCandleHelperMixin<T extends Indicator> on PaintObject<T> {
  /// 绘制Open-high-low-close样式的蜡烛图(美国线图)
  /// 主区: 蜡烛图
  /// 副区: 用于SubBoll图和SubSar图中
  void paintOHPLStyleCandleChart(
    Canvas canvas, {
    int? start,
    int? end,
    double? startOffset, // 起始偏移量.
  }) {
    if (!klineData.canPaintChart) return;
    start ??= klineData.start;
    end ??= (klineData.end + 1).clamp(start, klineData.length); // 多绘制一根蜡烛;
    startOffset ??= startCandleDx - candleWidthHalf;
    final barWidthHalf = candleWidthHalf;
    for (var i = start; i < end; i++) {
      paintCandleBar(
        canvas,
        klineData[i],
        dx: startOffset - (i - start) * candleActualWidth,
        barWidthHalf: barWidthHalf,
        chartStyle: ChartBarStyle.ohlc,
      );
    }
  }

  /// 绘制单根蜡烛柱(支持上涨下跌柱为空心或实心)
  /// [open], [close], [low], [high]为蜡烛[m]在当前图表中转换后的坐标值, 若不传, 则实时计算.
  /// [barWidthHalf]为蜡烛柱的宽度的一半, 若不传, 则实时计算.
  /// [chartStyle]为蜡烛柱的样式, 支持: ohlcChart, upHollow, downHollow
  void paintCandleBar(
    Canvas canvas,
    FlexiCandleModel m, {
    required double dx,
    double? high,
    double? low,
    double? open,
    double? close,
    double? barWidthHalf,
    required ChartBarStyle chartStyle,
  }) {
    barWidthHalf ??= candleWidthHalf - candleSpacing;
    final isLong = m.close >= m.open;
    high ??= valueToDy(m.high);
    low ??= valueToDy(m.low);
    (open, close) = ensureMinDistance(
      open ?? valueToDy(m.open),
      close ?? valueToDy(m.close),
    );

    final path = Path()..moveTo(dx, high);
    if (chartStyle == ChartBarStyle.ohlc) {
      path.moveTo(dx, high);
      path.lineTo(dx, low);
      path.moveTo(dx - barWidthHalf, open);
      path.lineTo(dx, open);
      path.moveTo(dx + barWidthHalf, close);
      path.lineTo(dx, close);
      canvas.drawPath(path, isLong ? defLongLinePaint : defShortLinePaint);
    } else if (isLong) {
      if (chartStyle.isHollowUp) {
        path.lineTo(dx, close);
        path.addRect(Rect.fromPoints(
          Offset(dx - barWidthHalf, close),
          Offset(dx + barWidthHalf, open),
        ));
        if (low > open) {
          path.moveTo(dx, low);
          path.lineTo(dx, open);
        }
        canvas.drawPath(path, defLongLinePaint);
      } else {
        path.lineTo(dx, low);
        canvas.drawPath(path, defLongLinePaint);
        canvas.drawLine(
          Offset(dx, open),
          Offset(dx, close),
          defLongBarPaint,
        );
      }
    } else {
      if (chartStyle.isHollowDown) {
        path.lineTo(dx, open);
        path.addRect(Rect.fromPoints(
          Offset(dx - barWidthHalf, open),
          Offset(dx + barWidthHalf, close),
        ));
        if (low > close) {
          path.moveTo(dx, low);
          path.lineTo(dx, close);
        }
        canvas.drawPath(path, defShortHollowBarPaint);
      } else {
        path.lineTo(dx, low);
        canvas.drawPath(path, defShortLinePaint);
        canvas.drawLine(
          Offset(dx, open),
          Offset(dx, close),
          defShortBarPaint,
        );
      }
    }
  }

  /// 绘制基于蜡烛数据的普通折线图
  void paintCandleLineChart(
    Canvas canvas, {
    int? start,
    int? end,
    double? startOffset, // 起始偏移量.
    required Paint linePaint, // 蜡烛线图画笔.
    LinearGradient? gradient, // 线图渐变.
  }) {
    if (!klineData.canPaintChart) return;
    start ??= klineData.start;
    end ??= (klineData.end + 1).clamp(start, klineData.length); // 多绘制一根蜡烛;
    startOffset ??= startCandleDx - candleWidthHalf;

    final points = <Offset>[];
    FlexiCandleModel m;
    for (var i = start; i < end; i++) {
      m = klineData[i];
      points.add(Offset(
        startOffset - (i - start) * candleActualWidth,
        valueToDy(m.close, correct: false),
      ));
    }

    // 默认策略：填充到底部
    paintLineChart(
      canvas,
      points: points,
      boundEnd: Offset(points.last.dx, chartRect.bottom),
      boundStart: Offset(points.first.dx, chartRect.bottom),
      linePaint: linePaint,
      shader: gradient,
    );
  }

  @protected
  void paintLineChart(
    Canvas canvas, {
    required List<Offset> points, // 绘制线
    required Paint linePaint, // 蜡烛线图画笔.
    Offset? boundEnd, // 边界结束坐标
    Offset? boundStart, // 边界起始坐标
    LinearGradient? shader, // 阴影配置.
  }) {
    canvas.drawPath(
      Path()..addPolygon(points, false),
      linePaint,
    );
    if (boundEnd != null && boundStart != null && shader != null) {
      points.add(boundEnd);
      points.add(boundStart);
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(
        path,
        Paint()..shader = shader.createShader(path.getBounds()),
      );
    }
  }

  /// 绘制基于蜡烛数据的涨跌线图
  void paintCandleUpDownLineChart(
    Canvas canvas, {
    int? start,
    int? end,
    double? startOffset, // 起始偏移量.
    required Paint longLinePaint, // 上涨线图画笔.
    required Paint shortLinePaint, // 下跌线图画笔.
    LinearGradient? longGradient, // 上涨渐变.
    LinearGradient? shortGradient, // 下跌渐变.
  }) {
    if (!klineData.canPaintChart) return;
    start ??= klineData.start;
    end ??= (klineData.end + 1).clamp(start, klineData.length); // 多绘制一根蜡烛;
    startOffset ??= startCandleDx - candleWidthHalf;

    final latestDy = valueToDy(klineData.latest!.close, correct: false);

    // 默认策略：使用最新价作为基准线
    Offset boundStart, boundEnd, prev, point;
    boundStart = Offset(startOffset.clamp(chartRect.left, chartRect.right), latestDy);
    prev = point = Offset(startOffset, valueToDy(klineData[start].close, correct: false));
    final points = [point];
    bool isLong = point.dy <= latestDy;
    for (var i = start + 1; i <= end; i++) {
      if (i < end) {
        point = Offset(
          startOffset - (i - start) * candleActualWidth,
          valueToDy(klineData[i].close, correct: false),
        );
      }
      if (point.dy <= latestDy != isLong || i == end) {
        if (point.dy <= latestDy != isLong) {
          boundEnd = latestDy.offsetWithDyOnAB(prev, point);
          points.add(boundEnd);
        } else {
          points.add(point);
          boundEnd = Offset(point.dx, boundStart.dy);
        }
        if (isLong) {
          // 绘制上涨区间的线图
          paintLineChart(
            canvas,
            points: points,
            boundEnd: boundEnd,
            boundStart: boundStart,
            linePaint: longLinePaint,
            shader: longGradient,
          );
        } else {
          // 绘制下跌区间的线图
          paintLineChart(
            canvas,
            points: points,
            boundEnd: boundEnd,
            boundStart: boundStart,
            linePaint: shortLinePaint,
            shader: shortGradient,
          );
        }
        isLong = !isLong;
        boundStart = boundEnd;
        points.clear();
        points.add(boundEnd);
      }
      points.add(point);
      prev = point;
    }
  }
}

// extension PaintObjectExt on PaintObject {
//   /// 获取当前指标计算参数
//   Map<IIndicatorKey, dynamic> getCalcParams() {
//     if (calcParams != null) {
//       return {key: calcParams};
//     }
//     return const <IIndicatorKey, dynamic>{};
//   }
// }

// extension MultiPaintObjectExt on MainPaintObject {
//   /// 收集[MainPaintObject]中子指标的计算参数
//   Map<IIndicatorKey, dynamic> getCalcParams() {
//     final params = <IIndicatorKey, dynamic>{};
//     for (final object in children) {
//       if (object.calcParams != null) {
//         params[object.key] = object.calcParams;
//       }
//     }
//     return params;
//   }
// }
