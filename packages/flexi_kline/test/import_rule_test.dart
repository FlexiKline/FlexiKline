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

/// `lib/` 下所有 Dart 文件, 可排除 [except] 目录; 为空时失败, 防止规则假通过。
List<File> _libFiles({String? except}) {
  final dir = Directory('lib');
  expect(dir.existsSync(), isTrue, reason: 'flutter test 的 cwd 应为包根');
  final skip = except == null ? null : Directory(except).absolute.path;
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && (skip == null || !f.absolute.path.startsWith(skip)))
      .toList();
  expect(files, isNotEmpty, reason: '空扫描会让规则假通过');
  return files;
}

/// 每个文件中匹配 [pattern] 的行, 格式为 `路径:行号: 内容`。
List<String> _matches(List<File> files, RegExp pattern) => [
  for (final file in files)
    for (final (i, line) in file.readAsLinesSync().indexed)
      if (pattern.hasMatch(line)) '${file.path}:${i + 1}: ${line.trim()}',
];

void main() {
  test('lib/ 只经公开入口引用 flexi_painting', () {
    final violations = _matches(_libFiles(), RegExp(r'''^\s*(?:import|export)\s+'package:flexi_painting/src/'''));
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('lib/ 在 extension/render 之外不调用 render 的文本与图片函数', () {
    final call = RegExp(r'\.(drawText|drawTextArea|drawImageText|drawImageView|drawTooltipInfos)\(');
    final violations = _matches(_libFiles(except: 'lib/src/extension/render'), call);
    expect(
      violations,
      isEmpty,
      reason: '每次调用都重新排版, 改用 LabelPainter / TooltipPainter / ImagePainter:\n${violations.join('\n')}',
    );
  });
}
