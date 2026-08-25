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

/// TouchGestureDetector 与 PaintObject 拖动的 Widget 级分发。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'PAINT-OBJECT-DRAG',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 命中区高 20px, 小于两条路径的手势识别容差(触摸 36px / 非鼠标 pan 36px),
/// 因此用识别时刻位置命中必然脱靶。
const _hitRect = Rect.fromLTWH(100, 100, 30, 20);

/// 一轮拖动的总位移: 必须大于识别容差, 否则手势不会被识别。
const _dragDelta = Offset(0, -40);

/// 总位移中的首段: 小于识别容差, 此时手势尚不应被识别。
const _firstStep = Offset(0, -12);

List<CandleModel> _candles() => List.generate(
      20,
      (index) => CandleModel(
        timestamp: 20000 - index * 60000,
        open: 100,
        high: 110,
        low: 90,
        close: 105,
        volume: 1000,
      ),
    );

Future<FlexiKlineController> _pumpChart(
  WidgetTester tester, {
  required TestInteractiveIndicator indicator,
  required bool isTouchDevice,
}) async {
  final controller = createChartController();
  controller.switchKlineData(_spec);
  controller.replaceKlineData(_spec, _candles());

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 400,
        height: 480,
        child: FlexiKlineWidget(
          controller: controller,
          candle: TestCandleIndicator(),
          time: TestTimeIndicator(),
          mainIndicators: [indicator],
          isTouchDevice: isTouchDevice,
        ),
      ),
    ),
  );
  await pumpUntilChart(
    tester,
    () => controller.isMounted && controller.mainChartWidth > 0 && controller.klineData.isNotEmpty,
    'chart data and layout',
  );
  return controller;
}

/// 从按下位置发起一次超过手势容差的拖动, 并断言 PaintObject 收到的是按下位置。
///
/// [listenerKey] 用于取到对应手势层的 RenderBox 做全局坐标换算。
Future<void> _expectDragClaimedAtDownPosition(
  WidgetTester tester, {
  required FlexiKlineController controller,
  required TestInteractivePaintObject object,
  required ValueKey<String> listenerKey,
  required PointerDeviceKind kind,
}) async {
  final downPosition = _hitRect.center;
  expect(controller.onTap(downPosition), isTrue);
  expect(controller.hasSelectedPaintObject, isTrue);

  final listenerBox = tester.renderObject<RenderBox>(find.byKey(listenerKey));
  final gesture = await tester.startGesture(
    listenerBox.localToGlobal(downPosition),
    kind: kind,
  );

  // 分两段移动: 首段在识别容差内, 手势尚未被识别, 对象不应收到任何拖动回调。
  await gesture.moveBy(_firstStep);
  await tester.pump();
  expect(object.calls, isNot(contains('dragStart')));

  // 补足到超过容差: 此时才识别, 命中位置必须仍是按下位置。
  await gesture.moveBy(_dragDelta - _firstStep);
  await tester.pump();

  expect(object.lastDragStartPosition, downPosition);
  expect(object.lastDragPosition, downPosition + _dragDelta);
  // 识别前发生的位移不能丢, 且与 PointerMove 分几段派发无关。
  expect(object.totalDragDelta, _dragDelta);
  expect(controller.isPaintObjectDragging, isTrue);

  await gesture.up();
  await tester.pump(const Duration(milliseconds: 20));
  expect(object.calls.last, 'dragEnd');
  expect(controller.isPaintObjectDragging, isFalse);
}

void main() {
  testWidgets('触摸路径以 PointerDown 位置认领延迟触发的拖动', (tester) async {
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('touch_drag'),
      hitRect: _hitRect,
    );
    final controller = await _pumpChart(tester, indicator: indicator, isTouchDevice: true);
    addTearDown(() => disposeChart(tester, controller));

    await _expectDragClaimedAtDownPosition(
      tester,
      controller: controller,
      object: indicator.object!,
      listenerKey: const ValueKey('TouchListener'),
      kind: PointerDeviceKind.touch,
    );
  });

  testWidgets('非触摸路径以 PointerDown 位置认领延迟触发的拖动', (tester) async {
    final indicator = TestInteractiveIndicator(
      key: const ExternalIndicatorKey('non_touch_drag'),
      hitRect: _hitRect,
    );
    final controller = await _pumpChart(tester, indicator: indicator, isTouchDevice: false);
    addTearDown(() => disposeChart(tester, controller));

    await _expectDragClaimedAtDownPosition(
      tester,
      controller: controller,
      object: indicator.object!,
      listenerKey: const ValueKey('NonTouchListener'),
      // 鼠标的 pan 容差仅 2px, 偏差不可见; 触控笔走 kPanSlop(36px), 才能暴露命中偏差。
      kind: PointerDeviceKind.stylus,
    );
  });
}
