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

import 'draw_param.dart';

/// 绘图工具参数的统一配置入口。
///
/// ```dart
/// DrawToolsConfig.configure(
///   arrowLine: const ArrowLineDrawParam(arrowsLen: 20),
///   rectangle: const RectangleDrawParam(rectangleBgOpacity: 0.2),
/// );
/// ```
class DrawToolsConfig {
  DrawToolsConfig._();

  static final DrawToolsConfig _instance = DrawToolsConfig._();
  static DrawToolsConfig get instance => _instance;

  ArrowLineDrawParam arrowLine = const ArrowLineDrawParam();
  PriceLineDrawParam priceLine = const PriceLineDrawParam();
  TrendAngleDrawParam trendAngle = const TrendAngleDrawParam();
  ParallelChannelDrawParam parallelChannel = const ParallelChannelDrawParam();
  RectangleDrawParam rectangle = const RectangleDrawParam();
  ParallelogramDrawParam parallelogram = const ParallelogramDrawParam();
  FibonacciDrawParam fibExpansion = const FibonacciDrawParam();
  FibonacciDrawParam fibRetracement = const FibonacciDrawParam();
  FibFansDrawParam fibFans = const FibFansDrawParam();

  /// Only the parameters you pass in are overwritten; the rest stay unchanged.
  static void configure({
    ArrowLineDrawParam? arrowLine,
    PriceLineDrawParam? priceLine,
    TrendAngleDrawParam? trendAngle,
    ParallelChannelDrawParam? parallelChannel,
    RectangleDrawParam? rectangle,
    ParallelogramDrawParam? parallelogram,
    FibonacciDrawParam? fibExpansion,
    FibonacciDrawParam? fibRetracement,
    FibFansDrawParam? fibFans,
  }) {
    if (arrowLine != null) _instance.arrowLine = arrowLine;
    if (priceLine != null) _instance.priceLine = priceLine;
    if (trendAngle != null) _instance.trendAngle = trendAngle;
    if (parallelChannel != null) _instance.parallelChannel = parallelChannel;
    if (rectangle != null) _instance.rectangle = rectangle;
    if (parallelogram != null) _instance.parallelogram = parallelogram;
    if (fibExpansion != null) _instance.fibExpansion = fibExpansion;
    if (fibRetracement != null) _instance.fibRetracement = fibRetracement;
    if (fibFans != null) _instance.fibFans = fibFans;
  }

  /// Reset all parameters to defaults. Intended for test isolation.
  static void resetAll() {
    _instance.arrowLine = const ArrowLineDrawParam();
    _instance.priceLine = const PriceLineDrawParam();
    _instance.trendAngle = const TrendAngleDrawParam();
    _instance.parallelChannel = const ParallelChannelDrawParam();
    _instance.rectangle = const RectangleDrawParam();
    _instance.parallelogram = const ParallelogramDrawParam();
    _instance.fibExpansion = const FibonacciDrawParam();
    _instance.fibRetracement = const FibonacciDrawParam();
    _instance.fibFans = const FibFansDrawParam();
  }
}
