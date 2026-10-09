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

/// painting 层依赖规则: 只能引用 `dart:*`、`package:flutter/*` 与本目录内的相对路径。
void main() {
  test('lib/src/painting 只依赖 dart:* / package:flutter/* / 同目录相对路径', () {
    final dir = Directory('lib/src/painting');
    expect(dir.existsSync(), isTrue, reason: 'flutter test 的 cwd 应为包根');

    final root = dir.absolute.uri;
    final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
    expect(files, isNotEmpty, reason: '空扫描会让规则假通过');

    final directive = RegExp(r'''^\s*(?:import|export|part)\s+'([^']+)'.*''');
    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final uri = directive.firstMatch(line)?.group(1);
        if (uri == null) continue;
        if (uri.startsWith('dart:') || uri.startsWith('package:flutter/')) continue;
        if (!uri.contains(':')) {
          final resolved = file.absolute.uri.resolve(uri);
          if (resolved.path.startsWith(root.path)) continue;
        }
        violations.add('${file.path}: $uri');
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
