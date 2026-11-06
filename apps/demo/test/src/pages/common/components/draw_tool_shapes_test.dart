import 'dart:ui' as ui;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/pages/common/components/draw_tool_shapes.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart' show drawObjectBuilders;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// [shape] 在 24x24 白底上的像素。
Future<List<int>> _pixels(IconShape shape) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(const Color(0xFFFFFFFF), BlendMode.src);
  shape.paint(canvas, const Size(24, 24), const Color(0xFF000000));
  final image = await recorder.endRecording().toImage(24, 24);
  final data = await image.toByteData();
  image.dispose();
  return data!.buffer.asUint8List();
}

bool _same(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 逐个绘制 [shapes], 断言两两像素不同。
Future<void> _expectDistinct(Iterable<IconShape> shapes) async {
  final seen = <List<int>>[];
  for (final shape in shapes) {
    final pixels = await _pixels(shape);
    expect(seen.any((other) => _same(other, pixels)), isFalse, reason: '$shape 与已有图标重复');
    seen.add(pixels);
  }
}

void main() {
  test('每个内置绘图工具都有图标, 且两两不同', () async {
    expect(drawToolShapes.keys.toSet(), drawObjectBuilders.keys.toSet());
    await _expectDistinct(drawToolShapes.values);
  });

  test('磁铁强弱、线宽、线型各自互不相同', () async {
    await _expectDistinct([const MagnetShape(), const MagnetShape(strong: true)]);
    await _expectDistinct([
      for (final width in const [1.0, 2.0, 3.0, 4.0]) LineWeightShape(width),
    ]);
    await _expectDistinct([for (final type in LineType.values) LineTypeShape(type)]);
  });

  test('同类图形相等, 类型或参数不同则不等', () {
    expect(const TrendLineShape(), const TrendLineShape());
    expect(const TrendLineShape(), isNot(const RayLineShape()));
    expect(const MagnetShape(), isNot(const MagnetShape(strong: true)));
    expect(const LineWeightShape(2), const LineWeightShape(2));
    expect(const LineWeightShape(2), isNot(const LineWeightShape(3)));
    expect(const LineTypeShape(LineType.dashed), isNot(const LineTypeShape(LineType.dotted)));
  });
}
