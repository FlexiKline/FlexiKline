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

library;

import 'package:flexi_kline/flexi_kline.dart';

import 'src/export.dart';

export 'src/export.dart';

/// All draw-tool builders (unmodifiable).
final Map<IDrawType, DrawObjectBuilder> drawObjectBuilders = Map.unmodifiable(<IDrawType, DrawObjectBuilder>{
  // lines
  trendLine: TrendLineDrawObject.new,
  trendAngle: TrendAngleDrawObject.new,
  crossLine: CrossLineDrawObject.new,
  horizontalLine: HorizontalLineDrawObject.new,
  horizontalRayLine: HorizontalRayLineDrawObject.new,
  horizontalTrendLine: HorizontalTrendLineDrawObject.new,
  verticalLine: VerticalLineDrawObject.new,
  extendedTrendLine: ExtendedTrendLineDrawObject.new,
  arrowLine: ArrowLineDrawObject.new,
  rayLine: RayLineDrawObject.new,
  priceLine: PriceLineDrawObject.new,
  // projection
  parallelChannel: ParallelChannelDrawObject.new,
  parallelogram: ParallelogramDrawObject.new,
  rectangle: RectangleDrawObject.new,
  // fibonacci
  fibRetracement: FibRetracementDrawObject.new,
  fibExpansion: FibExpansionDrawObject.new,
  fibFans: FibFansDrawObject.new,
  // patterns
  tripleWaves: ElliottImpulseWaveDrawObject.new,
  pentaWaves: ElliottImpulseWaveDrawObject.new,
});

/// Register all draw-tool builders onto [controller].
void registerAllDrawObjectBuilder(FlexiKlineController controller) {
  for (final MapEntry(key: type, value: builder) in drawObjectBuilders.entries) {
    controller.registerDrawObjectBuilder(type, builder);
  }
}

/// Mixin that provides [drawObjectBuilders] to an [IConfiguration].
///
/// mixin 内的 getter 与顶层同名变量同名; 通过显式 `_allBuilders` 引用
/// 避免 getter 递归调用自身。
final _allBuilders = drawObjectBuilders;

mixin DrawObjectBuildersConfigMixin on IConfiguration {
  @override
  Map<IDrawType, DrawObjectBuilder> get drawObjectBuilders => _allBuilders;
}
