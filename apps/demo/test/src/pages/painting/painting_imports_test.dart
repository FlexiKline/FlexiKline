import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 「flexi_painting」页的示例与公共外壳只依赖 flexi_painting 与 Flutter, 证明这些能力脱离 K 线可用。
void main() {
  test('flexi_painting 页的文件不引用 flexi_kline、K 线配置与 K 线场景', () {
    const root = 'lib/src/pages/painting/widgets';
    final files = [
      ...Directory('$root/painting').listSync().whereType<File>(),
      File('$root/section.dart'),
      File('$root/demo_image.dart'),
    ];
    expect(files.length, greaterThan(3));

    // 只取 URI, 带 as / show / hide 的写法同样检查。
    final imports = RegExp(r"^(?:import|export)\s+'([^']+)'", multiLine: true);
    for (final file in files) {
      for (final match in imports.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        final allowed =
            uri.startsWith('dart:') ||
            uri.startsWith('package:flutter/') ||
            uri == 'package:flexi_painting/flexi_painting.dart' ||
            uri == '../section.dart' ||
            uri == '../demo_image.dart';
        expect(allowed, isTrue, reason: '${file.path} 引用了 $uri');
      }
    }
  });
}
