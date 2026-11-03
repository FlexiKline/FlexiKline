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

extension AlignmentPlace on Alignment {
  /// 让 [size] 的本对齐点落在 [anchor] 上; 给了 [bounds] 就整体平移回其内。
  ///
  /// topLeft / topRight / topCenter 对应旧 DrawDirection 的 ltr / rtl / center;
  /// 调用点手算的 `dy - areaHeight / 2` 也由它表达, 且用实测高度而非估算。
  Rect place(Size size, Offset anchor, [Rect? bounds]) {
    final rect = (anchor - alongSize(size)) & size;
    if (bounds == null) return rect;
    // 外层 max 不可省: bounds 装不下时上下界会反, clamp 会抛异常。
    return Offset(
          math.max(bounds.left, math.min(rect.left, bounds.right - size.width)),
          math.max(bounds.top, math.min(rect.top, bounds.bottom - size.height)),
        ) &
        size;
  }
}

/// [placeAround] 的结果: 实际所在侧、锚点与绘制用的对齐方式。
typedef AnchorPlacement = ({AxisDirection side, Offset anchor, Alignment align});

/// 在 [target] 的 [side] 一侧摆放尺寸为 [size](含箭头外延)的标签: 锚点是该边中点向外 [spacing]。
///
/// [flip] 时首选侧在 [bounds] 内放不下而对侧放得下则换到对侧; 两侧都放不下时留在首选侧, 由绘制时的 bounds 夹回。
/// 只判断主轴, 交叉轴由夹取处理。
AnchorPlacement placeAround(
  Rect target,
  Size size, {
  required AxisDirection side,
  double spacing = 0,
  bool flip = true,
  Rect? bounds,
}) {
  AnchorPlacement at(AxisDirection side) => switch (side) {
    AxisDirection.up => (side: side, anchor: target.topCenter.translate(0, -spacing), align: Alignment.bottomCenter),
    AxisDirection.down => (side: side, anchor: target.bottomCenter.translate(0, spacing), align: Alignment.topCenter),
    AxisDirection.left => (side: side, anchor: target.centerLeft.translate(-spacing, 0), align: Alignment.centerRight),
    AxisDirection.right => (side: side, anchor: target.centerRight.translate(spacing, 0), align: Alignment.centerLeft),
  };

  bool fits(AnchorPlacement p) =>
      bounds == null ||
      switch (p.side) {
        AxisDirection.up => p.anchor.dy - size.height >= bounds.top,
        AxisDirection.down => p.anchor.dy + size.height <= bounds.bottom,
        AxisDirection.left => p.anchor.dx - size.width >= bounds.left,
        AxisDirection.right => p.anchor.dx + size.width <= bounds.right,
      };

  final preferred = at(side);
  if (!flip || fits(preferred)) return preferred;
  final opposite = at(flipAxisDirection(side));
  return fits(opposite) ? opposite : preferred;
}
