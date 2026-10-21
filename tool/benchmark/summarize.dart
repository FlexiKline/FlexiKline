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

/// 合并多次运行的 benchmark 结果并出对照表。
///
/// ```bash
/// dart tool/benchmark/summarize.dart l1 --target <runs-dir> [--baseline <runs-dir>] --out <dir>
/// dart tool/benchmark/summarize.dart l3 --target <runs-dir> [--baseline <runs-dir>] --out <dir>
/// ```
///
/// - l1: `compare.sh` 的输出, `<runs-dir>` 下每个子目录是一组运行, 内含各 suite 的 `<suite>.json`(schema 1);
///   产出对照 JSON、github-action-benchmark 输入与 Markdown 表。
/// - l3: `apps/benchmark/tool/device.sh` 的输出, `<runs-dir>` 下每个子目录是一次 drive, 内含 `env.json` 与
///   `frames.json`; 预算按实测刷新率计算, 产出 `device.json` 与 `device-summary.md`。
///
/// 只依赖 dart: 库, 不需要 pub get。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// 多组之间 best 的离散度超过它时, 对照表标记「不稳定」。
const _unstableSpread = 0.10;

void main(List<String> args) {
  if (args.isEmpty) _usage();
  final opts = _parseOptions(args.skip(1).toList());
  switch (args.first) {
    case 'l1':
      _l1(opts);
    case 'l3':
      _l3(opts);
    default:
      _usage();
  }
}

void _l1(Map<String, String> opts) {
  final targetDir = opts['target'] ?? _usage();
  final outDir = Directory(opts['out'] ?? _usage())
    ..createSync(recursive: true);
  final baselineDir = opts['baseline'];

  final target = _merge(targetDir);
  final baseline = baselineDir == null ? null : _merge(baselineDir);

  _writeJson('${outDir.path}/micro-target.json', target.toJson());
  if (baseline != null) {
    _writeJson('${outDir.path}/micro-baseline.json', baseline.toJson());
  }

  // github-action-benchmark 的 customSmallerIsBetter / customBiggerIsBetter 输入。
  _writeJson('${outDir.path}/gha.json', [
    for (final r in target.results.values)
      {
        'name': r.key,
        'unit': r.unit,
        'value': r.best,
        'range': '±${(r.spread * 100).toStringAsFixed(1)}%',
      },
  ]);
  if (baseline != null) {
    _writeJson('${outDir.path}/gha-speedup.json', [
      for (final r in target.results.values)
        if (baseline.results[r.key] case final b?)
          {'name': r.key, 'unit': 'x', 'value': _ratio(b.best, r.best)},
    ]);
  }

  final summary = _summary(target, baseline);
  File('${outDir.path}/summary.md').writeAsStringSync(summary);
  stdout.write(summary);
}

Never _usage() {
  stderr.writeln(
    'usage: summarize.dart l1 --target <runs-dir> [--baseline <runs-dir>] --out <dir>',
  );
  exit(64);
}

Map<String, String> _parseOptions(List<String> args) {
  final opts = <String, String>{};
  for (var i = 0; i + 1 < args.length; i += 2) {
    if (!args[i].startsWith('--')) _usage();
    opts[args[i].substring(2)] = args[i + 1];
  }
  return opts;
}

final class _Result {
  _Result(this.suite, this.name, this.unit, this.meta);

  final String suite;
  final String name;
  final String unit;
  final Object? meta;
  final bests = <double>[];

  String get key => '$suite/$name';
  double get best => bests.reduce(math.min);
  double get spread => (bests.reduce(math.max) - best) / best;
}

final class _Side {
  _Side(this.env, this.runs, this.results, this.skipped);

  final Map<String, Object?> env;
  final int runs;
  final Map<String, _Result> results;

  /// 某组里缺失的 suite(编译失败或测试失败)。
  final Set<String> skipped;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'env': env,
    'runs': runs,
    'skipped': skipped.toList()..sort(),
    'results': [
      for (final r in results.values)
        {
          'suite': r.suite,
          'name': r.name,
          'unit': r.unit,
          'best': r.best,
          'spread': double.parse(r.spread.toStringAsFixed(3)),
          'runs': r.bests,
          'meta': r.meta,
        },
    ],
  };
}

