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

/// 各子命令共用的参数解析、输出与外部进程调用。
library;

import 'dart:convert';
import 'dart:io';

const usageText = '''
usage: bench.dart <command> [args]

  summarize micro  --target <runs-dir> [--baseline <runs-dir>] --out <dir>
  summarize device --target <runs-dir> [--baseline <runs-dir>] --out <dir>
  plan <devices.conf>            print `<phase> <label> <id> <hz> <backend> <platform>` per connected combo
  device-info <device-id>        print `<platform> <model> <os>`
  flutter-version                print the Flutter framework version
  env <out.json> <key=value | key:=number>...  write a flat JSON object
''';

Never usage() {
  stderr.write(usageText);
  exit(64);
}

/// `--key value` 成对的选项。
Map<String, String> parseOptions(List<String> args) {
  final opts = <String, String>{};
  for (var i = 0; i < args.length; i += 2) {
    if (!args[i].startsWith('--') || i + 1 >= args.length) usage();
    opts[args[i].substring(2)] = args[i + 1];
  }
  return opts;
}

void writeJson(String path, Object json) {
  return File(path).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(json)}\n');
}

/// 运行外部命令并返回 stdout; 失败时带 stderr 退出。
String run(String executable, List<String> args) {
  final result = Process.runSync(executable, args);
  if (result.exitCode != 0) {
    stderr.writeln('$executable ${args.join(' ')} failed:\n${result.stderr}');
    exit(1);
  }
  return result.stdout as String;
}

/// `flutter devices --machine` 的结果: 设备 id → 设备信息。
Map<String, Map<String, Object?>> connectedDevices() {
  final out = run('fvm', ['flutter', 'devices', '--machine']);
  // flutter 可能在 JSON 前打印提示行。
  final json = jsonDecode(out.substring(out.indexOf('['))) as List;
  return {for (final d in json.cast<Map<String, Object?>>()) d['id']! as String: d};
}

/// 设备平台归类: `ios` 或 `android`; 其他平台(macOS、Web、模拟器以外的桌面设备)不做真机采集, 直接退出。
String platformKind(Map<String, Object?> device) {
  final platform = device['targetPlatform'] as String? ?? '';
  if (platform == 'ios') return 'ios';
  if (platform.startsWith('android')) return 'android';
  stderr.writeln('unsupported device ${device['id']} ($platform): only iOS and Android devices are benchmarked');
  exit(64);
}
