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
    required super.height,
    super.padding = defaultMainIndicatorPadding,

    // 最高价
    required this.high,
    // 最低价
    required this.low,
    // 最后价: 当最新蜡烛不在可视区域时使用.
    required this.last,
    // 最新价: 当最新蜡烛在可视区域时使用.
    required this.latest,
    this.useCandleColorAsLatestBg = true,
    // 倒计时, 在latest最新价之下展示
    this.showCountDown = true,
    required this.countDown,
    this.chartType = ChartType.bar,
    this.chartBarStyle = ChartBarStyle.allSolid,
    this.useLineChartForZoom = true,
    this.longColor,
    this.shortColor,
    this.lineColor,
  });

  // 最高价
  final MarkConfig high;
  // 最低价
  final MarkConfig low;
  // 最后价: 当最新蜡烛不在可视区域时使用.
  final MarkConfig last;
  // 最新价: 当最新蜡烛在可视区域时使用.
  final MarkConfig latest;
  // 使用蜡烛颜色做为Latest的背景
  final bool useCandleColorAsLatestBg;
  // 倒计时, 在latest最新价之下展示
  final bool showCountDown;
  final TextAreaConfig countDown;

  // Kline图表类型
  final ChartType chartType;
  // Kline图表样式
  final ChartBarStyle chartBarStyle;
  // Kline缩放到最小单位时使用线图
  final bool useLineChartForZoom;

  // 自定义上涨颜色
  final Color? longColor;
  // 自定义下跌颜色
  final Color? shortColor;
  // 自定义line图颜色
  final Color? lineColor;

  @override
  CandlePaintObject createPaintObject(IPaintContext context) {
    return CandlePaintObject(context: context, indicator: this);
  }

  factory CandleIndicator.fromJson(Map<String, dynamic> json) => _$CandleIndicatorFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CandleIndicatorToJson(this);
}

