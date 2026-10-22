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

/// L3 真机帧时间的汇总。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'common.dart';

/// 一个场景合并全部窗口后的统计, 时间单位 us。
///
/// - `missed`: build 或 raster 任一超预算的帧占比;
/// - `worst`: 窗口内最慢一帧(build 与 raster 取大);
/// - `op_p50`: 单次操作耗时的中位数, 只有切换类场景有(含义见 `apps/benchmark/integration_test/src/scenarios/` 各驱动);
/// - `rss` / `rss_max`: 窗口结束时的进程常驻内存与进程峰值, MB; 峰值只进 `device.json`。
final class _DeviceStat {
  _DeviceStat(this.windows, this.frames, this.metrics);

  final int windows;
  final int frames;
  final Map<String, double> metrics;
}

const _deviceMetrics = [
  'build_p50',
  'build_p90',
  'build_p99',
  'raster_p50',
  'raster_p90',
  'raster_p99',
  'missed',
  'worst',
];

final class _DeviceSide {
  _DeviceSide(this.env, this.runs, this.refreshRate, this.stats, this.gc);

  final Map<String, Object?> env;
  final int runs;
  final double refreshRate;
  final Map<String, _DeviceStat> stats;

  /// trace 运行的 GC 次数, 场景 → `new_gen` / `old_gen` 的中位数。
  final Map<String, Map<String, double>> gc;

  double get budgetUs => 1e6 / refreshRate;

  Map<String, Object?> toJson() => {
    'env': env,
    'runs': runs,
    'refreshRate': refreshRate,
    'budgetUs': double.parse(budgetUs.toStringAsFixed(1)),
    'scenarios': {
      for (final MapEntry(:key, :value) in stats.entries)
        key: {'windows': value.windows, 'frames': value.frames, ...value.metrics},
    },
    if (gc.isNotEmpty) 'gc': gc,
  };
}

double _percentile(List<int> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final index = ((sorted.length - 1) * p).round();
  return sorted[index].toDouble();
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  return sorted.isEmpty ? 0 : sorted[sorted.length ~/ 2];
}

