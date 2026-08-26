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

/// `hitTestDragStart` 沿 mixin 链的应答顺序与各 Binding 的判据边界。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'DRAG-HIT', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 绘制线与 PaintObject 命中区重叠，用来观察谁先应答。
const _sharedHit = Rect.fromLTRB(0, 0, 100, 100);
const _lineFrom = Offset(10, 50);
const _lineTo = Offset(90, 50);
const _onLine = Offset(50, 50);

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

void main() {
  group('拖动命中查询链', () {
    late ControllerScenario scene;
    late FlexiKlineController ctrl;
    late TestInteractiveIndicator indicator;

    Future<void> arrange({bool withLine = true}) async {
      scene = ControllerScenario();
      addTearDown(scene.dispose);
      ctrl = scene.controller;
      indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('drag_hit'),
        hitRect: _sharedHit,
      );
      await scene.initWithData(_spec, _candles(), mainIndicators: [indicator], canvasWidth: 400);
      ctrl.flushPendingKlineData();
      registerTestDrawObject(ctrl);
      ctrl.setDrawVisible(true);
      if (withLine) drawTestLine(ctrl, from: _lineFrom, to: _lineTo);
    }

    testWidgets('编辑中的绘制对象先于 PaintObject 应答', (tester) async {
      await arrange();
      expect(ctrl.drawState.isEditing, isTrue);

      expect(ctrl.hitTestDragStart(_onLine), isTrue);

      // DrawBinding 在 mixin 链最后, 先应答即短路, PaintObject 不该被问到。
      expect(indicator.object!.hitTestDragStartCount, 0);
    });

    testWidgets('绘制对象不应答时链继续走到 PaintObject', (tester) async {
      await arrange(withLine: false);

      expect(ctrl.hitTestDragStart(_onLine), isTrue);

      expect(indicator.object!.hitTestDragStartCount, 1);
    });

    testWidgets('两侧都不应答时返回 false', (tester) async {
      await arrange(withLine: false);
      indicator.object!.acceptDrag = false;

      expect(ctrl.hitTestDragStart(_onLine), isFalse);
    });

    testWidgets('锁定的绘制对象不应答, 让位给 PaintObject', (tester) async {
      await arrange();
      expect(ctrl.setDrawLockState(true), isTrue);

      expect(ctrl.hitTestDragStart(_onLine), isTrue);

      // 锁定即不可拖, 判据与 onDrawMoveStart 的 lock 检查同源。
      expect(indicator.object!.hitTestDragStartCount, 1);
    });

    testWidgets('绘制未完成时不应答: Drawing 的移动不依赖竞技场归属', (tester) async {
      await arrange(withLine: false);
      ctrl.startDraw(testDrawLineType, isInitPointer: false);
      ctrl.onDrawConfirm(GestureData.tap(_lineFrom));
      expect(ctrl.drawState.isDrawing, isTrue);

      expect(ctrl.hitTestDragStart(_onLine), isTrue);

      expect(indicator.object!.hitTestDragStartCount, 1);
    });

    testWidgets('绘制层隐藏时不应答', (tester) async {
      await arrange();
      ctrl.setDrawVisible(false);

      expect(ctrl.hitTestDragStart(_onLine), isTrue);

      expect(indicator.object!.hitTestDragStartCount, 1);
    });

    testWidgets('查询不产生任何状态变更', (tester) async {
      await arrange();

      ctrl.hitTestDragStart(_onLine);

      expect(ctrl.drawState.object!.moving, isFalse);
      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(indicator.object!.calls, isEmpty);
    });
  });
}
