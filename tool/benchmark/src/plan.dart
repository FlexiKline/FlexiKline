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

/// `plan` 与 `device-info`: 设备清单解析与设备探测。
library;

import 'dart:convert';
import 'dart:io';

import 'common.dart';

/// 读 devices.conf, 与已连接设备求交, 每个组合输出一行 `<label> <id> <hz> <backend> <platform>`。
///
/// 有未连接的设备时退出, 不跑半套。
void plan(String conf) {
  final devices = connectedDevices();
  final rows = <({String label, String id, int hz, String backend, String kind})>[];
  final missing = <String>{};
  for (final (n, raw) in File(conf).readAsLinesSync().indexed) {
    final fields = raw.split('#').first.trim().split(RegExp(r'\s+'));
    if (fields.length == 1 && fields.first.isEmpty) continue;
    if (fields.length != 4) {
      stderr.writeln('$conf:${n + 1}: expected `<label> <device-id> <hz> <backend>`');
      exit(64);
    }
    final [label, id, hzText, backend] = fields;
    final hz = int.tryParse(hzText);
    if (hz == null) {
      stderr.writeln('$conf:${n + 1}: hz must be an integer, got `$hzText`');
      exit(64);
    }
    final device = devices[id];
    if (device == null) {
      missing.add('$label ($id)');
      continue;
    }
    rows.add((
      label: label,
      id: id,
      hz: hz,
      backend: backend,
      kind: platformKind(device),
    ));
  }
  if (missing.isNotEmpty) {
    stderr.writeln('not connected: ${(missing.toList()..sort()).join(', ')}');
    exit(1);
  }
  for (final r in rows) {
    stdout.writeln('${r.label} ${r.id} ${r.hz} ${r.backend} ${r.kind}');
  }
}

/// 输出 `<platform> <model> <os>`, 空格换成下划线; 型号不用用户自定义的设备名:
/// Android 用 getprop, iOS 用 devicectl 的 marketingName(读不到时记 iOS_device, 不回退到设备名)。
void deviceInfo(String id) {
  final device = connectedDevices()[id];
  if (device == null) {
    stderr.writeln('device $id not found in flutter devices');
    exit(1);
  }
  final kind = platformKind(device);
  String clean(String v) => v.trim().replaceAll(RegExp(r'\s+'), '_');
  final (model, os) = kind == 'ios'
      ? (_iosModel(id), device['sdk']! as String)
      : (
          run('adb', ['-s', id, 'shell', 'getprop', 'ro.product.model']),
          'Android ${run('adb', ['-s', id, 'shell', 'getprop', 'ro.build.version.release']).trim()}',
        );
  stdout.writeln('$kind ${clean(model)} ${clean(os)}');
}

String _iosModel(String udid) {
  final dir = Directory.systemTemp.createTempSync('bench-devicectl');
  try {
    final file = '${dir.path}/devices.json';
    final result = Process.runSync('xcrun', ['devicectl', 'list', 'devices', '--json-output', file]);
    if (result.exitCode != 0) return 'iOS device';
    final devices = (jsonDecode(File(file).readAsStringSync()) as Map)['result']['devices'] as List;
    for (final d in devices.cast<Map<String, Object?>>()) {
      final hardware = d['hardwareProperties'] as Map<String, Object?>? ?? const {};
      if (hardware['udid'] == udid) return hardware['marketingName'] as String? ?? 'iOS device';
    }
    return 'iOS device';
  } on Object {
    return 'iOS device';
  } finally {
    dir.deleteSync(recursive: true);
  }
}
