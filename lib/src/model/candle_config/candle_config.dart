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

import 'package:flutter/material.dart';

import '../../constant.dart';
import '../../extension/render/common.dart';
import '../../framework/serializers.dart';
import '../line_config/line_config.dart';
import '../mark_config/mark_config.dart';
import '../text_area_config/text_area_config.dart';

part 'candle_config.g.dart';

@FlexiConfigSerializable
class CandleConfig {
  const CandleConfig({
    // 最高价
    this.high = const MarkConfig(
      spacing: 2,
      line: LineConfig(
        type: LineType.solid,
        color: Colors.black,
        length: 20,
        width: 0.5,
      ),
    ),
    // 最低价
    this.low = const MarkConfig(
      spacing: 2,
      line: LineConfig(
        type: LineType.solid,
        color: Colors.black,
        length: 20,
        width: 0.5,
      ),
    ),
    // 最后价: 当最新蜡烛不在可视区域时使用.
    this.last = const MarkConfig(
      show: true,
      spacing: 0,
      line: LineConfig(
        type: LineType.dashed,
        color: Colors.black,
        width: 0.5,
        dashes: [3, 3],
      ),
      text: TextAreaConfig(
        style: TextStyle(
          fontSize: defaulTextSize,
          color: Colors.white,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
        background: Colors.black38,
        padding: defaultTextPading,
        border: BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    ),
    // 最新价: 当最新蜡烛在可视区域时使用.
    this.latest = const MarkConfig(
      show: true,
      spacing: 1,
      line: LineConfig(
        type: LineType.dashed,
        color: Colors.black,
        width: 0.5,
        dashes: [3, 3],
      ),
      text: TextAreaConfig(
        style: TextStyle(
          fontSize: defaulTextSize,
          color: Colors.black,
          overflow: TextOverflow.ellipsis,
          height: defaultTextHeight,
        ),
        background: Colors.white,
        padding: defaultTextPading,
        border: BorderSide(color: Colors.black, width: 0.5),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    ),
    // 倒计时, 在latest最新价之下展示
    this.showCountDown = true,
    this.countDown = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      background: Colors.white30,
      padding: defaultTextPading,
      border: BorderSide(color: Colors.black, width: 0.5),
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
    // 时间刻度.
    this.timeTick = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaulTextSize,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      textWidth: 80,
    ),
  });

  // 最高价
  final MarkConfig high;
  // 最低价
  final MarkConfig low;
  // 最后价: 当最新蜡烛不在可视区域时使用.
  final MarkConfig last;
  // 最新价: 当最新蜡烛在可视区域时使用.
  final MarkConfig latest;
  // 倒计时, 在latest最新价之下展示
  final bool showCountDown;
  final TextAreaConfig countDown;
  // 时间刻度.
  final TextAreaConfig timeTick;

  factory CandleConfig.fromJson(Map<String, dynamic> json) =>
      _$CandleConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CandleConfigToJson(this);
}
