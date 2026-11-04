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

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 单色小图标的形状描述: 只负责在给定尺寸内画出图形, 不持有任何资源, 可 const 复用。
///
/// 同一个形状既能交给 ShapeImage 栅格化后排进画布标签, 也能在 Widget 中矢量绘制。
/// 形状参与缓存与重绘判断: 默认同类型即相等, 带参数的子类须按参数覆写相等运算符与 [hashCode]。
/// 尺寸跟随内容或需对准锚点的外形(气泡、带尖角的标签)用 ShapeBorder。
@immutable
abstract base class IconShape {
  const IconShape();

  /// 在 `Offset.zero & size` 内用 [color] 画出图形。
  void paint(Canvas canvas, Size size, Color color);

  /// 描边图标用的画笔: 圆头线端、圆角拐点。
  @protected
  @nonVirtual
  Paint strokePaint(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
