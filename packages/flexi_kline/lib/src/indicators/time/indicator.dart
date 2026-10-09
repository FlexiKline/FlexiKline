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
    this.timeLabel = const TextAreaConfig(
      style: TextStyle(
        fontSize: defaultTextSize,
        overflow: TextOverflow.ellipsis,
        height: defaultTextHeight,
      ),
      textWidth: 80,
      textAlign: TextAlign.center,
    ),
    this.clipToDrawableRect = false,
    this.tickFormatter,
  });

  /// 时间刻度.
  final TextAreaConfig timeLabel;

  /// 确保在时间刻度绘制区域内画图: 启用会启用裁切
  final bool clipToDrawableRect;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final DateTimeFormatter? tickFormatter;

  @override
  TimePaintObject createPaintObject() => TimePaintObject();

  factory TimeIndicator.fromJson(Map<String, dynamic> json) => _$TimeIndicatorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimeIndicatorToJson(this);
}

class TimePaintObject<T extends TimeIndicator> extends TimeBasePaintObject<T> {
  /// key 为 (ts, interval, tickFormatter): 宿主换了格式器, 函数身份不同, 文本随之重建。
  ///
  /// 约每 60px 一个刻度, 1200px 宽同屏已有 15 个; 64 覆盖桌面宽度, 并给缩放时来回切换的刻度组留余量。
  late final _timeLabels = own(LabelPainter(capacity: 64));
  late final _crossTimeLabel = own(LabelPainter());

  /// 两个时间刻度间隔的蜡烛数
  int get timeLabelIntervalCount {
    return ((math.max(60, indicator.timeLabel.textWidth ?? 0)) / candleActualWidth).round();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (indicator.clipToDrawableRect) {
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
    final start = data.start;
    final end = data.end;

    final offset = startCandleDx - candleWidthHalf;
    final interval = data.interval;
    if (!interval.isValid) return;
    final style = indicator.timeLabel.toLabelStyle(textColor: theme.ticksTextColor);
    final formatter = indicator.tickFormatter;
    final dy = chartRect.top + height / 2;
    final step = timeLabelIntervalCount;
    for (var i = start; i < end; i++) {
      if (i % step != 0) continue;
      final model = data.list[i];
      _timeLabels.paint(
        canvas,
        (model.ts, interval, formatter),
        build: () => formatTimeLabel(model, interval),
        style: style,
        anchor: Offset(offset - (i - start) * candleActualWidth, dy),
        align: Alignment.center,
      );
    }
  }

  String formatTimeLabel(FlexiCandleModel model, ITimeInterval interval) {
    if (indicator.tickFormatter != null) {
      return indicator.tickFormatter!.call(model.dateTime, interval);
    }
    return model.formatDateTime(interval);
  }

  @override
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    final selectedModel = model ?? offsetToCandle(offset);
    final interval = klineData.interval;
    if (selectedModel == null || !interval.isValid) return;

    _crossTimeLabel.paint(
      canvas,
      (selectedModel.ts, interval, indicator.tickFormatter),
      build: () => formatTimeLabel(selectedModel, interval),
      style: crossConfig.ticksText.toLabelStyle(
        textColor: theme.crossTextColor,
        backgroundColor: theme.crossTextBg,
      ),
      anchor: Offset(offset.dx, chartRect.top + height / 2),
      align: Alignment.center,
    );
  }
}
