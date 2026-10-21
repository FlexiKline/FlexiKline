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

/// `flutter drive` 的主机侧: 把 reportData 写进 `$FLEXI_BENCH_DEVICE_OUT`。
///
/// - frames 模式写 `frames.json`(原始帧时间);
/// - trace 模式额外写 `trace.timeline_summary.json`(入库)与 `trace.timeline.json`(不入库)。
///
/// `FLEXI_BENCH_HZ` 非空时核对实测刷新率, 偏差超过 5% 就失败: 设备没切到目标档位时不出数。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) throw StateError('no reportData from the device');
      final out = Directory(Platform.environment['FLEXI_BENCH_DEVICE_OUT'] ?? 'build/benchmark/device/latest');
      out.createSync(recursive: true);

      final timeline = data.remove('timeline');
      File('${out.path}/frames.json').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(data)}\n');
      if (timeline != null) {
        final summary = TimelineSummary.summarize(Timeline.fromJson(timeline as Map<String, dynamic>));
        await summary.writeTimelineToFile('trace', destinationDirectory: out.path, pretty: true);
      }

      final hz = double.tryParse(Platform.environment['FLEXI_BENCH_HZ'] ?? '');
      final measured = (data['refreshRate'] as num).toDouble();
      if (hz != null && (measured - hz).abs() > hz * 0.05) {
        throw StateError('refresh rate is ${measured.toStringAsFixed(1)}Hz, expected ${hz}Hz; switch the display mode');
      }
      stdout.writeln('wrote ${out.path} (refresh rate ${measured.toStringAsFixed(1)}Hz)');
    },
  );
}
