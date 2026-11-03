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

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/painting.dart';

import '../../constant.dart';
import '../../framework/serializers.dart';
import '../../painting/borders.dart';
import '../../painting/label_style.dart';
import '../text_area_config/text_area_config.dart';

part 'bubble_config.g.dart';

/// 指向锚点的带箭头气泡: 外观、所在侧与间距; 内容和何时显示由使用方决定。
@CopyWith()
@FlexiConfigSerializable
class BubbleConfig {
  const BubbleConfig({
    this.text = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    this.arrowSize = const Size(10, 5),
    this.arrowRadius = 0,
    this.spacing = 4,
    this.placement = AxisDirection.up,
    this.flip = true,
  });

  /// 文本与气泡外观, 含背景与边框渐变; 纵向背景渐变用 clamp 或 mirror, decal 会让箭头透明。
  final TextAreaConfig text;

  /// 箭头根宽与几何高度, 即 `BubbleBorder.arrowSize`。
  final Size arrowSize;

  /// 箭头尖端与两个根部的圆角半径, 即 `BubbleBorder.arrowRadius`。
  final double arrowRadius;

  /// 箭头尖端与锚点的距离。
  final double spacing;

  /// 气泡位于锚点的哪一侧, 箭头指向相反方向。
  final AxisDirection placement;

  /// 首选侧放不下而对侧放得下时换到对侧; 两侧都放不下时留在首选侧, 由绘制区域夹回。
  final bool flip;

  factory BubbleConfig.fromJson(Map<String, dynamic> json) => _$BubbleConfigFromJson(json);

  Map<String, dynamic> toJson() => _$BubbleConfigToJson(this);
}

extension BubbleConfigLabel on BubbleConfig {
  /// 气泡位于锚点 [side] 一侧时的样式, 主题色只在配置未指定时兜底; 按配置实例与方向记忆。
  ///
  /// [text] 没有任何装饰时没有形状可换, 原样返回。
  LabelStyle toLabelStyle(AxisDirection side, {Color? textColor, Color? backgroundColor, Color? borderColor}) {
    final source = text.toLabelStyle(textColor: textColor, backgroundColor: backgroundColor, borderColor: borderColor);
    var memo = _bubbleStyleMemo[this];
    if (memo == null || !identical(memo.source, source)) {
      memo = _bubbleStyleMemo[this] = (
        source: source,
        styles: List<LabelStyle?>.filled(AxisDirection.values.length, null),
      );
    }
    return memo.styles[side.index] ??= _derive(source, side);
  }

  LabelStyle _derive(LabelStyle source, AxisDirection side) {
    final decoration = source.decoration;
    if (decoration == null) return source;
    final shape = decoration.shape as RoundedRectangleBorder;
    return source.copyWith(
      decoration: ShapeDecoration(
        color: decoration.color,
        gradient: decoration.gradient,
        shadows: decoration.shadows,
        shape: BubbleBorder(
          side: shape.side,
          borderRadius: shape.borderRadius.resolve(TextDirection.ltr),
          direction: flipAxisDirection(side),
          arrowSize: arrowSize,
          arrowRadius: arrowRadius,
          gradient: shape is GradientRoundedRectangleBorder ? shape.gradient : null,
        ),
      ),
    );
  }
}

typedef _BubbleStyleMemo = ({LabelStyle source, List<LabelStyle?> styles});

final _bubbleStyleMemo = Expando<_BubbleStyleMemo>('BubbleConfig.toLabelStyle');
