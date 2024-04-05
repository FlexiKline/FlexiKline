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

import '../../constant.dart';
import '../../kline_controller.dart';
import '../data.dart';
import '../setting.dart';
import '../state.dart';

abstract class BaseState {
  BaseState({required this.controller});
  final KlineController controller;

  SettingBinding get setting => controller.getInstance(controller);
  StateBinding get state => controller.getInstance(controller);

  // 主图蜡烛宽度与半值
  double get candleActualWidth => setting.candleActualWidth;
  double get candleWidthHalf => setting.candleWidthHalf;

  // 绘制涨跌Paint
  Paint get longPaint => setting.candleBarLongPaint;
  Paint get shortPaint => setting.candleBarShortPaint;

  // 副图区域
  Rect get subRect => setting.subRect;

  // 指标图高度的集合
  List<double> get indicatorHeightList => setting.indicatorHeightList;

  // KlineData数据
  KlineData get curKlineData => state.curKlineData;
  double get startCandleDx => state.startCandleDx;
}

abstract class IndicatorChart extends BaseState {
  IndicatorChart({
    required this.index,
    required this.type,
    required super.controller,
    required this.height,
    this.padding = EdgeInsets.zero,
    this.tipHeight = 0.0,
  });

  late int index;
  final IndicatorType type;
  final EdgeInsets padding;
  final double height;
  final double tipHeight;

  void updateIndex(int index) {
    _drawRect = null;
    _tipRect = null;
    _chartRect = null;
    this.index = index;
  }

  // 是否有TooolTip
  bool get hasTooltip => tipHeight > 0;

  double get chartRectTop {
    if (_chartRect != null) return _chartRect!.top;
    final list = indicatorHeightList;
    assert(index < list.length, 'current index is invalid!');
    double height = 0.0;
    for (var i = 0; i < index; i++) {
      height += list[i];
    }
    return height;
  }

  double get chartRectBottom {
    if (_chartRect != null) return _chartRect!.bottom;
    final list = indicatorHeightList;
    assert(index < list.length, 'current index is invalid!');
    return chartRectTop + list[index];
  }

  // 指标图区域Rect
  Rect? _chartRect;
  Rect get chartRect {
    _chartRect ??= Rect.fromLTRB(
      subRect.left,
      subRect.top + chartRectTop,
      subRect.right,
      subRect.top + chartRectBottom,
    );
    return _chartRect!;
  }

  // 指标图tooltip区域的Rect
  Rect? _tipRect;
  Rect get tipRect {
    _tipRect ??= Rect.fromLTRB(
      chartRect.left + padding.left,
      chartRect.top + padding.top,
      chartRect.right - padding.right,
      chartRect.top + tipHeight,
    );
    return _tipRect!;
  }

  Rect? _drawRect;
  Rect get drawRect {
    _drawRect ??= Rect.fromLTRB(
      chartRect.left + padding.left,
      tipRect.bottom,
      chartRect.right - padding.right,
      chartRect.bottom - padding.bottom,
    );
    return _drawRect!;
  }

  void paintSubChart(Canvas canvas, Size size);

  void paintYAxisTick(Canvas canvas, Size size);

  void paintTooltip(Canvas canvas, Size size);
}