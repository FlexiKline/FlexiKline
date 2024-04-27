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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../utils/export.dart';
import 'indicator.dart';

const mainIndicatorSlot = -1;

/// 指标图的绘制边界接口
abstract interface class IPaintBoundingBox {
  bool get drawInMain;
  bool get drawInSub;

  /// 当前指标图paint内的padding.
  /// 增加padding后tipsRect和chartRect将在此以内绘制.
  /// 一些额外的信息可以通过padding在左上右下方向上增加扩展的绘制区域.
  /// 1. 主图的XAxis上的时间刻度绘制在pading.bottom上.
  EdgeInsets get paintPadding => EdgeInsets.zero;

  /// 当前指标图画笔可以绘制的范围
  Rect get drawBounding;

  /// 当前指标图去除padding后的区域
  Rect get paintRect;

  /// 当前指标图tooltip信息绘制区域
  Rect get tipsRect;

  /// 当前指标图绘制区域
  Rect get chartRect;

  /// 复位Tips区域
  void resetNextTipsRect();

  /// tips的绘制区域.
  Rect get nextTipsRect;

  /// 设置下一个Tips的绘制区域.
  void shiftNextTipsRect(double height);
}

/// 指标图的绘制数据初始化接口
abstract interface class IPaintDataInit {
  /// 计算指标需要的数据
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  });

  /// 重置minmax值为null.
  void resetMinMax();

  /// 最大值/最小值
  MinMax get minMax;

  set minMax(MinMax val);
}

/// 指标图的绘制接口/指标图的Cross事件绘制接口
abstract interface class IPaintChartAndHandleCross {
  /// 为当前指标的绘制绑定slot.
  void bindSolt(int newSlot);

  /// 绘制指标图
  void paintChart(Canvas canvas, Size size);

  /// 绘制Cross上的刻度值
  void onCross(Canvas canvas, Offset offset);

  /// 绘制顶部tips信息
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset});
}

abstract interface class IPaintDelegate {
  void doInitData({
    required List<CandleModel> list,
    required int start,
    required int end,
  });

  void doPaintChart(Canvas canvas, Size size);

  void doOnCross(Canvas canvas, Offset offset);

  void doPaintTips(Canvas canvas, {CandleModel? model, Offset? offset});
}

/// 绘制对象混入全局Setting配置.
mixin SettingProxyMixin on PaintObject {
  late final SettingBinding setting;

  double get candleActualWidth => setting.candleActualWidth;

  double get candleWidthHalf => setting.candleWidthHalf;
}

/// 绘制对象混入数据状态代理State
mixin StateProxyMixin on PaintObject {
  late final IState state;
  late final ICross cross;
  late final IConfig config;

  KlineData get klineData => state.curKlineData;

  double get paintDxOffset => state.paintDxOffset;

  double get startCandleDx => state.startCandleDx;

  bool get isCrossing => cross.isCrossing;
}

