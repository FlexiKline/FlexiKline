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

/// 常用绘制样式与画笔。
mixin PaintStyleMixin<T extends Indicator<IIndicatorKey>> on IndicatorObject<T> {
  /// 主题。
  @override
  IFlexiKlineTheme get theme => context.theme;

  /// 当前指标所使用的涨跌颜色
  Color get longColor => theme.longColor;
  Color get shortColor => theme.shortColor;

  /// 蜡烛线条宽度。
  double get candleLineWidth => settingConfig.candleLineWidth;

  /// 默认坐标轴刻度文本配置。
  TextAreaConfig get defTicksTextConfig => gridConfig.ticksText;

  /// 上涨浅色。
  Color get longTintColor => longColor.withAlpha(settingConfig.opacity.alpha);

  /// 下跌浅色。
  Color get shortTintColor => shortColor.withAlpha(settingConfig.opacity.alpha);

  // ---- 缓存画笔 ----
  // Paint 对象只在首次访问时创建，主题变化时由 [didChangeTheme] 清除。
  // 依赖 [candleWidth] 的 bar 类画笔每次访问更新 strokeWidth（一个 double 赋值），
  // 避免缩放手势期间每帧重建整个 Paint。

  Paint? _defLongBarPaint;
  Paint? _defShortBarPaint;
  Paint? _defLongTintBarPaint;
  Paint? _defShortTintBarPaint;
  Paint? _defLongHollowBarPaint;
  Paint? _defShortHollowBarPaint;
  Paint? _defLongLinePaint;
  Paint? _defShortLinePaint;

  /// 上涨实心柱画笔。
  Paint get defLongBarPaint => (_defLongBarPaint ??= Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke)
    ..strokeWidth = candleWidth;

  /// 下跌实心柱画笔。
  Paint get defShortBarPaint => (_defShortBarPaint ??= Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke)
    ..strokeWidth = candleWidth;

  /// 上涨浅色实心柱画笔。
  Paint get defLongTintBarPaint => (_defLongTintBarPaint ??= Paint()
    ..color = longTintColor
    ..style = PaintingStyle.stroke)
    ..strokeWidth = candleWidth;

  /// 下跌浅色实心柱画笔。
  Paint get defShortTintBarPaint => (_defShortTintBarPaint ??= Paint()
    ..color = shortTintColor
    ..style = PaintingStyle.stroke)
    ..strokeWidth = candleWidth;

  /// 上涨空心柱画笔。
  Paint get defLongHollowBarPaint => _defLongHollowBarPaint ??= Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = settingConfig.candleHollowBarBorderWidth;

  /// 下跌空心柱画笔。
  Paint get defShortHollowBarPaint => _defShortHollowBarPaint ??= Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = settingConfig.candleHollowBarBorderWidth;

  /// 上涨线条画笔。
  Paint get defLongLinePaint => _defLongLinePaint ??= Paint()
    ..color = longColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;

  /// 下跌线条画笔。
  Paint get defShortLinePaint => _defShortLinePaint ??= Paint()
    ..color = shortColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = candleLineWidth;

  /// 创建自定义线条画笔（不缓存：参数由调用方传入）。
  Paint getLinePaint({Color? color, double? strokeWidth}) => Paint()
    ..color = color ?? theme.lineChartColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth ?? candleLineWidth;

  @override
  void didChangeTheme() {
    super.didChangeTheme();
    _defLongBarPaint = null;
    _defShortBarPaint = null;
    _defLongTintBarPaint = null;
    _defShortTintBarPaint = null;
    _defLongHollowBarPaint = null;
    _defShortHollowBarPaint = null;
    _defLongLinePaint = null;
    _defShortLinePaint = null;
  }
}

