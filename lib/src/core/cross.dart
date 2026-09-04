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
/// 1. 如果返回null, 则尝试用 [OnCrossI18nTooltipLabels] 继续定制.
/// 2. 如果返回const [], 则不会再展示Tooltip信息.
typedef OnCrossCustomTooltipCallback = List<TooltipInfo>? Function(
  FlexiCandleModel? current, {
  FlexiCandleModel? prev,
});

/// 定制TooltipLabels国际化
///
/// 1. 如果返回null, 则使用默认[defaultTooltipLabels] 生成TooltipInfoList
/// 2. 如果返回const {}, 则不会再展示Tooltip信息
typedef OnCrossI18nTooltipLabels = Map<TooltipLabel, String>? Function();

/// 负责Cross图层的绘制
///
/// 处理cross事件.
/// Tooltip的绘制.
mixin CrossBinding on KlineBindingBase, SettingBinding {
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
    _crossOffsetNotifier.dispose();
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
      _updateOffset(crossOffset);
      _markRepaintCross();
    }
  }

  @override
  void onLanguageChanged() {
    super.onLanguageChanged();
    markRepaintCross();
  }

  // 是否正在绘制Cross
  @override
  bool get isCrossing => crossOffset?.isFinite == true;
  @override
  Offset? get crossOffset => _crossOffsetNotifier.value;

  /// 对外暴露 Cross 焦点的可监听对象, 供外部订阅焦点变化.
  ValueListenable<Offset?> get crossOffsetListenable => _crossOffsetNotifier;

  /// 当前 Cross 焦点位置, 为 null 时表示未处于 crossing 状态.
  final _crossOffsetNotifier = FlexiStateNotifier<Offset?>(null);
  void _updateOffset(Offset? val) {
    if (val != null) {
      _crossOffsetNotifier.value = _correctCrossOffset(val);
    } else {
      _crossOffsetNotifier.value = null;
      _tooltipStableContentWidth = null;
    }
    _clearTooltipHitTestData();
  }

  final List<_TooltipTapTarget> _tooltipTapTargets = [];

  /// 当前 crossing 会话内观测到的最大 Tooltip 内容区宽度（不含 padding）。
  double? _tooltipStableContentWidth;

  void _clearTooltipHitTestData() {
    _tooltipTapTargets.clear();
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

  /// 点击语义: 未开则开、已开则关。返回开启后是否处于 crossing。
  ///
  /// 服务「点一下进入十字线、再点一下退出」这一族输入(手指 tap、鼠标左键)。跟随类输入
  /// (hover)绝不能走这里 —— 指针每移动一步都会把十字线关掉, 那是 [onCrossFollow]。
  /// 两者在已开状态下做相反的事, 所以是两个方法而不是一个布尔参数。
  bool onCrossToggle(Offset position) {
    if (!crossConfig.enable || !klineData.canPaintChart) return false;
    if (isCrossing) {
      requestCancelCross();
      onCrossCustomTooltip?.call(null);
      return false;
    }
    logd('onCrossToggle > $position');
    _openCross(position);
    return true;
  }

  /// 跟随语义: 未开则开, 已开则只移动十字线。
  ///
  /// 服务持续跟随的输入(鼠标 hover、手写笔悬停)。已开时刻意走轻量路径:
  /// [onPaintObjectDragCancel] 与 [markRepaintChart](全图重绘)只在「从无到有地开启」时
  /// 才有意义, 指针每移动一步都做一遍太贵。
  void onCrossFollow(Offset position) {
    if (!crossConfig.enable || !klineData.canPaintChart) return;
    if (isCrossing) {
      _updateOffset(position);
      _markRepaintCross();
      return;
    }
    logd('onCrossFollow open > $position');
    _openCross(position);
  }

  /// 从无到有地开启 cross: 取消可能正在进行的对象拖动, 并清理 Chart 图层的 tips。
  void _openCross(Offset position) {
    onPaintObjectDragCancel();
    // 更新并校正起始焦点.
    _updateOffset(position);
    _markRepaintCross();
    // 当Cross事件启动后, 调用markRepaintChart清理Chart图层的tips信息.
    markRepaintChart();
  }

  /// 已开则移动十字线, 未开不做事。
  ///
  /// 服务「十字线跟着别的手势走」的场景: 图表平移中的跟随、signal 平移后的重吸附、
  /// 落点归属为 cross 的拖动。它不负责开启, 所以未开时是空操作。
  void onCrossUpdate(Offset position) {
    if (crossConfig.enable && isCrossing) {
      _updateOffset(position);
      _markRepaintCross();
    }
  }

  /// 请求取消当前 cross。
  @override
  void requestCancelCross() {
    if (isCrossing || crossOffset != null) {
      _updateOffset(null);
      // 当Cross事件结束后, 调用markRepaintChart触发绘制Chart图层首根蜡烛的tips信息.
      markRepaintChart();
      _markRepaintCross();
    }
  }

  /// 绘制最新价与十字线
  void paintCross(Canvas canvas, Size size) {
    if (!crossConfig.enable) return;

    if (isCrossing) {
      final offset = crossOffset;
      if (offset == null || offset.isInfinite) {
        return;
      }

      FlexiCandleModel? model;
      if (crossConfig.showLatestTipsInBlank) {
        model = dxToCandle(offset.dx);
        // 如果当前model为空, 则根据offset.dx计算当前model是最新的, 还是最后的.
        if (model == null && klineData.isNotEmpty) {
          if (offset.dx > startCandleDx) {
            model = klineData.latest;
          } else {
            model = klineData.list.last;
          }
        }
      }

      /// 绘制Cross Line
      paintCrossLine(canvas, offset);

      /// 绘制 Tooltip
      paintTooltip(canvas, offset, model: model);

      for (final paintObject in subPaintObjects) {
        paintObject.doPaintCross(canvas, offset, model: model);
      }
      mainPaintObject.doPaintCross(canvas, offset, model: model);
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

    canvas.drawLineByConfig(
      path,
      crossConfig.crosshair,
      themeColor: theme.crosshairColor,
    );

    canvas.drawCirclePoint(
      offset,
      crossConfig.crosspoint,
      themeColor: theme.crosshairColor,
      themeBorderColor: theme.crosshairColor.withAlpha(0.2.alpha),
    );
  }

  /// 绘制 Tooltip
  void paintTooltip(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    _clearTooltipHitTestData();

    final tooltipConfig = crossConfig.tooltipConfig;
    if (!tooltipConfig.show) return;
    final tooltipTextStyle = tooltipConfig.style.ensure(theme.tooltipTextColor);

    final index = dxToIndex(offset.dx);
    if (index == null) return;
    model ??= klineData.get(index);
    final prev = klineData.get(index + 1);
    if (model == null) return;

    /// 准备数据
    // 1. 使用定制接口生成TooltipInfoList.
    List<TooltipInfo>? tooltipInfoList;
    if (onCrossCustomTooltip != null) {
      tooltipInfoList = onCrossCustomTooltip!(model, prev: prev);
    }

    if (tooltipInfoList == null) {
      Map<TooltipLabel, String>? tooltipLabels;
      // 2. 使用定制多语言TooltipLabels生成TooltipInfoList
      if (onCrossI18nTooltipLabels != null) {
        tooltipLabels = onCrossI18nTooltipLabels!.call();
      }
      // 3. 使用FlexiKline内置(默认En)的Labels生成TooltipInfoList
      tooltipLabels ??= defaultTooltipLabels;

      tooltipInfoList = generateTooltipInfoListByLabels(
        tooltipLabels,
        model: model,
        pre: prev,
      );
    }

    if (tooltipInfoList.isEmpty) return;
    final list = tooltipInfoList;

    /// 开始绘制
    final double top = tooltipConfig.margin.top + mainPadding.top;

    final drawOnLeft = offset.dx > mainChartWidthHalf;
    final drawDirection = drawOnLeft ? DrawDirection.ltr : DrawDirection.rtl;
    final tooltipOffset = Offset(
      drawOnLeft ? mainRect.left + tooltipConfig.margin.left : mainRect.right - tooltipConfig.margin.right,
      top,
    );

    final availableWidth = drawOnLeft ? mainChartRect.right - tooltipOffset.dx : tooltipOffset.dx - mainChartRect.left;
    final maxContentWidth = math.max(
      0.0,
      availableWidth - tooltipConfig.padding.horizontal,
    );

    final size = canvas.drawTooltipInfos(
      offset: tooltipOffset,
      tooltipInfos: list,
      drawDirection: drawDirection,
      drawableRect: mainChartRect,
      defaultStyle: tooltipTextStyle,
      minContentWidth: _tooltipStableContentWidth,
      maxContentWidth: maxContentWidth,
      yAxisAlign: YAxisAlign.center,
      backgroundColor: theme.tooltipBg,
      borderRadius: tooltipConfig.radius,
      padding: tooltipConfig.padding,
      spacing: tooltipConfig.spacing,
      onLayout: (_, itemBounds) {
        for (int index = 0; index < list.length; index++) {
          final onTap = list[index].onTap;
          if (onTap == null) continue;

          _tooltipTapTargets.add(
            _TooltipTapTarget(
              bounds: itemBounds[index],
              onTap: onTap,
            ),
          );
        }
      },
    );

    final contentWidth = size.width - tooltipConfig.padding.horizontal;
    _tooltipStableContentWidth = math.max(
      _tooltipStableContentWidth ?? 0,
      contentWidth,
    );
  }

  /// Tooltip定制回调
  /// 当未实现此接口或定制返回null: 后续将触发[onCrossI18nTooltipLabels]接口实现.
  /// 当定制返回[]空数组时: 说明由用户自行在页面自由定制.
  OnCrossCustomTooltipCallback? onCrossCustomTooltip;

  /// TooltipLabels多语言回调
  /// 当未实现此接口或定制返回为null: 将使用[defaultTooltipLabels]默认英文Tooltip.
  OnCrossI18nTooltipLabels? onCrossI18nTooltipLabels;

  /// 根据TooltipLabels生成TooltipInfoList.
  List<TooltipInfo> generateTooltipInfoListByLabels(
    Map<TooltipLabel, String> tooltipLabels, {
    required FlexiCandleModel model,
    FlexiCandleModel? pre,
  }) {
    if (tooltipLabels.isEmpty) return const [];
    final p = klineData.precision;

    final tooltipTextStyle = crossConfig.tooltipConfig.style;
    TextStyle? getValueStyle(num signum) {
      if (signum > 0) {
        return tooltipTextStyle.ensure(theme.longColor);
      } else if (signum < 0) {
        return tooltipTextStyle.ensure(theme.shortColor);
      }
      return null;
    }

    final list = <TooltipInfo>[];
    tooltipLabels.forEach((key, label) {
      String? value;
      TextStyle? valueStyle;
      switch (key) {
        case TooltipLabel.time:
          final interval = klineData.interval;
          value = model.formatDateTime(interval);
          break;
        case TooltipLabel.open:
          value = formatPrice(model.open.toDecimal(), precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.high:
          value = formatPrice(model.high.toDecimal(), precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.low:
          value = formatPrice(model.low.toDecimal(), precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.close:
          value = formatPrice(model.close.toDecimal(), precision: p, cutInvalidZero: false);
          break;
        case TooltipLabel.chg:
          value = formatPrice(model.change.toDecimal(), precision: p, cutInvalidZero: false);
          valueStyle = getValueStyle(model.change.signum);
          break;
        case TooltipLabel.chgRate:
          value = formatPercentage(model.changeRate.toDecimal(), precision: 2);
          valueStyle = getValueStyle(model.change.signum);
          break;
        case TooltipLabel.range:
          if (pre != null) {
            value = formatPercentage(model.rangeRate(pre).toDecimal(), precision: 2);
            valueStyle = getValueStyle(model.rangeRate(pre));
          } else {
            value = formatPrice(model.range.toDecimal(), precision: p, cutInvalidZero: false);
            valueStyle = getValueStyle(model.range.signum);
          }
          break;
        case TooltipLabel.amount:
          value = formatAmount(model.vol.toDecimal(), precision: 2);
          break;
        case TooltipLabel.turnover:
          if (model.turnover != null) {
            value = formatAmount(model.turnover!.toDecimal(), precision: 2);
          }
          break;
      }
      if (value != null) {
        list.add(TooltipInfo(
          label: label,
          value: value,
          valueStyle: valueStyle,
        ));
      }
    });
    return list;
  }

  @override
  bool onTap(Offset position) {
    if (_handleTooltipTap(position)) return true;
    return super.onTap(position);
  }

  bool _handleTooltipTap(Offset position) {
    if (!isCrossing) return false;
    final hitTestMargin = crossConfig.tooltipConfig.hitTestMargin;
    for (final target in _tooltipTapTargets.reversed) {
      final bounds = hitTestMargin > 0 ? target.bounds.inflate(hitTestMargin) : target.bounds;
      if (bounds.contains(position)) {
        target.onTap();
        return true;
      }
    }
    return false;
  }
}

/// 最近一次 Cross Tooltip 绘制产生的单项点击目标。
class _TooltipTapTarget {
  const _TooltipTapTarget({
    required this.bounds,
    required this.onTap,
  });

  final Rect bounds;
  final VoidCallback onTap;
}
