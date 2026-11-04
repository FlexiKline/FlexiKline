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

import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 按 [id] 判等, 每次绘制把尺寸与颜色记入 [log]。
final class _Probe extends IconShape {
  const _Probe(this.log, [this.id = 0]);

  final List<(Size, Color)> log;
  final int id;

  @override
  void paint(Canvas canvas, Size size, Color color) => log.add((size, color));

  @override
  bool operator ==(Object other) => other is _Probe && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: child),
);

void main() {
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);

  testWidgets('未指定尺寸与颜色时取 IconTheme, 并乘以 opacity', (tester) async {
    final log = <(Size, Color)>[];
    await tester.pumpWidget(
      _host(
        IconTheme(
          data: const IconThemeData(size: 30, color: red, opacity: 0.5),
          child: ShapeIcon(_Probe(log)),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ShapeIcon)), const Size(30, 30));
    expect(log, [(const Size(30, 30), red.withValues(alpha: 0.5))]);
  });

  testWidgets('size 与 color 覆盖 IconTheme', (tester) async {
    final log = <(Size, Color)>[];
    await tester.pumpWidget(
      _host(
        IconTheme(
          data: const IconThemeData(size: 30, color: red),
          child: ShapeIcon(_Probe(log), size: const Size(12, 8), color: blue),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ShapeIcon)), const Size(12, 8));
    expect(log, [(const Size(12, 8), blue)]);
  });

  testWidgets('shape 或 color 变化时重绘, 同值重建不重绘', (tester) async {
    final log = <(Size, Color)>[];
    Future<void> pump(int id, Color color) => tester.pumpWidget(_host(ShapeIcon(_Probe(log, id), color: color)));

    await pump(0, red);
    expect(log, hasLength(1));
    await pump(0, red);
    expect(log, hasLength(1), reason: '新实例但同值');
    await pump(0, blue);
    expect(log, hasLength(2), reason: '换色');
    await pump(1, blue);
    expect(log, hasLength(3), reason: '换形状');
  });

  testWidgets('semanticLabel 进入语义树', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const ShapeIcon(StarShape(), semanticLabel: 'star')));

    expect(find.bySemanticsLabel('star'), findsOneWidget);
    handle.dispose();
  });
}
