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

/// 测试用 Indicator / PaintObject 子类（v2.2.0 三类型体系）
///
/// 提供 [CandleBaseIndicator]、[TimeBaseIndicator]、[DirectIndicator]、
/// [ComputedIndicator]、[ExternalIndicator] 的最小化实现，
/// 用于 [IndicatorPaintObjectManager] 的单元测试和属性测试。
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
  FlexiChartType resolveChartType() => FlexiChartType.barSolid;
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTooltip(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
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
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTooltip(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// Direct
// ---------------------------------------------------------------------------

/// 测试用 [DirectIndicator] 子类，支持自定义 key 和 height
class TestDirectIndicator extends DirectIndicator {
  TestDirectIndicator({required super.key, super.height = 100}) : super(padding: EdgeInsets.zero);

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _TestDirectPaintObject();
}

class _TestDirectPaintObject extends DirectPaintObject<TestDirectIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTooltip(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

// ---------------------------------------------------------------------------
// Computed
// ---------------------------------------------------------------------------

/// 测试用 [ComputedIndicator] 子类，支持自定义 key、height 和 param
class TestComputedIndicator extends ComputedIndicator {
  TestComputedIndicator({required super.key, super.height = 100, this.param}) : super(padding: EdgeInsets.zero);

  /// 可选计算参数，暴露给 [calcParam] getter
  final dynamic param;

  @override
  dynamic get calcParam => param;

  @override
  ComputedPaintObject<ComputedIndicator> createPaintObject() => _TestComputedPaintObject();
}

class _TestComputedPaintObject extends ComputedPaintObject<TestComputedIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTooltip(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
  @override
  bool shouldRecompute(covariant TestComputedIndicator oldIndicator) => false;
  @override
  void compute(Range range, {bool reset = false}) {}
}

// ---------------------------------------------------------------------------
// External
// ---------------------------------------------------------------------------

/// 测试用 [ExternalIndicator] 子类，支持自定义 key 和 height
class TestExternalIndicator extends ExternalIndicator {
  TestExternalIndicator({required super.key, super.height = 80}) : super(padding: EdgeInsets.zero);

  @override
  ExternalPaintObject<ExternalIndicator> createPaintObject() => _TestExternalPaintObject();
}

class _TestExternalPaintObject extends ExternalPaintObject<TestExternalIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTooltip(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}
