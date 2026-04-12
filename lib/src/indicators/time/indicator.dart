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

part of 'time.dart';

/// 时间刻度指标图
@CopyWith()
@FlexiIndicatorSerializable
class TimeIndicator extends TimeBaseIndicator {
  TimeIndicator({
    super.zIndex = 0,
    super.height = defaultTimeIndicatorHeight,
    super.padding = EdgeInsets.zero,
    super.position = DrawPosition.middle,
    // 时间刻度.
    required this.timeTick,
    this.ensurePaintInDrawableRect = false,
    this.tickFormatter,
  });

  /// 时间刻度.
  final TextAreaConfig timeTick;

  /// 确保在时间刻度绘制区域内画图: 启用会启用裁切
  final bool ensurePaintInDrawableRect;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final DateTimeFormatter? tickFormatter;

  @override
  TimePaintObject createPaintObject() => TimePaintObject();

  factory TimeIndicator.fromJson(Map<String, dynamic> json) => _$TimeIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimeIndicatorToJson(this);
}

class TimePaintObject<T extends TimeIndicator> extends TimeBasePaintObject<T> {
  /// 两个时间刻度间隔的蜡烛数
  int get timeTickIntervalCount {
    return ((math.max(60, indicator.timeTick.textWidth ?? 0)) / candleActualWidth).round();
  }

  @override
  MinMax? initState(int start, int end) {
    return null;
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    if (indicator.ensurePaintInDrawableRect) {
      canvas.save();
      canvas.clipRect(drawableRect);
      paintTimeChart(canvas, size);
      canvas.restore();
    } else {
      paintTimeChart(canvas, size);
    }
  }

  void paintTimeChart(Canvas canvas, Size size) {
    final data = klineData;
    if (data.list.isEmpty) return;
    final start = data.start;
    final end = data.end;

    final offset = startCandleDx - candleWidthHalf;
    final interval = data.interval;
    for (var i = start; i < end; i++) {
      final model = data.list[i];
      final dx = offset - (i - start) * candleActualWidth;
      if (interval.isValid && i % timeTickIntervalCount == 0) {
        final offset = Offset(dx, chartRect.top);

        // 绘制时间刻度.
        final timeTick = indicator.timeTick.of(
          textColor: theme.ticksTextColor,
        );
        final dyCenterOffset = (height - timeTick.areaHeight) / 2;
        canvas.drawTextArea(
          offset: Offset(
            offset.dx,
            offset.dy + dyCenterOffset,
          ),
          drawDirection: DrawDirection.center,
          text: formatDateTime(model, interval),
          textConfig: timeTick,
        );
      }
    }
  }

  String formatDateTime(FlexiCandleModel model, ITimeInterval interval) {
    if (indicator.tickFormatter != null) {
      return indicator.tickFormatter!.call(model.dateTime, interval);
    }
    return model.formatDateTime(interval);
  }

  @override
  void onCross(Canvas canvas, Offset offset) {
    final model = offsetToCandle(offset);
    final interval = klineData.interval;
    if (model == null || !interval.isValid) return;

    final time = formatDateTime(model, interval);
    // final time = formatyyMMddHHMMss(model.dateTime);

    final ticksText = crossConfig.ticksText;

    final dyCenterOffset = (height - ticksText.areaHeight) / 2;
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
    FlexiCandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    return null;
  }
}
