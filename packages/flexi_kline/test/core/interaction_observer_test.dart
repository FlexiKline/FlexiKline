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

/// 用户交互事件上报单测。
///
/// 覆盖层级：controller 各操作收口方法 → `dispatchInteractionEvent` 派发。
/// 不覆盖：手势识别与竞技场——一次真实手势是否恰好调到这些方法，只能靠真机验证。
@TestOn('vm')
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
// painting 而非 widgets: widgets 的 Overlay widget 与绘制框架的 Overlay 同名。
import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'OBS-TEST', interval: FlexiTimeInterval(1, TimeUnit.day));

final _subKey = directKey(1);

/// 记录型 observer：存下收到的事件供断言。
class _RecordingObserver extends FlexiKlineObserver {
  final List<FlexiKlineEvent> events = [];

  @override
  void onEvent(FlexiKlineEvent event) => events.add(event);

  List<FlexiKlineEvent> ofType(FlexiKlineEventType type) => events.where((e) => e.type == type).toList();
}

/// 每次回调都抛异常，用于验证异常隔离。
class _ThrowingObserver extends FlexiKlineObserver {
  int calls = 0;

  @override
  void onEvent(FlexiKlineEvent event) {
    calls++;
    throw StateError('observer boom');
  }
}

/// 回调内注销自己，用于验证遍历快照不抛并发修改。
class _SelfRemovingObserver extends FlexiKlineObserver {
  _SelfRemovingObserver(this.chart);

  final FlexiKlineController chart;
  int calls = 0;

  @override
  void onEvent(FlexiKlineEvent event) {
    calls++;
    chart.removeObserver(this);
  }
}

List<CandleModel> _candles({int count = 200, int intervalMs = 60000}) {
  const latest = 12000000;
  return List.generate(count, (index) {
    final center = 100 + index * 10.0;
    return CandleModel(
      timestamp: latest - index * intervalMs,
      open: center,
      high: center + 5,
      low: center - 5,
      close: center,
      volume: 1000,
    );
  });
}

