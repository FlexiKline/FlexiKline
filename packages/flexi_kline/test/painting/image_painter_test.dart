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

ShapeDecoration _rounded(double radius, {BorderSide side = BorderSide.none}) => ShapeDecoration(
  color: _red,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side),
);

/// 记录全部调用, 但在 drawImageRect 时抛出, 模拟图片绘制失败。
class _ThrowOnImageCanvas extends RecordingCanvas {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final result = super.noSuchMethod(invocation);
    if (invocation.memberName == #drawImageRect) throw StateError('drawImageRect failed');
    return result;
  }
}

void main() {
  // paintImage 在非 release 模式下访问 PaintingBinding / SchedulerBinding。
  TestWidgetsFlutterBinding.ensureInitialized();

  const arrowSize = Size(10, 6);
  const bubble = BubbleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    direction: AxisDirection.down,
    arrowSize: arrowSize,
  );
  const bubbleStyle = ImageStyle(
    size: Size(10, 10),
    padding: EdgeInsets.all(2),
    decoration: ShapeDecoration(color: _red, shape: bubble),
  );

  late ImagePainter painter;
  late RecordingCanvas canvas;
  late ui.Image image;

  List<Symbol> calls() => canvas.invocations.map((i) => i.memberName).toList();

  /// 从第一次 save 起的调用; 跳过装饰本身的绘制指令(填充、边框)。
  List<Symbol> afterDecoration() => calls().skipWhile((c) => c != #save).toList();

  Object? argOf(Symbol member) => canvas.invocations.singleWhere((i) => i.memberName == member).positionalArguments[0];

  setUp(() {
    painter = ImagePainter();
    canvas = RecordingCanvas();
    image = solidImage(4, 4);
  });

  tearDown(() {
    painter.dispose();
    image.dispose();
  });

  group('摆放', () {
    const style = ImageStyle(size: Size(10, 10), padding: EdgeInsets.all(2));

    test('body = size + padding, 落在 anchor 的对齐点上; 图片画进 padding 以内', () {
      final body = painter.paint(canvas, image, style: style, anchor: const Offset(50, 50), align: Alignment.center);
      expect(body, const Rect.fromLTWH(43, 43, 14, 14));
      expect(canvas.imageDstRects.single, style.padding.deflateRect(body));
    });

    test('九宫格对齐: body 的对齐点落在 anchor 上', () {
      const anchor = Offset(50, 50);
      for (final align in const [
        Alignment.topLeft,
        Alignment.topCenter,
        Alignment.topRight,
        Alignment.centerLeft,
        Alignment.center,
        Alignment.centerRight,
        Alignment.bottomLeft,
        Alignment.bottomCenter,
        Alignment.bottomRight,
      ]) {
        final body = painter.paint(canvas, image, style: style, anchor: anchor, align: align);
        expect(body.size, const Size(14, 14), reason: '$align');
        expect(align.withinRect(body), anchor, reason: '$align');
      }
    });

    test('bounds 夹取', () {
      final body = painter.paint(
        canvas,
        image,
        style: style,
        anchor: Offset.zero,
        align: Alignment.bottomRight,
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(body, const Rect.fromLTWH(0, 0, 14, 14));
    });

    test('BubbleBorder: body 不含箭头外延', () {
      const anchor = Offset(100, 100);
      final body = painter.paint(canvas, image, style: bubbleStyle, anchor: anchor, align: Alignment.bottomCenter);
      expect(body.size, const Size(14, 14));
      expect(body.bottom + arrowSize.height, anchor.dy);
      expect(body.center.dx, anchor.dx);
    });

    test('BubbleBorder: 外延参与 bounds 夹取', () {
      const bounds = Rect.fromLTWH(0, 0, 200, 100);
      final body = painter.paint(
        canvas,
        image,
        style: bubbleStyle,
        anchor: const Offset(100, 150),
        align: Alignment.bottomCenter,
        bounds: bounds,
      );
      expect(body.bottom + arrowSize.height, lessThanOrEqualTo(bounds.bottom));
      expect(canvas.pathBounds.first.bottom, lessThanOrEqualTo(bounds.bottom));
    });
  });

  group('裁切与指令序列', () {
    test('无 decoration: 只有 drawImageRect, 无 save / clip', () {
      painter.paint(
        canvas,
        image,
        style: const ImageStyle(size: Size(10, 10)),
        anchor: Offset.zero,
      );
      expect(calls(), [#drawImageRect]);
    });

    test('圆角大于 padding: save → clipRRect → drawImageRect → restore', () {
      final body = painter.paint(
        canvas,
        image,
        style: ImageStyle(size: const Size(20, 20), padding: const EdgeInsets.all(2), decoration: _rounded(8)),
        anchor: Offset.zero,
      );
      expect(calls(), [#drawRRect, #save, #clipRRect, #drawImageRect, #restore]);
      expect(argOf(#clipRRect), BorderRadius.circular(8).toRRect(body));
    });

    test('裁切后绘制抛异常: 仍 restore, save 栈平衡', () {
      final throwing = _ThrowOnImageCanvas();
      expect(
        () => painter.paint(
          throwing,
          image,
          style: ImageStyle(size: const Size(20, 20), padding: const EdgeInsets.all(2), decoration: _rounded(8)),
          anchor: Offset.zero,
        ),
        throwsStateError,
      );
      expect(throwing.invocations.map((i) => i.memberName).skipWhile((c) => c != #save).toList(), [
        #save,
        #clipRRect,
        #drawImageRect,
        #restore,
      ]);
    });

    test('padding 盖住圆角: 不裁切', () {
      painter.paint(
        canvas,
        image,
        style: ImageStyle(size: const Size(20, 20), padding: const EdgeInsets.all(4), decoration: _rounded(4)),
        anchor: Offset.zero,
      );
      expect(calls(), [#drawRRect, #drawImageRect]);
    });

    test('圆角 + 边框内收超过 padding: 按 getInnerPath 同一个 RRect 裁切', () {
      const side = BorderSide(width: 2); // 默认 inside, strokeInset = 2。
      final body = painter.paint(
        canvas,
        image,
        style: ImageStyle(
          size: const Size(20, 20),
          padding: const EdgeInsets.all(4),
          decoration: _rounded(4, side: side),
        ),
        anchor: Offset.zero,
      );
      expect(afterDecoration(), [#save, #clipRRect, #drawImageRect, #restore]);
      final expected = BorderRadius.circular(4).toRRect(body).deflate(2);
      expect(argOf(#clipRRect), expected);
      // 与 Flutter 自己的内轮廓一致。
      final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: side);
      expect(shape.getInnerPath(body).getBounds(), expected.outerRect);
    });

    test('圆角 + 边框内收被 padding 盖住: 不裁切', () {
      painter.paint(
        canvas,
        image,
        style: ImageStyle(
          size: const Size(20, 20),
          padding: const EdgeInsets.all(6),
          decoration: _rounded(4, side: const BorderSide(width: 2)),
        ),
        anchor: Offset.zero,
      );
      expect(calls(), isNot(contains(#save)));
      expect(calls(), isNot(contains(#clipRRect)));
      expect(calls().last, #drawImageRect);
    });

    test('某一个角未被盖住时仍裁切', () {
      painter.paint(
        canvas,
        image,
        style: const ImageStyle(
          size: Size(20, 20),
          padding: EdgeInsets.fromLTRB(4, 4, 4, 2),
          decoration: ShapeDecoration(
            color: _red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(4))),
          ),
        ),
        anchor: Offset.zero,
      );
      expect(afterDecoration(), [#save, #clipRRect, #drawImageRect, #restore]);
    });

    test('clip: false 不裁切', () {
      painter.paint(
        canvas,
        image,
        style: ImageStyle(
          size: const Size(20, 20),
          padding: const EdgeInsets.all(2),
          decoration: _rounded(8),
          clip: false,
        ),
        anchor: Offset.zero,
      );
      expect(calls(), [#drawRRect, #drawImageRect]);
    });

    test('BubbleBorder: clipPath 用对准后的内轮廓, 含箭头', () {
      const anchor = Offset(100, 100);
      painter.paint(canvas, image, style: bubbleStyle, anchor: anchor, align: Alignment.bottomCenter);
      expect(calls(), [#drawPath, #save, #clipPath, #drawImageRect, #restore]);
      final clip = argOf(#clipPath)! as Path;
      expect(clip.getBounds().bottom, anchor.dy);
      expect(clip.contains(anchor + const Offset(0, -0.5)), isTrue);
    });

    test('BubbleBorder 贴边夹取后: clipPath 与背景路径同一个已对准形状', () {
      final body = painter.paint(
        canvas,
        image,
        style: bubbleStyle,
        anchor: const Offset(2, 100),
        align: Alignment.bottomCenter,
        bounds: const Rect.fromLTWH(0, 0, 200, 200),
      );
      expect(body.left, 0);
      final clip = argOf(#clipPath)! as Path;
      expect(clip.getBounds(), canvas.pathBounds.single);
      // 箭头被夹进安全区, 不再指向 anchor.dx = 2。
      expect(clip.contains(Offset(2, body.bottom + arrowSize.height - 0.5)), isFalse);
    });

    test('style.size 为空: 不画图片, 装饰照画, 仍返回 body', () {
      final body = painter.paint(
        canvas,
        image,
        style: ImageStyle(size: Size.zero, padding: const EdgeInsets.all(4), decoration: _rounded(2)),
        anchor: Offset.zero,
      );
      expect(body, const Rect.fromLTWH(0, 0, 8, 8));
      expect(calls(), [#drawRRect]);
    });
  });

  group('图片绘制参数', () {
    test('fit: contain 按比例缩放并居中', () {
      final wide = solidImage(20, 10);
      painter.paint(
        canvas,
        wide,
        style: const ImageStyle(size: Size(10, 10), fit: BoxFit.contain),
        anchor: Offset.zero,
      );
      expect(canvas.imageDstRects.single, const Rect.fromLTWH(0, 2.5, 10, 5));
      wide.dispose();
    });

    test('默认 fill 拉伸铺满', () {
      final wide = solidImage(20, 10);
      painter.paint(
        canvas,
        wide,
        style: const ImageStyle(size: Size(10, 10)),
        anchor: Offset.zero,
      );
      expect(canvas.imageDstRects.single, Offset.zero & const Size(10, 10));
      wide.dispose();
    });

    test('opacity / filterQuality / colorFilter 透传, 开启抗锯齿', () {
      const filter = ColorFilter.mode(Color(0xFF00FF00), BlendMode.srcIn);
      painter.paint(
        canvas,
        image,
        style: const ImageStyle(
          size: Size(10, 10),
          opacity: 0.5,
          filterQuality: FilterQuality.low,
          colorFilter: filter,
        ),
        anchor: Offset.zero,
      );
      final paint = canvas.invocations.single.positionalArguments[3] as Paint;
      expect(paint.color.a, closeTo(0.5, 0.01));
      expect(paint.filterQuality, FilterQuality.low);
      expect(paint.isAntiAlias, isTrue);
      expect(paint.colorFilter, filter);
    });
  });

  group('BoxPainter 生命周期', () {
    test('同一 style 跨帧不重建; reset 释放后重建; dispose 释放', () {
      final decoration = ProbeDecoration();
      final style = ImageStyle(size: const Size(10, 10), decoration: decoration);
      painter.paint(canvas, image, style: style, anchor: Offset.zero);
      painter.paint(canvas, image, style: style, anchor: const Offset(30, 40));
      expect(decoration.counts.created, 1);

      painter.reset();
      expect(decoration.counts.disposed, 1);
      painter.paint(canvas, image, style: style, anchor: Offset.zero);
      expect(decoration.counts.created, 2);

      painter.dispose();
      expect(decoration.counts.disposed, 2);
    });
  });
}
