import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

class _LineTestIndicator extends DirectIndicator {
  _LineTestIndicator()
      : super(
          key: const DirectIndicatorKey('line-test'),
          height: 100,
          padding: EdgeInsets.zero,
        );

  @override
  _LineTestPaintObject createPaintObject() => _LineTestPaintObject();
}

class _LineTestPaintObject extends DirectPaintObject<_LineTestIndicator>
    with PaintCandleChartMixin<_LineTestIndicator> {
  @override
  Rect get chartRect => const Rect.fromLTWH(0, 0, 100, 100);

  /// 复刻 [paintCandleLineChart] 内联的动态底边计算, 作为调用方契约。
  double boundDy(List<Offset> points) => points.fold<double>(
        chartRect.bottom,
        (bottom, point) => math.max(bottom, point.dy),
      );

  void drawFill(
    Canvas canvas,
    List<Offset> points, {
    required LinearGradient shader,
  }) {
    final dy = boundDy(points);
    paintLineChart(
      canvas,
      points: points,
      boundEnd: Offset(points.last.dx, dy),
      boundStart: Offset(points.first.dx, dy),
      linePaint: Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke,
      shader: shader,
    );
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTips(
    Canvas canvas, {
    FlexiCandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) =>
      null;
}

void main() {
  test('所有点在图内时闭合底边等于 chart bottom', () {
    final object = _LineTestPaintObject();
    expect(
      object.boundDy(const [Offset(0, 20), Offset(10, 80)]),
      100,
    );
  });

  test('存在越界点时闭合底边下移到最低点', () {
    final object = _LineTestPaintObject();
    expect(
      object.boundDy(const [
        Offset(0, 80),
        Offset(10, 120),
        Offset(20, 90),
      ]),
      120,
    );
  });

  test('普通线图渐变在折线与底边之间正常绘制', () async {
    final object = _LineTestPaintObject();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const points = [Offset(10, 40), Offset(90, 60)];

    object.drawFill(
      canvas,
      points,
      shader: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    // (x=20, y=80): 折线下方、底边上方的填充区, 渐变透明度应介于两端之间。
    const alphaIndex = (80 * 100 + 20) * 4 + 3;

    expect(bytes!.getUint8(alphaIndex), inInclusiveRange(1, 254));

    image.dispose();
    picture.dispose();
  });
}
