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

/// 十字线 Tooltip 的内容来源与卡片装饰。
///
/// 覆盖层级：controller 的 `onCrossFollow` / `onCrossToggle` → `paintCross`。
/// 不覆盖：手势识别与 Widget 坐标转换。
@TestOn('vm')
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'CROSS-TOOLTIP', interval: FlexiTimeInterval(1, TimeUnit.minute));
const _red = Color(0xFFFF0000);

void main() {
  late FlexiKlineController chart;

  Future<void> arrange(WidgetTester tester) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(_spec, genFlatCandleList(count: 50), canvasWidth: 400);
    chart = scene.controller;
    chart.flushPendingKlineData();
    await paintChartFrame(tester, chart);
  }

  Offset focus() => Offset(chart.indexToDx(chart.klineData.length - 5), chart.mainRect.center.dy);

  RecordingCanvas paintCross() {
    final canvas = RecordingCanvas();
    chart.paintCross(canvas, chart.canvasRect.size);
    return canvas;
  }

  /// 关掉 Tooltip 时 paintCross 画的段落数, 即十字线刻度等其余内容。
  int baseParagraphs() {
    final show = chart.crossConfig.tooltipConfig;
    chart.updateCrossConfig((c) => c.copyWith(tooltipConfig: show.copyWith(show: false)));
    final count = paintCross().countOf(#drawParagraph);
    chart.updateCrossConfig((c) => c.copyWith(tooltipConfig: show));
    return count;
  }

  group('tooltipBuilder', () {
    testWidgets('为 null 或返回 null 时用默认文案生成', (tester) async {
      await arrange(tester);
      chart.onCrossFollow(focus());
      final base = baseParagraphs();
      final model = chart.klineData[chart.klineData.length - 5];
      final rows = chart.generateTooltipInfoListByLabels(defaultTooltipLabels, model: model).length;

      expect(paintCross().countOf(#drawParagraph), base + rows * 2);

      chart.tooltipBuilder = (current, {prev}) => null;
      expect(paintCross().countOf(#drawParagraph), base + rows * 2);
    });

    testWidgets('返回的行原样画出, 返回空列表时不画 Tooltip', (tester) async {
      await arrange(tester);
      chart.onCrossFollow(focus());
      final base = baseParagraphs();

      chart.tooltipBuilder = (current, {prev}) => [TooltipInfo(label: 'L', value: 'V')];
      expect(paintCross().countOf(#drawParagraph), base + 2);

      chart.tooltipBuilder = (current, {prev}) => const [];
      final canvas = paintCross();
      expect(canvas.countOf(#drawParagraph), base);
      expect(canvas.rrectBounds, isEmpty);
    });

    testWidgets('点击关闭十字线时不调用 builder', (tester) async {
      await arrange(tester);
      var calls = 0;
      chart.tooltipBuilder = (current, {prev}) {
        calls++;
        return null;
      };

      expect(chart.onCrossToggle(focus()), isTrue);
      expect(chart.onCrossToggle(focus()), isFalse);

      expect(calls, 0);
    });
  });

  group('卡片装饰', () {
    // Paint 以 float32 存色, 按 ARGB 整数比较。
    Iterable<int> fillColors(RecordingCanvas canvas) => canvas.invocations
        .where((i) => i.memberName == #drawRRect)
        .map((i) => (i.positionalArguments[1] as Paint).color.toARGB32());

    testWidgets('未配背景色时用主题 tooltipBg, 配置的背景色优先', (tester) async {
      await arrange(tester);
      chart.onCrossFollow(focus());
      expect(fillColors(paintCross()), contains(chart.theme.tooltipBg.toARGB32()));

      chart.updateCrossConfig((c) => c.copyWith(tooltipConfig: c.tooltipConfig.copyWith(backgroundColor: _red)));
      final colors = fillColors(paintCross());
      expect(colors, contains(_red.toARGB32()));
      expect(colors, isNot(contains(chart.theme.tooltipBg.toARGB32())));
    });

    testWidgets('配置的边框与阴影画到卡片上', (tester) async {
      await arrange(tester);
      chart.onCrossFollow(focus());
      final plain = paintCross();

      chart.updateCrossConfig(
        (c) => c.copyWith(
          tooltipConfig: c.tooltipConfig.copyWith(
            border: const BorderSide(color: _red),
            shadows: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
          ),
        ),
      );
      final decorated = paintCross();

      expect(decorated.countOf(#drawDRRect), plain.countOf(#drawDRRect) + 1, reason: '边框');
      expect(decorated.countOf(#drawRRect), plain.countOf(#drawRRect) + 1, reason: '阴影');
    });
  });
}
