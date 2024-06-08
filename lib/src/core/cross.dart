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

import 'package:flutter/material.dart';

import '../constant.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../utils/num_util.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 定制TooltipInfoList
/// [model] 当前Cross选中的CandleMode数据.
/// [pre] 前一个CandleMode数据
/// 1. 如果返回null, 则尝试用 [OnCrossI18nTooltipLables] 继续定制.
/// 2. 如果返回const [], 则不会再展示Tooltip信息.
typedef OnCrossCustomTooltipCallback = List<TooltipInfo>? Function(
  CandleModel model, {
  CandleModel? pre,
});

/// 定制TooltipLables
/// 1. 如果返回null, 则使用默认[defaultTooltipLables] 生成TooltipInfoList
/// 2. 如果返回const {}, 则不会再展示Tooltip信息
typedef OnCrossI18nTooltipLables = Map<TooltipLabel, String>? Function();

mixin CrossBinding
    on KlineBindingBase, SettingBinding
    implements ICross, IState, IChart {
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
  @override
  Listenable get repaintCross => _repaintCross;
  void _markRepaint() {
    _repaintCross.value++;
  }

  //// Cross ////
  @override
  void markRepaintCross() {
    if (isCrossing) {
      offset = offset;
      _markRepaint();
    }
  }

  // 是否正在绘制Cross
  @override
  bool get isCrossing => offset?.isFinite == true;

  // 取消当前Cross事件
  @override
  void cancelCross() {
    offset = null;
    _markRepaint();
  }

  Offset? _offset;
  Offset? get offset => _offset;
  set offset(Offset? val) {
    if (val != null) {
      _offset = correctCrossOffset(val);
    } else {
      _offset = null;
    }
  }

  /// 矫正Cross
  Offset? correctCrossOffset(Offset offset) {
    if (offset.isInfinite) return null;

    // X轴按蜡烛线移动.
    offset = offset.clamp(canvasRect);
    final diff = (startCandleDx - offset.dx) % candleActualWidth;
    final dx = offset.dx + diff - candleWidthHalf;
    return Offset(dx, offset.dy);

    // 当超出边界时, X轴平滑移动.
    // if (canvasRect.contains(offset)) {
    //   final diff = (startCandleDx - offset.dx) % candleActualWidth;
    //   final dx = offset.dx + diff - candleWidthHalf;
    //   return Offset(dx, offset.dy);
    // } else {
    //   return offset.clamp(canvasRect);
    // }
  }

  /// 绘制最新价与十字线
  @override
  void paintCross(Canvas canvas, Size size) {
    if (crossConfig.enable != true) return;

    if (isCrossing) {
      final offset = this.offset;
      if (offset == null || offset.isInfinite) {
        return;
      }

      CandleModel? model;
      if (crossConfig.showLatestTipsInBlank) {
        model = offsetToCandle(offset);
        // 如果当前model为空, 则根据offset.dx计算当前model是最新的, 还是最后的.
        if (model == null) {
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

      ensurePaintObjectInstance();

      for (var indicator in [mainIndicator, ...subRectIndicators]) {
        indicator.paintObject?.doOnCross(canvas, offset, model: model);
      }
    }
  }

  @override
  @protected
  bool handleTap(GestureData data) {
    if (crossConfig.enable != true) {
      super.handleTap(data);
      return false;
    }

    if (isCrossing) {
      offset = null;
      markRepaintChart(); // 当Cross事件结束后, 调用markRepaintChart绘制Painting图层首根蜡烛的tips信息.
      _markRepaint();
      return super.handleTap(data); // 不处理, 向上传递事件.
    }
    logd('handleTap cross > ${data.offset}');
    // 更新并校正起始焦点.
    offset = data.offset;
    _markRepaint();
    markRepaintChart(); // 当Cross事件启动后, 调用markRepaintChart清理Painting图层的tips信息.
    return true;
  }

  @override
  @protected
  void handleMove(GestureData data) {
    if (!isCrossing) {
      return super.handleMove(data);
    }
    offset = data.offset;
    _markRepaint();
  }

  @override
  @protected
  void handleScale(GestureData data) {
    if (isCrossing) {
      logd('handleMove cross > ${data.offset}');
      // 注: 当前正在展示Cross, 不能缩放, 直接return拦截.
      return;
    }
    return super.handleScale(data);
  }

  /// 绘制Cross Line
  @protected
  void paintCrossLine(Canvas canvas, Offset offset) {
    final path = Path()
      ..moveTo(mainChartLeft, offset.dy)
      ..lineTo(mainChartRight, offset.dy)
      ..moveTo(offset.dx, 0)
      ..lineTo(offset.dx, canvasHeight);

    canvas.drawLineType(
      crossConfig.crosshair.type,
      path,
      crossConfig.crosshairPaint,
      dashes: crossConfig.crosshair.dashes,
    );

    canvas.drawCircle(
      offset,
      crossConfig.point.radius,
      crossConfig.pointPaint,
    );
  }

  /// 绘制 Tooltip
  void paintTooltip(Canvas canvas, Offset offset, {CandleModel? model}) {
    if (!tooltipConfig.show) return;
    int index = offsetToIndex(offset);
    model ??= curKlineData.getCandle(index);
    final pre = curKlineData.getCandle(index + 1);
    if (model == null) return;

    /// 准备数据
    // 1. 使用定制接口生成TooltipInfoList.
    List<TooltipInfo>? tooltipInfoList;
    if (onCrossCustomTooltip != null) {
      tooltipInfoList = onCrossCustomTooltip!(model, pre: pre);
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
        style: info.labelStyle ?? tooltipConfig.style,
      ));
      TextStyle valStyle = info.valueStyle ?? tooltipConfig.style;
      if (info.riseOrFall > 0) {
        valStyle = valStyle.copyWith(color: settingConfig.longColor);
      } else if (info.riseOrFall < 0) {
        valStyle = valStyle.copyWith(color: settingConfig.shortColor);
      }
      valueSpanList.add(TextSpan(
        text: info.value + br,
        style: valStyle,
      ));
    }

    /// 开始绘制
    double top = tooltipConfig.margin.top;
    if (mainIndicator.drawBelowTipsArea) {
      top += mainIndicator.padding.top;
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
          style: tooltipConfig.style,
        ),
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: tooltipConfig.background,
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
          style: tooltipConfig.style,
        ),
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: tooltipConfig.background,
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
          style: tooltipConfig.style,
        ),
        textAlign: TextAlign.end,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: tooltipConfig.background,
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
          style: tooltipConfig.style,
        ),
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.longestLine,
        padding: tooltipConfig.padding,
        backgroundColor: tooltipConfig.background,
        borderRadius: BorderRadius.only(
          topLeft: tooltipConfig.radius.topLeft,
          bottomLeft: tooltipConfig.radius.bottomLeft,
        ),
      );
    }
  }

  /// Tooltip定制回调
  OnCrossCustomTooltipCallback? onCrossCustomTooltip;

  /// TooltipLables多语言回调
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
          value = model.formatDateTimeByTimeBar(timeBar);
          break;
        case TooltipLabel.open:
          value = formatPrice(model.o, precision: p);
          break;
        case TooltipLabel.high:
          value = formatPrice(model.h, precision: p);
          break;
        case TooltipLabel.low:
          value = formatPrice(model.l, precision: p);
          break;
        case TooltipLabel.close:
          value = formatPrice(model.c, precision: p);
          break;
        case TooltipLabel.chg:
          value = formatPrice(model.change, precision: p);
          break;
        case TooltipLabel.chgRate:
          value = formatPercentage(model.changeRate);
          riseOrFall = model.change.signum;
          break;
        case TooltipLabel.range:
          if (pre != null) {
            value = formatPercentage(model.rangeRate(pre));
          } else {
            value = formatPrice(model.range, precision: p);
          }
          break;
        case TooltipLabel.amount:
          value = formatAmount(model.v);
          break;
        case TooltipLabel.turnover:
          if (model.vc != null) {
            value = formatAmount(model.vc);
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