void main() {
  group('interaction-observer', () {
    late FlexiKlineController chart;
    late _RecordingObserver observer;

    /// 注册在 initWithData 之后，避免把初始化期的 switchKlineData 计入断言。
    Future<void> arrange(WidgetTester tester, {bool register = true}) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(
        _spec,
        _candles(count: 200),
        canvasWidth: 400,
        candle: TestCandleIndicator(visibleMinMaxFromData: true),
        subIndicators: [TestDirectIndicator(key: _subKey)],
      );
      chart = scene.controller;
      observer = _RecordingObserver();
      if (register) chart.addObserver(observer);
      chart.flushPendingKlineData();
      await paintChartFrame(tester, chart);
    }

    testWidgets('平移结束上报 pan', (tester) async {
      await arrange(tester);

      chart.onPanEnd();

      expect(observer.ofType(FlexiKlineEventType.pan), hasLength(1));
    });

    testWidgets('X 轴缩放结束上报 scale 带当前蜡烛宽度', (tester) async {
      await arrange(tester);

      chart.onChartScaleBy(2.0, position: ScalePosition.middle, focalDx: 200);
      chart.onChartScaleEnd();

      final scale = observer.ofType(FlexiKlineEventType.scale).single;
      expect(scale.data['candleWidth'], chart.candleWidth);
    });

    testWidgets('十字线 toggle 上报进入与退出', (tester) async {
      await arrange(tester);

      chart.onCrossToggle(const Offset(200, 100));
      chart.onCrossToggle(const Offset(200, 100));

      final crosses = observer.ofType(FlexiKlineEventType.cross);
      expect(crosses.map((e) => e.data['active']), [true, false]);
    });

    testWidgets('指标显隐上报 indicatorToggle', (tester) async {
      await arrange(tester);

      chart.showSubIndicator(_subKey);
      chart.hideSubIndicator(_subKey);

      final toggles = observer.ofType(FlexiKlineEventType.indicatorToggle);
      expect(toggles.map((e) => e.data['visible']), [true, false]);
      expect(toggles.first.data['inMain'], isFalse);
    });

    testWidgets('切换 K 线数据上报 switchKlineData', (tester) async {
      await arrange(tester);

      chart.switchKlineData(const KlineSpec(symbol: 'OTHER', interval: FlexiTimeInterval(5, TimeUnit.minute)));

      final event = observer.ofType(FlexiKlineEventType.switchKlineData).single;
      expect(event.data['symbol'], 'OTHER');
    });

    testWidgets('回到最新位置上报 moveToLatest', (tester) async {
      await arrange(tester);

      chart.requestMoveToInitialPosition();

      expect(observer.ofType(FlexiKlineEventType.moveToLatest), hasLength(1));
    });

    testWidgets('observer 抛异常被隔离，框架方法正常返回', (tester) async {
      await arrange(tester, register: false);
      final throwing = _ThrowingObserver();
      chart.addObserver(throwing);

      expect(() => chart.onPanEnd(), returnsNormally);
      expect(throwing.calls, 1, reason: 'observer 确实被调用了');
    });

    testWidgets('observer 可在回调内注销自己', (tester) async {
      await arrange(tester, register: false);
      final selfRemoving = _SelfRemovingObserver(chart);
      chart.addObserver(selfRemoving);

      expect(() => chart.onPanEnd(), returnsNormally, reason: '遍历快照避免并发修改');
      chart.onPanEnd();
      expect(selfRemoving.calls, 1, reason: '注销后不再收到');
    });

    testWidgets('注销后不再收到事件', (tester) async {
      await arrange(tester);
      chart.removeObserver(observer);

      chart.onPanEnd();

      expect(observer.events, isEmpty);
    });

    testWidgets('后注册的 observer 收不到历史事件', (tester) async {
      await arrange(tester, register: false);
      chart.onPanEnd();

      final later = _RecordingObserver();
      chart.addObserver(later);

      expect(later.events, isEmpty, reason: '派发不缓存历史');
    });

    testWidgets('Y 轴缩放与指标高度拖拽结束各上报一次', (tester) async {
      await arrange(tester);

      chart.onChartZoomEnd();
      chart.onGridResizeEnd();

      expect(observer.ofType(FlexiKlineEventType.zoomY), hasLength(1));
      expect(observer.ofType(FlexiKlineEventType.gridResize), hasLength(1));
    });

    testWidgets('平移越过历史阈值上报 loadMoreHistory 且只报一次', (tester) async {
      await arrange(tester);

      // 预测终点远超 maxPaintDxOffset，触发 none -> loadMore 跳变。
      // 不传 panDuration: 那条分支走 Future.delayed 通知，会留下 pending Timer 而与被测行为无关。
      chart.checkAndLoadMoreCandlesWhenPanEnd(panDistance: 1e6);
      // 已处于 loadMore 态，再检查不应重复上报。
      chart.checkAndLoadMoreCandlesWhenPanEnd(panDistance: 1e6);

      final events = observer.ofType(FlexiKlineEventType.loadMoreHistory);
      expect(events, hasLength(1), reason: '仅在 loadMore 状态跳变时上报');
      expect(events.single.data['length'], chart.klineData.length);
    });

    testWidgets('定位到指定日期成功后上报 moveToDate', (tester) async {
      await arrange(tester);
      final target = chart.klineData.get(10)!;

      final index = await chart.moveToDateTime(
        DateTime.fromMillisecondsSinceEpoch(target.ts),
      );

      expect(index, 10);
      final event = observer.ofType(FlexiKlineEventType.moveToDate).single;
      expect(event.data['ts'], target.ts);
    });

    testWidgets('绘图全流程按序上报 start/complete/select/move/delete', (tester) async {
      await arrange(tester);
      registerTestDrawObject(chart);

      // startDraw -> 两次 confirm 完成，完成后停在 Editing。
      drawTestLine(chart, from: const Offset(50, 50), to: const Offset(150, 100));
      final object = chart.drawState.object!;
      chart.onDrawSelect(object);
      chart.onDrawMoveEnd();
      chart.removeDrawObject(object: object);
      chart.removeAllDrawObjects();

      expect(
        observer.events.map((e) => e.type).toList(),
        containsAllInOrder([
          FlexiKlineEventType.drawStart,
          FlexiKlineEventType.drawComplete,
          FlexiKlineEventType.drawSelect,
          FlexiKlineEventType.drawMove,
          FlexiKlineEventType.drawDelete,
        ]),
      );
      expect(observer.ofType(FlexiKlineEventType.drawStart).single.data['type'], testDrawLineType.toString());
      final deletes = observer.ofType(FlexiKlineEventType.drawDelete);
      expect(deletes.map((e) => e.data['all']), [false, true], reason: '单个删除与清空都上报，用 all 区分');
    });

    testWidgets('PaintObject 拖动结束上报 paintObjectDrag', (tester) async {
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      final indicator = TestInteractiveIndicator(
        key: const ExternalIndicatorKey('obs_drag'),
        hitRect: const Rect.fromLTRB(0, 0, 100, 100),
      );
      await scene.initWithData(_spec, _candles(count: 3), mainIndicators: [indicator], canvasWidth: 400);
      chart = scene.controller;
      chart.flushPendingKlineData();
      observer = _RecordingObserver();
      chart.addObserver(observer);

      expect(chart.onPaintObjectDragStart(const Offset(10, 10)), isTrue);
      chart.onPaintObjectDragEnd();
      // 无对象在拖动时不应上报。
      chart.onPaintObjectDragEnd();

      final events = observer.ofType(FlexiKlineEventType.paintObjectDrag);
      expect(events, hasLength(1));
      expect(events.single.data['key'], indicator.key.toString());
    });
  });
}
