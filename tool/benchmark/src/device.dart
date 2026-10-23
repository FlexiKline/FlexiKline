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
/// - `win_frames`: 每个窗口的帧数(中位数); 两个版本的帧数差得多时, 说明它们画的工作量不一样;
/// - `op_p50`: 单次操作耗时的中位数, 只有切换类场景有(含义见 `apps/benchmark/integration_test/src/scenarios/` 各驱动);
///   精度约一帧, 因为终点是「数据生效后的那一帧画完」;
/// - `rss` / `rss_max`: 窗口结束时的进程常驻内存与进程峰值, MB; 峰值只进 `device.json`。`rss` 含前面场景留下、
///   尚未回收的堆, 受场景顺序影响, 只作参考;
/// - `rss_delta`: `rss` 减去本场景挂载前(上一个场景已卸载)的 RSS, MB, 是本场景带来的增量; 不强制 GC, 是近似值,
///   主要看 `memory/full`。
final class _DeviceStat {
  _DeviceStat(this.windows, this.frames, this.metrics);

  final int windows;
  final int frames;
  final Map<String, double> metrics;
}

/// 一次运行(一次 drive)里每个场景的关键指标, 每个值先在这次运行的窗口里取中位数; 用来看同一版本两次运行之间的差异。
typedef _Run = ({String name, Map<String, Map<String, double>> scenarios});

/// 记入每次运行明细的指标; 噪声只看 build 与 raster 的 p90(p99 本身波动更大, 不用来判断)。
const _runMetrics = ['build_p90', 'raster_p90', 'missed', 'win_frames'];
const _noiseMetrics = ['build_p90', 'raster_p90'];

/// 运行之间这些环境字段不一致时, 汇总里给出警告。
const _consistentEnvKeys = ['sha', 'code', 'flutter', 'windows', 'windowSeconds'];

final class _DeviceSide {
  _DeviceSide(this.env, this.runs, this.refreshRate, this.stats, this.gc, this.perRun, this.notes);

  final Map<String, Object?> env;
  final int runs;
  final double refreshRate;
  final Map<String, _DeviceStat> stats;

  /// trace 运行的 GC 次数, 场景 → `new_gen` / `old_gen` 的中位数。
  final Map<String, Map<String, double>> gc;
  final List<_Run> perRun;

  /// 这一侧的运行之间环境不一致的提示。
  final List<String> notes;

  double get budgetUs => 1e6 / refreshRate;

  /// 同一版本不同运行之间 p90 的相对差(build 与 raster 取大), 这是读数的噪声底线; 不足两次运行时为 null。
  double? noiseOf(String scenario) {
    double? noise;
    for (final metric in _noiseMetrics) {
      final values = [
        for (final run in perRun)
          if (run.scenarios[scenario]?[metric] case final value?) value,
      ];
      if (values.length < 2) continue;
      final low = values.reduce(math.min);
      if (low <= 0) continue;
      noise = math.max(noise ?? 0, (values.reduce(math.max) - low) / low);
    }
    return noise;
  }

  Map<String, Object?> toJson() => {
    'env': env,
    'runs': runs,
    'refreshRate': refreshRate,
    'budgetUs': double.parse(budgetUs.toStringAsFixed(1)),
    'scenarios': {
      for (final MapEntry(:key, :value) in stats.entries)
        key: {'windows': value.windows, 'frames': value.frames, ...value.metrics},
    },
    'perRun': [
      for (final run in perRun) {'run': run.name, 'scenarios': run.scenarios},
    ],
    if (notes.isNotEmpty) 'notes': notes,
    if (gc.isNotEmpty) 'gc': gc,
  };
}

double _percentile(List<int> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final index = ((sorted.length - 1) * p).round();
  return sorted[index].toDouble();
}

/// 偶数个值取上中位数; 两个版本口径一致, 不影响对比。
double _median(List<double> values) {
  final sorted = [...values]..sort();
  return sorted.isEmpty ? 0 : sorted[sorted.length ~/ 2];
}

/// 一个窗口的统计; [budget] 是帧预算(us)。窗口没有帧时返回 null。
Map<String, double>? _windowStats(Map<String, Object?> window, double budget) {
  final build = (window['build']! as List).cast<int>();
  final raster = (window['raster']! as List).cast<int>();
  if (build.isEmpty) return null;
  final sortedBuild = [...build]..sort();
  final sortedRaster = [...raster]..sort();
  var missed = 0;
  var worst = 0;
  for (var i = 0; i < build.length; i++) {
    if (build[i] > budget || raster[i] > budget) missed++;
    worst = math.max(worst, math.max(build[i], raster[i]));
  }
  final ops = (window['ops'] as List?)?.cast<int>();
  return {
    'build_p50': _percentile(sortedBuild, 0.5),
    'build_p90': _percentile(sortedBuild, 0.9),
    'build_p99': _percentile(sortedBuild, 0.99),
    'raster_p50': _percentile(sortedRaster, 0.5),
    'raster_p90': _percentile(sortedRaster, 0.9),
    'raster_p99': _percentile(sortedRaster, 0.99),
    'missed': missed / build.length,
    'worst': worst.toDouble(),
    'win_frames': build.length.toDouble(),
    if (ops != null && ops.isNotEmpty) 'op_p50': _percentile([...ops]..sort(), 0.5),
    if (window['rss'] case final num rss) 'rss': rss / (1 << 20),
    if (window['maxRss'] case final num rss) 'rss_max': rss / (1 << 20),
  };
}

