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
import '../extension/export.dart';
import '../model/export.dart';
import '../utils/export.dart';
import 'indicator.dart';

const mainDrawIndex = -1;

/// 指标图的绘制边界接口
abstract interface class IPaintBoundingBox {
  bool get drawInMain;
  bool get drawInSub;

  /// 当前指标索引(仅对副图有效)
  /// <0 代表在主图绘制
  /// >=0 代表在副图绘制
  int get index => -1;

  /// 当前指标图paint内的padding.
  /// 增加padding后tipsRect和chartRect将在此以内绘制.
  /// 一些额外的信息可以通过padding在左上右下方向上增加扩展的绘制区域.
  /// 1. 主图的XAxis上的时间刻度绘制在pading.bottom上.
  EdgeInsets get paintPadding => EdgeInsets.zero;

  /// 当前指标图画笔可以绘制的范围
  Rect get drawBounding;

  /// 当前指标图tooltip信息绘制区域
  Rect get tipsRect;

  /// 当前指标图绘制区域
  Rect get chartRect;
}

/// 指标图的绘制数据初始化接口
abstract interface class IPaintDataInit {
  /// 计算指标需要的数据
  void initData(List<CandleModel> list, {int start = 0, int end = 0});

  /// 最大值/最小值
  Decimal get maxVal;
  Decimal get minVal;
}

/// 指标图的绘制接口
abstract interface class IPaintChart {
  /// 绘制指标图
  void paintChart(Canvas canvas, Size size);

  /// 绘制XAxis与YAxis刻度值
  // void paintAxisTickMark(Canvas canvas, Size size);

  /// 绘制顶部tips信息
  // void paintTips(Canvas canvas, Size size);
}

/// 指标图的Cross事件绘制接口
abstract interface class IPaintCross {
  /// 绘制Cross上的刻度值
  void onCross(Canvas canvas, Offset offset);

  /// 绘制Cross命中的指标信息
  // void paintCrossTips(Canvas canvas, Offset offset);
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

  KlineData get curKlineData => state.curKlineData;

  double get paintDxOffset => state.paintDxOffset;

  double get startCandleDx => state.startCandleDx;
}

/// 绘制对象混入边界计算的通用扩展
mixin PaintObjectBoundingMixin on PaintObjectProxy
    implements IPaintBoundingBox {
  @override
  bool get drawInMain => index == mainDrawIndex; // TODO: 待优化
  @override
  bool get drawInSub => index > mainDrawIndex; // TODO: 待优化

  @override
  int get index => mainDrawIndex;

  @override
  EdgeInsets get paintPadding => indicator.padding;

  Rect? _bounding;
  @override
  Rect get drawBounding {
    if (drawInMain) {
      _bounding ??= setting.mainRect;
    } else {
      assert(
        index >= 0 && index < setting.subIndicatorChartMaxCount,
        'index is invalid!!!',
      );
      final top = index * setting.subIndicatorChartHeight;
      final bottom = (index + 1) * setting.subIndicatorChartHeight;
      _bounding ??= Rect.fromLTRB(
        setting.subRect.left,
        setting.subRect.top + top,
        setting.subRect.right,
        setting.subRect.top + bottom,
      );
    }
    return _bounding!;
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
    return Rect.fromLTWH(
      drawBounding.left + paintPadding.left,
      tipsRect.bottom,
      drawBounding.width - paintPadding.horizontal,
      drawBounding.bottom - paintPadding.bottom,
    );
  }

  double get chartRectWidthHalf => chartRect.width / 2;

  double clampDxInChart(double dx) => dx.clamp(chartRect.left, chartRect.right);
  double clampDyInChart(double dy) => dy.clamp(chartRect.top, chartRect.bottom);
}

/// 绘制对象混入数据初始化的通用扩展
mixin DataInitMixin on PaintObjectProxy implements IPaintDataInit {
  double get dyFactor {
    return chartRect.height / (maxVal - minVal).toDouble();
  }

  double valueToDy(Decimal value) {
    value = value.clamp(minVal, maxVal);
    return chartRect.bottom - (value - minVal).toDouble() * dyFactor;
  }

  double? indexToDx(int index) {
    double dx = chartRect.right - (index * candleActualWidth - paintDxOffset);
    if (chartRect.inclueDx(dx)) return dx;
    return null;
  }

  Decimal? dyToValue(double dy) {
    if (!chartRect.inclueDy(dy)) return null;
    return maxVal - ((dy - chartRect.top) / dyFactor).d;
  }

  int dxToIndex(double dx) {
    final dxPaintOffset = (chartRect.right - dx) + paintDxOffset;
    return (dxPaintOffset / candleActualWidth).floor();
  }

  CandleModel? dxToCandle(double dx) {
    final index = dxToIndex(dx);
    return state.curKlineData.getCandle(index);
  }
}

/// PaintObject
/// 通过实现对应的接口, 实现Chart的配置, 计算, 绘制, Cross
// @immutable
abstract class PaintObject<T extends Indicator>
    implements IPaintBoundingBox, IPaintDataInit, IPaintChart, IPaintCross {
  PaintObject({
    required T indicator,
  }) : _indicator = indicator;

  final T? _indicator;

  T get indicator => _indicator!;
}

/// PaintObjectProxy
/// 通过参数KlineBindingBase 混入对setting和state的代理
abstract class PaintObjectProxy<T extends PaintObjectIndicator>
    extends PaintObject with KlineLog, SettingProxyMixin, StateProxyMixin {
  PaintObjectProxy({
    required KlineBindingBase controller,
    required T super.indicator,
  }) {
    setting = controller as SettingBinding;
    state = controller as IState;
    _debug = controller.debug;
  }

  @override
  T get indicator => super.indicator as T;

  bool _debug = false;
  @override
  bool get isDebug => _debug;
  @override
  String get logTag => indicator.key.toString();
}

/// PaintObjectBox
/// 通过混入边界计算与数据初始化计算, 简化PaintObject接口.
abstract class PaintObjectBox<T extends PaintObjectIndicator>
    extends PaintObjectProxy with PaintObjectBoundingMixin, DataInitMixin {
  PaintObjectBox({
    required super.controller,
    required T super.indicator,
  });

  @override
  T get indicator => super.indicator as T;
}

/// 多个Indicator组合绘制
/// 主要实现接口遍历转发.
class MultiPaintObject extends PaintObjectBox<MultiPaintObjectIndicator> {
  MultiPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  void initData(List<CandleModel> list, {int start = 0, int end = 0}) {
    for (var indicator in indicator.children) {
      indicator.paintObject?.initData(list, start: start, end: end);
    }
  }

  @override
  Decimal get maxVal => throw UnimplementedError();

  @override
  Decimal get minVal => throw UnimplementedError();

  @override
  void paintChart(Canvas canvas, Size size) {
    for (var indicator in indicator.children) {
      indicator.paintObject?.paintChart(canvas, size);
    }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    for (var indicator in indicator.children) {
      indicator.paintObject?.onCross(canvas, offset);
    }
  }
}
