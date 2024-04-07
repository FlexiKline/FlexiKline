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

import 'dart:collection';

import 'package:flutter/material.dart';

import '../constant.dart';
import '../kline_controller.dart';

import 'binding_base.dart';
import 'indicator/export.dart';
import 'interface.dart';
import 'setting.dart';

mixin SubBinding
    on KlineBindingBase, SettingBinding
    implements ISubChart, IState, ICross {
  @override
  void initBinding() {
    super.initBinding();
    logd('init sub');
    appendIndicator(
      IndicatorType.volume,
      tipHeight: 10,
    );
    // appendIndicator(
    //   IndicatorType.macd,
    //   height: 100,
    // );
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose');
  }

  final Queue<IndicatorChart> indicatorQueue = ListQueue();

  // 副图指标数量
  @override
  int get indicatorCount => indicatorQueue.length;

  // 指标图高度的集合
  @override
  List<double> get indicatorHeightList {
    return indicatorQueue.map((e) => e.height).toList(growable: false);
  }

  @override
  double get subRectHeight {
    return indicatorHeightList.reduce((curr, next) => curr + next);
  }

  void appendIndicator(
    IndicatorType type, {
    double height = 60,
    double tipHeight = 0,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    // assert(tipHeight < indicatorHeight);
    switch (type) {
      case IndicatorType.volume:
        indicatorQueue.addLast(VolumeChart(
          debug: debug,
          index: indicatorQueue.length,
          controller: this as FlexiKlineController,
          height: height,
          tipHeight: tipHeight,
          padding: padding,
        ));
      case IndicatorType.ma:
        indicatorQueue.addLast(VolumeChart(
          debug: debug,
          index: indicatorQueue.length,
          controller: this as FlexiKlineController,
          height: height,
          tipHeight: tipHeight,
          padding: padding,
        ));
      case IndicatorType.candle:
      // TODO: Handle this case.
      case IndicatorType.composite:
      // TODO: Handle this case.
    }
  }

  @override
  void paintSubChart(Canvas canvas, Size size) {
    for (var indicator in indicatorQueue) {
      /// 绘制 Volume
      indicator.paintIndicatorChart(canvas, size);
    }
  }

  @override
  void paintSubTooltip(Canvas canvas, Size size) {
    for (var indicator in indicatorQueue) {
      /// 绘制 Volume
      indicator.paintSubTooltip(canvas, size);
    }
  }

  @override
  void paintSubCross(Canvas canvas, Size size) {
    final offset = crossingOffset;
    if (offset == null) return;
    for (var indicator in indicatorQueue) {
      /// 绘制 Volume
      indicator.handleIndicatorCross(canvas, offset);
    }
  }
}
