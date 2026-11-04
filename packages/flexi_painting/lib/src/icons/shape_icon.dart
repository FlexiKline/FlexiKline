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

import 'package:flutter/widgets.dart';

import 'icon_shape.dart';

/// 以 [shape] 矢量绘制的图标, 用法同 [Icon]: 未指定的尺寸与颜色取自 [IconTheme]。
///
/// 不持有位图, 任意像素密度都清晰, 换色只触发重绘。
final class ShapeIcon extends StatelessWidget {
  const ShapeIcon(this.shape, {super.key, this.size, this.color, this.semanticLabel});

  final IconShape shape;

  /// 默认取 [IconThemeData.size] 的正方形。
  final Size? size;

  /// 默认取 [IconThemeData.color]; 与 [Icon] 一致, 都会乘以 [IconThemeData.opacity]。
  final Color? color;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final opacity = theme.opacity ?? 1;
    var paintColor = color ?? theme.color!;
    if (opacity != 1) paintColor = paintColor.withValues(alpha: paintColor.a * opacity);

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.fromSize(
          size: size ?? Size.square(theme.size ?? 24),
          child: CustomPaint(painter: _ShapeIconPainter(shape, paintColor)),
        ),
      ),
    );
  }
}

final class _ShapeIconPainter extends CustomPainter {
  const _ShapeIconPainter(this.shape, this.color);

  final IconShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => shape.paint(canvas, size, color);

  @override
  bool shouldRepaint(_ShapeIconPainter oldDelegate) => oldDelegate.shape != shape || oldDelegate.color != color;
}
