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

import 'dart:ui';

import 'package:decimal/decimal.dart';

import '../model/export.dart';
import 'indicator_chart.dart';

class VolumeChart extends IndicatorChartBox<VolumeIndicator> {
  VolumeChart(
    super.controller, {
    required super.indicator,
  });

  @override
  void calculateIndicatorData() {
    // TODO: implement calculateIndicatorData
  }
  @override
  // TODO: implement dyFactor
  double get dyFactor => throw UnimplementedError();

  @override
  double valueToDy(Decimal value) {
    // TODO: implement valueToDy
    throw UnimplementedError();
  }

  @override
  double? indexToDx(int index) {
    // TODO: implement indexToDx
    throw UnimplementedError();
  }

  @override
  Decimal? dyToValue(double dy) {
    // TODO: implement dyToValue
    throw UnimplementedError();
  }

  @override
  int dxToIndex(double dx) {
    // TODO: implement dxToIndex
    throw UnimplementedError();
  }

  @override
  void paintIndicatorChart(Canvas canvas, Size size) {
    // TODO: implement paintIndicatorChart
  }

  @override
  void paintAxisTickMark(Canvas canvas, Size size) {
    // TODO: implement paintAxisTickMark
  }

  @override
  void paintCrossTickMark(Canvas canvas, Offset offset) {
    // TODO: implement paintCrossTickMark
  }

  @override
  void paintCrossTips(Canvas canvas, Offset offset) {
    // TODO: implement paintCrossTips
  }
}