_Side _merge(String path) {
  final runDirs = Directory(path).listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (runDirs.isEmpty) {
    stderr.writeln('no runs under $path');
    exit(1);
  }
  final results = <String, _Result>{};
  final suites = <String>{};
  final seen = <Set<String>>[];
  Map<String, Object?> env = const {};
  for (final dir in runDirs) {
    final present = <String>{};
    for (final file in dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    )) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final suite = json['suite']! as String;
      present.add(suite);
      env = json['env']! as Map<String, Object?>;
      for (final r in (json['results']! as List).cast<Map<String, Object?>>()) {
        final name = r['name']! as String;
        results
            .putIfAbsent(
              '$suite/$name',
              () => _Result(suite, name, r['unit']! as String, r['meta']),
            )
            .bests
            .add((r['best']! as num).toDouble());
      }
    }
    suites.addAll(present);
    seen.add(present);
  }
  final skipped = {
    for (final suite in suites)
      if (seen.any((present) => !present.contains(suite))) suite,
  };
  return _Side(env, runDirs.length, results, skipped);
}

double _ratio(double baseline, double target) =>
    double.parse((baseline / target).toStringAsFixed(2));

String _summary(_Side target, _Side? baseline) {
  final b = StringBuffer();
  String env(_Side s) =>
      '`${s.env['version']}` (`${s.env['sha']}`), ${s.runs} runs';
  b.writeln('# L1 benchmark summary');
  b.writeln();
  b.writeln('- target: ${env(target)}');
  if (baseline != null) b.writeln('- baseline: ${env(baseline)}');
  b.writeln('- host: ${target.env['host']}, Flutter ${target.env['flutter']}');
  b.writeln(
    '- value: fastest round across runs; spread: (slowest − fastest) / fastest of the per-run bests',
  );
  b.writeln();
  if (baseline == null) {
    b.writeln('| scenario | unit | target | spread |');
    b.writeln('| --- | --- | ---: | ---: |');
    for (final r in target.results.values) {
      b.writeln('| ${r.key} | ${r.unit} | ${r.best} | ${_pct(r.spread)} |');
    }
  } else {
    b.writeln('| scenario | unit | baseline | target | speedup | note |');
    b.writeln('| --- | --- | ---: | ---: | ---: | --- |');
    final keys = {...baseline.results.keys, ...target.results.keys};
    for (final key in keys) {
      final t = target.results[key];
      final base = baseline.results[key];
      final unit = (t ?? base)!.unit;
      final note = [
        if (t == null) 'missing in target',
        if (base == null) 'missing in baseline',
        if ((t?.spread ?? 0) > _unstableSpread ||
            (base?.spread ?? 0) > _unstableSpread)
          'unstable',
      ].join(', ');
      final speedup = t != null && base != null
          ? '${_ratio(base.best, t.best)}x'
          : '-';
      b.writeln(
        '| $key | $unit | ${base?.best ?? '-'} | ${t?.best ?? '-'} | $speedup | $note |',
      );
    }
  }
  for (final (label, side) in [('target', target), ('baseline', baseline)]) {
    if (side != null && side.skipped.isNotEmpty) {
      b.writeln();
      b.writeln(
        'Suites missing from some $label runs: ${side.skipped.join(', ')}.',
      );
    }
  }
  return b.toString();
}

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

void _writeJson(String path, Object json) => File(
  path,
).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(json)}\n');

// ---------------------------------------------------------------------------
// L3: 真机帧时间

