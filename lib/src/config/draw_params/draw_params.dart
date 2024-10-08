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

import '../../utils/vector_util.dart';
import '../../framework/serializers.dart';
import '../text_area_config/text_area_config.dart';

part 'draw_params.g.dart';

@CopyWith()
@FlexiConfigSerializable
class DrawParams {
  const DrawParams({
    this.arrowsRadians = pi30,
    this.arrowsLen = 16.0,
    this.priceText,
    this.priceTextMargin = EdgeInsets.zero,
  });

  /// 箭头相对于基线的角
  final double arrowsRadians;

  /// 箭头长度
  final double arrowsLen;

  /// 价值线(priceLine)的文本区域配置, 如果不指定, 使用DrawConfig的tickText.
  final TextAreaConfig? priceText;

  /// 价值线(priceLine)的文本区域相对于价值线的margin
  final EdgeInsets priceTextMargin;

  factory DrawParams.fromJson(Map<String, dynamic> json) =>
      _$DrawParamsFromJson(json);

  Map<String, dynamic> toJson() => _$DrawParamsToJson(this);
}
