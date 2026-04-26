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

/// 测试用 Indicator / PaintObject 子类
///
/// 提供 [CandleBaseIndicator]、[TimeBaseIndicator]、[DataIndicator]、
/// [BusinessIndicator] 的最小化实现，用于 [IndicatorPaintObjectManager]
/// 的单元测试和属性测试。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

// ---------------------------------------------------------------------------
// Candle
// ---------------------------------------------------------------------------

/// 测试用 [CandleBaseIndicator] 子类，支持自定义 height
class TestCandleIndicator extends CandleBaseIndicator {
  TestCandleIndicator({super.height = 300}) : super(padding: EdgeInsets.zero);

  @override
  CandleBasePaintObject<CandleBaseIndicator> createPaintObject() => _TestCandlePaintObject();
}

class _TestCandlePaintObject extends CandleBasePaintObject<TestCandleIndicator> {
  @override
  FlexiChartType getChartType() => FlexiChartType.barSolid;
  @override
  MinMax? initState(int start, int end) => null;
  @override
  void paintChart(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// Time
// ---------------------------------------------------------------------------

/// 测试用 [TimeBaseIndicator] 子类，支持自定义 height
class TestTimeIndicator extends TimeBaseIndicator {
  TestTimeIndicator({super.height = 20}) : super(padding: EdgeInsets.zero, position: DrawPosition.middle);

  @override
  TimeBasePaintObject<TimeBaseIndicator> createPaintObject() => _TestTimePaintObject();
}

class _TestTimePaintObject extends TimeBasePaintObject<TestTimeIndicator> {
  @override
  MinMax? initState(int start, int end) => null;
  @override
  void paintChart(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

/// 测试用 [DataIndicator] 子类，支持自定义 key 和 height
class TestDataIndicator extends DataIndicator {
  TestDataIndicator({required super.key, super.height = 100}) : super(padding: EdgeInsets.zero);

  @override
  DataPaintObject<DataIndicator> createPaintObject() => _TestDataPaintObject();
}

class _TestDataPaintObject extends DataPaintObject<TestDataIndicator> {
  @override
  MinMax? initState(int start, int end) => null;
  @override
  void paintChart(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
  @override
  bool shouldPrecompute(covariant TestDataIndicator oldIndicator) => false;
  @override
  void precompute(Range range, {bool reset = false}) {}
}

// ---------------------------------------------------------------------------
// Business
// ---------------------------------------------------------------------------

/// 测试用 [BusinessIndicator] 子类，支持自定义 key 和 height
class TestBusinessIndicator extends BusinessIndicator {
  TestBusinessIndicator({required super.key, super.height = 80}) : super(padding: EdgeInsets.zero);

  @override
  BusinessPaintObject<BusinessIndicator> createPaintObject() => _TestBusinessPaintObject();
}

class _TestBusinessPaintObject extends BusinessPaintObject<TestBusinessIndicator> {
  @override
  MinMax? initState(int start, int end) => null;
  @override
  void paintChart(Canvas canvas, Size size) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}
