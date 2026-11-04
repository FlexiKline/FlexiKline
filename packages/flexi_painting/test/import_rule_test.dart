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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(r'''^\s*(?:import|export|part)\s+'([^']+)'.*''');

/// [dir] 下所有 Dart 文件的 (文件, uri) 依赖; 目录不存在或为空时失败, 防止规则假通过。
List<(File, String)> _directives(String dir) {
  final root = Directory(dir);
  expect(root.existsSync(), isTrue, reason: 'flutter test 的 cwd 应为包根');
  final files = root.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  expect(files, isNotEmpty, reason: '空扫描会让规则假通过');
  return [
    for (final file in files)
      for (final line in file.readAsLinesSync())
        if (_directive.firstMatch(line)?.group(1) case final uri?) (file, uri),
  ];
}

/// [path] 相对 [root] 的第一级目录名; 直接位于 [root] 下的文件返回 null。
String? _layerOf(Uri root, Uri path) {
  final segments = path.path.substring(root.path.length).split('/');
  return segments.length > 1 ? segments.first : null;
}

/// `lib/src` 每层可依赖的下层; 同层引用不受限。
const _layers = {
  'foundation': <String>{},
  'geometry': <String>{},
  'borders': {'geometry'},
  'painters': {'foundation', 'geometry', 'borders'},
  'icons': {'foundation', 'geometry', 'painters'},
};

void main() {
  test('lib/src 只依赖 dart 与 flutter, 且各层只依赖下层', () {
    final root = Directory('lib/src').absolute.uri;
    final dirs = Directory.fromUri(root).listSync().whereType<Directory>().map((d) => _layerOf(root, d.uri)).toSet();
    expect(dirs, _layers.keys.toSet(), reason: '新增目录须在 _layers 中声明可依赖的层');

    final violations = <String>[];
    for (final (file, uri) in _directives('lib/src')) {
      if (uri.startsWith('dart:') || uri.startsWith('package:flutter/')) continue;
      final target = file.absolute.uri.resolve(uri);
      if (uri.contains(':') || !target.path.startsWith(root.path)) {
        violations.add('${file.path}: $uri 越出 lib/src');
        continue;
      }
      final from = _layerOf(root, file.absolute.uri);
      final to = _layerOf(root, target);
      if (from == null || from == to || (_layers[from]?.contains(to) ?? false)) continue;
      violations.add('${file.path}: $uri ($from 不能依赖 $to)');
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('入口只导出 lib/src', () {
    final uris = File(
      'lib/flexi_painting.dart',
    ).readAsLinesSync().map((line) => _directive.firstMatch(line)?.group(1)).whereType<String>().toList();
    expect(uris, isNotEmpty, reason: '空扫描会让规则假通过');
    expect(uris.where((uri) => !uri.startsWith('src/')), isEmpty);
  });

  test('test/ 只依赖本包与自身的测试替身', () {
    final root = Directory('test').absolute.uri;
    const allowed = ['dart:', 'package:flutter/', 'package:flutter_test/', 'package:flexi_painting/'];
    final violations = <String>[];
    for (final (file, uri) in _directives('test')) {
      if (allowed.any(uri.startsWith)) continue;
      if (!uri.contains(':') && file.absolute.uri.resolve(uri).path.startsWith(root.path)) continue;
      violations.add('${file.path}: $uri');
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
