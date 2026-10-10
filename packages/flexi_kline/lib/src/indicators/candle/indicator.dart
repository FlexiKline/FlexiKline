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

part of 'candle.dart';

/// 最新价与倒计时的派生样式, 见 [CandlePaintObject._resolveLatestStyles]。
typedef _LatestStyles = ({LabelStyle latest, LabelStyle countdown});

@CopyWith()
@FlexiIndicatorSerializable
class CandleIndicator extends CandleBaseIndicator {
  CandleIndicator({
    super.zIndex = -1,
    super.height = defaultMainIndicatorHeight,
    super.padding = defaultMainIndicatorPadding,

    // 主区网格线: 横线即价格刻度线, 竖线是几何参考线.
    super.horizontalGrid = CandleBaseIndicator.defaultHorizontalGrid,
    super.verticalGrid = CandleBaseIndicator.defaultVerticalGrid,

    // 最高价
    this.high = const MarkConfig(
      spacing: 2,
      line: LineConfig(
        type: LineType.solid,
        length: 20,
        paint: PaintConfig(
          strokeWidth: defaultAuxiliaryLineWidth,
        ),
      ),
      text: TextAreaConfig(
        style: TextStyle(
          fontSize: defaultTextSize,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
      ),
    ),
    // 最低价
    this.low = const MarkConfig(
      spacing: 2,
      line: LineConfig(
        type: LineType.solid,
        length: 20,
        paint: PaintConfig(
          strokeWidth: defaultAuxiliaryLineWidth,
        ),
      ),
      text: TextAreaConfig(
        style: TextStyle(
          fontSize: defaultTextSize,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
      ),
    ),

    /// 最后价: 当最新蜡烛不在可视区域时使用.
    /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorForLatestPriceBackground为true,则会采用涨跌色
    this.offViewPriceMark = const MarkConfig(
      show: true,
      spacing: 1,
      line: LineConfig(
        type: LineType.dashed,
        dashes: [3, 3],
        paint: PaintConfig(
          strokeWidth: defaultAuxiliaryLineWidth,
        ),
      ),
      hitTestMargin: 4,
      text: TextAreaConfig(
        style: TextStyle(
          fontSize: defaultTextSize,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
          textBaseline: TextBaseline.alphabetic,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ),
        border: defaultBorderSide,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),

    /// 最新价: 当最新蜡烛在可视区域时使用.
    /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorForLatestPriceBackground为true,则会采用涨跌色
    this.inViewPriceMark = const MarkConfig(
      show: true,
      spacing: 1,
      line: LineConfig(
        type: LineType.dashed,
        dashes: [3, 3],
        paint: PaintConfig(
          strokeWidth: defaultAuxiliaryLineWidth,
        ),
      ),
      text: TextAreaConfig(
        style: TextStyle(
          fontSize: defaultTextSize,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
        textAlign: TextAlign.center,
        padding: EdgeInsets.all(2),
        border: BorderSide(
          color: transparent,
          width: 0.5,
        ),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    ),

    /// 最新蜡烛点: 仅在线图中使用.
    this.showLatestPoint = true,
    this.latestPoint = const PointConfig(
      radius: 2,
      width: 0,
      borderWidth: 2,
      borderOpacity: 0.5,
    ),

    /// 使用蜡烛颜色做为Latest的背景
    this.useCandleColorForLatestPriceBackground = true,

    /// 倒计时, 在latest最新价之下展示
    this.showCountdown = true,
    this.countdown = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      textAlign: TextAlign.center,
      padding: EdgeInsets.all(2),
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),

    /// 日期气泡, moveToDateTime 完成后指向目标蜡烛
    this.dateMark = const DateMarkConfig(),
    this.chartType = FlexiChartType.barSolid,
    this.minWidthLineType,
    this.intervalChartTypes = const {},
    this.hideMainIndicatorsInLineChartMode = true,
    this.longColor,
    this.shortColor,
    this.lineColor,
    this.lineGradientConfig = GradientPresets.lineChart,
    this.longGradientConfig = GradientPresets.long,
    this.shortGradientConfig = GradientPresets.short,
  });

  /// 最高价
  final MarkConfig high;

  /// 最低价
  final MarkConfig low;

  /// 最后价: 当最新蜡烛不在可视区域时使用.
  /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorForLatestPriceBackground为true,则会采用涨跌色
  final MarkConfig offViewPriceMark;

  /// 最新价: 当最新蜡烛在可视区域时使用.
  /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorForLatestPriceBackground为true,则会采用涨跌色
  final MarkConfig inViewPriceMark;

  /// 最新蜡烛点: 仅在线图中使用.
  final bool showLatestPoint;
  final PointConfig? latestPoint;

  /// 使用蜡烛颜色做为Latest的背景
  final bool useCandleColorForLatestPriceBackground;

  /// 倒计时, 在latest最新价之下展示
  final bool showCountdown;
  final TextAreaConfig countdown;

  /// 日期气泡, `moveToDateTime` 完成后指向目标蜡烛, 见 [CandlePaintObject.didMoveToDate]。
  final DateMarkConfig dateMark;

  /// 主区蜡烛图表默认类型（包含样式）
  final FlexiChartType chartType;

  /// 缩放至最小蜡烛宽度时使用的线图类型
  /// 限制为 LineChartType，因为最小宽度时蜡烛图无法正常显示
  /// 如果为 null，则使用默认 chartType
  final FlexiLineChartType? minWidthLineType;

  /// 指定时间周期使用的图表类型映射
  /// Key: 时间周期，Value: 对应的图表类型
  /// 优先级高于 minWidthLineType
  /// 匹配规则：基于 milliseconds 匹配，支持不同 [ITimeInterval] 实现互相等效
  @IntervalChartTypesConverter()
  final Map<ITimeInterval, FlexiChartType>? intervalChartTypes;

  /// 当图表类型为线图时，是否隐藏主区的技术指标（如 MA 等）
  /// 用于避免主线图与技术指标线重合，影响可读性
  /// 默认值为 false，即显示所有指标
  final bool hideMainIndicatorsInLineChartMode;

  // 自定义上涨颜色
  final Color? longColor;
  // 自定义下跌颜色
  final Color? shortColor;
  // 自定义line图颜色
  final Color? lineColor;

  /// 自定义line图渐变配置. 如果为 null，则不绘制渐变填充，仅绘制线条
  final GradientConfig? lineGradientConfig;

  /// 自定义上涨渐变配置. 如果为 null，则不绘制上涨区域的渐变填充
  final GradientConfig? longGradientConfig;

  /// 自定义下跌渐变配置. 如果为 null，则不绘制下跌区域的渐变填充
  final GradientConfig? shortGradientConfig;

  @override
  CandlePaintObject createPaintObject() => CandlePaintObject();

  factory CandleIndicator.fromJson(Map<String, dynamic> json) => _$CandleIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CandleIndicatorToJson(this);
}

class CandlePaintObject<T extends CandleIndicator> extends CandleBasePaintObject<T>
    with PaintYAxisTicksOnCrossMixin, PaintCandleChartMixin {
  FlexiNum? _maxHigh, _minLow;

  /// 最高价与最低价共用: 默认配置下两者是同一个 const 实例, 样式一致, 两个 key 都留在池里。
  late final _extremePriceLabels = own(LabelPainter(capacity: 2));

  late final _inViewPriceLabel = own(LabelPainter());
  late final _countdownLabel = own(LabelPainter());
  late final _offViewPriceLabel = own(LabelPainter());

  late final _offViewArrow = own(createOffViewPriceArrow());

  /// [_resolveLatestStyles] 的单项记忆: 输入与上次相同(样式按 identical)时直接返回上次的结果。
  ({LabelStyle latestBase, LabelStyle countdownBase, bool withCountdown, bool candleColor, _LatestStyles styles})?
  _latestStyles;

  /// 日期气泡指向的蜡烛 ts, null 不显示; 存 ts 不存 index: 新蜡烛插入 index 0 时下标整体后移。
  int? _dateMarkTs;
  Timer? _dateMarkTimer;
  late final _dateMarkLabel = own(LabelPainter());

  /// [_resolveDateMarkStyle] 的单项记忆: source 按 identical、arrowSize 按值比较, 上下两个方向一并派生。
  ({LabelStyle source, Size arrowSize, LabelStyle above, LabelStyle below})? _dateMarkStyles;

  /// 日期气泡指向的蜡烛 ts; null 不显示。
  int? get dateMarkTs => _dateMarkTs;

  /// 最新价标签相对屏幕右侧的负偏移量。
  @protected
  double latestPriceLabelOffsetX = 0.0;

  /// 最后价标签本帧绘出的矩形, 用于点击命中; 未画最后价时为 null。
  @protected
  Rect? offViewPriceLabelRect;

  /// 最后价标签本帧的大小。
  Size? get offViewPriceLabelSize => offViewPriceLabelRect?.size;

  @override
  Color get longColor => indicator.longColor ?? theme.longColor;

  @override
  Color get shortColor => indicator.shortColor ?? theme.shortColor;

  @override
  bool get hideMainIndicatorsInLineChartMode => indicator.hideMainIndicatorsInLineChartMode;

  @override
  FlexiChartType resolveChartType() {
    // 1. 优先检查时间周期映射（基于 milliseconds 匹配）
    final interval = klineData.interval;
    final chartTypes = indicator.intervalChartTypes;
    if (chartTypes != null && chartTypes.isNotEmpty) {
      for (final entry in chartTypes.entries) {
        if (entry.key == interval) {
          return entry.value;
        }
      }
    }

    // 2. 检查是否达到最小蜡烛宽度
    if (candleWidth <= settingConfig.candleMinWidth && indicator.minWidthLineType != null) {
      return indicator.minWidthLineType!;
    }

    // 3. 返回默认图表类型
    return indicator.chartType;
  }

  @mustCallSuper
  @override
  void didChangeDependencies(KlineSpec oldSpec) {
    super.didChangeDependencies(oldSpec);
    _hideDateMark();
  }

  @mustCallSuper
  @override
  void didUpdateIndicator(covariant T oldIndicator) {
    super.didUpdateIndicator(oldIndicator);
    if (!indicator.dateMark.show) _hideDateMark();
  }

  @override
  void dispose() {
    _dateMarkTimer?.cancel();
    super.dispose();
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    final minmax = klineData.calculateMinmax(start, end);
    _maxHigh = minmax?.max;
    _minLow = minmax?.min;
    return minmax;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartType = resolveChartType();

    switch (chartType) {
      case FlexiBarChartType(:final style):
        // 绘制蜡烛柱状图，传入样式
        paintCandleBars(canvas, size, style);
      case FlexiLineChartType(:final style):
        switch (style) {
          case ChartLineStyle.normal:
            // 绘制普通折线图
            paintCandleLineChart(
              canvas,
              startOffset: startCandleDx - candleWidthHalf,
              linePaint: getLinePaint(
                color: indicator.lineColor,
                strokeWidth: candleLineWidth,
              ),
              gradient: indicator.lineGradientConfig?.createGradient(
                baseColor: indicator.lineColor ?? theme.lineChartColor,
              ),
            );
            paintLatestPoint(canvas, size);
          case ChartLineStyle.updown:
            // 绘制涨跌线图
            paintCandleUpDownLineChart(
              canvas,
              startOffset: startCandleDx - candleWidthHalf,
              longLinePaint: getLinePaint(color: longColor),
              shortLinePaint: getLinePaint(color: shortColor),
              longGradient: indicator.longGradientConfig?.createGradient(
                baseColor: longColor,
              ),
              shortGradient: indicator.shortGradientConfig?.createGradient(
                baseColor: shortColor,
              ),
            );
            paintLatestPoint(canvas, size);
        }
    }
  }

  @override
  void paintOverlay(Canvas canvas, Size size) {
    // 绘制最新价刻度线与价钱标记
    paintLatestPriceMarkers(canvas, size);
    // 日期气泡压在最新价线之上
    paintDateMark(canvas);
  }

  /// 显示指向 [ts] 的日期气泡, 替换已有的并重新计时; [DateMarkConfig.show] 关闭时忽略。
  @override
  void didMoveToDate(int ts) {
    final config = indicator.dateMark;
    if (!config.show) return;
    _dateMarkTimer?.cancel();
    _dateMarkTs = ts;
    _dateMarkTimer = config.holdDuration > 0 ? Timer(Duration(milliseconds: config.holdDuration), _hideDateMark) : null;
    // moveToDateTime 返回前已等过 endOfFrame, 那一帧还没有 ts。
    context.requestRepaint();
  }

  @override
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    // 绘制Cross Y轴价钱刻度
    paintYAxisTicksOnCross(
      canvas,
      offset,
      precision: klineData.precision,
    );
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    FlexiCandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    return null;
  }

  /// 格式化 Y 轴价格刻度值。
  @override
  String formatTicksValue(FlexiNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      cutInvalidZero: false,
      enableGrouping: true,
    );
  }

  /// Cross 时格式化 Y 轴上的标记值。
  @override
  String formatTicksValueOnCross(FlexiNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: klineData.precision,
      cutInvalidZero: false,
    );
  }

  @override
  bool handleTap(Offset position) {
    final lastTxtRect = offViewPriceLabelRect?.inflate(indicator.offViewPriceMark.hitTestMargin);
    if (lastTxtRect != null && lastTxtRect.include(position)) {
      // 命中最后价, 回到蜡烛图初始位置。
      context.requestMoveToInitialPosition();
      return true;
    }
    return false;
  }

  /// 最后价标签末尾的箭头, 首次使用时创建一次并随本对象释放; 子类覆写可换成其他 [ShapeImage]。
  @protected
  ShapeImage createOffViewPriceArrow() => TriangleImage(const Size(5, 6));

  /// 最后价标签内容: 价格文本加 [createOffViewPriceArrow] 的箭头。
  ///
  /// 仅在缓存未命中时调用, 结果须只由 (close, precision) 与 [color] 决定; 子类覆写可替换整个内容。
  @protected
  InlineSpan buildOffViewPriceSpan(String price, Color color) => TextSpan(
    children: [
      TextSpan(text: '$price '),
      _offViewArrow.span(color),
    ],
  );

  /// 绘制蜡烛柱状图
  void paintCandleBars(Canvas canvas, Size size, ChartBarStyle style) {
    final start = klineData.start;
    final end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final barWidthHalf = candleWidthHalf - candleSpacing;

    Offset? maxHighOffset, minLowOffset;
    final hasEnough = paintDxOffset > 0;
    FlexiNum maxHigh = klineData[start].high;
    FlexiNum minLow = klineData[start].low;
    FlexiCandleModel m;
    for (var i = start; i < end; i++) {
      m = klineData[i];
      final dx = offset - (i - start) * candleActualWidth;
      addCandleBar(m, dx: dx, barWidthHalf: barWidthHalf, chartStyle: style);

      if (indicator.high.show) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (m.high == _maxHigh) {
            maxHighOffset = Offset(dx, valueToDy(m.high, correct: false));
            maxHigh = _maxHigh!;
          }
        } else {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (m.high >= maxHigh) {
            maxHighOffset = Offset(dx, valueToDy(m.high, correct: false));
            maxHigh = m.high;
          }
        }
      }

      if (indicator.low.show) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (m.low == _minLow) {
            minLowOffset = Offset(dx, valueToDy(m.low, correct: false));
            minLow = _minLow!;
          }
        } else {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (m.low <= minLow) {
            minLowOffset = Offset(dx, valueToDy(m.low, correct: false));
            minLow = m.low;
          }
        }
      }
    }
    flushCandleBars(canvas);

    // 最后绘制在蜡烛图中的最大价钱标记
    if (maxHighOffset != null && maxHigh > FlexiNum.zero) {
      paintPriceMark(canvas, maxHighOffset, maxHigh, indicator.high);
    }
    // 最后绘制在蜡烛图中的最小价钱标记
    if (minLowOffset != null && minLow > FlexiNum.zero) {
      paintPriceMark(canvas, minLowOffset, minLow, indicator.low);
    }
  }

  /// 绘制蜡烛图上最大最小值价钱标记.
  void paintPriceMark(
    Canvas canvas,
    Offset offset,
    FlexiNum val,
    MarkConfig markConfig,
  ) {
    final flag = offset.dx > chartRectWidthHalf ? -1 : 1;
    final lineEnd = Offset(
      offset.dx + markConfig.lineLength * flag,
      offset.dy,
    );
    canvas.drawLine(
      offset,
      lineEnd,
      markConfig.line.getLinePaint(theme.markLineColor),
    );

    final precision = klineData.precision;
    _extremePriceLabels.paint(
      canvas,
      (val, precision),
      build: () => formatPrice(val.toDecimal(), precision: precision),
      style: markConfig.text.toLabelStyle(textColor: theme.textColor),
      anchor: Offset(lineEnd.dx + flag * markConfig.spacing, lineEnd.dy),
      align: flag < 0 ? Alignment.centerRight : Alignment.centerLeft,
    );
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLatestPriceMarkers(Canvas canvas, Size size) {
    if (!indicator.inViewPriceMark.show && !indicator.offViewPriceMark.show) return;
    final model = klineData.latest;
    if (model == null) {
      logd('paintLatestPriceMarkers > no data!');
      return;
    }

    // 计算最新价YAxis位置.
    double dy = clampDyInChart(valueToDy(model.close));

    // 计算最新价XAxis位置.
    final rdx = chartRect.right;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.

    if (paintDxOffset < latestPriceLabelOffsetX) {
      offViewPriceLabelRect = null;
      // 绘制最新价和倒计时
      final MarkConfig inViewPriceMark = indicator.inViewPriceMark;
      if (!inViewPriceMark.show) return;

      ldx = startCandleDx;

      final useCandleColor = indicator.useCandleColorForLatestPriceBackground;
      final updownColor = model.close >= model.open ? longColor : shortColor;

      final textConfig = indicator.inViewPriceMark.text;

      final halfHeight = textConfig.areaHeight / 2;
      // 修正dy位置
      dy = dy.clamp(
        drawableRect.top + halfHeight,
        drawableRect.bottom - halfHeight,
      );

      // 绘制首根蜡烛到rdx的刻度线.
      final latestPath = Path();
      latestPath.moveTo(rdx, dy);
      latestPath.lineTo(ldx, dy);
      canvas.drawLineByConfig(
        latestPath,
        indicator.inViewPriceMark.line,
        themeColor: useCandleColor ? updownColor : theme.markLineColor,
      );

      // 倒计时: 时间周期 > 1 秒且下次更新在未来时显示; 文本由剩余整秒数唯一决定, 以它作 key。
      DateTime? next;
      final now = DateTime.now();
      if (indicator.showCountdown && klineData.interval.milliseconds > Duration.millisecondsPerSecond) {
        next = model.nextUpdateDateTime(klineData.interval);
        if (next != null && next.millisecondsSinceEpoch <= now.millisecondsSinceEpoch) next = null;
      }

      final styles = _resolveLatestStyles(
        textConfig.toLabelStyle(
          textColor: useCandleColor ? white : theme.textColor,
          backgroundColor: useCandleColor ? updownColor : theme.latestPriceBg,
          borderColor: useCandleColor ? null : theme.markLineColor,
        ),
        indicator.countdown.toLabelStyle(textColor: theme.textColor, backgroundColor: theme.countdownBg),
        withCountdown: next != null,
        candleColor: useCandleColor,
      );

      final precision = klineData.precision;
      final latest = _inViewPriceLabel.paint(
        canvas,
        (model.close, precision),
        build: () => formatPrice(model.close.toDecimal(), precision: precision, cutInvalidZero: false),
        style: styles.latest,
        anchor: Offset(rdx - inViewPriceMark.spacing, dy),
        align: Alignment.centerRight,
        bounds: drawableRect,
      );
      latestPriceLabelOffsetX = -(latest.width + inViewPriceMark.spacing);

      if (next != null) {
        final countdownEnd = next;
        // 与最新价同宽: minWidth 撑开, bounds 的宽度封顶。纵向不夹取: 最新价贴底时倒计时溢出到时间轴上。
        _countdownLabel.paint(
          canvas,
          countdownEnd.difference(now).inSeconds,
          build: () => countdownEnd.diffAsCountdown(now),
          style: styles.countdown,
          anchor: latest.bottomRight,
          align: Alignment.topRight,
          bounds: Rect.fromLTRB(latest.left, latest.bottom, latest.right, double.infinity),
          minWidth: latest.width,
        );
      }
    } else {
      // 绘制最后价
      final offViewPriceMark = indicator.offViewPriceMark;
      if (!offViewPriceMark.show) return;

      ldx = 0;

      final halfHeight = offViewPriceMark.text.areaHeight / 2;
      // 修正dy位置
      dy = dy.clamp(
        drawableRect.top + halfHeight,
        drawableRect.bottom - halfHeight,
      );

      // 绘制横穿画板的最后价刻度线.
      final lastPath = Path();
      final lastSize = offViewPriceLabelSize;
      if (lastSize != null) {
        final lastTextAreaRight = rdx + latestPriceLabelOffsetX - offViewPriceMark.spacing;
        lastPath.moveTo(rdx, dy);
        lastPath.lineTo(lastTextAreaRight, dy);
        lastPath.moveTo(lastTextAreaRight - lastSize.width, dy);
        lastPath.lineTo(ldx, dy);
      } else {
        lastPath.moveTo(rdx, dy);
        lastPath.lineTo(ldx, dy);
      }
      canvas.drawLineByConfig(
        lastPath,
        offViewPriceMark.line,
        themeColor: theme.markLineColor,
      );

      // 绘制最后价标记
      final precision = klineData.precision;
      final style = offViewPriceMark.text.toLabelStyle(
        textColor: theme.lastPriceColor,
        backgroundColor: theme.lastPriceBg,
      );
      offViewPriceLabelRect = _offViewPriceLabel.paint(
        canvas,
        (model.close, precision),
        // 箭头颜色取自 style: 颜色一变 style.text 随之变, 排版缓存被丢弃后 build 会重跑。
        build: () => buildOffViewPriceSpan(
          formatPrice(model.close.toDecimal(), precision: precision, cutInvalidZero: false),
          style.text.color ?? theme.lastPriceColor,
        ),
        style: style,
        anchor: Offset(rdx + latestPriceLabelOffsetX - offViewPriceMark.spacing, dy),
        align: Alignment.centerRight,
        bounds: drawableRect,
      );
    }
  }

  /// 最新价与倒计时的派生样式: 有倒计时时最新价只留上圆角, 倒计时以其上圆角作下圆角;
  /// 涨跌色背景时边框透明。倒计时不用 padding, 改由行高撑到 areaHeight - 1。
  _LatestStyles _resolveLatestStyles(
    LabelStyle latestBase,
    LabelStyle countdownBase, {
    required bool withCountdown,
    required bool candleColor,
  }) {
    final memo = _latestStyles;
    if (memo != null &&
        identical(memo.latestBase, latestBase) &&
        identical(memo.countdownBase, countdownBase) &&
        memo.withCountdown == withCountdown &&
        memo.candleColor == candleColor) {
      return memo.styles;
    }

    final radius = indicator.inViewPriceMark.text.borderRadius;
    var latest = latestBase;
    final decoration = latestBase.decoration;
    final shape = decoration?.shape;
    if (decoration != null && shape is RoundedRectangleBorder && (withCountdown || candleColor)) {
      latest = latestBase.copyWith(
        decoration: ShapeDecoration(
          color: decoration.color,
          gradient: decoration.gradient,
          shadows: decoration.shadows,
          shape: shape.copyWith(
            side: candleColor ? shape.side.copyWith(color: transparent) : null,
            borderRadius: withCountdown && radius != null
                ? radius.copyWith(bottomLeft: Radius.zero, bottomRight: Radius.zero)
                : null,
          ),
        ),
      );
    }

    final config = indicator.countdown;
    final countdown = countdownBase.copyWith(
      text: countdownBase.text.copyWith(height: (config.areaHeight - 1) / config.textHeight),
      maxLines: config.maxLines ?? 1,
      padding: EdgeInsets.zero,
      decoration: ShapeDecoration(
        color: countdownBase.decoration?.color,
        gradient: countdownBase.decoration?.gradient,
        shadows: countdownBase.decoration?.shadows,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: candleColor ? transparent : theme.markLineColor,
            width: config.border?.width ?? 0.5,
          ),
          borderRadius: radius == null
              ? BorderRadius.zero
              : BorderRadius.only(bottomLeft: radius.topLeft, bottomRight: radius.topRight),
        ),
      ),
    );

    final styles = (latest: latest, countdown: countdown);
    _latestStyles = (
      latestBase: latestBase,
      countdownBase: countdownBase,
      withCountdown: withCountdown,
      candleColor: candleColor,
      styles: styles,
    );
    return styles;
  }

  /// 绘制最新蜡烛点
  void paintLatestPoint(Canvas canvas, Size size) {
    if (!indicator.showLatestPoint) return;
    if (indicator.latestPoint == null) return;
    final model = klineData.latest;
    if (model == null) {
      logd('paintLatestPoint > no data!');
      return;
    }
    if (paintDxOffset > latestPriceLabelOffsetX) {
      // 最新价在屏幕右侧, 不绘制点
      // logd('paintLatestPoint > latestPoint is on the right of the screen!');
      return;
    }

    final point = indicator.latestPoint!;
    final offset = Offset(
      startCandleDx - candleWidthHalf,
      clampDyInChart(valueToDy(model.close)),
    );
    canvas.drawCirclePoint(
      offset,
      point,
      themeColor: theme.lineChartColor,
      themeBorderColor: theme.lineChartColor,
    );
  }

  /// 计时到期、换 spec 或关闭开关时清空日期气泡。
  void _hideDateMark() {
    _dateMarkTimer?.cancel();
    _dateMarkTimer = null;
    if (_dateMarkTs == null) return;
    _dateMarkTs = null;
    context.requestRepaint();
  }

  /// 日期气泡内容, 默认是日期文本; 子类覆写可换格式(时区、星期)或加图标。
  ///
  /// 仅在缓存未命中时调用, 结果须只由 (ts, interval) 与 [color] 决定; 外观由 [DateMarkConfig] 决定。
  @protected
  InlineSpan buildDateMarkSpan(FlexiCandleModel model, Color color) => TextSpan(
    text: model.formatDateTime(klineData.interval),
  );

  /// 绘制日期气泡: 每帧按 ts 重新锚定, 随平移、缩放与 Y 轴调整联动; 目标蜡烛不在可视区或已不在数据中时不画。
  @protected
  void paintDateMark(Canvas canvas) {
    final ts = _dateMarkTs;
    if (ts == null) return;
    final i = klineData.indexAtOrBefore(ts);
    if (i == null || i < klineData.start || i >= klineData.end || klineData[i].ts != ts) return;

    final model = klineData[i];
    final config = indicator.dateMark;
    final (top, bottom) = resolveChartType() is FlexiLineChartType
        ? (model.close, model.close)
        : (model.high, model.low);
    final topDy = valueToDy(top);
    // auto 按配置估算上方是否放得下; 强制方位放不下时由 bounds 夹回主区。
    final above = switch (config.position) {
      DateMarkPosition.above => true,
      DateMarkPosition.below => false,
      DateMarkPosition.auto =>
        topDy - config.spacing - config.arrowSize.height - config.text.areaHeight >= drawableRect.top,
    };
    final style = _resolveDateMarkStyle(config, above);

    _dateMarkLabel.paint(
      canvas,
      (ts, klineData.interval),
      build: () => buildDateMarkSpan(model, style.text.color ?? theme.crossTextColor),
      style: style,
      anchor: Offset(
        // 同 paintCandleBars: 蜡烛中心。
        startCandleDx - candleWidthHalf - (i - klineData.start) * candleActualWidth,
        above ? topDy - config.spacing : valueToDy(bottom) + config.spacing,
      ),
      align: above ? Alignment.bottomCenter : Alignment.topCenter,
      bounds: drawableRect,
    );
  }

  /// 把 [DateMarkConfig.text] 解析出的圆角矩形换成指向蜡烛的气泡; [above] 时箭头朝下。
  LabelStyle _resolveDateMarkStyle(DateMarkConfig config, bool above) {
    // 背景色有主题兜底, toLabelStyle 必然产出 RoundedRectangleBorder 的 decoration。
    final source = config.text.toLabelStyle(
      textColor: theme.crossTextColor,
      backgroundColor: theme.crossTextBg,
    );
    var styles = _dateMarkStyles;
    if (styles == null || !identical(styles.source, source) || styles.arrowSize != config.arrowSize) {
      final decoration = source.decoration!;
      final shape = decoration.shape as RoundedRectangleBorder;
      LabelStyle derive(AxisDirection direction) => source.copyWith(
        decoration: ShapeDecoration(
          color: decoration.color,
          gradient: decoration.gradient,
          shadows: decoration.shadows,
          shape: BubbleBorder(
            side: shape.side,
            borderRadius: shape.borderRadius.resolve(null),
            direction: direction,
            arrowSize: config.arrowSize,
          ),
        ),
      );
      styles = _dateMarkStyles = (
        source: source,
        arrowSize: config.arrowSize,
        above: derive(AxisDirection.down),
        below: derive(AxisDirection.up),
      );
    }
    return above ? styles.above : styles.below;
  }
}
