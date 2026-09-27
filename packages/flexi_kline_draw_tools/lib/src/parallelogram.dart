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

import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';

import 'draw_param.dart';
import 'draw_tools_config.dart';

/// 平行四边形绘图对象（3 点，第 4 点自动推算）。
///
/// 用户依次点 A、B、C，第四点 D = A + C - B，
/// 构成平行四边形 A→B→C→D（AB ∥ DC，AD ∥ BC）。
class ParallelogramDrawObject extends DrawObject {
  ParallelogramDrawObject(super.overlay, super.config);

  static ParallelogramDrawParam get drawParam => DrawToolsConfig.instance.parallelogram;

  /// 从三个锚点推算四个顶点 [A, B, C, D]。
  List<Offset>? getVertices() {
    final pts = allPoints;
    final a = pts.firstOrNull?.offset;
    final b = pts.secondOrNull?.offset;
    final c = pts.thirdOrNull?.offset;
    if (a == null || b == null || c == null) return null;
    final d = a + c - b;
    return [a, b, c, d];
  }

  @override
  Rect? getTicksMarksBounds() {
    final verts = getVertices();
    if (verts == null) return null;
    var rect = Rect.fromPoints(verts[0], verts[1]);
    for (int i = 2; i < verts.length; i++) {
      rect = rect.expandToInclude(Rect.fromPoints(verts[0], verts[i]));
    }
    return rect;
  }

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();
    final verts = getVertices();
    if (verts == null) return false;
    return isInsideOfPolygon(position, verts);
  }

  @override
  void drawing(DrawContext context, Canvas canvas, Size size) {
    if (isReady) {
      final verts = getVertices();
      if (verts == null) return;
      _drawParallelogram(canvas, verts);
    }
    drawConnectingLine(context, canvas, size);
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();
    final verts = getVertices();
    if (verts == null) return;
    _drawParallelogram(canvas, verts);
  }

  void _drawParallelogram(Canvas canvas, List<Offset> verts) {
    final path = Path()..addPolygon(verts, true);

    // 填充背景
    canvas.drawPath(
      path,
      line.linePaint
        ..color = line.paint.color?.withAlpha(drawParam.bgOpacity.alpha) ?? transparent
        ..style = PaintingStyle.fill,
    );

    // 画四条边
    canvas.drawLineByConfig(path, line);
  }
}