/// 绘制对象混入边界计算的通用扩展
mixin PaintObjectBoundingMixin on PaintObjectProxy
    implements IPaintBoundingBox {
  @override
  bool get drawInMain => slot == mainIndicatorSlot;
  @override
  bool get drawInSub => slot > mainIndicatorSlot;

  int _slot = mainIndicatorSlot;

  /// 当前指标索引(仅对副图有效)
  /// <0 代表在主图绘制
  /// >=0 代表在副图绘制
  int get slot => _slot;

  @override
  @mustCallSuper
  void bindSolt(int newSlot) {
    if (newSlot != slot) {
      _bounding = null;
      _slot = newSlot;
    }
  }

  @override
  EdgeInsets get paintPadding => indicator.padding;

  Rect? _bounding;
  @override
  Rect get drawBounding {
    if (drawInMain) {
      _bounding ??= setting.mainRect;
    } else {
      if (_bounding == null) {
        final top = config.calculateIndicatorTop(slot);
        _bounding = Rect.fromLTRB(
          setting.subRect.left,
          setting.subRect.top + top,
          setting.subRect.right,
          setting.subRect.top + top + indicator.height,
        );
      }
    }
    return _bounding!;
  }

  @override
  Rect get paintRect {
    return Rect.fromLTRB(
      drawBounding.left + paintPadding.left,
      drawBounding.top + paintPadding.top,
      drawBounding.right - paintPadding.right,
      drawBounding.bottom - paintPadding.bottom,
    );
  }

  @override
  Rect get tipsRect {
    return Rect.fromLTWH(
      drawBounding.left + paintPadding.left,
      drawBounding.top + paintPadding.top,
      drawBounding.width - paintPadding.horizontal,
      indicator.tipsHeight,
    );
  }

  @override
  Rect get chartRect {
    return Rect.fromLTRB(
      drawBounding.left + paintPadding.left,
      tipsRect.bottom,
      drawBounding.right - paintPadding.right,
      drawBounding.bottom - paintPadding.bottom,
    );
  }

  double get chartRectWidthHalf => chartRect.width / 2;

  double clampDxInChart(double dx) => dx.clamp(chartRect.left, chartRect.right);
  double clampDyInChart(double dy) => dy.clamp(chartRect.top, chartRect.bottom);

  // 下一个Tips的绘制区域
  Rect? _nextTipsRect;

  // 复位Tips区域
  @override
  void resetNextTipsRect() => _nextTipsRect = null;

  @override
  Rect get nextTipsRect => _nextTipsRect ?? tipsRect;

  // Tips区域向下移动height.
  @override
  void shiftNextTipsRect(double height) {
    _nextTipsRect = tipsRect.shiftYAxis(height);
  }
}

/// 绘制对象混入数据初始化的通用扩展
mixin DataInitMixin on PaintObjectProxy implements IPaintDataInit {
  final Decimal twentieth = (Decimal.one / Decimal.fromInt(20)).toDecimal();

  MinMax? _minMax;

  @override
  void resetMinMax() => _minMax = null;

  @override
  MinMax get minMax => _minMax ?? MinMax.zero;

  @override
  set minMax(MinMax val) {
    _minMax = val;
  }

  double get dyFactor {
    return chartRect.height / (minMax.size).toDouble();
  }

  double valueToDy(Decimal value, {bool correct = true}) {
    if (correct) value = value.clamp(minMax.min, minMax.max);
    return chartRect.bottom - (value - minMax.min).toDouble() * dyFactor;
  }

  Decimal? dyToValue(double dy) {
    if (!chartRect.inclueDy(dy)) return null;
    return minMax.max - ((dy - chartRect.top) / dyFactor).d;
  }

  double? indexToDx(int index) {
    double dx = chartRect.right - (index * candleActualWidth - paintDxOffset);
    if (chartRect.inclueDx(dx)) return dx;
    return null;
  }

  int dxToIndex(double dx) {
    final dxPaintOffset = (chartRect.right - dx) + paintDxOffset;
    return (dxPaintOffset / candleActualWidth).floor();
  }

  CandleModel? dxToCandle(double dx) {
    final index = dxToIndex(dx);
    return state.curKlineData.getCandle(index);
  }

  CandleModel? offsetToCandle(Offset? offset) {
    if (offset != null) return dxToCandle(offset.dx);
    return null;
  }
}

