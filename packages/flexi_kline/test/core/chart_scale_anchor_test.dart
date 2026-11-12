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

/// X 轴缩放的锚点：锚点下的内容在缩放前后保持不动。
///
/// 两个维度都要覆盖：最新蜡烛在屏内（`paintDxOffset <= 0`）与已滑出屏幕（`> 0`）走同一条
/// 锚点公式；蜡烛间距按宽度派生时，比例必须取更新宽度之后的实际宽度，否则每帧都会漂。
///
/// 覆盖层级：controller 的 `onChartScaleBy`。不覆盖：手势识别与焦点坐标的来源。
@TestOn('vm')
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'SCALE-ANCHOR', interval: FlexiTimeInterval(1, TimeUnit.minute));

const _canvasWidth = 400.0;

/// 偏左的焦点：与主图中心、左右缘都不重合，锚错了位置必然测得出漂移。
const _focalDx = 130.0;

void main() {
  late FlexiKlineController chart;

  Future<void> arrange(WidgetTester tester, {required bool history, required bool fixedSpacing}) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(_spec, genFlatCandleList(count: 600), canvasWidth: _canvasWidth);
    chart = scene.controller;
    chart.flushPendingKlineData();
    await paintChartFrame(tester, chart);
    if (fixedSpacing) chart.updateSettingConfig((c) => c.copyWith(candleFixedSpacing: 2));
    expect(chart.settingConfig.isFixedCandleSpacing, fixedSpacing, reason: '前置：间距模式');
    if (history) chart.onChartMove(const Offset(150, 0));
    expect(chart.paintDxOffset > 0, history, reason: '前置：最新蜡烛是否已滑出屏幕');
  }

  /// [dx] 处的连续下标，即该位置下的内容。
  double contentAt(double dx) => (dx - chart.indexToDx(0)) / chart.candleActualWidth;

  /// 先放大再缩小，每步后检查 [anchorDx] 下的内容。
  void expectAnchored(ScalePosition position, double anchorDx) {
    final content = contentAt(anchorDx);
    for (final delta in [...List.filled(10, 0.05), ...List.filled(15, -0.05)]) {
      final before = chart.candleWidth;
      chart.onChartScaleBy(delta, position: position, focalDx: _focalDx);
      expect(chart.candleWidth, isNot(before), reason: '前置：每步都真的改了宽度');
      expect(contentAt(anchorDx), closeTo(content, 1e-6), reason: '宽度 ${chart.candleWidth} 时锚点下的内容漂移');
    }
  }

  for (final history in [false, true]) {
    for (final fixedSpacing in [false, true]) {
      final label = 'history=$history fixedSpacing=$fixedSpacing';

      testWidgets('auto 锚定焦点 ($label)', (tester) async {
        await arrange(tester, history: history, fixedSpacing: fixedSpacing);
        expectAnchored(ScalePosition.auto, _focalDx);
      });

      testWidgets('middle 锚定主图中心, 与焦点无关 ($label)', (tester) async {
        await arrange(tester, history: history, fixedSpacing: fixedSpacing);
        expectAnchored(ScalePosition.middle, chart.mainChartRect.center.dx);
      });

      testWidgets('left 锚定主图左缘 ($label)', (tester) async {
        await arrange(tester, history: history, fixedSpacing: fixedSpacing);
        expectAnchored(ScalePosition.left, chart.mainChartLeft);
      });
    }
  }

  testWidgets('right: 最新蜡烛滑出屏幕后锚定主图右缘', (tester) async {
    await arrange(tester, history: true, fixedSpacing: false);
    expectAnchored(ScalePosition.right, chart.mainChartRight);
  });

  testWidgets('right: 最新蜡烛在屏内时固定右侧空白', (tester) async {
    await arrange(tester, history: false, fixedSpacing: false);
    final blank = chart.paintDxOffset;
    chart.onChartScaleBy(0.5, position: ScalePosition.right, focalDx: _focalDx);
    expect(chart.paintDxOffset, closeTo(blank, 1e-9));
  });

  testWidgets('不传 position 时取 GestureConfig.scalePosition', (tester) async {
    await arrange(tester, history: true, fixedSpacing: false);
    chart.updateGestureConfig((c) => c.copyWith(scalePosition: ScalePosition.left));
    final content = contentAt(chart.mainChartLeft);
    chart.onChartScaleBy(0.5, focalDx: _focalDx);
    expect(contentAt(chart.mainChartLeft), closeTo(content, 1e-6));
  });

  testWidgets('auto 不传 focalDx 时锚定主图中心', (tester) async {
    await arrange(tester, history: true, fixedSpacing: false);
    final center = chart.mainChartRect.center.dx;
    final content = contentAt(center);
    chart.onChartScaleBy(0.5, position: ScalePosition.auto);
    expect(contentAt(center), closeTo(content, 1e-6));
  });
}
