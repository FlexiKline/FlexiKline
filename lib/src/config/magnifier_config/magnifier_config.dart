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

import '../../framework/serializers.dart';

part 'magnifier_config.g.dart';

@CopyWith()
@FlexiConfigSerializable
class MagnifierConfig {
  const MagnifierConfig({
    this.enable = true,
    this.margin = EdgeInsets.zero,
    this.size = const Size(80, 80),
    this.magnificationScale = 2,
    this.clipBehavior = Clip.none,
    this.decorationOpactity = 1.0,
    this.decorationShadows,
    this.shapeSide = BorderSide.none,
  });

  /// 是否启用放大镜
  final bool enable;

  /// 放大镜margin
  final EdgeInsets margin;

  /// 放大镜大小
  final Size size;

  /// 放大倍数 参考[RawMagnifier]Widget对应的属性.
  final double magnificationScale;

  /// Whether and how to clip the parts of [decoration] that render inside the
  /// loupe.
  ///
  /// Defaults to [Clip.none].
  ///
  /// See the discussion at [decoration].
  final Clip clipBehavior;

  /// The opacity of the magnifier and decorations around the magnifier.
  ///
  /// When this is 1.0, the magnified image shows in the [shape] of the
  /// magnifier. When this is less than 1.0, the magnified image is transparent
  /// and shows through the unmagnified background.
  ///
  /// Generally this is only useful for animating the magnifier in and out, as a
  /// transparent magnifier looks quite confusing.
  final double decorationOpactity;

  /// A list of shadows cast by the [shape].
  ///
  /// If the shadows are offset, consider setting [RawMagnifier.clipBehavior] to
  /// [Clip.hardEdge] (or similar) to ensure the shadow does not occlude the
  /// magnifier (the shadow is drawn above the magnifier).
  ///
  /// If the shadows are _not_ offset, consider using [BlurStyle.outer] in the
  /// shadows instead, to avoid having to introduce a clip.
  ///
  /// In the event that [shape] consists of a stack of borders, the shadow is
  /// drawn using the bounds of the last one.
  ///
  /// See also:
  ///
  ///  * [kElevationToShadow], which defines some shadows for Material design.
  ///    Those shadows use [BlurStyle.normal] and may need to be converted to
  ///    [BlurStyle.outer] for use with [MagnifierDecoration].
  final List<BoxShadow>? decorationShadows;

  /// 放大镜默认圆形边框样式
  final BorderSide shapeSide;

  factory MagnifierConfig.fromJson(Map<String, dynamic> json) =>
      _$MagnifierConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MagnifierConfigToJson(this);
}
