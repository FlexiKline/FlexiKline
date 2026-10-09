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

/// painting 测试共用的替身; 阶段 1 不改 test/support, 暂放本目录。
library;

import 'dart:ui' as ui;

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';

/// 同步现画一张 [width] x [height] 的图片; 调用方负责 dispose。
ui.Image solidImage(int width, int height) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint());
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

const _bubble = BubbleBorder(borderRadius: BorderRadius.all(Radius.circular(4)), arrowSize: Size(10, 6));

/// 记录 anchorTo 收到的锚点, 其余委托给圆角 4、箭头 10x6 的 [BubbleBorder]; 用来观测装饰是否重建。
final class ProbeBorder extends AnchoredBorder {
  ProbeBorder();

  final List<Offset> anchors = <Offset>[];

  @override
  EdgeInsets get outsets => _bubble.outsets;

  @override
  ShapeBorder anchorTo(Offset anchor) {
    anchors.add(anchor);
    return _bubble.anchorTo(anchor);
  }

  @override
  EdgeInsetsGeometry get dimensions => _bubble.dimensions;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _bubble.getInnerPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _bubble.getOuterPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) => _bubble.paint(canvas, rect);

  @override
  ShapeBorder scale(double t) => _bubble.scale(t);
}

/// BoxPainter 创建与释放次数; ShapeDecoration 是 @immutable, 计数放在独立对象里。
final class BoxCounts {
  int created = 0;
  int disposed = 0;
}

/// 圆角 4 的纯色 ShapeDecoration, 记录 createBoxPainter 与 BoxPainter.dispose, 绘制委托给父类。
class ProbeDecoration extends ShapeDecoration {
  ProbeDecoration({Color color = const Color(0xFFFF0000)})
    : super(
        color: color,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      );

  final BoxCounts counts = BoxCounts();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    counts.created++;
    return _ProbeBoxPainter(counts, super.createBoxPainter(onChanged));
  }
}

class _ProbeBoxPainter extends BoxPainter {
  _ProbeBoxPainter(this.counts, this.inner);

  final BoxCounts counts;
  final BoxPainter inner;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) =>
      inner.paint(canvas, offset, configuration);

  @override
  void dispose() {
    counts.disposed++;
    inner.dispose();
    super.dispose();
  }
}
