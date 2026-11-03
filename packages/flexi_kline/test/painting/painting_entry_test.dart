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

import 'package:flexi_kline/painting.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Owner with PaintResourceOwner {
  late final label = own(LabelPainter());

  void dispose() => disposeResources();
}

void main() {
  test('painting.dart 单独提供绘制原语与资源登记', () {
    final owner = _Owner();
    expect(owner.label, isA<PaintResource>());
    expect(const BubbleBorder(), isA<ShapeBorder>());
    owner.dispose();
  });

  test('painting.dart 只导出 src/painting', () {
    final directive = RegExp(r'''^\s*export\s+'([^']+)'.*''');
    final exports = File(
      'lib/painting.dart',
    ).readAsLinesSync().map((line) => directive.firstMatch(line)?.group(1)).whereType<String>().toList();
    expect(exports, ['src/painting/export.dart']);
  });
}