/// 绘制对象边界计算能力。
mixin PaintObjectBoundingMixin<T extends Indicator<IIndicatorKey>> on IndicatorObject<T> implements IPaintBounding {
  bool get drawInMain => paneIndex == mainPaneIndex;
  bool get drawInSub => paneIndex > mainPaneIndex;

  int _paneIndex = mainPaneIndex;

  /// 当前指标所在位置索引：<0 为主区，>=0 为副区。
  int get paneIndex => _paneIndex;

  Rect? _drawableRect;
  Rect? _chartRect;
  Rect? _topRect;
  Rect? _bottomRect;

  @nonVirtual
  @override
  void resetPaintBounding({int? paneIndex}) {
    if (paneIndex != null) _paneIndex = paneIndex;
    _drawableRect = null;
    _chartRect = null;
    _topRect = null;
    _bottomRect = null;
  }

  @override
  Rect get drawableRect {
    if (_drawableRect != null) return _drawableRect!;
    if (drawInMain) {
      _drawableRect = context.mainRect;
    } else {
      final top = context.calculatePaneTop(paneIndex);
      final subRect = context.subRect;
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
      drawableRect.top + padding.top + _tipsAreaHeight,
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

/// 绘制对象几何状态与坐标映射能力。
///
/// 提供 minMax 管理、Y 轴换算、X 轴 index/dx 映射等功能。
mixin PaintObjectGeometryStateMixin<T extends Indicator<IIndicatorKey>> on IndicatorObject<T> implements IPaintState {
  int? _start;
  int? _end;

  MinMax? _minMax;

  /// 用于平移过程中 Y 轴边界平滑过渡的缓存
  MinMax? _smoothMinMax;

  @override
  MinMax get minMax {
    // alone / 副区：用自己的区间
    // combine 子对象和主区分别在 PaintObject / MainPaintObject 中 override
    return _smoothMinMax ?? _minMax ?? MinMax.zero;
  }

  @override
  void setMinMax(MinMax val) {
    if (val.isSame) val.expandByRatios(settingConfig.expandRatiosOfSameMinmax);
    _minMax = val;
    _dyFactor = null;
  }

  /// 对 minMax 做平滑插值, 减少平移过程中 Y 轴坐标系的跳变。
  ///
  /// [smoothFactor] 控制平滑程度: 值越小越平滑(但响应越慢), 建议 0.1~0.25。
  /// 当 factor=1.0 时, lerp 直接返回精确值, 无需特殊处理。
  ///
  /// 插值结果只写入 [_smoothMinMax], 不碰 [_minMax] —— 后者恒为
  /// [computeVisibleMinMax] 写入的纯净目标值, 用作下一帧 smooth 的收敛目标。
  /// [minMax] getter 按 `_smoothMinMax ?? _minMax` 的优先级读取, 确保渲染使用平滑值。
  ///
  /// 只服务自动路径: 缩放区间由用户精确控制, 插值只会让跟手性变差。这条边界由
  /// [MainPaintObject._zoomMinMax] 存在时的事实保证 —— [MainPaintObject.minMax]
  /// 优先返回它、设置时清掉平滑缓存、且缩放态的重算路径根本不调本方法。
  void smoothMinMax({double smoothFactor = 1.0}) {
    if (_minMax == null) return;
    if (smoothFactor >= 1.0) {
      _smoothMinMax = null;
    } else {
      _smoothMinMax = MinMax.lerp(_smoothMinMax ?? _minMax!, _minMax!, smoothFactor);
      _dyFactor = null;
    }
  }

  double? _dyFactor;
  @override
  double get dyFactor {
    if (_dyFactor != null) return _dyFactor!;
    if (chartRect.height <= 0) return _dyFactor = 0;
    return _dyFactor = chartRect.height / minMax.diffDivisor.toDouble();
  }

  double valueToDy(FlexiNum value, {bool correct = true}) {
    if (correct) value = value.clamp(minMax.min, minMax.max);
    return chartRect.bottom - (value - minMax.min).toDouble() * dyFactor;
  }

  FlexiNum? dyToValue(double dy, {bool check = true}) {
    if (check && !drawableRect.includeDy(dy)) return null;
    if (dyFactor <= 0) return null;
    return minMax.max - ((dy - chartRect.top) / dyFactor).toFlexiNum();
  }

  double? indexToDx(num index, {bool check = true}) {
    final indexDx = index * candleActualWidth;
    final dx = chartRect.right + paintDxOffset - indexDx;
    if (!check) return dx;
    return chartRect.includeDx(dx) ? dx : null;
  }

  double? timestampToDx(int ts, {bool check = true}) {
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

  double candleValueToDy(FlexiNum value, {bool correct = false}) {
    return context.candleValueToDy(value, correct: correct);
  }

  FlexiNum? dyToCandleValue(double dy, {bool check = false}) {
    return context.dyToCandleValue(dy, check: check);
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    // 默认实现返回 null，表示使用当前 minMax
    // 子类可以 override 此方法提供自定义实现
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

/// 绘制基于蜡烛数据的图表能力。
mixin PaintCandleChartMixin<T extends Indicator> on PaintObject<T> {
  /// 绘制 Open-high-low-close 样式的蜡烛图（美国线图）
  /// 主区: 蜡烛图
  /// 副区: 用于SubBoll图和SubSar图中
  void paintOHLCStyleCandleChart(
    Canvas canvas, {
    int? start,
    int? end,
    double? startOffset, // 起始偏移量.
  }) {
    start ??= klineData.start;
    end ??= math.min(klineData.end + 1, klineData.length); // 多绘制一根蜡烛;
    // start/end 可由调用方传入, 不受绘制入口担保, 故校验实际生效的区间。
    if (!klineData.checkStartAndEnd(start, end)) return;
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
    high ??= valueToDy(m.high, correct: false);
    low ??= valueToDy(m.low, correct: false);
    (open, close) = ensureMinDistance(
      open ?? valueToDy(m.open, correct: false),
      close ?? valueToDy(m.close, correct: false),
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
    start ??= klineData.start;
    end ??= math.min(klineData.end + 1, klineData.length); // 多绘制一根蜡烛;
    // start/end 可由调用方传入, 不受绘制入口担保, 故校验实际生效的区间。
    if (!klineData.checkStartAndEnd(start, end)) return;
    startOffset ??= startCandleDx - candleWidthHalf;

    final points = <Offset>[];
    FlexiCandleModel m;
    double boundDy = chartRect.bottom;
    for (var i = start; i < end; i++) {
      m = klineData[i];
      final dy = valueToDy(m.close, correct: false);
      points.add(Offset(
        startOffset - (i - start) * candleActualWidth,
        dy,
      ));
      boundDy = math.max(boundDy, dy);
    }

    paintLineChart(
      canvas,
      points: points,
      boundEnd: Offset(points.last.dx, boundDy),
      boundStart: Offset(points.first.dx, boundDy),
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
      final path = Path()..addPolygon([...points, boundEnd, boundStart], true);
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
    start ??= klineData.start;
    end ??= math.min(klineData.end + 1, klineData.length); // 多绘制一根蜡烛;
    // start/end 可由调用方传入, 不受绘制入口担保, 故校验实际生效的区间。
    if (!klineData.checkStartAndEnd(start, end)) return;
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
