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

  /// 对 minMax 做平滑插值, 减少平移中 Y 轴坐标跳变。
  ///
  /// 只写 [_smoothMinMax], 不碰 [_minMax](保持纯净收敛目标)。factor=1.0 时清除平滑。
  /// 只服务自动路径: 缩放态由用户精确控制, 不走此方法。
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

/// 网格线与 Y 轴刻度的绘制能力。
///
/// 算与画分成两组: `resolveXxx` 只产出位置、不碰 canvas; `paintXxx` 只消费已算好的位置。
/// 分开是因为「算了但不画」是常态 —— 线关掉了仍要产出位置供刻度文本使用, 竖线的位置还要
/// 跨 pane 供副区对齐。
///
/// 全部方法只在 `List<double>` 这一种货币上交易: 刻度值不随位置一起传递, 由
/// [paintYAxisTicks] 内部经 `dyToValue` 现算。
mixin PaintGridTicksMixin<T extends Indicator> on PaintObject<T> {
  // ---- 算: 只产出位置 ----

  /// 按 [mode] 产出横向网格线的 dy 序列, **不含落在 [bounds] 两端的位置**。
  ///
  /// 两端不产出: 那里有 grid 层的顶边框与 pane 分隔线, 再画一条只是重合。[bounds] 默认
  /// [drawableRect] —— 横线要横穿整个可绘制区, chartRect 已让出 padding 会让线短一截。
  ///
  /// `count` / `size` 是纯几何, 与任何值无关; `nice` 由算法定值再经
  /// `valueToDy(correct: false)` 换算位置, 区间不可用时退化为 `count`。
  ///
  /// 前两种只是把参数转交给 [evenPositions] / [spacedPositions] 这两个纯函数; `nice` 的
  /// **值到像素**那一步留在这里, 因为它要经 [dyToValue] / [valueToDy] 在值与像素之间来回,
  /// 而那是本对象的坐标体系 —— 搬进纯函数就得把两个映射当闭包传进去, 接口复杂度会超过它
  /// 自己的实现复杂度。取整算法本身在 [computePriceTicks]。
  @protected
  List<double> resolveHorizontalDys(GridTickMode mode, {Rect? bounds}) {
    final rect = bounds ?? drawableRect;
    switch (mode) {
      case GridCountTickMode(:final divisions):
        return evenPositions(divisions, start: rect.top, length: rect.height);
      case GridSizeTickMode(:final spacing):
        return spacedPositions(spacing, start: rect.top, length: rect.height);
      case GridNiceTickMode(:final targetDivisions):
        // 区间不可用时退化为 count。两个判据各管一头: canPaintChart 与 paintChart 的门禁同源
        // (切标的时 minMax 还是上一帧的旧值, 只看它会让 nice 拿旧价格算位置); minMax.isZero
        // 则覆盖数据已就绪但区间为零的坏数据 —— computePriceTicks 对非正跨度返回空, 不退化
        // 会让主区一条横线都没有。
        if (!klineData.canPaintChart || minMax.isZero) {
          return evenPositions(targetDivisions, start: rect.top, length: rect.height);
        }

        // 取值范围是 [rect] 反算出的价格区间, **不外扩 minMax** —— 后者是 Y 轴 zoom 的数据
        // 载体, 外扩会让用户精确控制的跨度被算法撑回去, 也会让 step 换档时整幅画面跳一下。
        // 代价是最顶/最底刻度到边缘的距离随平移连续变化, 与 TradingView 一致。
        //
        // 显式 check: false —— 这两个 dy 恰在 [rect] 边界上, 带检查的默认值会返回 null, 刻度
        // 会整体消失且不抛异常。
        final top = dyToValue(rect.top, check: false);
        final bottom = dyToValue(rect.bottom, check: false);
        if (top == null || bottom == null) return const [];

        final ticks = computePriceTicks(
          bottom: bottom.toDouble(),
          top: top.toDouble(),
          targetCount: targetDivisions,
          precision: klineData.precision,
        );

        // correct: false —— 默认会把值 clamp 进 [minMax.min, max], 留白区(padding 与 tips)的
        // 刻度会被压到边缘叠在一起。
        return [for (final value in ticks.values) valueToDy(value.toFlexiNum(), correct: false)];
    }
  }

  /// 按**刻度数**等分产出横向 dy 序列, **含两端**。副区历来的口径(3 表示高 / 中 / 低)。
  ///
  /// 与 [resolveHorizontalDys] 的 `count` 分支刻意不同: 那里的参数是间隔数且避开两端,
  /// 因为主区两端有边框; 副区没有边框, 贴顶贴底的两条正是该指标在可视区的极值, 是信息而非
  /// 冗余。[bounds] 因此也默认 [chartRect] 而非 [drawableRect] —— 刻度文本落在图表区内。
  @protected
  List<double> resolveDysByCount(int tickCount, {Rect? bounds}) {
    final rect = bounds ?? chartRect;
    return positionsByCount(tickCount, start: rect.top, length: rect.height);
  }

  /// 按 [mode] 产出纵向网格线的 dx 序列, **不含落在 [bounds] 两端的位置**(那里是左右边框)。
  ///
  /// `nice` 在此不成立, 退化为 `count`: 竖线是几何参考线, 按值取整会让网格随数据漂移。
  @protected
  List<double> resolveVerticalDxs(GridTickMode mode, {Rect? bounds}) {
    final rect = bounds ?? drawableRect;
    switch (mode) {
      case GridCountTickMode(:final divisions):
        return evenPositions(divisions, start: rect.left, length: rect.width);
      case GridSizeTickMode(:final spacing):
        return spacedPositions(spacing, start: rect.left, length: rect.width);
      case GridNiceTickMode(:final targetDivisions):
        assert(false, '竖线不支持 nice: 已退化为 count($targetDivisions)。');
        return evenPositions(targetDivisions, start: rect.left, length: rect.width);
    }
  }

  // ---- 画: 只消费已算好的位置 ----

  /// 画横向网格线。[line] 为 null 则不画。
  @protected
  void paintHorizontalGridLines(
    Canvas canvas, {
    required Iterable<double> dys,
    LineConfig? line,
    Rect? bounds,
  }) {
    if (line == null) return;
    final rect = bounds ?? drawableRect;
    for (final dy in dys) {
      canvas.drawLineByConfig(
        Path()
          ..moveTo(rect.left, dy)
          ..lineTo(rect.right, dy),
        line,
        themeColor: theme.gridLineColor,
      );
    }
  }

  /// 画纵向网格线。[line] 为 null 则不画。
  ///
  /// 副区指标传主区产出的 dx 序列即与主区对齐。
  @protected
  void paintVerticalGridLines(
    Canvas canvas, {
    required Iterable<double> dxs,
    LineConfig? line,
    Rect? bounds,
  }) {
    if (line == null) return;
    final rect = bounds ?? drawableRect;
    for (final dx in dxs) {
      canvas.drawLineByConfig(
        Path()
          ..moveTo(dx, rect.top)
          ..lineTo(dx, rect.bottom),
        line,
        themeColor: theme.gridLineColor,
      );
    }
  }

  /// 画 Y 轴刻度文本, 返回本次文本的最大宽度(未画任何文本时为 0)。
  ///
  /// 逐个 `dyToValue(dy, check: false)` 取值, null 的跳过(无区间时取不到), 再经
  /// [formatTicksValue] 格式化。**必须 check: false**: `includeDy` 是闭区间, 而 nice 刻度
  /// 可以落在留白区端点上, 浮点误差足以让它差之毫厘被判出界, 整条刻度静默消失。
  ///
  /// 返回宽度供主区那一趟上行给编排层: zoom 滑竿热区的宽度由本帧刻度文本实测而来
  /// (见 `MainPaintDelegateExt.doPaintChart`)。自行绘制刻度文本的子类覆写它, 返回实测最大宽度
  /// 即可, 否则 zoom 手势拿不到热区。
  @protected
  double paintYAxisTicks(
    Canvas canvas, {
    required Iterable<double> dys,
    required int precision,
  }) {
    if (minMax.isZero) return 0;

    final dx = chartRect.right;
    final ticksText = defTicksTextConfig;
    double maxWidth = 0;
    for (final dy in dys) {
      final value = dyToValue(dy, check: false);
      if (value == null) continue;

      final size = canvas.drawTextArea(
        offset: Offset(
          dx,
          dy - ticksText.areaHeight, // 绘制在刻度线之上
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: formatTicksValue(value, precision: precision),
        textConfig: ticksText,
        themeTextColor: theme.ticksTextColor,
      );
      if (size.width > maxWidth) maxWidth = size.width;
    }
    return maxWidth;
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
