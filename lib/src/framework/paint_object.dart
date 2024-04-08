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
import 'element.dart';

const mainDrawIndex = -1;

/// 指标图的绘制边界接口
abstract interface class IIndicatorBoundingBox {
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

/// 数据与坐标相互转换接口
abstract interface class IDataInit {
  /// 计算指标需要的数据
  void initData(List<CandleModel> list, {int start = 0, int end = 0});

  /// 最大值/最小值
  Decimal get maxVal;
  Decimal get minVal;
}

/// 指标图绘制接口
abstract interface class IPaintChart {
  /// 绘制指标图
  void paintChart(Canvas canvas, Size size);

  /// 绘制XAxis与YAxis刻度值
  // void paintAxisTickMark(Canvas canvas, Size size);

  /// 绘制顶部tips信息
  // void paintTips(Canvas canvas, Size size);
}

/// 指标图的Cross绘制接口
abstract interface class IPaintCross {
  /// 绘制Cross上的刻度值
  void onCross(Canvas canvas, Offset offset);

  /// 绘制Cross命中的指标信息
  // void paintCrossTips(Canvas canvas, Offset offset);
}

/// IndicatorChart
/// 通过实现对应的接口, 实现Chart的配置, 计算, 绘制, Cross
// @immutable
abstract class IndicatorChart<T extends PaintObjectIndicator>
    implements IIndicatorBoundingBox, IDataInit, IPaintChart, IPaintCross {
  const IndicatorChart({
    required this.indicator,
  });

  final T indicator;

  // T get myindicator => indicator
}

/// IndicatorChart 对 KlineBindingBase的代理.
/// 主要是setting和state的代理
abstract class IndicatorChartProxy<T extends PaintObjectIndicator>
    extends IndicatorChart with KlineLog, SettingProxyMixin, StateProxyMixin {
  IndicatorChartProxy({
    required KlineBindingBase controller,
    required T super.indicator,
  }) {
    setting = controller as SettingBinding;
    state = controller as IState;
    _debug = controller.debug;
  }

  bool _debug = false;
  @override
  bool get isDebug => _debug;
  @override
  String get logTag => indicator.key.toString();
}

abstract class IndicatorChartBox<T extends PaintObjectIndicator>
    extends IndicatorChartProxy with IndicatorBoundingMixin, DataInitMixin {
  IndicatorChartBox({
    required super.controller,
    required T super.indicator,
  });
}

/// 代理Setting.
mixin SettingProxyMixin on IndicatorChart {
  late final SettingBinding setting;

  double get candleActualWidth => setting.candleActualWidth;

  double get candleWidthHalf => setting.candleWidthHalf;
}

/// 代理State
mixin StateProxyMixin on IndicatorChart {
  late final IState state;

  KlineData get curKlineData => state.curKlineData;

  double get paintDxOffset => state.paintDxOffset;

  double get startCandleDx => state.startCandleDx;
}

/// IndicatorChart的接口实现的通用扩展

/// IndicatorBounding的通用扩展
mixin IndicatorBoundingMixin on IndicatorChartProxy
    implements IIndicatorBoundingBox {
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

/// DataInit的通用扩展
mixin DataInitMixin on IndicatorChartProxy implements IDataInit {
  double get candleWidth => candleActualWidth;

  double get dyFactor {
    return chartRect.height / (maxVal - minVal).toDouble();
  }

  double valueToDy(Decimal value) {
    value = value.clamp(minVal, maxVal);
    return chartRect.bottom - (value - minVal).toDouble() * dyFactor;
  }

  double? indexToDx(int index) {
    double dx = chartRect.right - (index * candleWidth - paintDxOffset);
    if (chartRect.inclueDx(dx)) return dx;
    return null;
  }

  Decimal? dyToValue(double dy) {
    if (!chartRect.inclueDy(dy)) return null;
    return maxVal - ((dy - chartRect.top) / dyFactor).d;
  }

  int dxToIndex(double dx) {
    final dxPaintOffset = (chartRect.right - dx) + paintDxOffset;
    return (dxPaintOffset / candleWidth).floor();
  }

  CandleModel? dxToCandle(double dx) {
    final index = dxToIndex(dx);
    return state.curKlineData.getCandle(index);
  }
}
