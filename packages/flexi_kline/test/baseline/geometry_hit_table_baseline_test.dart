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

/// Step 1 翻转前基准（2.6.1 倒序）：几何命中表。
///
/// 用真实 controller 冻结当前几何契约：`dxToIndex(dx)` 的取整下标。采样覆盖画布右缘
/// （最新根）、中部、左缘与最新根右侧的空白区。
///
/// 倒序约定下：index 0 = 最新根，贴在画布右缘；dx 越往左下标越大（越旧）。
/// 数据正向化（v2.7.0）后，升序实现须产出本表的镜像：同一 dx 命中的下标变为
/// `length - 1 - index`，可见区间 `[start, end)` 变为 `[length - end, length - start)`。
/// 届时逐行改写期望，差异即几何契约翻转点。
///
/// 捕获方式：`_dump=true` 跑一次，从日志抄出 golden 填入 [frozen]，再改回 false 冻结。
@Tags(['baseline'])
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 改 true 时打印当前生产几何输出，用于首次捕获 golden。
const bool _dump = false;

const _spec = KlineSpec(symbol: 'GEOM-BASELINE', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 一个几何状态下的命中 golden。
typedef _Frozen = ({double panDx, double offset, List<int> hits});

void main() {
  const length = 200;
  const canvasWidth = 400.0;

  List<CandleModel> candles(int n) => [
    for (int i = 0; i < n; i++)
      CandleModel(
        timestamp: 1700000000000 - i * 86400000,
        open: '100',
        high: '101',
        low: '99',
        close: '100',
        volume: '1',
      ),
  ];

  // 固定 dx 采样点：右缘(最新)、右缘内半像素、3/4、中、1/4、左缘、负越界、右越界空白区。
  const sampleDx = <double>[400.0, 399.5, 300.0, 200.0, 100.0, 0.0, -10.0, 410.0];

  // 两个平移量：0（初始位置）与向左平移 300px（露出更旧的蜡烛）。
  const pans = <double>[0.0, -300.0];

  // 冻结的 golden：首次用 _dump=true 捕获后填入，与 [pans] 一一对应。
  const frozen = <_Frozen>[
    (panDx: 0.0, offset: 0.0, hits: [0, 0, 12, 25, 37, 50, 51, -1]),
    (panDx: -300.0, offset: -300.0, hits: [-37, -37, -25, -12, 0, 12, 13, -38]),
  ];

  testWidgets('geometry_hit_table_matches_frozen_golden', (tester) async {
    final results = <_Frozen>[];
    for (final pan in pans) {
      final scenario = ControllerScenario();
      addTearDown(scenario.dispose);
      await scenario.initWithData(_spec, candles(length), canvasWidth: canvasWidth);
      final chart = scenario.controller;
      await paintChartFrame(tester, chart);
      if (pan != 0) {
        chart.onChartMove(Offset(pan, 0));
        await paintChartFrame(tester, chart);
      }
      final hits = [for (final dx in sampleDx) chart.dxToIndex(dx) ?? -999];
      results.add((panDx: pan, offset: chart.paintDxOffset, hits: hits));
    }

    if (_dump) {
      final buf = StringBuffer('const frozen = <_Frozen>[\n');
      for (final r in results) {
        buf.writeln('  (panDx: ${r.panDx}, offset: ${r.offset}, hits: ${r.hits}),');
      }
      buf.write('];');
      // ignore: avoid_print
      print(buf.toString());
      return;
    }

    expect(frozen, isNotEmpty, reason: '请先用 _dump=true 捕获 golden 再冻结');
    expect(results.length, frozen.length);
    for (int i = 0; i < results.length; i++) {
      final got = results[i], want = frozen[i];
      expect(got.offset, closeTo(want.offset, 1e-6), reason: 'pan=${want.panDx} offset');
      expect(got.hits, want.hits, reason: 'pan=${want.panDx} hits');
    }
  });
}
