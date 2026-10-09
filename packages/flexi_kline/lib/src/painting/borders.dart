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

import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// 外延在 body 之外、且依赖锚点的形状(带箭头的气泡、单侧收口的价格标签等)。
///
/// 宿主实现它即可接入 LabelPainter 的摆放与夹取, 不需要改框架。
abstract class AnchoredBorder extends ShapeBorder {
  const AnchoredBorder();

  /// 形状在 body 之外占的空间, 参与摆放与边界夹取。
  EdgeInsets get outsets;

  /// 返回对准 [anchor] 的形状; [anchor] 相对 body(即 getOuterPath 收到的 rect)的左上角。
  ///
  /// body 被夹取平移后锚点可能落在可放置区间外, 实现须自己把箭头夹进去。
  /// 路径必须按 rect 相对计算, 这样阴影平移 rect 时箭头跟着平移。
  ShapeBorder anchorTo(Offset anchor);
}

/// 带箭头的圆角矩形。路径一次成型, 不用 Path.combine(union): union 的接缝会被描边画出来。
///
/// 传给 [getOuterPath] / [paint] 的 rect 是 body(不含箭头), 箭头画在 body 之外 [outsets] 的位置。
/// 描边按 [BorderSide.strokeAlign] 把 body 与圆角整体内缩或外扩; 箭头根宽与高度不随之调整,
/// 粗边框下尖端处的描边是近似的。
final class BubbleBorder extends AnchoredBorder {
  const BubbleBorder({
    this.side = BorderSide.none,
    this.borderRadius = BorderRadius.zero,
    this.direction = AxisDirection.down,
    this.arrowSize = const Size(10, 6),
    this.arrow,
  });

  final BorderSide side;
  final BorderRadius borderRadius;

  /// 箭头所在的边: up 上边、right 右边、down 下边、left 左边。
  final AxisDirection direction;

  /// 箭头根宽与伸出高度。
  final Size arrowSize;

  /// 箭头尖端要对准的点, 相对 rect 左上角; null 对准所在边的中点。
  ///
  /// 用相对坐标: 阴影以 rect.shift(offset) 调 getOuterPath 时箭头随之偏移;
  /// 标签整体平移而未被夹取时它不变, BoxPainter 可以跨帧复用。
  final Offset? arrow;

  @override
  EdgeInsets get outsets => switch (direction) {
    AxisDirection.up => EdgeInsets.only(top: arrowSize.height),
    AxisDirection.down => EdgeInsets.only(bottom: arrowSize.height),
    AxisDirection.left => EdgeInsets.only(left: arrowSize.height),
    AxisDirection.right => EdgeInsets.only(right: arrowSize.height),
  };

  @override
  BubbleBorder anchorTo(Offset anchor) =>
      BubbleBorder(side: side, borderRadius: borderRadius, direction: direction, arrowSize: arrowSize, arrow: anchor);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(math.max(side.strokeInset, 0));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect, 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect, -side.strokeInset);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    // 描边中心线落在 strokeAlign 对应的位置(默认 inside: 内缩半个线宽)。
    canvas.drawPath(_path(rect, side.strokeOffset / 2), side.toPaint());
  }

  @override
  BubbleBorder scale(double t) => BubbleBorder(
    side: side.scale(t),
    borderRadius: borderRadius * t,
    direction: direction,
    arrowSize: arrowSize * t,
    // 相对 rect 的长度, 与 rect 一同缩放。
    arrow: arrow == null ? null : arrow! * t,
  );

  /// 从左上角顺时针走一圈, 在 [direction] 对应的边上插入箭头。
  ///
  /// [delta] 把 rect 外扩(正)或内缩(负), 圆角半径同步增减并夹到不小于 0; [arrow] 始终相对未缩放的 [rect],
  /// 所以内外两条路径的箭头对准同一点。
  Path _path(Rect rect, double delta) {
    final b = rect.inflate(delta);
    Radius grow(Radius r) => Radius.elliptical(math.max(0, r.x + delta), math.max(0, r.y + delta));
    final tl = grow(borderRadius.topLeft);
    final tr = grow(borderRadius.topRight);
    final br = grow(borderRadius.bottomRight);
    final bl = grow(borderRadius.bottomLeft);
    final h = arrowSize.height;
    final target = arrow == null ? null : rect.topLeft + arrow!;

    // 箭头在直边 [start, end](两侧圆角之间)上的中心与半个根宽。中心夹到「圆角之外 + 半个根宽」的安全区;
    // 直边放不下根宽时根宽收缩到直边长度、中心取直边中点, 路径不越过圆角端点(否则描边会画出折返毛刺);
    // 直边长度 ≤ 0 时不画箭头, outsets 照旧保留。
    ({double center, double half})? place(double? value, double start, double end, double mid) {
      final length = end - start;
      if (length <= 0) return null;
      if (length < arrowSize.width) return (center: (start + end) / 2, half: length / 2);
      final half = arrowSize.width / 2;
      return (center: (value ?? mid).clamp(start + half, end - half).toDouble(), half: half);
    }

    final path = Path()..moveTo(b.left + tl.x, b.top);

    if (direction == AxisDirection.up) {
      if (place(target?.dx, b.left + tl.x, b.right - tr.x, b.center.dx) case (:final center, :final half)) {
        path
          ..lineTo(center - half, b.top)
          ..lineTo(center, b.top - h)
          ..lineTo(center + half, b.top);
      }
    }
    path
      ..lineTo(b.right - tr.x, b.top)
      ..arcToPoint(Offset(b.right, b.top + tr.y), radius: tr);

    if (direction == AxisDirection.right) {
      if (place(target?.dy, b.top + tr.y, b.bottom - br.y, b.center.dy) case (:final center, :final half)) {
        path
          ..lineTo(b.right, center - half)
          ..lineTo(b.right + h, center)
          ..lineTo(b.right, center + half);
      }
    }
    path
      ..lineTo(b.right, b.bottom - br.y)
      ..arcToPoint(Offset(b.right - br.x, b.bottom), radius: br);

    if (direction == AxisDirection.down) {
      if (place(target?.dx, b.left + bl.x, b.right - br.x, b.center.dx) case (:final center, :final half)) {
        path
          ..lineTo(center + half, b.bottom)
          ..lineTo(center, b.bottom + h)
          ..lineTo(center - half, b.bottom);
      }
    }
    path
      ..lineTo(b.left + bl.x, b.bottom)
      ..arcToPoint(Offset(b.left, b.bottom - bl.y), radius: bl);

    if (direction == AxisDirection.left) {
      if (place(target?.dy, b.top + tl.y, b.bottom - bl.y, b.center.dy) case (:final center, :final half)) {
        path
          ..lineTo(b.left, center + half)
          ..lineTo(b.left - h, center)
          ..lineTo(b.left, center - half);
      }
    }
    path
      ..lineTo(b.left, b.top + tl.y)
      ..arcToPoint(Offset(b.left + tl.x, b.top), radius: tl)
      ..close();
    return path;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BubbleBorder &&
          side == other.side &&
          borderRadius == other.borderRadius &&
          direction == other.direction &&
          arrowSize == other.arrowSize &&
          arrow == other.arrow;

  @override
  int get hashCode => Object.hash(side, borderRadius, direction, arrowSize, arrow);
}
