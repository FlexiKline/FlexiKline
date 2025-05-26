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
      );
    }
  }

  /// 如果要定制格式化刻度值. 在PaintObject中覆写此方法.
  @protected
  String formatTicksValue(BagNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
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
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
    );
  }
}

/// 绘制蜡烛图辅助Mixin
mixin PaintCandleHelperMixin<T extends Indicator> on PaintObject<T> {
  /// 绘制Open-high-low-close chart(美国线图)
  /// 用于SubBoll图和SubSar图中
  void paintOHPLKlineChart(
    Canvas canvas,
    Size size, {
    int? start,
    int? end,
    double? startOffset, // 起始偏移量.
  }) {
    if (!klineData.canPaintChart) return;
    start ??= klineData.start;
    end ??= klineData.end;
    startOffset ??= startCandleDx - candleWidthHalf;
    final barWidthHalf = candleWidthHalf;
    for (var i = start; i < end; i++) {
      paintCandleBar(
        canvas,
        klineData[i],
        dx: startOffset - (i - start) * candleActualWidth,
        barWidthHalf: barWidthHalf,
        chartStyle: ChartStyle.ohlc,
      );
    }
  }

  /// 绘制单根蜡烛柱(支持上涨下跌柱为空心或实心)
  /// [open], [close], [low], [high]为蜡烛[m]在当前图表中转换后的坐标值, 若不传, 则实时计算.
  /// [barWidthHalf]为蜡烛柱的宽度的一半, 若不传, 则实时计算.
  /// [chartStyle]为蜡烛柱的样式, 支持: ohlcChart, upHollow, downHollow
  void paintCandleBar(
    Canvas canvas,
    CandleModel m, {
    required double dx,
    double? high,
    double? low,
    double? open,
    double? close,
    double? barWidthHalf,
    required ChartStyle chartStyle,
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
    if (chartStyle == ChartStyle.ohlc) {
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

  /// 绘制蜡烛线图
  void paintCandleLineChart(
    Canvas canvas, {
    int? start,
    int? end,
    double? startOffset, // 起始偏移量.
    Paint? linePaint, // 蜡烛线图画笔.
  }) {
    if (!klineData.canPaintChart) return;
    start ??= klineData.start;
    end ??= klineData.end;
    startOffset ??= startCandleDx - candleWidthHalf;

    List<Offset> points = [];
    CandleModel m;
    for (var i = start; i < end; i++) {
      m = klineData[i];
      points.add(Offset(
        startOffset - (i - start) * candleActualWidth,
        valueToDy(m.close, correct: false),
      ));
    }

    final linePaint = getLinePaint();
    _paintLineChart(
      canvas,
      points: points,
      boundLeft: Offset(points.last.dx, chartRect.bottom),
      boundRight: Offset(points.first.dx, chartRect.bottom),
      linePaint: linePaint,
      shader: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          linePaint.color.withAlpha(0.5.alpha),
          theme.transparent,
        ],
        stops: [0, 1],
        tileMode: TileMode.decal,
      ),
    );
  }

  void _paintLineChart(
    Canvas canvas, {
    required List<Offset> points, // 绘制线
    required Offset boundLeft, // 左边界坐标
    required Offset boundRight, // 右边界坐标
    required Paint linePaint, // 蜡烛线图画笔.
    required LinearGradient shader, // 阴影配置.
  }) {
    canvas.drawPath(
      Path()..addPolygon(points, false),
      linePaint,
    );
    points.add(boundLeft);
    points.add(boundRight);
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(
      path,
      Paint()..shader = shader.createShader(path.getBounds()),
    );
  }

  /// 绘制蜡烛线图(涨跌)
  void parintCandleLineUpDownChart(
    Canvas canvas, {
    int? start,
    int? end,
    double? startOffset, // 起始偏移量.
  }) {
    if (!klineData.canPaintChart) return;
    start ??= klineData.start;
    end ??= klineData.end;
    startOffset ??= startCandleDx - candleWidthHalf;

    final barWidthHalf = candleWidthHalf;
    final double latestDy = valueToDy(klineData.latest!.close, correct: false);
    List<Offset> points = [];
    double dx, dy;
    bool isLong = valueToDy(klineData[start].close, correct: false) <= latestDy;
    for (var i = start; i < end; i++) {
      dx = startOffset - (i - start) * candleActualWidth;
      dy = valueToDy(klineData[i].close, correct: false);
      if (dy <= latestDy == isLong) {
        points.add(Offset(dx, dy));
      } else {
        points.add(Offset(dx + barWidthHalf, latestDy));
        if (isLong) {
          // 绘制上涨区间的线图
          _paintLineChart(
            canvas,
            points: points,
            boundLeft: Offset(points.last.dx, latestDy),
            boundRight: Offset(points.first.dx, latestDy),
            linePaint: getLinePaint(color: theme.long),
            shader: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                theme.long.withAlpha(0.5.alpha),
                theme.transparent,
              ],
              stops: [0, 1],
              tileMode: TileMode.decal,
            ),
          );
        } else {
          // 绘制下跌区间的线图
          _paintLineChart(
            canvas,
            points: points,
            boundLeft: Offset(points.last.dx, latestDy),
            boundRight: Offset(points.first.dx, latestDy),
            linePaint: getLinePaint(color: theme.short),
            shader: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                theme.short.withAlpha(0.5.alpha),
                theme.transparent,
              ],
              stops: [0, 1],
              tileMode: TileMode.decal,
            ),
          );
        }
        points.clear();
        isLong = !isLong;
        points.add(Offset(dx + barWidthHalf, latestDy));
        points.add(Offset(dx, dy));
        points.add(Offset(dx - barWidthHalf, latestDy));
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
