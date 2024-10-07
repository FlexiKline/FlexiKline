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
    this.times = 2,
    this.opactity = 1.0,
    this.opactityWhenOverlap = 0.75,
    this.margin = EdgeInsets.zero,
    this.size = const Size(80, 80),
    this.boder = BorderSide.none,
  });

  /// 是否启用放大镜
  final bool enable;

  /// 放大镜默认背景不透明度
  final double opactity;

  /// 当与当前指针重叠时, 放大镜背景不透明度
  final double opactityWhenOverlap;

  /// 放大倍数
  final double times;

  /// 放大镜margin
  final EdgeInsets margin;

  /// 放大镜大小
  final Size size;

  /// 放大镜边框样式
  final BorderSide boder;

  factory MagnifierConfig.fromJson(Map<String, dynamic> json) =>
      _$MagnifierConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MagnifierConfigToJson(this);
}
