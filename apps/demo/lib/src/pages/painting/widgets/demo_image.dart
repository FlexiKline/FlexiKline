import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 四色棋盘, 便于看出裁切边缘。
ui.Image checkerImage() => _record(64, (canvas) {
  const colors = [Colors.orange, Colors.teal, Colors.indigo, Colors.pink];
  for (var i = 0; i < 4; i++) {
    for (var j = 0; j < 4; j++) {
      canvas.drawRect(Rect.fromLTWH(i * 16.0, j * 16.0, 16, 16), Paint()..color = colors[(i + j) % 4]);
    }
  }
});

/// 圆形图标, 用作行内 [ImageSpan]。
ui.Image dotImage(Color color) => _record(32, (canvas) {
  canvas.drawCircle(const Offset(16, 16), 14, Paint()..color = color);
});

/// 向右的三角箭头, 替代字符 '▸'(各平台字体里的字形大小与基线不一致)。
ui.Image arrowImage(Color color) => _record(32, (canvas) {
  final path = Path()
    ..moveTo(8, 4)
    ..lineTo(28, 16)
    ..lineTo(8, 28)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
});

ui.Image _record(int size, void Function(Canvas canvas) draw) {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  return recorder.endRecording().toImageSync(size, size);
}
