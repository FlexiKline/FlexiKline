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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';

import 'config/configuration.dart';
import 'constants.dart';
import 'data/candles.dart';
import 'preset.dart';

/// 全屏一个触屏模式的 K 线图, 无导航与动画; 由 integration test 或手动 `flutter run` 驱动。
class BenchChart extends StatefulWidget {
  const BenchChart({
    super.key,
    required this.preset,
    this.features = const {},
    this.candles = benchCandleCount,
  });

  final BenchPreset preset;
  final Set<BenchFeature> features;

  /// 初始蜡烛根数。
  final int candles;

  @override
  State<BenchChart> createState() => BenchChartState();
}

/// [controller] 与 [subKeys] 是 integration test 的入口。
class BenchChartState extends State<BenchChart> {
  late final FlexiKlineController controller;
  late final _main = widget.preset.mainIndicators();
  late final _sub = widget.preset.subIndicators();

  /// 副区指标的 key; indicators 场景用 `showSubIndicator` / `hideSubIndicator` 来回切换。
  List<IIndicatorKey> get subKeys => [for (final i in _sub) i.key];

  @override
  void initState() {
    super.initState();
    controller = FlexiKlineController(
      configuration: BenchConfiguration(
        features: widget.features,
        mainChildren: {for (final i in _main) i.key},
        subKeys: {for (final i in _sub) i.key},
      ),
    );
    controller.switchKlineData(benchSpec);
    controller.replaceKlineData(benchSpec, benchCandles(count: widget.candles));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlexiKlineWidget(
      controller: controller,
      candle: CandleIndicator(),
      time: TimeIndicator(),
      mainIndicators: _main,
      subIndicators: _sub,
      isTouchDevice: true,
    );
  }
}
