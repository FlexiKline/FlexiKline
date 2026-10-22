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

/// 真机采集(L3)的设备端入口: 逐个场景挂载图表、预热、按窗口记录, 经 reportData 回传原始数据。
///
/// 不用 `watchPerformance` 的汇总: 它的超预算判定固定按 16ms, 高刷下会漏判;
/// 这里只回传原始 build / raster 耗时、单次操作耗时、RSS 与实测刷新率, 统计由 `tool/benchmark/bench.dart` 做。
///
/// dart-define:
/// - `MODE`: `frames`(默认)或 `trace`(只跑选中的一个场景的一个窗口, 包在 traceAction 里取时间线);
/// - `SCENARIO`: 逗号分隔的场景名, 可用 `pan/*` 这样的前缀; 为空跑全部;
/// - `WINDOWS` / `WINDOW_SECONDS`: 每场景计时窗口数与窗口时长, 默认 5 × 10s, 冒烟时调小。
library;

import 'package:flexi_kline_benchmark/src/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'src/recorder.dart';
import 'src/scenario.dart';
import 'src/scenarios/data.dart';
import 'src/scenarios/draw.dart';
import 'src/scenarios/interaction.dart';

const _mode = String.fromEnvironment('MODE', defaultValue: 'frames');
const _filter = String.fromEnvironment('SCENARIO');
const _windows = int.fromEnvironment('WINDOWS', defaultValue: 5);

Map<String, Scenario> _allScenarios() {
  final all = <String, Scenario>{};
  for (final table in [interactionScenarios, dataScenarios, drawScenarios]) {
    for (final MapEntry(:key, :value) in table.entries) {
      if (all.containsKey(key)) throw StateError('duplicate scenario $key');
      all[key] = value;
    }
  }
  return all;
}

/// [_filter] 选中的场景名; 每项是完整名称或以 `/*` 结尾的前缀。
List<String> _select(Iterable<String> names) {
  if (_filter.isEmpty) return names.toList();
  final selected = <String>[];
  for (final pattern in _filter.split(',').map((p) => p.trim())) {
    final matches = pattern.endsWith('*')
        ? names.where((n) => n.startsWith(pattern.substring(0, pattern.length - 1)))
        : names.where((n) => n == pattern);
    if (matches.isEmpty) throw ArgumentError('SCENARIO $pattern matches nothing; expected one of $names');
    selected.addAll(matches.where((n) => !selected.contains(n)));
  }
  return selected;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // 否则 integration_test 不按真实 vsync 出帧。
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final scenarios = _allScenarios();
  final selected = _select(scenarios.keys);
  if (_mode == 'trace' && selected.length != 1) throw ArgumentError('MODE=trace requires exactly one SCENARIO');

  testWidgets('device benchmark', (tester) async {
    final results = <String, Object>{};
    double refreshRate = 0;
    for (final name in selected) {
      final scenario = scenarios[name]!;
      await tester.pumpWidget(
        BenchApp(
          key: UniqueKey(),
          preset: scenario.preset,
          features: scenario.features,
          candles: scenario.candles,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
      refreshRate = tester.view.display.refreshRate;
      final ctx = ScenarioContext(tester, refreshRate);

      Future<void> prepare() async => scenario.prepare?.call(ctx);
      Future<void> drive() => scenario.drive(ctx);

      if (_mode == 'trace') {
        await prepare();
        ctx.startWindow();
        await drive(); // 预热
        await prepare();
        ctx.startWindow();
        await binding.traceAction(drive, reportKey: 'timeline');
        results[name] = {'windows': 0};
        continue;
      }

      await prepare();
      await recordWindow(ctx, drive); // 预热窗口, 丢弃
      final windows = <Map<String, Object>>[];
      for (var w = 0; w < _windows; w++) {
        await prepare();
        windows.add(await recordWindow(ctx, drive));
      }
      results[name] = {'windows': windows};
      debugPrint('bench[$name]: ${[for (final w in windows) w['frames']]} frames per window');
    }
    binding.reportData = {
      ...?binding.reportData,
      'schema': 1,
      'mode': _mode,
      'refreshRate': refreshRate,
      'windowSeconds': windowDuration.inSeconds,
      'scenarios': results,
    };
  }, timeout: Timeout.none);
}