class CandlePaintObject<T extends CandleIndicator> extends CandleBasePaintObject<T>
    with PaintYAxisTicksOnCrossMixin, PaintCandleHelperMixin {
  CandlePaintObject({
    required super.context,
    required super.indicator,
  });

  @override
  Color get longColor => indicator.longColor ?? theme.long;

  @override
  Color get shortColor => indicator.shortColor ?? theme.short;

  BagNum? _maxHigh, _minLow;

  @override
  MinMax? initState(int start, int end) {
    if (!klineData.canPaintChart) return null;

    MinMax? minmax = klineData.calculateMinmax(start, end);
    _maxHigh = minmax?.max;
    _minLow = minmax?.min;
    return minmax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    switch (indicator.chartType) {
      case ChartType.bar:
        if (indicator.useLineChartForZoom && candleWidth < 1) {
          /// 绘制蜡烛线图
          paintLineTypeCandleChart(
            canvas,
            startOffset: startCandleDx - candleWidthHalf,
            linePaint: getLinePaint(
              color: indicator.lineColor,
              strokeWidth: candleLineWidth,
            ),
          );
        } else {
          /// 绘制蜡烛柱状图
          paintBarTypeCandleChart(canvas, size);
        }
      case ChartType.line:
        // 绘制蜡烛线图
        paintLineTypeCandleChart(
          canvas,
          startOffset: startCandleDx - candleWidthHalf,
          linePaint: getLinePaint(
            color: indicator.lineColor,
            strokeWidth: candleLineWidth,
          ),
        );
      case ChartType.upDownLine:
        // 绘制蜡烛线图
        paintUpDownLineTypeCandleChart(
          canvas,
          startOffset: startCandleDx - candleWidthHalf,
        );
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
  String formatTicksValueOnCross(BagNum value, {required int precision}) {
    return formatPrice(
      value.toDecimal(),
      precision: klineData.precision,
      cutInvalidZero: false,
    );
  }

  /// 绘制蜡烛柱状图
  void paintBarTypeCandleChart(Canvas canvas, Size size) {
    if (!klineData.canPaintChart) {
      logw('paintBarTypeCandleChart Data.list is empty or Index is out of bounds');
      return;
    }

    int start = klineData.start;
    int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;
    final barWidthHalf = candleWidthHalf - candleSpacing;

    Offset? maxHihgOffset, minLowOffset;
    bool hasEnough = paintDxOffset > 0;
    BagNum maxHigh = klineData[start].high;
    BagNum minLow = klineData[start].low;
    CandleModel m;
    for (var i = start; i < end; i++) {
      m = klineData[i];
      final dx = offset - (i - start) * candleActualWidth;
      final hight = valueToDy(m.high);
      final low = valueToDy(m.low);
      paintCandleBar(
        canvas,
        m,
        dx: dx,
        high: hight,
        low: low,
        barWidthHalf: barWidthHalf,
        chartStyle: indicator.chartBarStyle,
      );

      if (indicator.high.show) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (m.high == _maxHigh) {
            maxHihgOffset = Offset(dx, hight);
            maxHigh = _maxHigh!;
          }
        } else if (dx > 0) {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (m.high >= maxHigh) {
            maxHihgOffset = Offset(dx, hight);
            maxHigh = m.high;
          }
        }
      }

      if (indicator.low.show) {
        if (hasEnough) {
          // 满足一屏, 根据initData中的最大最小值来记录最大最小偏移量.
          if (m.low == _minLow) {
            minLowOffset = Offset(dx, low);
            minLow = _minLow!;
          }
        } else {
          // 如果当前绘制不足一屏, 最大最小绘制仅限可见区域.
          if (m.low <= minLow) {
            minLowOffset = Offset(dx, low);
            minLow = m.low;
          }
        }
      }
    }

    // 最后绘制在蜡烛图中的最大价钱标记
    if (maxHihgOffset != null && maxHigh > BagNum.zero) {
      paintPriceMark(canvas, maxHihgOffset, maxHigh, indicator.high);
    }
    // 最后绘制在蜡烛图中的最小价钱标记
    if (minLowOffset != null && minLow > BagNum.zero) {
      paintPriceMark(canvas, minLowOffset, minLow, indicator.low);
    }
  }

  /// 绘制蜡烛图上最大最小值价钱标记.
  void paintPriceMark(
    Canvas canvas,
    Offset offset,
    BagNum val,
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
      markConfig.line.of(paintColor: theme.markLineColor).linePaint,
    );

    final markText = markConfig.text.of(textColor: theme.textColor);

    endOffset = Offset(
      endOffset.dx + flag * markConfig.spacing,
      endOffset.dy - (markText.areaHeight) / 2,
    );

    final text = formatPrice(val.toDecimal(), precision: klineData.precision);

    canvas.drawTextArea(
      offset: endOffset,
      drawDirection: flag < 0 ? DrawDirection.rtl : DrawDirection.ltr,
      text: text,
      textConfig: markText,
    );
  }

  /// 缓存价钱刻度文本区域大小, 用于定位缩放拖拽条区域
  Size? _zoomSlideBarize;

  /// 绘制蜡烛图右侧价钱刻度
  /// 根据Grid horizontal配置来绘制, 保证在grid.horizontal线之上.
  void paintYAxisPriceTick(Canvas canvas, Size size) {
    final dyStep = drawableRect.height / gridConfig.horizontal.count;
    final dx = chartRect.right;
    double dy = 0;
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
      );
      if (settingConfig.useCandleTicksAsZoomSlideBar) {
        final newSize = Size(size.width, drawableRect.height);
        if (newSize != _zoomSlideBarize) {
          _zoomSlideBarize = newSize;
          updateZoomSlideBarRect(Rect.fromLTWH(
            drawableRect.right - newSize.width,
            drawableRect.top,
            newSize.width,
            newSize.height,
          ));
        }
      }
    }
  }

  /// 缓存latest文本相对于屏幕右侧的负偏移量
  double _latestTextOffset = 0.0;

  /// 缓存last文本所占大小
  Size? _lastTextSize;

  /// 最后价文本区域位置, 用于后续点击事件命中测试.
  Rect? get lastTextAreaRect {
    if (_lastTextSize == null) return null;
    final model = klineData.latest;
    if (model == null) return null;
    // 计算最新价YAxis位置.
    double dy;
    if (model.close >= minMax.max) {
      dy = drawableRect.top; // 画板顶部展示.
    } else if (model.close <= minMax.min) {
      dy = drawableRect.bottom; // 画板底部展示.
    } else {
      dy = clampDyInChart(valueToDy(model.close));
    }
    return Rect.fromLTWH(
      chartRect.right + _latestTextOffset - indicator.last.spacing - _lastTextSize!.width,
      dy,
      _lastTextSize!.width,
      _lastTextSize!.height,
    );
  }

  /// 绘制最新价刻度线与价钱标记
  /// 1. 价钱标记始终展示在画板最右边.
  /// 2. 最新价向右移出屏幕后, 刻度线横穿整屏.
  ///    且展示在指定价钱区间内, 如超出边界, 则停靠在最高最低线上.
  /// 3. 最新价向左移动后, 刻度线根据最新价蜡烛线平行移动.
  void paintLatestPriceMark(Canvas canvas, Size size) {
    if (!indicator.latest.show || !indicator.last.show) return;
    final model = klineData.latest;
    if (model == null) {
      logd('paintLatestPriceMark > on data!');
      return;
    }

    // 计算最新价YAxis位置.
    double dy = clampDyInChart(valueToDy(model.close));
    // if (model.close >= minMax.max) {
    //   dy = chartRect.top; // 画板顶部展示.
    // } else if (model.close <= minMax.min) {
    //   dy = chartRect.bottom; // 画板底部展示.
    // } else {
    //   dy = clampDyInChart(valueToDy(model.close));
    // }

    // 计算最新价XAxis位置.
    final rdx = chartRect.right;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.

    if (paintDxOffset < _latestTextOffset) {
      _lastTextSize = null;
      // 绘制最新价和倒计时
      final latest = indicator.latest;
      if (!latest.show) return;

      ldx = startCandleDx;

      TextAreaConfig textConfig;
      if (indicator.useCandleColorAsLatestBg) {
        textConfig = latest.text.copyWith(
          style: latest.text.style.copyWith(color: const Color(0xFFFFFFFF)),
          background: model.close >= model.open ? longColor : shortColor,
          border: BorderSide.none,
        );
      } else {
        textConfig = latest.text.of(
          textColor: theme.textColor,
          background: theme.latestPriceTextBg,
          borderColor: theme.markLineColor,
        );
      }

      Color? background = textConfig.background;
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
        latest.line.of(paintColor: theme.markLineColor),
      );

      /// 最新价文本和样式配置
      final text = formatPrice(
        model.close.toDecimal(),
        precision: klineData.req.precision,
        cutInvalidZero: false,
      );

      /// 倒计时Text
      String? countDownText;
      if (indicator.showCountDown && !klineData.isTimeChart) {
        final nextUpdateDateTime = model.nextUpdateDateTime(klineData.req.bar);
        if (nextUpdateDateTime != null) {
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
        backgroundColor: background,
        borderRadius: borderRadius,
      );
      _latestTextOffset = -(size.width + latest.spacing);

      if (countDownText != null) {
        TextAreaConfig countDown;
        if (indicator.useCandleColorAsLatestBg) {
          countDown = indicator.countDown.of(
            textColor: theme.textColor,
            background: theme.countDownTextBg,
          );
        } else {
          countDown = indicator.countDown.of(
            textColor: theme.textColor,
            background: theme.countDownTextBg,
            borderColor: theme.markLineColor,
          );
        }

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
            // 修正倒计时文本区域高度:
            // 由于倒计时使用了固定宽度(最新价的size.width), 保持与最新价同宽.
            // 此处无法再为countDown设置padding, 固在此处修正
            height: (countDown.areaHeight - 1) / countDown.textHeight,
          ),
          textAlign: countDown.textAlign,
          textWidth: size.width,
          // padding: countDown.padding,
          backgroundColor: countDown.background,
          borderRadius: borderRadius,
          borderSide: countDown.border,
          maxLines: countDown.maxLines ?? 1,
        );
      }
    } else {
      /// 绘制最后价
      final last = indicator.last;
      if (!last.show) return;

      ldx = 0;

      final lastText = last.text.of(
        textColor: theme.lastPriceTextColor,
        background: theme.lastPriceTextBg,
      );

      final halfHeight = lastText.areaHeight / 2;
      // 修正dy位置
      dy = dy.clamp(
        drawableRect.top + halfHeight,
        drawableRect.bottom - halfHeight,
      );

      /// 绘制横穿画板的最后价刻度线.
      final lastPath = Path();
      if (_lastTextSize != null) {
        final lastTextAreaRight = rdx + _latestTextOffset - last.spacing;
        lastPath.moveTo(rdx, dy);
        lastPath.lineTo(lastTextAreaRight, dy);
        lastPath.moveTo(lastTextAreaRight - _lastTextSize!.width, dy);
        lastPath.lineTo(ldx, dy);
      } else {
        lastPath.moveTo(rdx, dy);
        lastPath.lineTo(ldx, dy);
      }
      canvas.drawLineByConfig(
        lastPath,
        last.line.of(paintColor: theme.markLineColor),
      );

      final text = formatPrice(
        model.close.toDecimal(),
        precision: klineData.precision,
        cutInvalidZero: false,
      );

      /// 绘制最后价标记
      _lastTextSize = canvas.drawTextArea(
        offset: Offset(
          rdx + _latestTextOffset - last.spacing,
          dy - halfHeight, // 居中
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: '$text ▸', // ➤➤▹►▸▶︎≻
        textConfig: lastText,
      );
    }
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
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
