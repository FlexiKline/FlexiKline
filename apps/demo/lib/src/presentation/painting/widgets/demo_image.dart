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

ui.Image _record(int size, void Function(Canvas canvas) draw) {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  return recorder.endRecording().toImageSync(size, size);
}
