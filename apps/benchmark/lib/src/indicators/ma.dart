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

import 'package:flexi_formatter/flexi_formatter.dart' show formatPrice;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

typedef MaParam = ({int count, Color color});

/// 主区 MA: close 的 5 / 10 / 30 / 60 均线, combine 共享主区坐标系; 4 条折线 + tips。
///
/// 计算与绘制对标 `flexi_kline_indicators` 的 `MAIndicator`, 配置最小化: 只保留高度、边距、精度、tips 样式与均线参数(周期与颜色),
/// 不做序列化与 copyWith。
class BenchMaIndicator extends ComputedIndicator {
  BenchMaIndicator({
    super.height = defaultMainIndicatorHeight,
    super.padding = defaultMainIndicatorPadding,
    this.precision,
    this.calcParam = const [
      (count: 5, color: Color(0xFFDD93E2)),
      (count: 10, color: Color(0xFFFCA744)),
      (count: 30, color: Color(0xFF6951FF)),
      (count: 60, color: Color(0xFFF15866)),
    ],
    this.tipsStyle = const TextStyle(
      fontSize: defaultTextSize,
      overflow: TextOverflow.ellipsis,
      height: defaultTipsTextHeight,
    ),
  }) : super(key: const ComputedIndicatorKey('bench_ma'));

  @override
  final List<MaParam> calcParam;

  /// 为空表示使用当前 klineData 的精度。
  final int? precision;
  final TextStyle tipsStyle;

  @override
  ComputedPaintObject<ComputedIndicator> createPaintObject() => _BenchMaPaintObject();

  @override
  IndicatorCalculator createCalculator(int dataIndex) => _BenchMaCalculator(this, dataIndex);
}

/// 从旧到新滑动求和; 增量计算只重算 [range] 内新进入或变化的那段。
class _BenchMaCalculator extends IndicatorCalculator<BenchMaIndicator> {
  _BenchMaCalculator(super.indicator, super.dataIndex);

  @override
  void compute(KlineData data, Range range, {bool reset = false}) {
    if (data.isEmpty) return;
    if (reset) {
      range = Range(0, data.length);
      for (int i = 0; i < data.length; i++) {
        data.list[i].clean(dataIndex);
      }
    }
    final params = indicator.calcParam;
    for (final (j, param) in params.indexed) {
      final count = param.count;
      // 周期非正的线不写值, tips 显示 `--`; 否则 sum.divNum(count) 会除以 0。
      if (count <= 0) continue;
      final end = math.min(data.length - count, range.end - 1);
      final start = math.max(0, range.start - count);
      if (end < start) continue;
      var sum = data[end].close;
      for (int i = end + 1; i < end + count; i++) {
        sum += data[i].close;
      }
      data[end].getOrInitList<FlexiNum>(dataIndex, params.length)[j] = sum.divNum(count);
      for (int i = end - 1; i >= start; i--) {
        sum = sum - data[i + count].close + data[i].close;
        data[i].getOrInitList<FlexiNum>(dataIndex, params.length)[j] = sum.divNum(count);
      }
    }
  }
}

class _BenchMaPaintObject extends ComputedPaintObject<BenchMaIndicator> {
  FlexiNum? _value(FlexiCandleModel m, int j) => m.getList<FlexiNum>(dataIndex)?[j];

  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    final params = indicator.calcParam;
    final len = klineData.length;
    // 任一周期长于数据时整体不出值(与计算器一致)。
    if (params.isEmpty || params.any((p) => p.count > len)) return null;

    final int minCount = params.map((p) => p.count).reduce(math.min);
    end = math.min(len - minCount, end - 1);

    MinMax? minmax;
    FlexiCandleModel m;
    for (int i = end; i >= start; i--) {
      m = klineData[i];
      minmax ??= m.getList<FlexiNum>(dataIndex)?.minmax;
      minmax?.updateMinMax(m.getList<FlexiNum>(dataIndex)?.minmax);
    }
    return minmax;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start = klineData.start;
    final end = math.min(klineData.end + 1, klineData.length);
    final startOffset = startCandleDx - candleWidthHalf;
    for (int j = 0; j < indicator.calcParam.length; j++) {
      final points = <Offset>[];
      for (int i = start; i < end; i++) {
        final value = _value(klineData[i], j);
        if (value == null) continue;
        points.add(
          Offset(
            startOffset - (i - start) * candleActualWidth,
            valueToDy(value, correct: false),
          ),
        );
      }
      canvas.drawPath(
        Path()..addPolygon(points, false),
        Paint()
          ..color = indicator.calcParam[j].color
          ..style = PaintingStyle.stroke
          ..strokeWidth = defaultIndicatorLineWidth,
      );
    }
  }

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    model ??= offsetToCandle(offset);
    if (model == null) return null;
    final children = <TextSpan>[
      for (int j = 0; j < indicator.calcParam.length; j++)
        TextSpan(
          text: formatPrice(
            _value(model, j)?.toDecimal(),
            precision: indicator.precision ?? klineData.precision,
            prefix: 'MA${indicator.calcParam[j].count}:$nbsp',
            suffix: '  ',
          ),
          style: indicator.tipsStyle.copyWith(color: indicator.calcParam[j].color),
        ),
    ];
    tipsRect ??= drawableRect;
    return canvas.drawText(
      offset: tipsRect.topLeft,
      textSpan: TextSpan(children: children),
      drawableRect: tipsRect,
      padding: defaultTipsPadding,
    );
  }
}
