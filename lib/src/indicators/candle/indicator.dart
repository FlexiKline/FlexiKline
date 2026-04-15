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

@CopyWith()
@FlexiIndicatorSerializable
class CandleIndicator extends CandleBaseIndicator {
  CandleIndicator({
    super.zIndex = -1,
    super.height = defaultMainIndicatorHeight,
    super.padding = defaultMainIndicatorPadding,

    // 最高价
    this.high = const MarkConfig(
      spacing: 2,
      line: LineConfig(
        type: LineType.solid,
        length: 20,
        paint: PaintConfig(
          strokeWidth: 0.5,
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
          strokeWidth: 0.5,
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
    /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorAsLatestBg为true,则会采用涨跌色
    this.last = const MarkConfig(
      show: true,
      spacing: 1,
      line: LineConfig(
        type: LineType.dashed,
        dashes: [3, 3],
        paint: PaintConfig(
          strokeWidth: 0.5,
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
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),

    /// 最新价: 当最新蜡烛在可视区域时使用.
    /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorAsLatestBg为true,则会采用涨跌色
    this.latest = const MarkConfig(
      show: true,
      spacing: 1,
      line: LineConfig(
        type: LineType.dashed,
        dashes: [3, 3],
        paint: PaintConfig(
          strokeWidth: 0.5,
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
        border: BorderSide(width: 0.5),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    ),

    /// 最新蜡烛点: 仅在线图中使用.
    this.showLatestPoint = true,
    this.latestPoint = const PointConfig(
      radius: 2,
      width: 0,
      borderWidth: 2,
    ),

    /// 使用蜡烛颜色做为Latest的背景
    this.useCandleColorAsLatestBg = true,

    /// 倒计时, 在latest最新价之下展示
    this.showCountDown = true,
    this.countDown = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      textAlign: TextAlign.center,
      padding: EdgeInsets.all(2),
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
    this.chartType = FlexiChartType.barSolid,
    this.minWidthLineType,
    this.intervalChartTypes = const {},
    this.hideIndicatorsWhenLineChart = true,
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
  /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorAsLatestBg为true,则会采用涨跌色
  final MarkConfig last;

  /// 最新价: 当最新蜡烛在可视区域时使用.
  /// 注: 如果其中线的配置颜色透明度为0(默认为0) 且useCandleColorAsLatestBg为true,则会采用涨跌色
  final MarkConfig latest;

  /// 最新蜡烛点: 仅在线图中使用.
  final bool showLatestPoint;
  final PointConfig? latestPoint;

  /// 使用蜡烛颜色做为Latest的背景
  final bool useCandleColorAsLatestBg;

  /// 倒计时, 在latest最新价之下展示
  final bool showCountDown;
  final TextAreaConfig countDown;

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
  final bool hideIndicatorsWhenLineChart;

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
    with PaintYAxisTicksOnCrossMixin, PaintCandleHelperMixin {
  @override
  Color get longColor => indicator.longColor ?? theme.longColor;

  @override
  Color get shortColor => indicator.shortColor ?? theme.shortColor;

  FlexiNum? _maxHigh, _minLow;

  @override
  bool get hideIndicatorsWhenLineChart => indicator.hideIndicatorsWhenLineChart;

  @override
  FlexiChartType getChartType() {
    // 1. 优先检查时间周期映射（基于 milliseconds 匹配）
    final interval = klineData.interval;
    final chartTypes = indicator.intervalChartTypes;
    if (chartTypes != null && chartTypes.isNotEmpty) {
      for (final entry in chartTypes.entries) {
        if (entry.key.milliseconds == interval.milliseconds) {
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

  @override
  MinMax? initState(int start, int end) {
    if (!klineData.canPaintChart) return null;

    final minmax = klineData.calculateMinmax(start, end);
    _maxHigh = minmax?.max;
    _minLow = minmax?.min;
    return minmax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    final chartType = getChartType();

    switch (chartType) {
      case FlexiBarChartType(:final style):
        // 绘制蜡烛柱状图，传入样式
        paintBarTypeCandleChart(canvas, size, style);
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
            paintLatestCandlePoint(canvas, size);
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
            paintLatestCandlePoint(canvas, size);
        }
    }

    /// 绘制价钱刻度数据
    if (settingConfig.showYAxisTick) {
      paintYAxisPriceTick(canvas, size);
    }
  }

  @override
  void paintExtraAboveChart(Canvas canvas, Size size) {
    /// 绘制最新价刻度线与价钱标记
    paintLatestPriceMark(canvas, size);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    /// 绘制Cross Y轴价钱刻度
    paintYAxisTicksOnCross(
      canvas,
      offset,
      precision: klineData.precision,
    );
  }

  // onCross时, 格式化Y轴上的标记值.
  @override
  String formatTicksValueOnCross(FlexiNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: klineData.precision,
      cutInvalidZero: false,
    );
  }

  /// 绘制蜡烛柱状图
  void paintBarTypeCandleChart(Canvas canvas, Size size, ChartBarStyle style) {
    if (!klineData.canPaintChart) {
      logw('paintBarTypeCandleChart Data.list is empty or Index is out of bounds');
      return;
    }

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
      final highY = valueToDy(m.high);
      final lowY = valueToDy(m.low);
      paintCandleBar(
        canvas,
        m,
        dx: dx,
        high: highY,
        low: lowY,
        barWidthHalf: barWidthHalf,
        chartStyle: style,
      );

      if (indicator.high.show) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (m.high == _maxHigh) {
            maxHighOffset = Offset(dx, highY);
            maxHigh = _maxHigh!;
          }
        } else {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (m.high >= maxHigh) {
            maxHighOffset = Offset(dx, highY);
            maxHigh = m.high;
          }
        }
      }

      if (indicator.low.show) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (m.low == _minLow) {
            minLowOffset = Offset(dx, lowY);
            minLow = _minLow!;
          }
        } else {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (m.low <= minLow) {
            minLowOffset = Offset(dx, lowY);
            minLow = m.low;
          }
        }
      }
    }

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
    Offset endOffset = Offset(
      offset.dx + markConfig.lineLength * flag,
      offset.dy,
    );
    canvas.drawLine(
      offset,
      endOffset,
      markConfig.line.getLinePaint(theme.markLineColor),
    );

    endOffset = Offset(
      endOffset.dx + flag * markConfig.spacing,
      endOffset.dy - markConfig.text.areaHeight / 2,
    );

    final text = formatPrice(val.toDecimal(), precision: klineData.precision);

    canvas.drawTextArea(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      text: text,
      textConfig: markConfig.text,
      themeTextColor: theme.textColor,
    );
  }

  /// 缓存价钱刻度文本区域大小, 用于定位缩放拖拽条区域
  Size? _zoomSlideBarSize;

  /// 绘制蜡烛图右侧价钱刻度
  /// 根据Grid horizontal配置来绘制, 保证在grid.horizontal线之上.
  void paintYAxisPriceTick(Canvas canvas, Size size) {
    final dyStep = drawableRect.height / gridConfig.horizontal.count;
    final dx = chartRect.right;
    double dy = 0;
    double maxTickWidth = 0.0;
    for (int i = 1; i <= gridConfig.horizontal.count; i++) {
      dy = i * dyStep;
      final price = dyToValue(dy);
      if (price == null) continue;

      final text = formatPrice(
        price.toDecimal(),
        precision: klineData.precision,
        cutInvalidZero: false,
        enableGrouping: true,
      );

      final ticksText = defTicksTextConfig;

      final size = canvas.drawTextArea(
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

      if (size.width > maxTickWidth) maxTickWidth = size.width;
    }

    if (!gestureConfig.isManualSetZoomRect && (_zoomSlideBarSize == null || _zoomSlideBarSize!.width != maxTickWidth)) {
      final barSize = Size(maxTickWidth, drawableRect.height);
      _zoomSlideBarSize = barSize;
      updateZoomSlideBarRect(Rect.fromLTWH(
        drawableRect.right - barSize.width,
        drawableRect.top,
        barSize.width,
        barSize.height,
      ));
    }
  }

  /// 缓存latest文本相对于屏幕右侧的负偏移量
  @protected
  double latestTextOffset = 0.0;

  /// 缓存last文本所占大小
  @protected
  Size? lastTextSize;

  /// 最后价文本区域位置, 用于后续点击事件命中测试.
  Rect? get lastTextAreaRect {
    if (lastTextSize == null) return null;
    final model = klineData.latest;
    if (model == null) return null;
    // 计算最新价YAxis位置.
    final dy = clampDyInChart(valueToDy(model.close));
    return Rect.fromLTWH(
      chartRect.right + latestTextOffset - indicator.last.spacing - lastTextSize!.width,
      dy,
      lastTextSize!.width,
      lastTextSize!.height,
    );
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLatestPriceMark(Canvas canvas, Size size) {
    if (!indicator.latest.show && !indicator.last.show) return;
    final model = klineData.latest;
    if (model == null) {
      logd('paintLatestPriceMark > on data!');
      return;
    }

    // 计算最新价YAxis位置.
    double dy = clampDyInChart(valueToDy(model.close));

    // 计算最新价XAxis位置.
    final rdx = chartRect.right;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.

    if (paintDxOffset < latestTextOffset) {
      lastTextSize = null;
      // 绘制最新价和倒计时
      final MarkConfig latest = indicator.latest;
      if (!latest.show) return;

      ldx = startCandleDx;

      final useCandleColor = indicator.useCandleColorAsLatestBg;
      final updownColor = model.close >= model.open ? longColor : shortColor;

      final textConfig = indicator.latest.text;
      BorderRadius? borderRadius = textConfig.borderRadius;

      final halfHeight = textConfig.areaHeight / 2;
      // 修正dy位置
      dy = dy.clamp(
        drawableRect.top + halfHeight,
        drawableRect.bottom - halfHeight,
      );

      /// 绘制首根蜡烛到rdx的刻度线.
      final latestPath = Path();
      latestPath.moveTo(rdx, dy);
      latestPath.lineTo(ldx, dy);
      canvas.drawLineByConfig(
        latestPath,
        indicator.latest.line,
        themeColor: useCandleColor ? updownColor : theme.markLineColor,
      );

      /// 最新价文本和样式配置
      final text = formatPrice(
        model.close.toDecimal(),
        precision: klineData.precision,
        cutInvalidZero: false,
      );

      /// 倒计时Text
      String? countDownText;
      // 时间周期 > 1秒时才显示倒计时
      if (indicator.showCountDown && klineData.interval.milliseconds > Duration.millisecondsPerSecond) {
        final nextUpdateDateTime = model.nextUpdateDateTime(klineData.interval);
        if (nextUpdateDateTime != null &&
            nextUpdateDateTime.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch) {
          countDownText = nextUpdateDateTime.diffAsCountdown();
        }
      }
      if (countDownText != null) {
        // 如果展示倒计时, 最新价仅保留顶部radius
        borderRadius = borderRadius?.copyWith(
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: const Radius.circular(0),
          bottomRight: const Radius.circular(0),
        );
      }

      final offset = Offset(
        rdx - latest.spacing,
        dy - halfHeight, // 垂直居中
      );

      /// 绘制最新价标记
      final size = canvas.drawTextArea(
        offset: offset,
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: text,
        textConfig: textConfig,
        themeTextColor: useCandleColor ? white : theme.textColor,
        themeBackgroundColor: useCandleColor ? updownColor : theme.latestPriceBg,
        themeBorderColor: useCandleColor ? null : theme.markLineColor,
        borderRadius: borderRadius,
        borderSide: useCandleColor ? textConfig.border?.copyWith(color: transparent) : null,
      );
      latestTextOffset = -(size.width + latest.spacing);

      if (countDownText != null) {
        final countDown = indicator.countDown;
        // 展示倒计时, 倒计时radius始终使用最新价的, 且保留底部radius
        borderRadius = borderRadius?.copyWith(
          topLeft: const Radius.circular(0),
          topRight: const Radius.circular(0),
          bottomLeft: borderRadius.topLeft,
          bottomRight: borderRadius.topRight,
        );

        /// 绘制倒计时标记
        canvas.drawText(
          offset: Offset(
            offset.dx,
            offset.dy + size.height - 0.5,
          ),
          drawDirection: DrawDirection.rtl,
          drawableRect: drawableRect,
          text: countDownText,
          style: countDown.style.copyWith(
            color: theme.textColor,
            // 修正倒计时文本区域高度:
            // 由于倒计时使用了固定宽度(最新价的size.width), 保持与最新价同宽.
            // 此处无法再为countDown设置padding, 固在此处修正
            height: (countDown.areaHeight - 1) / countDown.textHeight,
          ),
          textAlign: countDown.textAlign,
          textWidth: size.width,
          // padding: countDown.padding,
          backgroundColor: theme.countDownBg,
          borderRadius: borderRadius,
          borderSide: BorderSide(
            color: useCandleColor ? const Color(0x00000000) : theme.markLineColor,
            width: countDown.border?.width ?? 0.5,
          ),
          maxLines: countDown.maxLines ?? 1,
        );
      }
    } else {
      /// 绘制最后价
      final last = indicator.last;
      if (!last.show) return;

      ldx = 0;

      final halfHeight = last.text.areaHeight / 2;
      // 修正dy位置
      dy = dy.clamp(
        drawableRect.top + halfHeight,
        drawableRect.bottom - halfHeight,
      );

      /// 绘制横穿画板的最后价刻度线.
      final lastPath = Path();
      if (lastTextSize != null) {
        final lastTextAreaRight = rdx + latestTextOffset - last.spacing;
        lastPath.moveTo(rdx, dy);
        lastPath.lineTo(lastTextAreaRight, dy);
        lastPath.moveTo(lastTextAreaRight - lastTextSize!.width, dy);
        lastPath.lineTo(ldx, dy);
      } else {
        lastPath.moveTo(rdx, dy);
        lastPath.lineTo(ldx, dy);
      }
      canvas.drawLineByConfig(
        lastPath,
        last.line,
        themeColor: theme.markLineColor,
      );

      final text = formatPrice(
        model.close.toDecimal(),
        precision: klineData.precision,
        cutInvalidZero: false,
      );

      /// 绘制最后价标记
      lastTextSize = canvas.drawTextArea(
        offset: Offset(
          rdx + latestTextOffset - last.spacing,
          dy - halfHeight, // 居中
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: '$text ▸', // ➤➤▹►▸▶︎≻
        textConfig: last.text,
        themeTextColor: theme.lastPriceColor,
        themeBackgroundColor: theme.lastPriceBg,
      );
    }
  }

  /// 绘制最新蜡烛点
  void paintLatestCandlePoint(Canvas canvas, Size size) {
    if (!indicator.showLatestPoint) return;
    if (indicator.latestPoint == null) return;
    final model = klineData.latest;
    if (model == null) {
      logd('paintLatestCandlePoint > on data!');
      return;
    }
    if (paintDxOffset > latestTextOffset) {
      // 最新价在屏幕右侧, 不绘制点
      // logd('paintLatestCandlePoint > latestPoint is on the right of the screen!');
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
      themeBorderColor: theme.lineChartColor.withAlpha(0x7F),
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

  @override
  bool handleTap(Offset position) {
    final lastTxtRect = lastTextAreaRect?.inflate(indicator.last.hitTestMargin);
    if (lastTxtRect != null && lastTxtRect.include(position)) {
      // 命中最后价区域, 此时应该移动到蜡烛图初始位置
      moveToInitialPosition();
      return true;
    }
    return false;
  }
}
