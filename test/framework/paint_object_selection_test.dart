// Copyright 2024 Andy.Zhao
//
// ignore_for_file: invalid_use_of_protected_member
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

/// PaintObject 选中态：框架持有、对象粒度、失选触发源收口。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
// 直接引入内部库，使 PaintDelegateExt 的 mount/onExitTree 对包内测试可见。
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _specA = KlineSpec(symbol: 'AAA', interval: FlexiTimeInterval(1, TimeUnit.day));
const _specB = KlineSpec(symbol: 'BBB', interval: FlexiTimeInterval(1, TimeUnit.day));

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

/// 命中区 (0,0)-(100,100) 的可交互指标
TestInteractiveIndicator _interactive(String id, {Rect? hitRect}) {
  return TestInteractiveIndicator(
    key: ExternalIndicatorKey('interactive_$id'),
    hitRect: hitRect ?? const Rect.fromLTRB(0, 0, 100, 100),
  );
}

void main() {
  group('PaintObject 选中态/对象侧语义', () {
    TestInteractivePaintObject mounted(FakePaintContext context, {String id = 'a'}) {
      final indicator = _interactive(id);
      final object = indicator.createPaintObject();
      object.mount(indicator, context);
      return object;
    }

    test('isSelected 反映框架持有的选中对象', () {
      final context = FakePaintContext();
      final object = mounted(context);

      expect(object.isSelected, isFalse);
      context.selectedPaintObject = object;
      expect(object.isSelected, isTrue);
      object.deselect();
      expect(object.isSelected, isFalse);
    });

    test('PaintObject 没有自我提权通道: 只能读与放弃, 不能授予', () {
      final context = FakePaintContext();
      final object = mounted(context);

      // 对象侧不存在 select() —— 授予只发生在 ChartBinding.onTap 的分发窗口内。
      expect(object.isSelected, isFalse);
      object.deselect();
      expect(context.selectedPaintObject, isNull);
    });

    test('deselect 只对当前选中对象生效, 不会误清他人选中态', () {
      final context = FakePaintContext();
      final selected = mounted(context, id: 'a');
      final other = mounted(context, id: 'b');

      context.selectedPaintObject = selected;
      other.deselect();

      expect(selected.isSelected, isTrue);
    });

    test('onExitTree 释放选中态', () {
      final context = FakePaintContext();
      final object = mounted(context)..doInitState();
      object.onEnterTree();
      context.selectedPaintObject = object;
      expect(object.isSelected, isTrue);

      object.onExitTree();

      expect(context.selectedPaintObject, isNull);
    });
  });

  group('PaintObject 选中态/Controller 分发', () {
    late ControllerScenario scene;
    late FlexiKlineController ctrl;
    late TestInteractiveIndicator indicator;
    late TestInteractivePaintObject object;

    Future<void> arrange({KlineSpec spec = _specA}) async {
      scene = ControllerScenario();
      addTearDown(scene.dispose);
      ctrl = scene.controller;
      indicator = _interactive('main');
      await scene.initWithData(spec, _candles(3), mainIndicators: [indicator], canvasWidth: 400);
      // 挂载前提交的数据仍在 pending, 落地后 canPaintChart 才为 true（cross 的前置条件）。
      ctrl.flushPendingKlineData();
      object = indicator.object!;
    }

    testWidgets('点击命中对象 => 消费点击并进入选中态', (tester) async {
      await arrange();

      final handled = ctrl.onTap(const Offset(10, 10));

      expect(handled, isTrue);
      expect(object.isSelected, isTrue);
      expect(ctrl.hasSelectedPaintObject, isTrue);
      expect(ctrl.selectedPaintObjectListenable.value, same(object));
    });

    testWidgets('二次点击同一对象 => 由对象自行取消选中', (tester) async {
      await arrange();

      ctrl.onTap(const Offset(10, 10));
      final handled = ctrl.onTap(const Offset(10, 10));

      expect(handled, isTrue);
      expect(object.calls, ['tap', 'tap']);
      expect(object.isSelected, isFalse);
      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('点击落在对象之外 => 不消费点击, 且框架清除选中态', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      expect(ctrl.hasSelectedPaintObject, isTrue);

      final handled = ctrl.onTap(const Offset(500, 500));

      expect(handled, isFalse, reason: '未命中应交还框架, 由其启动 cross');
      expect(ctrl.hasSelectedPaintObject, isFalse);
      expect(object.calls, ['tap'], reason: '未命中不应再次回调 handleTap');
    });

    testWidgets('启动 cross => 清除选中态', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      expect(ctrl.hasSelectedPaintObject, isTrue);

      final started = ctrl.onCrossStart(GestureData.tap(const Offset(200, 200)));

      expect(started, isTrue);
      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('选中即取消 cross', (tester) async {
      await arrange();
      ctrl.onCrossStart(GestureData.tap(const Offset(200, 200)));
      expect(ctrl.isCrossing, isTrue);

      ctrl.onTap(const Offset(10, 10));

      expect(ctrl.isCrossing, isFalse);
      expect(ctrl.hasSelectedPaintObject, isTrue);
    });

    testWidgets('spec.key 变化 => 清除选中态', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      expect(ctrl.hasSelectedPaintObject, isTrue);

      ctrl.switchKlineData(_specB);

      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('进入手绘 => 清除选中态', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      expect(ctrl.hasSelectedPaintObject, isTrue);

      ctrl.prepareDraw(force: true);
      ctrl.startDraw(const FlexiDrawType('test_line', 2));

      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('deselectPaintObject 幂等', (tester) async {
      await arrange();

      ctrl.deselectPaintObject();
      ctrl.deselectPaintObject();

      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('选中态落在主区子对象上, 而非 MainPaintObject 容器', (tester) async {
      await arrange();

      ctrl.onTap(const Offset(10, 10));

      final selected = ctrl.selectedPaintObjectListenable.value;
      expect(selected, same(object));
      expect(selected, isNot(isA<MainPaintObject>()));
    });

    testWidgets('handled: 消费点击但不授予选中态', (tester) async {
      await arrange();
      object.tapResult = PaintTapResult.handled;

      final handled = ctrl.onTap(const Offset(10, 10));

      expect(handled, isTrue, reason: '点击已被消费, 不应启动 cross');
      expect(object.calls, ['tap']);
      expect(ctrl.hasSelectedPaintObject, isFalse);
    });

    testWidgets('handled: 清除既有选中态', (tester) async {
      scene = ControllerScenario();
      addTearDown(scene.dispose);
      ctrl = scene.controller;
      final first = _interactive('a', hitRect: const Rect.fromLTRB(0, 0, 100, 40));
      final second = _interactive('b', hitRect: const Rect.fromLTRB(0, 60, 100, 100));
      await scene.initWithData(_specA, _candles(3), mainIndicators: [first, second], canvasWidth: 400);
      ctrl.flushPendingKlineData();
      // 仅处理点击、不需要选中态的指标。
      second.object!.tapResult = PaintTapResult.handled;

      ctrl.onTap(const Offset(10, 10));
      expect(ctrl.selectedPaintObjectListenable.value, same(first.object));

      ctrl.onTap(const Offset(10, 80));

      expect(ctrl.hasSelectedPaintObject, isFalse);
      expect(first.object!.isSelected, isFalse);
    });

    testWidgets('授予与清除各只通知一次', (tester) async {
      await arrange();
      var notifyCount = 0;
      ctrl.selectedPaintObjectListenable.addListener(() => notifyCount++);

      ctrl.onTap(const Offset(10, 10));
      expect(notifyCount, 1, reason: '授予通知一次');

      ctrl.onTap(const Offset(10, 10));
      expect(notifyCount, 2, reason: '二次点击 => handled => 清除通知一次');
      expect(ctrl.hasSelectedPaintObject, isFalse);

      ctrl.deselectPaintObject();
      expect(notifyCount, 2, reason: '已无选中, 不应再通知');
    });

    testWidgets('副区位置的点击不询问主区指标', (tester) async {
      await arrange();
      final subPosition = ctrl.subRect.center;

      final handled = ctrl.onTap(subPosition);

      expect(handled, isFalse);
      expect(object.calls, isEmpty, reason: '主区指标不应收到副区位置的点击');
    });
  });

  group('PaintObject 选中态/可绘制性门控', () {
    late ControllerScenario scene;
    late FlexiKlineController ctrl;
    late TestInteractiveIndicator indicator;
    late TestInteractivePaintObject object;

    /// 蜡烛指标开启「线图模式隐藏其余主区指标」，与内置 CandleIndicator 的默认一致。
    Future<void> arrange() async {
      scene = ControllerScenario();
      addTearDown(scene.dispose);
      ctrl = scene.controller;
      indicator = _interactive('main');
      await scene.initWithData(
        _specA,
        _candles(3),
        mainIndicators: [indicator],
        canvasWidth: 400,
        candle: TestCandleIndicator(hideMainIndicatorsInLineChartMode: true),
      );
      ctrl.flushPendingKlineData();
      object = indicator.object!;
    }

    /// 切到线图模式：主区仅绘制蜡烛。
    void enterLineChartMode() {
      scene.candle.object!.chartTypeOverride = FlexiChartType.lineNormal;
    }

    testWidgets('线图模式下不询问被隐藏的主区指标', (tester) async {
      await arrange();
      enterLineChartMode();

      final handled = ctrl.onTap(const Offset(10, 10));

      expect(handled, isFalse);
      expect(object.calls, isEmpty, reason: 'paintableChildren 已过滤掉它');
    });

    testWidgets('选中后变为不可绘制: 选中态保留, 但有效选中为空', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      expect(ctrl.hasSelectedPaintObject, isTrue);

      enterLineChartMode();

      expect(
        ctrl.selectedPaintObjectListenable.value,
        same(object),
        reason: '原始选中不因可见性变化而丢失',
      );
      expect(ctrl.hasSelectedPaintObject, isFalse, reason: '有效选中为空, 不再抑制 hover cross');
    });

    testWidgets('不可绘制时不认领拖动', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      enterLineChartMode();

      final claimed = ctrl.onPaintObjectDragStart(const Offset(10, 10));

      expect(claimed, isFalse);
      expect(ctrl.isPaintObjectDragging, isFalse);
      expect(object.calls, ['tap'], reason: 'handleDragStart 不应被调用');
    });

    testWidgets('恢复可绘制后选中态自动生效', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      enterLineChartMode();
      expect(ctrl.hasSelectedPaintObject, isFalse);

      scene.candle.object!.chartTypeOverride = FlexiChartType.barSolid;

      expect(ctrl.hasSelectedPaintObject, isTrue);
      expect(ctrl.onPaintObjectDragStart(const Offset(10, 10)), isTrue);
    });

    testWidgets('拖动途中变为不可绘制, 仍能收到 handleDragCancel', (tester) async {
      await arrange();
      ctrl.onTap(const Offset(10, 10));
      ctrl.onPaintObjectDragStart(const Offset(10, 10));
      enterLineChartMode();

      ctrl.deselectPaintObject();

      expect(object.calls.last, 'dragCancel', reason: '未提交状态必须回滚');
      expect(ctrl.isPaintObjectDragging, isFalse);
    });
  });
}
