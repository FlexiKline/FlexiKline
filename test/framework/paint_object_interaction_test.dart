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

/// PaintObject 点击与拖动命中分发。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'INTERACTION', interval: FlexiTimeInterval(1, TimeUnit.day));

List<CandleModel> _candles() => List.generate(
      3,
      (i) => CandleModel(
        timestamp: 1000 + i * 86400000,
        open: Decimal.fromInt(100 + i),
        high: Decimal.fromInt(110 + i),
        low: Decimal.fromInt(90 + i),
        close: Decimal.fromInt(105 + i),
        volume: Decimal.fromInt(1000 + i),
      ),
    );

TestInteractiveIndicator _interactive(String id, {int zIndex = 0, Rect? hitRect}) {
  return TestInteractiveIndicator(
    key: ExternalIndicatorKey('interactive_$id'),
    zIndex: zIndex,
    hitRect: hitRect ?? const Rect.fromLTRB(0, 0, 100, 100),
  );
}

void main() {
  group('PaintObject 交互分发', () {
    late ControllerScenario scene;
    late FlexiKlineController ctrl;

    Future<void> arrange(List<TestInteractiveIndicator> indicators) async {
      scene = ControllerScenario();
      addTearDown(scene.dispose);
      ctrl = scene.controller;
      await scene.initWithData(_spec, _candles(), mainIndicators: indicators, canvasWidth: 400);
      ctrl.flushPendingKlineData();
    }

    testWidgets('handleTap 返回 true 后停止分发并消费点击', (tester) async {
      final lower = _interactive('lower', zIndex: 1);
      final upper = _interactive('upper', zIndex: 2);
      await arrange([lower, upper]);

      final handled = ctrl.onTap(const Offset(10, 10));

      expect(handled, isTrue);
      expect(upper.object!.calls, ['tap']);
      expect(lower.object!.calls, isEmpty);
    });

    testWidgets('上层对象返回 false 后继续询问下层对象', (tester) async {
      final lower = _interactive('lower', zIndex: 1);
      final upper = _interactive('upper', zIndex: 2);
      await arrange([lower, upper]);
      upper.object!.acceptTap = false;

      final handled = ctrl.onTap(const Offset(10, 10));

      expect(handled, isTrue);
      expect(upper.object!.calls, ['tap']);
      expect(lower.object!.calls, ['tap']);
    });

    testWidgets('没有对象命中时不消费点击', (tester) async {
      final object = _interactive('main');
      await arrange([object]);

      final handled = ctrl.onTap(const Offset(200, 200));

      expect(handled, isFalse);
      expect(object.object!.calls, isEmpty);
    });

    testWidgets('PaintObject 消费点击后关闭 crossing', (tester) async {
      final object = _interactive('main');
      await arrange([object]);
      expect(ctrl.onCrossStart(GestureData.tap(const Offset(200, 200))), isTrue);
      expect(ctrl.isCrossing, isTrue);

      expect(ctrl.onTap(const Offset(10, 10)), isTrue);

      expect(ctrl.isCrossing, isFalse);
      expect(object.object!.calls, ['tap']);
    });

    testWidgets('handleDragStart 按 zIndex 倒序命中并固定拖动归属', (tester) async {
      final lower = _interactive('lower', zIndex: 1);
      final upper = _interactive('upper', zIndex: 2);
      await arrange([lower, upper]);

      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isTrue);
      final data = GestureData.pan(const Offset(10, 10))..update(const Offset(10, 20));
      ctrl.onPaintObjectDragUpdate(data);
      ctrl.onPaintObjectDragEnd();

      expect(upper.object!.calls, ['dragStart', 'dragUpdate', 'dragEnd']);
      expect(lower.object!.calls, isEmpty);
    });

    testWidgets('上层对象拒绝拖动后继续询问下层对象', (tester) async {
      final lower = _interactive('lower', zIndex: 1);
      final upper = _interactive('upper', zIndex: 2);
      await arrange([lower, upper]);
      upper.object!.acceptDrag = false;

      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isTrue);

      expect(upper.object!.calls, isEmpty);
      expect(lower.object!.calls, ['dragStart']);
    });

    testWidgets('hitTestPaintObjectDrag 命中返回 true 且不产生任何回调', (tester) async {
      final object = _interactive('main');
      await arrange([object]);

      expect(ctrl.hitTestPaintObjectDrag(const Offset(10, 10)), isTrue);

      expect(object.object!.hitTestDragStartCount, 1);
      expect(object.object!.calls, isEmpty, reason: '查询不得提交任何拖动状态');
      expect(ctrl.isPaintObjectDragging, isFalse);
    });

    testWidgets('hitTestPaintObjectDrag 未命中返回 false', (tester) async {
      final object = _interactive('main');
      await arrange([object]);

      expect(ctrl.hitTestPaintObjectDrag(const Offset(200, 200)), isFalse);
      expect(object.object!.calls, isEmpty);
    });

    testWidgets('hitTestPaintObjectDrag 按 zIndex 倒序: 上层命中即返回, 不询问下层', (tester) async {
      final lower = _interactive('lower', zIndex: 1);
      final upper = _interactive('upper', zIndex: 2);
      await arrange([lower, upper]);

      expect(ctrl.hitTestPaintObjectDrag(const Offset(10, 10)), isTrue);

      expect(upper.object!.hitTestDragStartCount, 1);
      expect(lower.object!.hitTestDragStartCount, 0);
    });

    testWidgets('上层拒绝拖动时 hitTestPaintObjectDrag 继续询问下层', (tester) async {
      final lower = _interactive('lower', zIndex: 1);
      final upper = _interactive('upper', zIndex: 2);
      await arrange([lower, upper]);
      upper.object!.acceptDrag = false;

      expect(ctrl.hitTestPaintObjectDrag(const Offset(10, 10)), isTrue);

      expect(upper.object!.hitTestDragStartCount, 1);
      expect(lower.object!.hitTestDragStartCount, 1);
    });

    testWidgets('拖动进行中 hitTestPaintObjectDrag 恒返回 false', (tester) async {
      final object = _interactive('main');
      await arrange([object]);
      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isTrue);

      expect(ctrl.hitTestPaintObjectDrag(const Offset(10, 10)), isFalse);

      // 已在拖动时直接短路, 连对象都不询问。
      expect(object.object!.hitTestDragStartCount, 0);
      ctrl.onPaintObjectDragEnd();
    });

    testWidgets('线图模式下被隐藏的主区指标不参与 hitTestPaintObjectDrag', (tester) async {
      final object = _interactive('main');
      final candle = TestCandleIndicator(hideMainIndicatorsInLineChartMode: true);
      scene = ControllerScenario();
      addTearDown(scene.dispose);
      ctrl = scene.controller;
      await scene.initWithData(
        _spec,
        _candles(),
        candle: candle,
        mainIndicators: [object],
        canvasWidth: 400,
      );
      ctrl.flushPendingKlineData();
      candle.object!.chartTypeOverride = FlexiChartType.line();

      expect(ctrl.hitTestPaintObjectDrag(const Offset(10, 10)), isFalse);
      expect(object.object!.hitTestDragStartCount, 0);
      // 与既有的认领路径保持一致。
      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isFalse);
    });
  });
}