mixin PaintYAxisTickMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// 为副区的指标图绘制Y轴上的刻度信息
  @protected
  void paintYAxisTick(
    Canvas canvas,
    Size size, {
    required int tickCount, // 刻度数量.
  }) {
    if (minMax.isZero) return;

    double yAxisStep = chartRect.height / (setting.subChartYAxisTickCount - 1);
    final dx = chartRect.right;
    double dy = 0.0;
    double drawTop = chartRect.top;

    for (int i = 0; i < tickCount; i++) {
      dy = drawTop + i * yAxisStep;
      final value = dyToValue(dy);
      if (value == null) continue;

      final text = fromatYAxisTickValue(value);

      canvas.drawText(
        offset: Offset(
          dx,
          dy - setting.yAxisTickRectHeight,
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawBounding,
        text: text,
        style: setting.yAxisTickTextStyle,
        // textWidth: tickTextWidth,
        textAlign: TextAlign.end,
        padding: setting.yAxisTickRectPadding,
        maxLines: 1,
      );
    }
  }

  /// 如果要定制格式化刻度值. 在PaintObject中覆写此方法.
  @protected
  String fromatYAxisTickValue(Decimal value) {
    return formatNumber(
      value,
      precision: 2,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

mixin PaintYAxisMarkOnCrossMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// onCross时, 绘制Y轴上的标记值
  @protected
  void paintYAxisMarkOnCross(Canvas canvas, Offset offset) {
    final value = dyToValue(offset.dy);
    if (value == null) return;

    final text = formatYAxisMarkValueOnCross(value);

    canvas.drawText(
      offset: Offset(
        chartRect.right - setting.crossYTickRectRigthMargin,
        offset.dy - setting.crossYTickRectHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawBounding,
      text: text,
      style: setting.crossYTickTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: setting.crossYTickRectPadding,
      backgroundColor: setting.crossYTickRectBackgroundColor,
      radius: setting.crossYTickRectBorderRadius,
      borderWidth: setting.crossYTickRectBorderWidth,
      borderColor: setting.crossYTickRectBorderColor,
    );
  }

  @protected
  String formatYAxisMarkValueOnCross(Decimal value) {
    return formatNumber(
      value,
      precision: 2,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

/// PaintObject
/// 通过实现对应的接口, 实现Chart的配置, 计算, 绘制, Cross
// @immutable
abstract class PaintObject<T extends Indicator>
    implements
        IPaintBoundingBox,
        IPaintDataInit,
        IPaintChartAndHandleCross,
        IPaintDelegate {
  PaintObject({
    required T indicator,
  }) : _indicator = indicator;

  T? _indicator;

  T get indicator => _indicator!;

  // 父级PaintObject. 主要用于给其他子级PaintObject限定范围.
  PaintObject? parent;

  @mustCallSuper
  void dispose() {
    _indicator = null;
    parent = null;
  }
}

/// PaintObjectProxy
/// 通过参数KlineBindingBase 混入对setting和state的代理
abstract class PaintObjectProxy<T extends Indicator> extends PaintObject
    with KlineLog, SettingProxyMixin, StateProxyMixin {
  PaintObjectProxy({
    required KlineBindingBase controller,
    required T super.indicator,
  }) {
    loggerDelegate = controller.loggerDelegate;
    setting = controller as SettingBinding;
    state = controller as IState;
    cross = controller as ICross;
    config = controller as IConfig;
  }

  @override
  T get indicator => super.indicator as T;

  @override
  String get logTag => '${super.logTag}\t${indicator.key.toString()}';
}

/// PaintObjectBox
/// 通过混入边界计算与数据初始化计算, 简化PaintObject接口.
abstract class SinglePaintObjectBox<T extends SinglePaintObjectIndicator>
    extends PaintObjectProxy with PaintObjectBoundingMixin, DataInitMixin {
  SinglePaintObjectBox({
    required super.controller,
    required T super.indicator,
  });

  @override
  T get indicator => super.indicator as T;

  /// 转换parent为MultiPaintObjectBox类型的.
  // MultiPaintObjectBox<MultiPaintObjectIndicator>? get multiBoxParent {
  //   if (super.parent is MultiPaintObjectBox) {
  //     return super.parent as MultiPaintObjectBox;
  //   }
  //   return null;
  // }

  // MinMax? _minMax;

  // @override
  // void cleanMinMax() => _minMax = null;

  // @override
  // MinMax get minMax {
  //   return _minMax ?? MinMax.zero;
  // }

  // @override
  // set minMax(MinMax val) {
  //   _minMax = val;
  // }

  @override
  void doInitData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    resetMinMax();
    final ret = initData(list: list, start: start, end: end);
    if (ret != null) {
      minMax = ret;
    }
  }

  @override
  void doPaintChart(Canvas canvas, Size size) {
    paintChart(canvas, size);

    if (!cross.isCrossing) {
      doPaintTips(canvas, model: state.curKlineData.latest);
    }
  }

  @override
  void doOnCross(Canvas canvas, Offset offset) {
    onCross(canvas, offset);

    doPaintTips(canvas, offset: offset);
  }

  @override
  void doPaintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    paintTips(canvas, model: model, offset: offset);
  }
}

/// 多个Indicator组合绘制
/// 主要实现接口遍历转发.
class MultiPaintObjectBox<T extends MultiPaintObjectIndicator>
    extends PaintObjectProxy with PaintObjectBoundingMixin, DataInitMixin {
  MultiPaintObjectBox({
    required super.controller,
    required T super.indicator,
  });

  @override
  T get indicator => super.indicator as T;

  // 下一个Tips的绘制区域
  // Rect _nextTipsRect = Rect.zero;

  // Rect? get nextTipsRect => _nextTipsRect;

  // void resetNextTipsRect() => _nextTipsRect = tipsRect;

  // MinMax? _minMax;

  // @override
  // void cleanMinMax() => _minMax = null;

  // @override
  // MinMax get minMax => _minMax ?? MinMax.zero;

  @override
  set minMax(MinMax val) {
    if (_minMax == null) {
      _minMax = val;
    } else {
      _minMax!.updateMinMax(val);
    }
  }

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    return _minMax;
  }

  @override
  void bindSolt(int newSlot) {
    super.bindSolt(newSlot);
    for (var child in indicator.children) {
      child.paintObject?.bindSolt(newSlot);
    }
  }

  @override
  void paintChart(Canvas canvas, Size size) {}

  @override
  void onCross(Canvas canvas, Offset offset) {}

  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    return Size(tipsRect.width, nextTipsRect.bottom - tipsRect.top);
  }

  @override
  void doInitData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    resetMinMax();
    for (var child in indicator.children) {
      final childPaintObject = child.paintObject;
      if (childPaintObject == null) continue;
      childPaintObject.resetMinMax();
      final ret = childPaintObject.initData(
        list: list,
        start: start,
        end: end,
      );
      if (ret != null) {
        childPaintObject.minMax = ret;
        minMax = ret.clone();
      }
    }
    if (indicator.paintMode == MultiPaintMode.combine) {
      for (var child in indicator.children) {
        child.paintObject?.minMax = minMax;
      }
    }
  }

  @override
  void doPaintChart(Canvas canvas, Size size) {
    for (var child in indicator.children) {
      child.paintObject?.paintChart(canvas, size);
    }

    if (!cross.isCrossing) {
      doPaintTips(canvas, model: state.curKlineData.latest);
    }
  }

  @override
  void doOnCross(Canvas canvas, Offset offset) {
    for (var child in indicator.children) {
      child.paintObject?.onCross(canvas, offset);
    }

    doPaintTips(canvas, offset: offset);
  }

  @override
  void doPaintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    // 每次绘制前, 重置Tips区域大小为0
    resetNextTipsRect();
    double height = 0;
    for (var child in indicator.children) {
      child.paintObject?.shiftNextTipsRect(height);
      final size = child.paintObject?.paintTips(
        canvas,
        model: model,
        offset: offset,
      );
      if (size != null) {
        height += size.height;
        shiftNextTipsRect(height);
      }
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    for (var child in indicator.children) {
      child.paintObject?.dispose();
    }
    super.dispose();
  }
}
