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
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/painting.dart';

import '../config/export.dart';
import '../constant.dart';
import '../core/core.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import '../framework/export.dart';

part 'time.g.dart';

/// 时间刻度指标图
@CopyWith()
@FlexiIndicatorSerializable
class TimeIndicator extends SinglePaintObjectIndicator {
  TimeIndicator({
    super.key = IndicatorType.time,
    super.name = 'Time',
    super.zIndex = 0,
    super.height = defaultTimeIndicatorHeight,
    super.padding = EdgeInsets.zero,
    this.position = DrawPosition.middle,
    // 时间刻度.
    required this.timeTick,
  });

  // 时间刻度.
  final TextAreaConfig timeTick;
  final DrawPosition position;

  @override
  TimePaintObject createPaintObject(covariant IPaintContext context) {
    return TimePaintObject(context: context, indicator: this);
  }

  factory TimeIndicator.fromJson(Map<String, dynamic> json) =>
      _$TimeIndicatorFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TimeIndicatorToJson(this);
}

class TimePaintObject<T extends TimeIndicator> extends SinglePaintObjectBox<T> {
  TimePaintObject({
    required super.context,
    required super.indicator,
  });

  /// 两个时间刻度间隔的蜡烛数
  int get timeTickIntervalCount {
    return ((math.max(60, indicator.timeTick.textWidth ?? 0)) /
            candleActualWidth)
        .round();
  }

  @override
  MinMax? initState({required int start, required int end}) {
    return null;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    final data = klineData;
    if (data.list.isEmpty) return;
    int start = data.start;
    int end = data.end;

    final offset = startCandleDx - candleWidthHalf;
    final bar = data.timeBar;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      if (bar != null && i % timeTickIntervalCount == 0) {
        final offset = Offset(dx, chartRect.top);

        // 绘制时间刻度.
        final timeTick = indicator.timeTick;
        final dyCenterOffset = (indicator.height - timeTick.areaHeight) / 2;
        canvas.drawTextArea(
          offset: Offset(
            offset.dx,
            offset.dy + dyCenterOffset,
          ),
          drawDirection: DrawDirection.center,
          text: model.formatDateTime(bar),
          textConfig: timeTick,
        );
      }
    }
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    final model = offsetToCandle(offset);
    final timeBar = klineData.timeBar;
    if (model == null || timeBar == null) return;

    final time = model.formatDateTime(timeBar);
    // final time = formatyyMMddHHMMss(model.dateTime);

    final ticksText = crossConfig.ticksText;

    final dyCenterOffset = (indicator.height - ticksText.areaHeight) / 2;
    canvas.drawTextArea(
      offset: Offset(
        offset.dx,
        chartRect.top + dyCenterOffset,
      ),
      drawDirection: DrawDirection.center,
      text: time,
      textConfig: ticksText,
    );
  }

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    return null;
  }
}
