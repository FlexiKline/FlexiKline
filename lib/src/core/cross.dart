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

part of 'core.dart';

/// 定制TooltipInfoList
///
/// [current] 当前Cross选中的CandleMode数据.
///   如果为null, 说明当前Cross线已取消.
/// [prev] 前一个CandleMode数据
/// 1. 如果返回null, 则尝试用 [OnCrossI18nTooltipLables] 继续定制.
/// 2. 如果返回const [], 则不会再展示Tooltip信息.
typedef OnCrossCustomTooltipCallback = List<TooltipInfo>? Function(
  CandleModel? current, {
  CandleModel? prev,
});

/// 定制TooltipLables国际化
///
/// 1. 如果返回null, 则使用默认[defaultTooltipLables] 生成TooltipInfoList
/// 2. 如果返回const {}, 则不会再展示Tooltip信息
typedef OnCrossI18nTooltipLables = Map<TooltipLabel, String>? Function();

/// 负责Cross图层的绘制
///
/// 处理cross事件.
/// Tooltip的绘制.
mixin CrossBinding on KlineBindingBase, SettingBinding implements ICross {
  @override
  void initState() {
    super.initState();
    logd('initState cross');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose cross');
    _repaintCross.dispose();
  }

  final ValueNotifier<int> _repaintCross = ValueNotifier(0);
  Listenable get repaintCross => _repaintCross;
  void _markRepaintCross() {
    _repaintCross.value++;
  }

  //// Cross ////
  @override
  void markRepaintCross() {
    if (isCrossing) {
      _updateOffset(_offset);
      _markRepaintCross();
    }
  }

  LineConfig? _crosshair;
  PointConfig? _crosspoint;

  @override
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    super.onThemeChanged(oldTheme);
    _crosshair = null;
    _crosspoint = null;
  }

  @override
  void onLanguageChanged() {
    super.onLanguageChanged();
    markRepaintCross();
  }

  // 是否正在绘制Cross
  @override
  bool get isCrossing => crossOffset?.isFinite == true;

  Offset? _offset;
  @override
  Offset? get crossOffset => _offset;
  void _updateOffset(Offset? val) {
    if (val != null) {
      _offset = _correctCrossOffset(val);
    } else {
      _offset = null;
    }
  }

  /// 矫正Cross
  Offset? _correctCrossOffset(Offset val) {
    if (val.isInfinite) return null;

    // Horizontal轴按蜡烛线移动.
    val = val.clamp(canvasRect);
    final diff = startCandleDx - val.dx;
    if (!crossConfig.moveByCandleInBlank && diff < 0) return val;
    return Offset(
      val.dx + diff % candleActualWidth - candleWidthHalf,
      val.dy,
    );

    // 当超出边界时, 校正到边界.
    // if (canvasRect.contains(val)) {
    //   final diff = (startCandleDx - val.dx) % candleActualWidth;
    //   final dx = val.dx + diff - candleWidthHalf;
    //   return Offset(dx, val.dy);
    // } else {
    //   return val.clamp(canvasRect);
    // }
  }

  /// 启动Cross事件
  bool onCrossStart(GestureData data, {bool force = false}) {
    if (crossConfig.enable) {
      /// 如果其他手势与Cross手势事件允许共存 或者当前不在Crossing中时, 开启Cross.
      if (force || !isCrossing) {
        logd('handleTap cross > $force > ${data.offset}');
        // 更新并校正起始焦点.
        _updateOffset(data.offset);
        _markRepaintCross();
        // 当Cross事件启动后, 调用markRepaintChart清理Chart图层的tips信息.
        markRepaintChart();
        return true;
      }

      cancelCross();
      onCrossCustomTooltip?.call(null);
      return false;
    }
    return false;
  }

  /// 更新Cross事件数据.
  void onCrossUpdate(GestureData data) {
    if (crossConfig.enable && isCrossing) {
      _updateOffset(data.offset);
      _markRepaintCross();
    }
  }

  /// 取消当前Cross事件
  @override
  void cancelCross() {
    if (isCrossing || _offset != null) {
      _updateOffset(null);
      // 当Cross事件结束后, 调用markRepaintChart触发绘制Chart图层首根蜡烛的tips信息.
      markRepaintChart();
      _markRepaintCross();
    }
  }

  /// 绘制最新价与十字线
  void paintCross(Canvas canvas, Size size) {
    if (crossConfig.enable != true) return;

    if (isCrossing) {
      final offset = _offset;
      if (offset == null || offset.isInfinite) {
        return;
      }

      CandleModel? model;
      if (crossConfig.showLatestTipsInBlank) {
        model = dxToCandle(offset.dx);
        // 如果当前model为空, 则根据offset.dx计算当前model是最新的, 还是最后的.
        if (model == null && curKlineData.isNotEmpty) {
          if (offset.dx > startCandleDx) {
            model = curKlineData.latest;
          } else {
            model = curKlineData.list.last;
          }
        }
      }

      /// 绘制Cross Line
      paintCrossLine(canvas, offset);

      /// 绘制 Tooltip
      paintTooltip(canvas, offset, model: model);

      for (var paintObject in subPaintObjects) {
        paintObject.doOnCross(canvas, offset, model: model);
      }
      mainPaintObject.doOnCross(canvas, offset, model: model);
    }
  }

  /// 绘制Cross Line
  @protected
  void paintCrossLine(Canvas canvas, Offset offset) {
    final path = Path()
      ..moveTo(mainChartLeft, offset.dy)
      ..lineTo(mainChartRight, offset.dy)
      ..moveTo(offset.dx, 0)
      ..lineTo(offset.dx, canvasHeight);

    _crosshair ??= crossConfig.crosshair.of(paintColor: theme.crossColor);

    canvas.drawLineByConfig(
      path,
      _crosshair!,
    );

    _crosspoint ??= crossConfig.crosspoint.of(color: theme.crossColor);
    canvas.drawCirclePoint(
      offset,
      _crosspoint!,
    );
  }

  /// 绘制 Tooltip
  void paintTooltip(Canvas canvas, Offset offset, {CandleModel? model}) {
    final tooltipConfig = crossConfig.tooltipConfig;
    if (!tooltipConfig.show) return;
    final tooltipTextStyle = tooltipConfig.style.copyWith(
      color: theme.tooltipTextColor,
    );

    int? index = dxToIndex(offset.dx);
    if (index == null) return;
    model ??= curKlineData.get(index);
    final pre = curKlineData.get(index + 1);
    if (model == null) return;

    /// 准备数据
    // 1. 使用定制接口生成TooltipInfoList.
    List<TooltipInfo>? tooltipInfoList;
    if (onCrossCustomTooltip != null) {
      tooltipInfoList = onCrossCustomTooltip!(model, prev: pre);
    }

    if (tooltipInfoList == null) {
      Map<TooltipLabel, String>? tooltipLables;
      // 2. 使用定制多语言TooltipLables生成TooltipInfoList
      if (onCrossI18nTooltipLables != null) {
        tooltipLables = onCrossI18nTooltipLables!.call();
      }
      // 3. 使用FlexiKline内置(默认En)的Lables生成TooltipInfoList
      tooltipLables ??= defaultTooltipLables;

      tooltipInfoList = genTooltipInfoListByLables(
        tooltipLables,
        model: model,
        pre: pre,
      );
    }

    if (tooltipInfoList.isEmpty) return;

    /// 初始化绘制数据
    final labelSpanList = <TextSpan>[];
    final valueSpanList = <TextSpan>[];
    TooltipInfo info;
    for (int i = 0; i < tooltipInfoList.length; i++) {
      info = tooltipInfoList[i];
      String br = i < tooltipInfoList.length - 1 ? '\n' : '';
      labelSpanList.add(TextSpan(
        text: info.label + br,
        style: info.labelStyle ?? tooltipTextStyle,
      ));
      TextStyle valStyle = info.valueStyle ?? tooltipTextStyle;
      if (info.riseOrFall > 0) {
        valStyle = valStyle.copyWith(color: theme.long);
      } else if (info.riseOrFall < 0) {
        valStyle = valStyle.copyWith(color: theme.short);
      }
      valueSpanList.add(TextSpan(
        text: info.value + br,
        style: valStyle,
      ));
    }

    /// 开始绘制
    double top = tooltipConfig.margin.top;
    if (isStartZoomChart) {
      top += mainOriginPadding.top;
    } else {
      top += mainPadding.top;
    }

    if (offset.dx > mainChartWidthHalf) {
      // 点击区域在右边; 绘制在左边
      Offset offset = Offset(
        mainRect.left + tooltipConfig.margin.left,
        mainRect.top + top,
      );

      final size = canvas.drawText(
        offset: offset,
        drawDirection: DrawDirection.ltr,
        drawableRect: mainChartRect,
        textSpan: TextSpan(
          children: labelSpanList,
          style: tooltipTextStyle,
        ),
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: theme.tooltipBg,
        borderRadius: BorderRadius.only(
          topLeft: tooltipConfig.radius.topLeft,
          bottomLeft: tooltipConfig.radius.bottomLeft,
        ),
      );

      canvas.drawText(
        offset: Offset(
          offset.dx + size.width - 1,
          offset.dy,
        ),
        drawDirection: DrawDirection.ltr,
        drawableRect: mainChartRect,
        textSpan: TextSpan(
          children: valueSpanList,
          style: tooltipTextStyle,
        ),
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: theme.tooltipBg,
        borderRadius: BorderRadius.only(
          topRight: tooltipConfig.radius.topRight,
          bottomRight: tooltipConfig.radius.bottomRight,
        ),
      );
    } else {
      // 点击区域在左边; 绘制在右边
      Offset offset = Offset(
        mainRect.right - tooltipConfig.margin.right,
        mainRect.top + top,
      );

      final size = canvas.drawText(
        offset: offset,
        drawDirection: DrawDirection.rtl,
        drawableRect: mainChartRect,
        textSpan: TextSpan(
          children: valueSpanList,
          style: tooltipTextStyle,
        ),
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: theme.tooltipBg,
        borderRadius: BorderRadius.only(
          topRight: tooltipConfig.radius.topRight,
          bottomRight: tooltipConfig.radius.bottomRight,
        ),
      );

      canvas.drawText(
        offset: Offset(
          offset.dx - size.width + 1,
          offset.dy,
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: mainChartRect,
        textSpan: TextSpan(
          children: labelSpanList,
          style: tooltipTextStyle,
        ),
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: theme.tooltipBg,
        borderRadius: BorderRadius.only(
          topLeft: tooltipConfig.radius.topLeft,
          bottomLeft: tooltipConfig.radius.bottomLeft,
        ),
      );
    }
  }

  /// Tooltip定制回调
  /// 当未实现此接口或定制返回null: 后续将触发[onCrossI18nTooltipLables]接口实现.
  /// 当定制返回[]空数组时: 说明由用户自行在页面自由定制.
  OnCrossCustomTooltipCallback? onCrossCustomTooltip;

  /// TooltipLables多语言回调
  /// 当未实现此接口或定制返回为null: 将使用[defaultTooltipLables]默认英文Tooltip.
  OnCrossI18nTooltipLables? onCrossI18nTooltipLables;

  /// 根据TooltipLables生成TooltipInfoList.
  List<TooltipInfo> genTooltipInfoListByLables(
    Map<TooltipLabel, String> tooltipLables, {
    required CandleModel model,
    CandleModel? pre,
  }) {
    if (tooltipLables.isEmpty) return const [];
    final p = curKlineData.precision;

    final list = <TooltipInfo>[];
    tooltipLables.forEach((key, label) {
      String? value;
      int riseOrFall = 0;
      switch (key) {
        case TooltipLabel.time:
          final timeBar = curKlineData.timeBar;
          value = model.formatDateTime(timeBar);
          break;
        case TooltipLabel.open:
          value = formatPrice(model.o, precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.high:
          value = formatPrice(model.h, precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.low:
          value = formatPrice(model.l, precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.close:
          value = formatPrice(model.c, precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.chg:
          value = formatPrice(model.change, precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.chgRate:
          value = formatPercentage(model.changeRate.d, precision: 2);
          riseOrFall = model.change.signum;
          break;
        case TooltipLabel.range:
          if (pre != null) {
            value = formatPercentage(model.rangeRate(pre).d, precision: 2);
          } else {
            value = formatPrice(model.range, precision: p, cutInvalidZero: false);
          }
          break;
        case TooltipLabel.amount:
          value = formatAmount(model.v, precision: 2);
          break;
        case TooltipLabel.turnover:
          if (model.vc != null) {
            value = formatAmount(model.vc, precision: 2);
          }
          break;
      }
      if (value != null) {
        list.add(TooltipInfo(
          label: label,
          value: value,
          riseOrFall: riseOrFall,
        ));
      }
    });
    return list;
  }
}
