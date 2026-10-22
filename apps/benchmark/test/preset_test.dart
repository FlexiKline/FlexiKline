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
import 'package:flexi_kline_benchmark/src/app.dart';
import 'package:flexi_kline_benchmark/src/chart.dart';
import 'package:flexi_kline_benchmark/src/preset.dart';
import 'package:flutter_test/flutter_test.dart';

/// 装配里声明的指标都要真正进树: 没激活的指标不画也不算, 场景读数会悄悄变轻。
void main() {
  testWidgets('full preset activates all four indicators', (tester) async {
    await tester.pumpWidget(const BenchApp(preset: BenchPreset.full));
    await tester.pump();
    final controller = tester.state<BenchChartState>(find.byType(BenchChart)).controller;

    expect(
      controller.mainIndicatorKeys,
      containsAll(const [DirectIndicatorKey('bench_volume'), ComputedIndicatorKey('bench_ma')]),
    );
    expect(
      controller.subIndicatorKeys,
      containsAll(const [ComputedIndicatorKey('bench_macd'), ComputedIndicatorKey('bench_vol_ma')]),
    );
  });

  testWidgets('base preset has no extra indicators', (tester) async {
    await tester.pumpWidget(const BenchApp(preset: BenchPreset.base));
    await tester.pump();
    final controller = tester.state<BenchChartState>(find.byType(BenchChart)).controller;

    expect(controller.getSubIndicatorHeights(), isEmpty);
  });
}
