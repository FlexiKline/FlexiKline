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

/// L1 本机微基准的汇总。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'common.dart';

/// 多组之间 best 的离散度超过它时, 对照表标记「不稳定」。
const _unstableSpread = 0.10;

/// `summarize micro`: 合并 `compare.sh` 的多组 L1 运行, 产出对照 JSON、github-action-benchmark 输入与 Markdown 表。
void summarizeMicro(Map<String, String> opts) {
  final targetDir = opts['target'] ?? usage();
  final outDir = Directory(opts['out'] ?? usage())..createSync(recursive: true);
  final baselineDir = opts['baseline'];

  final target = _merge(targetDir);
  final baseline = baselineDir == null ? null : _merge(baselineDir);

  writeJson('${outDir.path}/micro-target.json', target.toJson());
  if (baseline != null) {
    writeJson('${outDir.path}/micro-baseline.json', baseline.toJson());
  }

  // github-action-benchmark 的 customSmallerIsBetter / customBiggerIsBetter 输入。
  writeJson('${outDir.path}/gha.json', [
    for (final r in target.results.values)
      {'name': r.key, 'unit': r.unit, 'value': r.best, 'range': '±${(r.spread * 100).toStringAsFixed(1)}%'},
  ]);
  if (baseline != null) {
    writeJson('${outDir.path}/gha-speedup.json', [
      for (final r in target.results.values)
        if (baseline.results[r.key] case final b?) {'name': r.key, 'unit': 'x', 'value': _ratio(b.best, r.best)},
    ]);
  }

  final summary = _summary(target, baseline);
  File('${outDir.path}/summary.md').writeAsStringSync(summary);
  stdout.write(summary);
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
  final runDirs = Directory(path).listSync().whereType<Directory>().toList()..sort((a, b) => a.path.compareTo(b.path));
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
    for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final suite = json['suite']! as String;
      present.add(suite);
      env = json['env']! as Map<String, Object?>;
      for (final r in (json['results']! as List).cast<Map<String, Object?>>()) {
        final name = r['name']! as String;
        results
            .putIfAbsent('$suite/$name', () => _Result(suite, name, r['unit']! as String, r['meta']))
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

double _ratio(double baseline, double target) => double.parse((baseline / target).toStringAsFixed(2));

String _summary(_Side target, _Side? baseline) {
  final b = StringBuffer();
  String env(_Side s) => '`${s.env['version']}` (`${s.env['sha']}`), ${s.runs} runs';
  b.writeln('# L1 benchmark summary');
  b.writeln();
  b.writeln('- target: ${env(target)}');
  if (baseline != null) b.writeln('- baseline: ${env(baseline)}');
  b.writeln('- host: ${target.env['host']}, Flutter ${target.env['flutter']}');
  b.writeln('- value: fastest round across runs; spread: (slowest − fastest) / fastest of the per-run bests');
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
        if ((t?.spread ?? 0) > _unstableSpread || (base?.spread ?? 0) > _unstableSpread) 'unstable',
      ].join(', ');
      final speedup = t != null && base != null ? '${_ratio(base.best, t.best)}x' : '-';
      b.writeln('| $key | $unit | ${base?.best ?? '-'} | ${t?.best ?? '-'} | $speedup | $note |');
    }
  }
  for (final (label, side) in [('target', target), ('baseline', baseline)]) {
    if (side != null && side.skipped.isNotEmpty) {
      b.writeln();
      b.writeln('Suites missing from some $label runs: ${side.skipped.join(', ')}.');
    }
  }
  return b.toString();
}

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
