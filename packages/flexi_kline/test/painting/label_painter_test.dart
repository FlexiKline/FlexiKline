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

import 'dart:ui' as ui;

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';
import 'painting_doubles.dart';

const _red = Color(0xFFFF0000);
const _rounded = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)));
const _bubble = BubbleBorder(borderRadius: BorderRadius.all(Radius.circular(4)), arrowSize: Size(10, 6));

/// 记录 == 调用次数的 TextStyle; 用来区分 identical 快路径与深比较。
class _CountingTextStyle extends TextStyle {
  const _CountingTextStyle(this.compares) : super(fontSize: 10);

  /// 只用第 0 个元素计数。
  final List<int> compares;

  @override
  bool operator ==(Object other) {
    compares[0]++;
    return super == other;
  }

  // hash_and_equals 要求与 == 成对覆写; 哈希语义不变。
  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;
}

void main() {
  const red = _red;
  const blue = Color(0xFF0000FF);
  const rounded = _rounded;
  const arrowSize = Size(10, 6);

  // FlutterTest 字体: 每个字形宽高都等于字号。
  const style = LabelStyle(
    text: TextStyle(fontSize: 10),
    padding: EdgeInsets.all(4),
    decoration: ShapeDecoration(color: red, shape: rounded),
  );
  const bubbleStyle = LabelStyle(
    text: TextStyle(fontSize: 10),
    padding: EdgeInsets.all(4),
    decoration: ShapeDecoration(
      color: red,
      shape: BubbleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        direction: AxisDirection.down,
        arrowSize: arrowSize,
      ),
    ),
  );

  late LabelPainter label;
  late RecordingCanvas canvas;
  var builds = 0;

  Object Function() counted(Object content) => () {
    builds++;
    return content;
  };

  List<Symbol> calls() => canvas.invocations.map((i) => i.memberName).toList();

  setUp(() {
    label = LabelPainter();
    canvas = RecordingCanvas();
    builds = 0;
  });

  tearDown(() => label.dispose());

  group('摆放', () {
    test('body = 文本尺寸 + padding, 落在 anchor 的对齐点上', () {
      final body = label.paint(canvas, 'abc', style: style, anchor: const Offset(10, 20));
      expect(body, const Rect.fromLTWH(10, 20, 38, 18));
      expect(canvas.paragraphOffsets.single, const Offset(14, 24));
    });

    test('带 BubbleBorder 时 body 不含箭头外延', () {
      const anchor = Offset(100, 100);
      final body = label.paint(canvas, 'abc', style: bubbleStyle, anchor: anchor, align: Alignment.bottomCenter);
      expect(body.size, const Size(38, 18));
      expect(body.bottom + arrowSize.height, anchor.dy);
      expect(body.center.dx, anchor.dx);
      // 箭头路径伸到 anchor。
      expect(canvas.pathBounds.single.bottom, anchor.dy);
    });

    test('带 BubbleBorder 时外延参与 bounds 夹取', () {
      const bounds = Rect.fromLTWH(0, 0, 200, 100);
      final body = label.paint(
        canvas,
        'abc',
        style: bubbleStyle,
        anchor: const Offset(100, 150),
        align: Alignment.bottomCenter,
        bounds: bounds,
      );
      expect(body.bottom + arrowSize.height, lessThanOrEqualTo(bounds.bottom));
      expect(canvas.pathBounds.single.bottom, lessThanOrEqualTo(bounds.bottom));
    });

    test('bounds 限制可用宽度', () {
      const bounds = Rect.fromLTWH(0, 0, 40, 100);
      final body = label.paint(canvas, 'abcdefghij', style: style, anchor: Offset.zero, bounds: bounds);
      expect(body.width, lessThanOrEqualTo(bounds.width));
    });

    test('minWidth 撑开容器(含 padding)', () {
      final body = label.paint(canvas, 'a', style: style, anchor: Offset.zero, minWidth: 100);
      expect(body.width, 100);
    });
  });

  group('缓存', () {
    test('同一 style 实例连续 paint 走快路径, 不重复 build', () {
      label.paint(canvas, 'k', build: counted('abc'), style: style, anchor: Offset.zero);
      label.paint(canvas, 'k', build: counted('abc'), style: style, anchor: Offset.zero);
      expect(builds, 1);
    });

    test('只换背景色时不 build, 装饰已更新', () {
      label.paint(canvas, 'k', build: counted('abc'), style: style, anchor: Offset.zero);
      final recolored = style.copyWith(
        decoration: const ShapeDecoration(color: blue, shape: rounded),
      );
      canvas.clear();
      label.paint(canvas, 'k', build: counted('abc'), style: recolored, anchor: Offset.zero);
      expect(builds, 1);
      final paint = canvas.invocations.firstWhere((i) => i.memberName == #drawRRect).positionalArguments[1] as Paint;
      expect(paint.color, blue);
    });

    test('排版字段变化时重新 build', () {
      label.paint(canvas, 'k', build: counted('abc'), style: style, anchor: Offset.zero);
      final bigger = style.copyWith(text: const TextStyle(fontSize: 12));
      final body = label.paint(canvas, 'k', build: counted('abc'), style: bigger, anchor: Offset.zero);
      expect(builds, 2);
      expect(body.size, const Size(36 + 8, 12 + 8));
    });

    test('AnchoredBorder 锚点变化时箭头跟随', () {
      label.paint(canvas, 'abc', style: bubbleStyle, anchor: const Offset(100, 100), align: Alignment.bottomCenter);
      label.paint(canvas, 'abc', style: bubbleStyle, anchor: const Offset(150, 80), align: Alignment.bottomCenter);
      final [first, second] = canvas.pathBounds;
      expect(first.bottom, 100);
      expect(second.bottom, 80);
      expect(second.center.dx - first.center.dx, 50);
    });

    test('值相等的新实例替换旧实例: 不清排版缓存、不重建装饰, 之后走 identical 快路径', () {
      final compares = [0];
      final decoration = ProbeDecoration();
      LabelStyle make() =>
          LabelStyle(text: _CountingTextStyle(compares), padding: const EdgeInsets.all(4), decoration: decoration);
      final a = make();
      final b = make();
      expect(identical(a, b), isFalse);
      expect(a, b);

      label.paint(canvas, 'k', build: counted('abc'), style: a, anchor: Offset.zero);
      label.paint(canvas, 'k', build: counted('abc'), style: b, anchor: Offset.zero);
      expect(builds, 1);
      expect(decoration.counts.created, 1);
      expect(decoration.counts.disposed, 0);

      // b 已成为当前实例: 继续传 b 不再深比较。
      compares[0] = 0;
      for (var i = 0; i < 3; i++) {
        label.paint(canvas, 'k', build: counted('abc'), style: b, anchor: Offset.zero);
      }
      expect(compares[0], 0);
      expect(builds, 1);
      expect(decoration.counts.created, 1);
    });

    test('标签整体平移且未被夹取时 BoxPainter 复用, 不再 anchorTo, 箭头跟着平移', () {
      final probe = ProbeBorder();
      final probed = LabelStyle(
        text: const TextStyle(fontSize: 10),
        padding: const EdgeInsets.all(4),
        decoration: ShapeDecoration(color: red, shape: probe),
      );
      label.paint(canvas, 'abc', style: probed, anchor: const Offset(100, 100), align: Alignment.bottomCenter);
      label.paint(canvas, 'abc', style: probed, anchor: const Offset(150, 80), align: Alignment.bottomCenter);
      // body 38 x 18, 箭头高 6: anchor 相对 body 左上角恒为 (19, 24)。
      expect(probe.anchors, [const Offset(19, 24)]);
      final [first, second] = canvas.pathBounds;
      expect(second, first.shift(const Offset(50, -20)));
    });

    test('贴边夹取后重新 anchorTo, 箭头夹在安全区内', () {
      final probe = ProbeBorder();
      final probed = LabelStyle(
        text: const TextStyle(fontSize: 10),
        padding: const EdgeInsets.all(4),
        decoration: ShapeDecoration(color: red, shape: probe),
      );
      const bounds = Rect.fromLTWH(0, 0, 200, 100);
      label.paint(canvas, 'abc', style: probed, anchor: const Offset(100, 50), align: Alignment.bottomCenter);
      final body = label.paint(
        canvas,
        'abc',
        style: probed,
        anchor: const Offset(2, 50),
        align: Alignment.bottomCenter,
        bounds: bounds,
      );
      expect(body.left, bounds.left);
      expect(probe.anchors, [const Offset(19, 24), const Offset(2, 24)]);

      final path = canvas.invocations.lastWhere((i) => i.memberName == #drawPath).positionalArguments[0] as Path;
      const safe = 4 + 5.0; // 圆角 + 半个根宽
      expect(path.contains(Offset(body.left + safe, body.bottom + arrowSize.height - 0.5)), isTrue);
      expect(path.contains(Offset(2, body.bottom + arrowSize.height - 0.5)), isFalse);
    });

    test('阴影的箭头随阴影一起偏移', () {
      const shift = Offset(3, 2);
      const shadowed = LabelStyle(
        text: TextStyle(fontSize: 10),
        padding: EdgeInsets.all(4),
        decoration: ShapeDecoration(
          color: red,
          shadows: [BoxShadow(offset: shift)],
          shape: _bubble,
        ),
      );
      const anchor = Offset(100, 100);
      label.paint(canvas, 'abc', style: shadowed, anchor: anchor, align: Alignment.bottomCenter);
      final [shadow, fill] = [
        for (final i in canvas.invocations.where((i) => i.memberName == #drawPath)) i.positionalArguments[0] as Path,
      ];
      const nearTip = Offset(0, -0.5);
      expect(fill.contains(anchor + nearTip), isTrue);
      expect(shadow.contains(anchor + shift + nearTip), isTrue);
      expect(shadow.contains(anchor + nearTip), isFalse);
    });

    test('reset 释放 BoxPainter, 之后同 key 重新 build 并重建装饰', () {
      final decoration = ProbeDecoration();
      final probed = LabelStyle(text: const TextStyle(fontSize: 10), decoration: decoration);
      label.paint(canvas, 'k', build: counted('abc'), style: probed, anchor: Offset.zero);
      label.reset();
      expect(decoration.counts.disposed, 1);
      label.paint(canvas, 'k', build: counted('abc'), style: probed, anchor: Offset.zero);
      expect(builds, 2);
      expect(decoration.counts.created, 2);
    });

    test('dispose 释放 TextPainter 的段落与装饰的 BoxPainter', () {
      // TextPainter 本身的释放由 TextLayoutCache 的 debugDisposed 用例覆盖; 这里经段落间接观测。
      final decoration = ProbeDecoration();
      final probed = LabelStyle(text: const TextStyle(fontSize: 10), decoration: decoration);
      final local = LabelPainter(capacity: 2);
      local.paint(canvas, 'a', style: probed, anchor: Offset.zero);
      local.paint(canvas, 'b', style: probed, anchor: Offset.zero);
      final paragraphs = [
        for (final i in canvas.invocations.where((i) => i.memberName == #drawParagraph))
          i.positionalArguments[0] as ui.Paragraph,
      ];
      expect(paragraphs, hasLength(2));
      expect(paragraphs.any((p) => p.debugDisposed), isFalse);

      local.dispose();
      expect(paragraphs.every((p) => p.debugDisposed), isTrue);
      expect(decoration.counts.created, 1);
      expect(decoration.counts.disposed, 1);
    });
  });

  group('绘制指令序列', () {
    test('纯色圆角矩形: drawRRect + drawParagraph', () {
      final body = label.paint(canvas, 'abc', style: style, anchor: Offset.zero);
      expect(calls(), [#drawRRect, #drawParagraph]);
      expect(canvas.rrectBounds.single, body);
    });

    test('无装饰: 只有 drawParagraph', () {
      label.paint(
        canvas,
        'abc',
        style: const LabelStyle(text: TextStyle(fontSize: 10)),
        anchor: Offset.zero,
      );
      expect(calls(), [#drawParagraph]);
    });

    test('带图片: drawRRect + drawParagraph + drawImageRect, 目标框尺寸等于 ImageSpan.size', () {
      final image = solidImage(4, 4);
      const size = Size(12, 12);
      final body = label.paint(
        canvas,
        'img',
        build: () => TextSpan(
          children: [
            ImageSpan(image, size),
            const TextSpan(text: 'ab'),
          ],
        ),
        style: style,
        anchor: const Offset(10, 10),
      );
      expect(calls(), [#drawRRect, #drawParagraph, #drawImageRect]);
      final dst = canvas.imageDstRects.single;
      expect(dst.size, size);
      expect(dst.topLeft.dx, body.left + 4);
      expect(body.deflate(4).contains(dst.center), isTrue);
      image.dispose();
    });

    test('截断掉 ImageSpan 后占位框少于 span: 不越界, 只画剩下的', () {
      final image = solidImage(4, 4);
      const size = Size(10, 10);
      const truncated = LabelStyle(text: TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis), maxLines: 1);
      label.paint(
        canvas,
        'img',
        build: () => TextSpan(
          children: [
            ImageSpan(image, size),
            const TextSpan(text: 'abcdefghij'),
            ImageSpan(image, size),
          ],
        ),
        style: truncated,
        anchor: Offset.zero,
        bounds: const Rect.fromLTWH(0, 0, 50, 100),
      );
      expect(calls(), [#drawParagraph, #drawImageRect]);
      expect(canvas.imageDstRects.single, Offset.zero & size);
      image.dispose();
    });
  });
}
