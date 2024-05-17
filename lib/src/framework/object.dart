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

import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../utils/export.dart';
import 'indicator.dart';
import 'logger.dart';

const mainIndicatorSlot = -1;

/// 指标图的绘制边界接口
abstract interface class IPaintBoundingBox {
  /// 当前指标图paint内的padding.
  /// 增加padding后tipsRect和chartRect将在此以内绘制.
  /// 一些额外的信息可以通过padding在左上右下方向上增加扩展的绘制区域.
  /// 1. 主图的XAxis上的时间刻度绘制在pading.bottom上.
  EdgeInsets get padding => EdgeInsets.zero;

  /// 当前指标图画笔可以绘制的范围
  Rect get drawableRect;

  /// 当前指标图绘制区域
  Rect get chartRect;

  /// 当前指标图顶部绘制区域
  Rect get topRect;

  /// 当前指标图底部绘制区域
  Rect get bottomRect;

  // /// 复位Tips区域
  // void resetNextTipsRect();

  // /// tips的绘制区域.
  // Rect get nextTipsRect;

  /// 设置下一个Tips的绘制区域.
  Rect shiftNextTipsRect(double height);
}

/// 指标图的绘制数据初始化接口
abstract interface class IPaintDataInit {
  /// 最大值/最小值
  MinMax get minMax;

  set minMax(MinMax val);
}

/// 指标图的绘制接口/指标图的Cross事件绘制接口
abstract interface class IPaintObject {
  /// 计算指标需要的数据, 并返回 [start] ~ [end] 之间MinMax.
  MinMax? initState({required int start, required int end});

  /// 绘制指标图
  void paintChart(Canvas canvas, Size size);

  /// 在所有指标图绘制结束后额外的绘制
  void paintExtraAboveChart(Canvas canvas, Size size);

  /// 绘制Cross上的刻度值
  void onCross(Canvas canvas, Offset offset);

  /// 绘制顶部tips信息
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  });
}

abstract interface class IPaintDelegate {
  MinMax? doInitState(
    int newSlot, {
    required int start,
    required int end,
    bool reset = false,
  });

  void doPaintChart(Canvas canvas, Size size);

  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model});
}

/// FlexiKlineController 状态/配置/接口代理
mixin ControllerProxyMixin on PaintObject {
  late final KlineBindingBase controller;

  /// Binding
  SettingBinding get setting => controller as SettingBinding;
  IState get state => controller as IState;
  ICross get cross => controller as ICross;
  IConfig get config => controller as IConfig;

  /// Config
  SettingConfig get settingConfig => setting.settingConfig;
  GridConfig get gridConfig => (controller as IGrid).gridConfig;
  CrossConfig get crossConfig => cross.crossConfig;

  double get candleActualWidth => setting.candleActualWidth;

  double get candleWidthHalf => setting.candleWidthHalf;

  KlineData get klineData => state.curKlineData;

  double get paintDxOffset => state.paintDxOffset;

  double get startCandleDx => state.startCandleDx;

  bool get isCrossing => cross.isCrossing;
}

