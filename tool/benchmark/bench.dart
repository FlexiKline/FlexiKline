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

/// benchmark 的数据处理入口: 汇总、设备清单、环境元数据; shell 脚本只做进程编排, 解析与统计都在这里。
///
/// 只依赖 dart: 库, 不需要 pub get: `fvm dart tool/benchmark/bench.dart <command>`, 用法见 [usageText]。
library;

import 'dart:convert';
import 'dart:io';

import 'src/common.dart';
import 'src/device.dart';
import 'src/micro.dart';
import 'src/plan.dart';

void main(List<String> args) {
  switch (args) {
    case ['summarize', 'micro', ...final rest]:
      summarizeMicro(parseOptions(rest));
    case ['summarize', 'device', ...final rest]:
      summarizeDevice(parseOptions(rest));
    case ['plan', final conf]:
      plan(conf);
    case ['device-info', final id]:
      deviceInfo(id);
    case ['flutter-version']:
      final out = run('fvm', ['flutter', '--version', '--machine']);
      final json = jsonDecode(out.substring(out.indexOf('{'))) as Map<String, Object?>;
      stdout.writeln(json['frameworkVersion']);
    case ['env', final out, ...final pairs]:
      writeJson(out, {for (final pair in pairs) ..._envField(pair)});
    default:
      usage();
  }
}

/// `key=value` 写成字符串, `key:=value` 写成数字: sha 这类全数字的字符串不能被猜成数字。
Map<String, Object> _envField(String pair) {
  final number = RegExp(r'^(\w+):=(.*)$').firstMatch(pair);
  if (number != null) return {number[1]!: num.parse(number[2]!)};
  final text = RegExp(r'^(\w+)=(.*)$').firstMatch(pair) ?? usage();
  return {text[1]!: text[2]!};
}
