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

/// PaintObject 拖动：只路由给选中对象，且 dragging 蕴含 selected。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'AAA', interval: FlexiTimeInterval(1, TimeUnit.day));

List<CandleModel> _candles(int n) => List.generate(
      n,
      (i) => CandleModel(
        timestamp: 1000 + i * 86400000,
        open: Decimal.fromInt(100 + i),
        high: Decimal.fromInt(110 + i),
        low: Decimal.fromInt(90 + i),
        close: Decimal.fromInt(105 + i),
        volume: Decimal.fromInt(1000 + i),
      ),
    );

void main() {
  group('PaintObject 拖动/Controller 分发', () {
    late ControllerScenario scene;
    late FlexiKlineController ctrl;
    late TestInteractivePaintObject object;

    Future<void> arrange() async {
      scene = ControllerScenario();
      addTearDown(scene.dispose);
      ctrl = scene.controller;
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('interactive_main'),
        hitRect: const Rect.fromLTRB(0, 0, 100, 100),
      );
      await scene.initWithData(_spec, _candles(3), mainIndicators: [indicator], canvasWidth: 400);
      ctrl.flushPendingKlineData();
      object = indicator.object!;
    }

    /// 走完 tap 选中 => 认领拖动
    bool selectThenStartDrag({Offset at = const Offset(10, 10)}) {
      ctrl.onTap(at);
      return ctrl.onPaintObjectDragStart(at);
    }

    testWidgets('未选中任何对象 => 不认领拖动', (tester) async {
      await arrange();

      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isFalse);
      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(object.calls, isEmpty);
    });

    testWidgets('已选中且命中 => 认领拖动', (tester) async {
      await arrange();

      expect(selectThenStartDrag(), isTrue);
      expect(ctrl.isPaintObjectDragging, isTrue);
      expect(object.calls, ['tap', 'dragStart']);
    });

    testWidgets('已选中但对象拒绝 => 不认领, 不进入拖动态', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      object.acceptDrag = false;

      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isFalse);
      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(object.calls, ['tap']);
    });

    testWidgets('已选中但按在命中区之外 => 不认领', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));

      expect(ctrl.onPaintObjectDragStart(const Offset(500, 500)), isFalse);
      expect(ctrl.isPaintObjectDragging, isFalse);
    });

    testWidgets('update 透传 position 与 delta', (tester) async {
      await arrange();
      selectThenStartDrag();

      final data = GestureData.pan(const Offset(10, 10))..update(const Offset(10, 40));
      ctrl.onPaintObjectDragUpdate(data);

      expect(object.lastDragPosition, const Offset(10, 40));
      expect(object.lastDragDelta, const Offset(0, 30));
    });

    testWidgets('拖动结束 => handleDragEnd 且退出拖动态', (tester) async {
      await arrange();
      selectThenStartDrag();

      ctrl.onPaintObjectDragEnd();

      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(object.calls.last, 'dragEnd');
      expect(object.isSelected, isTrue, reason: '结束拖动不应连带取消选中');
    });

    testWidgets('拖动取消 => handleDragCancel 且退出拖动态', (tester) async {
      await arrange();
      selectThenStartDrag();

      ctrl.onPaintObjectDragCancel();

      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(object.calls.last, 'dragCancel');
      expect(object.isSelected, isTrue);
    });

    testWidgets('未在拖动时 update / end / cancel 均为空操作', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));

      ctrl.onPaintObjectDragUpdate(GestureData.pan(const Offset(10, 10)));
      ctrl.onPaintObjectDragEnd();
      ctrl.onPaintObjectDragCancel();

      expect(object.calls, ['tap']);
    });

    testWidgets('拖动中不允许重复认领', (tester) async {
      await arrange();
      selectThenStartDrag();

      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isFalse);
      expect(object.calls, ['tap', 'dragStart']);
    });

    testWidgets('拖动中被强制失选 => 先 handleDragCancel 再清选中态', (tester) async {
      await arrange();
      selectThenStartDrag();

      ctrl.deselectPaintObject();

      expect(object.calls.last, 'dragCancel');
      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('拖动中启动 cross => 取消拖动并清选中态', (tester) async {
      await arrange();
      selectThenStartDrag();

      ctrl.onCrossStart(GestureData.tap(const Offset(200, 200)));

      expect(object.calls.last, 'dragCancel');
      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('不变量: isPaintObjectDragging 蕴含 hasSelectedPaintObject', (tester) async {
      await arrange();
      selectThenStartDrag();

      expect(ctrl.isPaintObjectDragging, isTrue);
      expect(ctrl.hasSelectedPaintObject, isTrue);

      ctrl.deselectPaintObject();

      expect(ctrl.isPaintObjectDragging, isFalse);
    });
  });
}
