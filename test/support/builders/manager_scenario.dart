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

/// Manager 级薄 arrange 脚手架。
///
/// 只负责 declare/mount/activate/update，断言永远留在测试体内。
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';

import '../doubles/fake_kline_config.dart';
import '../doubles/fake_paint_context.dart';
import '../doubles/test_indicators.dart';
import '../generators/indicator_desc.dart';

/// Manager 级场景构建器
class ManagerScenario {
  ManagerScenario(
    this.rng, {
    FakeFlexiKlineConfiguration? config,
    int subMax = defaultSubIndicatorMaxCount,
  }) : context = FakePaintContext() {
    manager = IndicatorPaintObjectManager(
      configuration: config ?? FakeFlexiKlineConfiguration(),
      subIndicatorMaxCount: subMax,
    );
  }

  final Random rng;
  final FakePaintContext context;
  late final IndicatorPaintObjectManager manager;

  List<IndicatorDesc> _main = const [];
  List<IndicatorDesc> _sub = const [];

  /// 声明主区指标
  ManagerScenario declareMain(List<IndicatorDesc> descs) {
    _main = descs;
    return this;
  }

  /// 声明副区指标
  ManagerScenario declareSub(List<IndicatorDesc> descs) {
    _sub = descs;
    return this;
  }

  /// 执行 mountIndicators
  ManagerScenario mount() {
    manager.mountIndicators(
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: _main.map(createIndicator).toList(),
      subIndicators: _sub.map(createIndicator).toList(),
      context: context,
    );
    return this;
  }

  /// 激活主区指标
  void activateMain(IIndicatorKey key) => manager.addMainPaintObject(key, context);

  /// 激活副区指标
  void activateSub(IIndicatorKey key) => manager.addSubPaintObject(key, context);
}
