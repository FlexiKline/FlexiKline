// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// 非触摸端触控板（通道 P）的平移与捏合定责：scale 偏离 1.0 超过 0.05 才算捏合。
///
/// 经 PointerPanZoom* → Listener → controller API。**不覆盖**真机触控板惯性衔接，**未经真机验证**。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

const _spec = KlineSpec(
  symbol: 'NON-TOUCH-TRACKPAD',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _frame = Duration(milliseconds: 16);
const _settle = Duration(milliseconds: 60);

Future<FlexiKlineController> _pumpNonTouchChart(WidgetTester tester) async {
  final controller = createChartController();
  controller.switchKlineData(_spec);
  controller.replaceKlineData(_spec, genFlatCandleList());

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 400,
        height: 480,
        child: FlexiKlineWidget(
          controller: controller,
          candle: TestCandleIndicator(),
          time: TestTimeIndicator(),
          isTouchDevice: false,
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => controller.isMounted && controller.mainChartWidth > 0 && controller.klineData.isNotEmpty,
    'non-touch chart data and layout',
  );
  return controller;
}

Offset _toGlobal(WidgetTester tester, Offset local) {
  final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('NonTouchListener')));
  return box.localToGlobal(local);
}

/// 在主区中心发一轮触控板手势，第 i 帧（从 1 起）的累积 pan 与 scale 由回调给出。
Future<void> _panZoom(
  WidgetTester tester,
  FlexiKlineController controller, {
  required int frames,
  required Offset Function(int i) pan,
  required double Function(int i) scale,
  void Function()? onStart,
}) async {
  final global = _toGlobal(tester, controller.mainRect.center);
  final gesture = await tester.createGesture(kind: PointerDeviceKind.trackpad);
  await gesture.panZoomStart(global);
  await tester.pump(_frame);
  onStart?.call();

  var at = Duration.zero;
  for (var i = 1; i <= frames; i++) {
    at += _frame;
    await gesture.panZoomUpdate(global, pan: pan(i), scale: scale(i), timeStamp: at);
    await tester.pump(_frame);
  }

  await gesture.panZoomEnd();
  await tester.pump(_frame);
  await tester.pump(_settle);
}

void main() {
  testWidgets('双指横滑带 scale 微波动（< 0.05）→ 平移，不缩放', (tester) async {
    final controller = await _pumpNonTouchChart(tester);
    addTearDown(() => disposeChart(tester, controller));
    final initWidth = controller.candleWidth;
    final initDx = controller.paintDxOffset;

    // 真机横滑的 scale 噪声通常 < 0.02。
    await _panZoom(
      tester,
      controller,
      frames: 8,
      pan: (i) => Offset(8.0 * i, 0),
      scale: (i) => i.isEven ? 1.015 : 0.99,
    );

    expect(controller.candleWidth, initWidth, reason: '噪声不应触发 X 缩放');
    expect(controller.paintDxOffset, isNot(initDx), reason: '横滑应平移');
  });

  testWidgets('双指捏合（scale 越过 0.05）→ X 缩放，pan 被抑制', (tester) async {
    final controller = await _pumpNonTouchChart(tester);
    addTearDown(() => disposeChart(tester, controller));
    // right 锚点下缩放本身不改 paintDxOffset，断言只反映 pan 位移。
    controller.updateGestureConfig((c) => c.copyWith(scalePosition: ScalePosition.right));
    final initWidth = controller.candleWidth;
    late double baselineDx;

    // pan 非零：真实捏合时手指也会移动，正是要被抑制的部分。
    await _panZoom(
      tester,
      controller,
      frames: 5,
      pan: (i) => Offset(8.0 * i, 0),
      scale: (i) => 1.0 + 0.06 * i,
      onStart: () => baselineDx = controller.paintDxOffset,
    );

    expect(controller.candleWidth, isNot(initWidth), reason: '捏合应触发 X 缩放');
    expect((controller.paintDxOffset - baselineDx).abs(), lessThan(2.0), reason: '捏合期间应抑制 pan');
  });

  testWidgets('捏合结束后新一轮横滑正常平移', (tester) async {
    final controller = await _pumpNonTouchChart(tester);
    addTearDown(() => disposeChart(tester, controller));

    await _panZoom(tester, controller, frames: 1, pan: (_) => Offset.zero, scale: (_) => 1.3);
    final afterPinchDx = controller.paintDxOffset;

    await _panZoom(tester, controller, frames: 5, pan: (i) => Offset(10.0 * i, 0), scale: (_) => 1.0);

    expect(controller.paintDxOffset, isNot(afterPinchDx), reason: 'pinching 应随 session 清零');
  });
}
