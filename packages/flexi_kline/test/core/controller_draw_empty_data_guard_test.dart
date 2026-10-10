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

/// 无数据时的画图入口护栏：[klineData] 为空时不得进入画图态，也不得落指针。
///
/// 覆盖 Controller 的 `startDraw` / `onDrawConfirm` 入口判据；不覆盖手势识别与 Widget 层。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart' show Canvas, Offset, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'DRAW-EMPTY-DATA-GUARD',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _emptySpec = KlineSpec(
  symbol: 'DRAW-EMPTY-DATA-GUARD-EMPTY',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 与 mount spec 同 symbol、不同 interval: 不触发 `exitDraw`, 画图对象得以保留。
const _switchSpec = KlineSpec(
  symbol: 'DRAW-EMPTY-DATA-GUARD',
  interval: FlexiTimeInterval(5, TimeUnit.minute),
);

const _canvasWidth = 400.0;

void main() {
  Future<void> paintChartFrame(WidgetTester tester, FlexiKlineController chart) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Future<FlexiKlineController> mountChart(
    WidgetTester tester,
    FakeFlexiKlineConfiguration config, {
    bool withData = true,
  }) async {
    final controller = FlexiKlineController(configuration: config);
    registerTestDrawObject(controller);
    final scenario = ControllerScenario(controller: controller);
    await scenario.initWithData(
      // 空数据态用独立 spec, 避免有数据用例把同名 symbol 的数据写进缓存, 污染本用例。
      withData ? _spec : _emptySpec,
      withData ? genFlatCandleList() : const [],
      canvasWidth: _canvasWidth,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    addTearDown(scenario.dispose);
    controller.flushPendingKlineData();
    await paintChartFrame(tester, controller);
    return controller;
  }

  FakeFlexiKlineConfiguration newConfig() => FakeFlexiKlineConfiguration(
    enableStorage: true,
    enableDraw: true,
    shareConfigInstance: true,
  );

  ({Offset from, Offset to}) lineEnds(FlexiKlineController controller, {double dyShift = 0}) {
    final mainRect = controller.mainRect;
    final dy = mainRect.center.dy + dyShift;
    return (
      from: Offset(mainRect.right - 120, dy),
      to: Offset(mainRect.right - 40, dy),
    );
  }

  group('v2.6.0/FlexiKlineController/draw-empty-data-guard', () {
    testWidgets('空数据 startDraw → drawState 保持 Prepared, 不落指针', (tester) async {
      final controller = await mountChart(tester, newConfig(), withData: false);
      expect(controller.klineData.isEmpty, isTrue, reason: '前置：当前为空数据态');
      expect(controller.drawState.object, isNull, reason: '前置：初始无画图对象');

      controller.startDraw(testDrawLineType);

      expect(
        controller.drawState.object,
        isNull,
        reason: '空数据时落点无法换算成有效蜡烛坐标, 不该创建画图对象 / 进入画图态。',
      );
      expect(
        controller.drawState.isOngoing,
        isFalse,
        reason: '不得进入 Drawing / Editing 态。',
      );
    });

    testWidgets('画图中数据被清空 → onDrawConfirm 不新增指针', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final ends = lineEnds(controller);

      controller.startDraw(testDrawLineType, isInitPointer: false);
      controller.onDrawConfirm(ends.from);
      final object = controller.drawState.object;
      expect(object, isNotNull, reason: '前置：有数据时第一次确认已落下首个指针');
      final pointerCountBefore = object!.points.where((p) => p != null).length;
      expect(pointerCountBefore, 1, reason: '前置：两点线段此刻只落了一个点');

      controller.switchKlineData(_switchSpec);
      controller.replaceKlineData(_switchSpec, const []);
      controller.flushPendingKlineData();
      expect(controller.klineData.isEmpty, isTrue, reason: '前置：切换后数据为空');
      expect(
        controller.drawState.object,
        same(object),
        reason: '前置：同 symbol 切换不触发 exitDraw, 画图对象应保留 —— 守卫才有被测意义。',
      );

      controller.onDrawConfirm(ends.to);

      expect(
        object.points.where((p) => p != null).length,
        pointerCountBefore,
        reason: '数据清空后确认落点会换算出错位坐标, 应被忽略, 指针数不变。',
      );
    });

    testWidgets('有数据 → 正常画线行为不受影响', (tester) async {
      final controller = await mountChart(tester, newConfig());
      final ends = lineEnds(controller);

      drawTestLine(controller, from: ends.from, to: ends.to);

      expect(controller.drawState.object, isNotNull);
      expect(controller.drawState.isEditing, isTrue, reason: '两点线段画完应停在 Editing 态');
      expect(controller.hasDrawOverlay, isTrue);
    });
  });
}
