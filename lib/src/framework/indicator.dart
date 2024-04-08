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
import '../model/export.dart';
import 'element.dart';
import 'paint_object.dart';

@immutable
abstract class Indicator {
  const Indicator({this.key});
  final Key? key;

  @protected
  @factory
  IndicatorElement createElement();

  static bool canUpdate(Indicator oldIndicator, Indicator newIndicator) {
    return oldIndicator.runtimeType == newIndicator.runtimeType &&
        oldIndicator.key == newIndicator.key;
  }

  static bool isMultiIndicator(Indicator indicator) {
    return indicator is MultiChartIndicator;
  }
}

@immutable
abstract class PaintObjectIndicator extends Indicator {
  const PaintObjectIndicator({
    super.key,
    this.tipsHeight = 0.0,
    this.padding = EdgeInsets.zero,
  });

  final double tipsHeight;
  final EdgeInsets padding;

  @protected
  @factory
  IndicatorChart createIndicatorChart(KlineBindingBase controller);

  @override
  @protected
  @factory
  IndicatorElement<PaintObjectIndicator> createElement();

  @protected
  void updateIndicatorChart(
    KlineBindingBase controller,
    covariant IndicatorChart indicatorChart,
  ) {}

  static bool canUpdate(
      PaintObjectIndicator oldIndicator, PaintObjectIndicator newIndicator) {
    return oldIndicator.runtimeType == newIndicator.runtimeType &&
        oldIndicator.key == newIndicator.key;
  }

  static bool isMultiIndicator(PaintObjectIndicator indicator) {
    return indicator is MultiChartIndicator;
  }
}

abstract class SingleChartIndicator extends PaintObjectIndicator {
  const SingleChartIndicator({
    super.key,
    super.tipsHeight,
    super.padding,
  });

  @override
  IndicatorElement<PaintObjectIndicator> createElement() {
    return SingleIndicatorElement(this);
  }
}

class MultiChartIndicator extends PaintObjectIndicator {
  const MultiChartIndicator({
    super.key,
    super.tipsHeight,
    super.padding,
    this.children = const <PaintObjectIndicator>[],
  });

  final List<PaintObjectIndicator> children;

  @override
  MultiChartIndicatorChart createIndicatorChart(KlineBindingBase controller) {
    return MultiChartIndicatorChart(controller: controller, indicator: this);
  }

  @override
  IndicatorElement<PaintObjectIndicator> createElement() {
    // TODO: implement createElement
    throw UnimplementedError();
  }

  @override
  void updateIndicatorChart(
    KlineBindingBase controller,
    covariant MultiChartIndicatorChart indicatorChart,
  ) {
    super.updateIndicatorChart(controller, indicatorChart);
  }
}

class MultiChartIndicatorChart extends IndicatorChartBox<MultiChartIndicator> {
  MultiChartIndicatorChart({
    required super.controller,
    required super.indicator,
  });

  MultiChartIndicator get multiIndicator => indicator as MultiChartIndicator;

  @override
  void initData(List<CandleModel> list, {int start = 0, int end = 0}) {}

  @override
  Decimal get maxVal => throw UnimplementedError();

  @override
  Decimal get minVal => throw UnimplementedError();

  @override
  void paintChart(Canvas canvas, Size size) {}

  @override
  void onCross(Canvas canvas, Offset offset) {}
}
