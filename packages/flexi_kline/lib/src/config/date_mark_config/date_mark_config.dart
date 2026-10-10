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
import '../../framework/chart/indicator.dart';
import '../../framework/serializers.dart';
import '../text_area_config/text_area_config.dart';

part 'date_mark_config.g.dart';

/// 日期定位气泡: `moveToDateTime` 完成后指向目标蜡烛, 在 overlay 中逐帧绘制, 随平移缩放联动。
@CopyWith()
@FlexiConfigSerializable
class DateMarkConfig {
  const DateMarkConfig({
    this.show = true,
    this.spacing = 4,
    this.arrowSize = const Size(10, 5),
    this.holdDuration = 2000,
    this.position = DateMarkPosition.auto,
    this.text = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  });

  /// 关闭后框架不画; 接入方可依据 `moveToDateTime` 的返回值自行实现(不随滚动联动)。
  final bool show;

  /// 箭头尖端与锚点的距离; 锚点是蜡烛 high(线图为 close), 放在下方时是 low。
  final double spacing;

  /// 箭头根宽与伸出高度, 即 `BubbleBorder.arrowSize`。
  final Size arrowSize;

  /// 显示时长(ms); 0 表示一直显示, 直到下一次定位成功或切换数据。
  final int holdDuration;

  /// 放在蜡烛上方还是下方; 放不下时整体被夹回主区边界内(可能压住蜡烛)。
  final DateMarkPosition position;

  /// 文本与气泡外观; 颜色未指定时取主题的 crossTextColor / crossTextBg。
  final TextAreaConfig text;

  factory DateMarkConfig.fromJson(Map<String, dynamic> json) => _$DateMarkConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DateMarkConfigToJson(this);
}