/// 每个窗口各自算百分位与超预算占比, 再取全部窗口(含多次 drive)的中位数: 单个窗口的抖动不放大成结论。
_DeviceSide _mergeDevice(String path) {
  final runDirs =
      Directory(path)
          .listSync()
          .whereType<Directory>()
          .where(
            (d) => File('${d.path}/frames.json').existsSync(),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (runDirs.isEmpty) {
    stderr.writeln('no frames.json under $path');
    exit(1);
  }
  final perWindow = <String, Map<String, List<double>>>{};
  final frames = <String, int>{};
  final windows = <String, int>{};
  Map<String, Object?> env = const {};
  final rates = <double>[];
  // 只数有帧数据的运行; trace 运行只贡献 GC 次数。
  final framed = <String>{};
  final gc = <String, Map<String, List<double>>>{};
  for (final dir in runDirs) {
    final envFile = File('${dir.path}/env.json');
    if (envFile.existsSync()) env = jsonDecode(envFile.readAsStringSync()) as Map<String, Object?>;
    final trace = File('${dir.path}/trace.timeline_summary.json');
    if (trace.existsSync()) {
      final summary = jsonDecode(trace.readAsStringSync()) as Map<String, Object?>;
      final counts = gc.putIfAbsent('${env['scenario']}', () => {'new_gen': [], 'old_gen': []});
      counts['new_gen']!.add((summary['new_gen_gc_count']! as num).toDouble());
      counts['old_gen']!.add((summary['old_gen_gc_count']! as num).toDouble());
    }
    final json = jsonDecode(File('${dir.path}/frames.json').readAsStringSync()) as Map<String, Object?>;
    final rate = (json['refreshRate']! as num).toDouble();
    rates.add(rate);
    final budget = 1e6 / rate;
    for (final MapEntry(:key, :value) in (json['scenarios']! as Map<String, Object?>).entries) {
      // trace 运行写的是 `windows: 0`, 没有帧数据。
      final raw = (value! as Map<String, Object?>)['windows'];
      for (final w in raw is List ? raw.cast<Map<String, Object?>>() : const <Map<String, Object?>>[]) {
        final build = (w['build']! as List).cast<int>();
        final raster = (w['raster']! as List).cast<int>();
        if (build.isEmpty) continue;
        final sortedBuild = [...build]..sort();
        final sortedRaster = [...raster]..sort();
        var missed = 0;
        var worst = 0;
        for (var i = 0; i < build.length; i++) {
          if (build[i] > budget || raster[i] > budget) missed++;
          worst = math.max(worst, math.max(build[i], raster[i]));
        }
        final m = perWindow.putIfAbsent(key, () => {for (final k in _deviceMetrics) k: <double>[]});
        m['build_p50']!.add(_percentile(sortedBuild, 0.5));
        m['build_p90']!.add(_percentile(sortedBuild, 0.9));
        m['build_p99']!.add(_percentile(sortedBuild, 0.99));
        m['raster_p50']!.add(_percentile(sortedRaster, 0.5));
        m['raster_p90']!.add(_percentile(sortedRaster, 0.9));
        m['raster_p99']!.add(_percentile(sortedRaster, 0.99));
        m['missed']!.add(missed / build.length);
        m['worst']!.add(worst.toDouble());
        final ops = (w['ops'] as List?)?.cast<int>();
        if (ops != null && ops.isNotEmpty) m.putIfAbsent('op_p50', () => []).add(_percentile([...ops]..sort(), 0.5));
        if (w['rss'] case final num rss) m.putIfAbsent('rss', () => []).add(rss / (1 << 20));
        if (w['maxRss'] case final num rss) m.putIfAbsent('rss_max', () => []).add(rss / (1 << 20));
        frames[key] = (frames[key] ?? 0) + build.length;
        framed.add(dir.path);
        windows[key] = (windows[key] ?? 0) + 1;
      }
    }
  }
  return _DeviceSide(
    env,
    framed.length,
    _median(rates),
    {
      for (final MapEntry(:key, :value) in perWindow.entries)
        key: _DeviceStat(windows[key]!, frames[key]!, {
          for (final MapEntry(:key, :value) in value.entries) key: _median(value),
        }),
    },
    {
      for (final MapEntry(:key, :value) in gc.entries)
        key: {for (final MapEntry(:key, :value) in value.entries) key: _median(value)},
    },
  );
}

/// `summarize device`: 合并 `device.sh` 的多次运行; 预算按实测刷新率计算, 产出 `device.json` 与 `device-summary.md`。
void summarizeDevice(Map<String, String> opts) {
  final target = _mergeDevice(opts['target'] ?? usage());
  final baselineDir = opts['baseline'];
  final baseline = baselineDir == null ? null : _mergeDevice(baselineDir);
  final outDir = Directory(opts['out'] ?? usage())..createSync(recursive: true);

  writeJson('${outDir.path}/device.json', {
    'target': target.toJson(),
    if (baseline != null) 'baseline': baseline.toJson(),
  });

  final b = StringBuffer();
  final env = target.env;
  String side(_DeviceSide s) => '`${s.env['version']}` (`${s.env['sha']}`), ${s.runs} runs';
  b.writeln('# L3 device summary');
  b.writeln();
  b.writeln(
    '- device: ${env['device']} (${env['os']}), ${env['backend']}, '
    '${target.refreshRate.toStringAsFixed(0)}Hz, budget ${(target.budgetUs / 1000).toStringAsFixed(2)}ms',
  );
  b.writeln('- target: ${side(target)}');
  if (baseline != null) b.writeln('- baseline: ${side(baseline)}');
  b.writeln('- Flutter ${env['flutter']}, profile build; values are medians over windows, in ms');
  if (baseline != null && (baseline.refreshRate - target.refreshRate).abs() > target.refreshRate * 0.05) {
    b.writeln('- **warning**: baseline ran at ${baseline.refreshRate.toStringAsFixed(0)}Hz, not comparable');
  }
  if (baseline != null && baseline.env['flutter'] != env['flutter']) {
    b.writeln('- **warning**: baseline built with Flutter ${baseline.env['flutter']}, not comparable');
  }
  String windowsOf(Map<String, Object?> e) => '${e['windows']}x${e['windowSeconds']}s';
  if (baseline != null && windowsOf(baseline.env) != windowsOf(env)) {
    b.writeln(
      '- **warning**: baseline used ${windowsOf(baseline.env)} windows, target ${windowsOf(env)}; not comparable',
    );
  }
  b.writeln();
  String ms(double? us) => us == null ? '-' : (us / 1000).toStringAsFixed(2);
  String pct(double? v) => v == null ? '-' : '${(v * 100).toStringAsFixed(1)}%';
  String mb(double? v) => v == null ? '-' : v.toStringAsFixed(0);
  if (baseline == null) {
    b.writeln(
      '| scenario | build p90 | build p99 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | frames |',
    );
    b.writeln('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
    for (final MapEntry(:key, value: s) in target.stats.entries) {
      final m = s.metrics;
      b.writeln(
        '| $key | ${ms(m['build_p90'])} | ${ms(m['build_p99'])} | ${ms(m['raster_p90'])} | '
        '${ms(m['raster_p99'])} | ${ms(m['worst'])} | ${pct(m['missed'])} | ${ms(m['op_p50'])} | '
        '${mb(m['rss'])} | ${s.frames} |',
      );
    }
  } else {
    b.writeln('| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB |');
    b.writeln('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
    for (final key in {...baseline.stats.keys, ...target.stats.keys}) {
      final t = target.stats[key]?.metrics;
      final base = baseline.stats[key]?.metrics;
      String pair(String metric, String Function(double?) fmt) {
        if (base?[metric] == null && t?[metric] == null) return '-';
        return '${fmt(base?[metric])} → ${fmt(t?[metric])}';
      }

      b.writeln(
        '| $key | ${pair('build_p90', ms)} | ${pair('raster_p90', ms)} | ${pair('raster_p99', ms)} | '
        '${pair('worst', ms)} | ${pair('missed', pct)} | ${pair('op_p50', ms)} | ${pair('rss', mb)} |',
      );
    }
    b.writeln();
    b.writeln('Each cell is `baseline → target`.');
  }
  final gcKeys = {...target.gc.keys, ...?baseline?.gc.keys};
  if (gcKeys.isNotEmpty) {
    b.writeln();
    b.writeln('GC count in trace runs (one window each), new gen / old gen:');
    b.writeln();
    b.writeln('| scenario | baseline | target |');
    b.writeln('| --- | ---: | ---: |');
    String gcOf(_DeviceSide? s, String key) {
      final g = s?.gc[key];
      return g == null ? '-' : '${g['new_gen']!.toStringAsFixed(0)} / ${g['old_gen']!.toStringAsFixed(0)}';
    }

    for (final key in gcKeys) {
      b.writeln('| $key | ${gcOf(baseline, key)} | ${gcOf(target, key)} |');
    }
  }
  File('${outDir.path}/device-summary.md').writeAsStringSync(b.toString());
  stdout.write(b);
}