/// 一个场景合并全部窗口后的统计, 时间单位 us。
///
/// - `missed`: build 或 raster 任一超预算的帧占比;
/// - `worst`: 窗口内最慢一帧(build 与 raster 取大);
/// - `op_p50`: 单次操作耗时的中位数, 只有切换类场景有(含义见 frames_test.dart 各驱动);
/// - `rss`: 窗口结束时的进程常驻内存, MB。
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
        key: {
          'windows': value.windows,
          'frames': value.frames,
          ...value.metrics,
        },
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
          .where((d) => File('${d.path}/frames.json').existsSync())
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
    if (envFile.existsSync())
      env = jsonDecode(envFile.readAsStringSync()) as Map<String, Object?>;
    final trace = File('${dir.path}/trace.timeline_summary.json');
    if (trace.existsSync()) {
      final summary =
          jsonDecode(trace.readAsStringSync()) as Map<String, Object?>;
      final counts = gc.putIfAbsent(
        '${env['scenario']}',
        () => {'new_gen': [], 'old_gen': []},
      );
      counts['new_gen']!.add((summary['new_gen_gc_count']! as num).toDouble());
      counts['old_gen']!.add((summary['old_gen_gc_count']! as num).toDouble());
    }
    final json =
        jsonDecode(File('${dir.path}/frames.json').readAsStringSync())
            as Map<String, Object?>;
    final rate = (json['refreshRate']! as num).toDouble();
    rates.add(rate);
    final budget = 1e6 / rate;
    for (final MapEntry(:key, :value)
        in (json['scenarios']! as Map<String, Object?>).entries) {
      // trace 运行写的是 `windows: 0`, 没有帧数据。
      final raw = (value! as Map<String, Object?>)['windows'];
      for (final w
          in raw is List
              ? raw.cast<Map<String, Object?>>()
              : const <Map<String, Object?>>[]) {
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
        final m = perWindow.putIfAbsent(
          key,
          () => {for (final k in _deviceMetrics) k: <double>[]},
        );
        m['build_p50']!.add(_percentile(sortedBuild, 0.5));
        m['build_p90']!.add(_percentile(sortedBuild, 0.9));
        m['build_p99']!.add(_percentile(sortedBuild, 0.99));
        m['raster_p50']!.add(_percentile(sortedRaster, 0.5));
        m['raster_p90']!.add(_percentile(sortedRaster, 0.9));
        m['raster_p99']!.add(_percentile(sortedRaster, 0.99));
        m['missed']!.add(missed / build.length);
        m['worst']!.add(worst.toDouble());
        final ops = (w['ops'] as List?)?.cast<int>();
        if (ops != null && ops.isNotEmpty)
          m
              .putIfAbsent('op_p50', () => [])
              .add(_percentile([...ops]..sort(), 0.5));
        if (w['rss'] case final num rss)
          m.putIfAbsent('rss', () => []).add(rss / (1 << 20));
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
          for (final MapEntry(:key, :value) in value.entries)
            key: _median(value),
        }),
    },
    {
      for (final MapEntry(:key, :value) in gc.entries)
        key: {
          for (final MapEntry(:key, :value) in value.entries)
            key: _median(value),
        },
    },
  );
}

void _l3(Map<String, String> opts) {
  final target = _mergeDevice(opts['target'] ?? _usage());
  final baselineDir = opts['baseline'];
  final baseline = baselineDir == null ? null : _mergeDevice(baselineDir);
  final outDir = Directory(opts['out'] ?? _usage())
    ..createSync(recursive: true);

  _writeJson('${outDir.path}/device.json', {
    'target': target.toJson(),
    if (baseline != null) 'baseline': baseline.toJson(),
  });

  final b = StringBuffer();
  final env = target.env;
  String side(_DeviceSide s) =>
      '`${s.env['version']}` (`${s.env['sha']}`), ${s.runs} runs';
  b.writeln('# L3 device summary');
  b.writeln();
  b.writeln(
    '- device: ${env['device']} (${env['os']}), ${env['backend']}, '
    '${target.refreshRate.toStringAsFixed(0)}Hz, budget ${(target.budgetUs / 1000).toStringAsFixed(2)}ms',
  );
  b.writeln('- target: ${side(target)}');
  if (baseline != null) b.writeln('- baseline: ${side(baseline)}');
  b.writeln(
    '- Flutter ${env['flutter']}, profile build; values are medians over windows, in ms',
  );
  if (baseline != null &&
      (baseline.refreshRate - target.refreshRate).abs() >
          target.refreshRate * 0.05) {
    b.writeln(
      '- **warning**: baseline ran at ${baseline.refreshRate.toStringAsFixed(0)}Hz, not comparable',
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
    b.writeln(
      '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
    );
    for (final MapEntry(:key, value: s) in target.stats.entries) {
      final m = s.metrics;
      b.writeln(
        '| $key | ${ms(m['build_p90'])} | ${ms(m['build_p99'])} | ${ms(m['raster_p90'])} | '
        '${ms(m['raster_p99'])} | ${ms(m['worst'])} | ${pct(m['missed'])} | ${ms(m['op_p50'])} | '
        '${mb(m['rss'])} | ${s.frames} |',
      );
    }
  } else {
    b.writeln(
      '| scenario | build p90 | raster p90 | raster p99 | worst | over budget | op p50 | RSS MB |',
    );
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
      return g == null
          ? '-'
          : '${g['new_gen']!.toStringAsFixed(0)} / ${g['old_gen']!.toStringAsFixed(0)}';
    }

    for (final key in gcKeys) {
      b.writeln('| $key | ${gcOf(baseline, key)} | ${gcOf(target, key)} |');
    }
  }
  File('${outDir.path}/device-summary.md').writeAsStringSync(b.toString());
  stdout.write(b);
}