void _collect(Map<String, Map<String, List<double>>> sink, String scenario, Map<String, double> values) {
  final metrics = sink.putIfAbsent(scenario, () => {});
  for (final MapEntry(:key, :value) in values.entries) {
    metrics.putIfAbsent(key, () => []).add(value);
  }
}

/// 每个窗口各自算百分位与超预算占比, 再取全部窗口(含多次 drive)的中位数: 单个窗口的抖动不放大成结论。
///
/// 目录不存在或一次成功的运行都没有(全部失败)时返回 null, 由调用方决定怎么处理。
_DeviceSide? _mergeDevice(String path) {
  if (!Directory(path).existsSync()) return null;
  final runDirs =
      Directory(path)
          .listSync()
          .whereType<Directory>()
          .where(
            (d) => File('${d.path}/frames.json').existsSync(),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (runDirs.isEmpty) return null;
  final perWindow = <String, Map<String, List<double>>>{};
  final frames = <String, int>{};
  final windows = <String, int>{};
  Map<String, Object?> env = const {};
  final framedEnvs = <Map<String, Object?>>[];
  final rates = <double>[];
  final perRun = <_Run>[];
  final gc = <String, Map<String, List<double>>>{};
  for (final dir in runDirs) {
    Map<String, Object?> runEnv = const {};
    final envFile = File('${dir.path}/env.json');
    if (envFile.existsSync()) runEnv = jsonDecode(envFile.readAsStringSync()) as Map<String, Object?>;
    final trace = File('${dir.path}/trace.timeline_summary.json');
    if (trace.existsSync()) {
      final summary = jsonDecode(trace.readAsStringSync()) as Map<String, Object?>;
      final counts = gc.putIfAbsent('${runEnv['scenario']}', () => {'new_gen': [], 'old_gen': []});
      counts['new_gen']!.add((summary['new_gen_gc_count']! as num).toDouble());
      counts['old_gen']!.add((summary['old_gen_gc_count']! as num).toDouble());
    }
    final json = jsonDecode(File('${dir.path}/frames.json').readAsStringSync()) as Map<String, Object?>;
    final rate = (json['refreshRate']! as num).toDouble();
    final budget = 1e6 / rate;
    final runWindows = <String, Map<String, List<double>>>{};
    for (final MapEntry(:key, :value) in (json['scenarios']! as Map<String, Object?>).entries) {
      // trace 运行写的是 `windows: 0`, 没有帧数据。
      final scenario = value! as Map<String, Object?>;
      final raw = scenario['windows'];
      final rssBefore = scenario['rssBefore'];
      for (final w in raw is List ? raw.cast<Map<String, Object?>>() : const <Map<String, Object?>>[]) {
        final stats = _windowStats(w, budget);
        if (stats == null) continue;
        if ((stats['rss'], rssBefore) case (final double rss, final num before)) {
          stats['rss_delta'] = rss - before / (1 << 20);
        }
        _collect(perWindow, key, stats);
        _collect(runWindows, key, stats);
        frames[key] = (frames[key] ?? 0) + stats['win_frames']!.toInt();
        windows[key] = (windows[key] ?? 0) + 1;
      }
    }
    // trace 运行只贡献 GC 次数, 不算一次有帧数据的运行。
    if (runWindows.isEmpty) continue;
    rates.add(rate);
    env = runEnv;
    framedEnvs.add(runEnv);
    perRun.add((
      name: dir.path.split('/').last,
      scenarios: {
        for (final MapEntry(:key, :value) in runWindows.entries)
          key: {
            for (final metric in _runMetrics)
              if (value[metric] case final values?) metric: _median(values),
          },
      },
    ));
  }
  if (perRun.isEmpty) return null;
  final notes = <String>[];
  for (final key in _consistentEnvKeys) {
    final values = {for (final e in framedEnvs) '${e[key]}'};
    if (values.length > 1) notes.add('runs differ in $key: ${(values.toList()..sort()).join(', ')}');
  }
  return _DeviceSide(
    env,
    perRun.length,
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
    perRun,
    notes,
  );
}

/// `summarize device`: 合并 `device.sh` 的多次运行; 预算按实测刷新率计算, 产出 `device.json` 与 `device-summary.md`。
///
/// 目标侧没有可用运行时报错退出(没有东西可汇总); 基线侧没有可用运行时退化成单侧表并注明。
void summarizeDevice(Map<String, String> opts) {
  final target = _mergeDevice(opts['target'] ?? usage());
  if (target == null) {
    stderr.writeln('no frames.json under ${opts['target']}');
    exit(1);
  }
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
  if (baseline != null) {
    b.writeln('- baseline: ${side(baseline)}');
  } else if (baselineDir != null) {
    b.writeln('- baseline: **no usable runs** (all failed); showing the target only');
  }
  b.writeln('- Flutter ${env['flutter']}, profile build; values are medians over windows, in ms');
  b.writeln(
    '- percentiles use nearest rank, medians over an even count take the upper one; `op p50` is accurate to about '
    'one frame; `noise` is the relative spread of p90 between runs of the same version, `~` marks a difference '
    'within it; `RSS MB` is the process RSS at the end of each window and includes heap left by earlier '
    'scenarios, `ΔRSS MB` subtracts the RSS measured before the scenario mounted (no forced GC, approximate)',
  );
  for (final (label, s) in [('target', target), ('baseline', baseline)]) {
    for (final note in s?.notes ?? const <String>[]) {
      b.writeln('- **warning**: $label $note');
    }
  }
  if (baseline != null && (baseline.refreshRate - target.refreshRate).abs() > target.refreshRate * 0.05) {
    b.writeln('- **warning**: baseline ran at ${baseline.refreshRate.toStringAsFixed(0)}Hz, not comparable');
  }
  if (baseline != null && baseline.env['flutter'] != env['flutter']) {
    b.writeln('- **warning**: baseline built with Flutter ${baseline.env['flutter']}, not comparable');
  }
  if (baseline != null && baseline.env['code'] != env['code']) {
    b.writeln(
      '- **warning**: baseline ran benchmark code ${baseline.env['code']}, target ${env['code']}; not comparable',
    );
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
      '| scenario | build p90 | build p99 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB '
      '| frames | noise |',
    );
    b.writeln('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
    for (final MapEntry(:key, value: s) in target.stats.entries) {
      final m = s.metrics;
      b.writeln(
        '| $key | ${ms(m['build_p90'])} | ${ms(m['build_p99'])} | ${ms(m['raster_p90'])} | '
        '${ms(m['raster_p99'])} | ${ms(m['worst'])} | ${pct(m['missed'])} | ${ms(m['op_p50'])} | '
        '${mb(m['rss'])} | ${mb(m['rss_delta'])} | ${s.frames} | ${pct(target.noiseOf(key))} |',
      );
    }
  } else {
    b.writeln(
      '| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB | ΔRSS MB | frames '
      '| noise |',
    );
    b.writeln('| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |');
    for (final key in {...baseline.stats.keys, ...target.stats.keys}) {
      final t = target.stats[key]?.metrics;
      final base = baseline.stats[key]?.metrics;
      final noise = [
        target.noiseOf(key),
        baseline.noiseOf(key),
      ].nonNulls.fold<double?>(null, (a, n) => math.max(a ?? 0, n));
      String pair(String metric, String Function(double?) fmt, {bool withNoise = false}) {
        final (x, y) = (base?[metric], t?[metric]);
        if (x == null && y == null) return '-';
        final inNoise = withNoise && noise != null && x != null && y != null && x > 0 && (y - x).abs() / x <= noise;
        return '${fmt(x)} → ${fmt(y)}${inNoise ? ' ~' : ''}';
      }

      // 帧数差得多时, 两边画的不是同样多的工作, 这一行的分位数不能直接比。
      final (fx, fy) = (base?['win_frames'], t?['win_frames']);
      final framesOff = fx != null && fy != null && fx > 0 && (fy - fx).abs() / fx > 0.1;
      String frameCount(double? v) => v == null ? '-' : v.toStringAsFixed(0);

      b.writeln(
        '| $key | ${pair('build_p90', ms, withNoise: true)} | ${pair('raster_p90', ms, withNoise: true)} | '
        '${pair('raster_p99', ms)} | ${pair('worst', ms)} | ${pair('missed', pct)} | ${pair('op_p50', ms)} | '
        '${pair('rss', mb)} | ${pair('rss_delta', mb)} | ${frameCount(fx)} → ${frameCount(fy)}${framesOff ? ' !' : ''} | ${pct(noise)} |',
      );
    }
    b.writeln();
    b.writeln(
      'Each cell is `baseline → target`; `frames` is frames per window, `!` marks a difference above 10% '
      '(the two versions drew a different amount of work).',
    );
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
