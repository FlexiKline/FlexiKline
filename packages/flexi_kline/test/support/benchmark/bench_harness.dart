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

/// benchmark 的计时与结构化输出。
///
/// 不 import flexi_kline: `tool/benchmark/overlay.sh` 会把它复制进旧版本的 worktree,
/// 核心包 API 的差异不能让它编译失败。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 一个 benchmark 文件的结果收集器; 在 `tearDownAll` 里 [write]。
///
/// 环境元数据由脚本经 `--dart-define` 注入并原样写出, Dart 侧不探测系统。
final class BenchReport {
  BenchReport(this.suite, {this.config = const {}});

  final String suite;
  final Map<String, Object> config;
  final _results = <Map<String, Object?>>[];

  /// 预热 1 轮后跑 [rounds] 轮, 每轮执行一次 [body], 单价 = 该轮耗时 ÷ [perRound]; 返回 best。
  ///
  /// best 用于定位单价(预热、GC、调度只会让某轮变慢); median 与 spread 判断这组读数是否可信。
  /// [name] 按 `<操作>/<装配>/<参数>` 命名、不带空格: 它是 CI 序列名与对照表行键, 入库后不再改名。
  double measure(
    String name,
    void Function() body, {
    required int rounds,
    int perRound = 1,
    String unit = 'us/frame',
    Map<String, Object?> meta = const {},
  }) {
    assert(!name.contains(' '), 'benchmark name must not contain spaces: $name');
    body();
    final samples = <double>[];
    for (var r = 0; r < rounds; r++) {
      final sw = Stopwatch()..start();
      body();
      sw.stop();
      samples.add(sw.elapsedMicroseconds / perRound);
    }
    final sorted = [...samples]..sort();
    final best = sorted.first;
    final median = sorted[sorted.length ~/ 2];
    final spread = best > 0 ? (sorted.last - best) / best : 0.0;
    _results.add({
      'name': name,
      'unit': unit,
      'best': _round(best),
      'median': _round(median),
      'spread': double.parse(spread.toStringAsFixed(3)),
      'rounds': [for (final s in samples) _round(s)],
      'meta': meta,
    });
    debugPrint(
      '${suite}_bench[$name]: ${best.toStringAsFixed(1)}$unit '
      '(median ${median.toStringAsFixed(1)}, spread ${(spread * 100).toStringAsFixed(1)}%'
      '${meta.isEmpty ? '' : ', $meta'})',
    );
    return best;
  }

  /// 写 `$FLEXI_BENCH_OUT/<suite>.json`; 未设置时只保留 [measure] 打印的行。
  ///
  /// 同步 IO: 在 tearDownAll 里调用, 避开 testWidgets 的 fake async。
  void write() {
    const out = String.fromEnvironment('FLEXI_BENCH_OUT');
    if (out.isEmpty || _results.isEmpty) return;
    final file = File('$out/$suite.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'schema': 1,
        'suite': suite,
        'env': {
          'sha': const String.fromEnvironment('FLEXI_BENCH_SHA'),
          'version': const String.fromEnvironment('FLEXI_BENCH_VERSION'),
          'flutter': const String.fromEnvironment('FLEXI_BENCH_FLUTTER'),
          'host': const String.fromEnvironment('FLEXI_BENCH_HOST'),
          'date': DateTime.now().toUtc().toIso8601String(),
        },
        'config': config,
        'results': _results,
      }),
    );
  }

  static double _round(double v) => (v * 10).roundToDouble() / 10;
}