/// 绘制对象混入边界计算的通用扩展
mixin PaintObjectBoundingMixin on PaintObjectProxy
    implements IPaintBoundingBox {
  bool get drawInMain => slot == mainIndicatorSlot;
  bool get drawInSub => slot > mainIndicatorSlot;

  int _slot = mainIndicatorSlot;

  /// 当前指标索引
  /// <0 代表在主图绘制
  /// >=0 代表在副图绘制
  int get slot => _slot;

  @override
  EdgeInsets get padding => indicator.padding;

  Rect? _bounding;

  @override
  Rect get drawableRect {
    if (drawInMain) {
      _bounding ??= settingConfig.mainRect;
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
  Rect get topRect {
    return Rect.fromLTRB(
      drawableRect.left,
      drawableRect.top,
      drawableRect.right,
      drawableRect.top + padding.top,
    );
  }

  @override
  Rect get bottomRect {
    return Rect.fromLTRB(
      drawableRect.left,
      drawableRect.bottom - padding.bottom,
      drawableRect.right,
      drawableRect.bottom,
    );
  }

  @override
  Rect get chartRect {
    final chartBottom = drawableRect.bottom - padding.bottom;
    double chartTop;
    if (indicator.paintMode == PaintMode.alone) {
      chartTop = chartBottom - indicator.height;
    } else {
      chartTop = drawableRect.top + padding.top;
    }
    return Rect.fromLTRB(
      drawableRect.left + padding.left,
      chartTop,
      drawableRect.right - padding.right,
      chartBottom,
    );
  }

  double get chartRectWidthHalf => chartRect.width / 2;

  double clampDxInChart(double dx) => dx.clamp(chartRect.left, chartRect.right);
  double clampDyInChart(double dy) => dy.clamp(chartRect.top, chartRect.bottom);

  // 下一个Tips的绘制区域
  // Rect? _nextTipsRect;

  // 复位Tips区域
  // @override
  // void resetNextTipsRect() => _nextTipsRect = null;

  // @override
  // Rect get nextTipsRect => _nextTipsRect ?? topRect;

  // Tips区域向下移动height.
  @override
  Rect shiftNextTipsRect(double height) {
    return drawableRect.shiftYAxis(height);
  }
}

/// 绘制对象混入数据初始化的通用扩展
mixin DataInitMixin on PaintObjectProxy implements IPaintDataInit {
  int? _start;
  int? _end;

  MinMax? _minMax;

  @override
  MinMax get minMax => _minMax ?? MinMax.zero;

  @override
  set minMax(MinMax val) {
    _minMax = val;
  }

  double? _dyFactor;
  double get dyFactor {
    return _dyFactor ??= chartRect.height / (minMax.size).toDouble();
  }

  double valueToDy(BagNum value, {bool correct = true}) {
    if (correct) value = value.clamp(minMax.min, minMax.max);
    return chartRect.bottom - (value - minMax.min).toDouble() * dyFactor;
  }

  BagNum? dyToValue(double dy) {
    if (!chartRect.inclueDy(dy)) return null;
    return minMax.max - ((dy - chartRect.top) / dyFactor).toBagNum();
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

mixin PaintHorizontalTickMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// 为副区的指标图绘制Y轴上的刻度信息
  @protected
  void paintHorizontalTick(
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

      final text = fromatTickValue(value, precision: precision);

      final tickText = settingConfig.tickText;

      canvas.drawTextArea(
        offset: Offset(
          dx,
          dy - tickText.areaHeight, // 绘制在刻度线之上
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: text,
        textConfig: tickText,
      );
    }
  }

  /// 如果要定制格式化刻度值. 在PaintObject中覆写此方法.
  @protected
  String fromatTickValue(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

mixin PaintHorizontalTickOnCrossMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// onCross时, 绘制Y轴上的刻度值
  @protected
  void paintHorizontalTickOnCross(
    Canvas canvas,
    Offset offset, {
    required int precision,
  }) {
    final value = dyToValue(offset.dy);
    if (value == null) return;

    final text = formatTickValueOnCross(value, precision: precision);

    final tickText = crossConfig.tickText;

    canvas.drawTextArea(
      offset: Offset(
        chartRect.right - crossConfig.spacing,
        offset.dy - tickText.areaHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawableRect,
      text: text,
      textConfig: tickText,
    );
  }

  @protected
  String formatTickValueOnCross(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

/// PaintObject
/// 通过实现对应的接口, 实现Chart的配置, 计算, 绘制, Cross
// @immutable
abstract class PaintObject<T extends Indicator>
    implements IPaintBoundingBox, IPaintDataInit, IPaintObject, IPaintDelegate {
  PaintObject({
    required T indicator,
  }) : _indicator = indicator;

  T? _indicator;

  T get indicator => _indicator!;

  // 父级PaintObject. 主要用于给其他子级PaintObject限定范围.
  PaintObject? parent;

  bool get hasParentObject => parent != null;

  @mustCallSuper
  void dispose() {
    _indicator = null;
    parent = null;
  }

  @protected
  @override
  void paintExtraAboveChart(Canvas canvas, Size size) {}
}

/// PaintObjectProxy
/// 通过参数KlineBindingBase 混入对setting和state的代理
abstract class PaintObjectProxy<T extends Indicator> extends PaintObject
    with KlineLog, ControllerProxyMixin {
  PaintObjectProxy({
    required KlineBindingBase controller,
    required T super.indicator,
  }) {
    this.controller = controller;
    loggerDelegate = controller.loggerDelegate;
    // settingBinding = controller as SettingBinding;
    // setting = controller.settingData; // TODO: 待命名统一
    // state = controller as IState;
    // cross = controller as ICross;
    // config = controller as IConfig;
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

  @override
  MinMax? doInitState(
    int newSlot, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (reset || newSlot != slot) {
      _bounding = null;
      _minMax = null;
      _slot = newSlot;
    }

    if (_start != start || _end != end || _minMax == null) {
      _start = start;
      _end = end;

      _minMax = null;
      final ret = initState(start: start, end: end);
      if (ret != null) {
        minMax = ret;
      }
    }

    _dyFactor = null;
    return minMax;
  }

  @override
  void doPaintChart(Canvas canvas, Size size) {
    paintChart(canvas, size);

    if (!cross.isCrossing) {
      paintTips(
        canvas,
        model: state.curKlineData.latest,
        tipsRect: drawableRect,
      );
    }

    paintExtraAboveChart(canvas, size);
  }

  @override
  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    onCross(canvas, offset);

    paintTips(
      canvas,
      offset: offset,
      model: model,
      tipsRect: drawableRect,
    );
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

  @override
  MinMax? initState({required int start, required int end}) {
    return minMax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {}

  @override
  void onCross(Canvas canvas, Offset offset, {CandleModel? model}) {}

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    // return Size(topRect.width, nextTipsRect.top - topRect.top);
    return topRect.size;
  }

  @override
  set minMax(MinMax val) {
    if (_minMax == null) {
      _minMax = val;
    } else {
      _minMax!.updateMinMax(val);
    }
  }

  @override
  MinMax? doInitState(
    int newSlot, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (reset || newSlot != slot) {
      _bounding = null;
      _minMax = null;
      _dyFactor = null;
      _slot = newSlot;
    }

    if (_start != start || _end != end) {
      _start = start;
      _end = end;
    }

    _minMax = null;
    for (var child in indicator.children) {
      final childPaintObject = child.paintObject;
      if (childPaintObject == null) continue;
      final ret = childPaintObject.doInitState(
        newSlot,
        start: start,
        end: end,
        reset: reset,
      );
      if (ret != null && child.paintMode == PaintMode.combine) {
        minMax = ret.clone();
      }
    }

    for (var child in indicator.children) {
      if (child.paintMode == PaintMode.combine) {
        child.paintObject?.minMax = minMax;
      }
    }

    _dyFactor = null;
    return minMax;
  }

  @override
  void doPaintChart(Canvas canvas, Size size) {
    if (indicator.drawBelowTipsArea) {
      // 1.1 如果设置总是要在Tips区域下绘制指标图, 则要首先绘制完所有Tips.
      if (!cross.isCrossing) {
        final tipsHeight = doPaintTips(
          canvas,
          model: state.curKlineData.latest,
        );

        if (tipsHeight > 0 && tipsHeight != padding.top) {
          indicator.updateLayout(padding: padding.copyWith(top: tipsHeight));
        }
      }
      for (var child in indicator.children) {
        child.paintObject?.paintChart(canvas, size);
      }
    } else {
      for (var child in indicator.children) {
        child.paintObject?.paintChart(canvas, size);
      }
      if (!cross.isCrossing) {
        doPaintTips(canvas, model: state.curKlineData.latest);
      }
    }

    for (var child in indicator.children) {
      child.paintObject?.paintExtraAboveChart(canvas, size);
    }
  }

  @override
  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    for (var child in indicator.children) {
      child.paintObject?.onCross(canvas, offset);
    }

    doPaintTips(canvas, offset: offset, model: model);
  }

  double doPaintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    // 每次绘制前, 重置Tips区域大小为0
    double height = 0;
    for (var child in indicator.children) {
      final size = child.paintObject?.paintTips(
        canvas,
        model: model,
        offset: offset,
        tipsRect: shiftNextTipsRect(height),
      );
      if (size != null) height += size.height;
    }
    return height;
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
