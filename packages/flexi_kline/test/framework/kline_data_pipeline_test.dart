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

import 'dart:math' as math;
import 'dart:math' show Random;

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/kline_data_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'TEST', interval: FlexiTimeInterval(1, TimeUnit.day));

CandleModel _candle(int timestamp) => CandleModel(
  timestamp: timestamp,
  open: Decimal.one,
  high: Decimal.fromInt(2),
  low: Decimal.zero,
  close: Decimal.one,
  volume: Decimal.one,
);

({KlineData data, IndicatorPaintObjectManager manager, SpyComputedCalculator calculator}) _scene() {
  const key = ComputedIndicatorKey('pipeline');
  final manager = IndicatorPaintObjectManager(
    configuration: FakeFlexiKlineConfiguration(mainChildren: {key}),
  );
  manager.mountIndicators(
    candle: TestCandleIndicator(),
    time: TestTimeIndicator(),
    mainIndicators: [SpyComputedIndicator(key: key, log: LifecycleLog())],
    subIndicators: const [],
    context: FakePaintContext(),
  );
  return (
    data: KlineData(_spec),
    manager: manager,
    calculator: manager.getCalculator(key)! as SpyComputedCalculator,
  );
}

void main() {
  testWidgets('绑定非空数据后 start 不自动计算', (tester) async {
    final scene = _scene();
    scene.data.replace([_candle(1), _candle(2)], slotCount: scene.manager.computedDataCapacity);
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);

    pipeline.start();
    await tester.pump();

    expect(scene.calculator.computeCount, 0);
  });

  test('interval 为零时抛出 ArgumentError', () {
    final scene = _scene();
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);

    expect(
      () => KlineDataPipeline(
        scene.data,
        scene.manager,
        interval: Duration.zero,
        onCandlesMerged: ({required replace}) {},
        onComputed: () {},
      ),
      throwsArgumentError,
    );
  });

  test('interval 为负值时抛出 ArgumentError', () {
    final scene = _scene();
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);

    expect(
      () => KlineDataPipeline(
        scene.data,
        scene.manager,
        interval: const Duration(milliseconds: -1),
        onCandlesMerged: ({required replace}) {},
        onComputed: () {},
      ),
      throwsArgumentError,
    );
  });

  testWidgets('入队时浅复制调用方 batch', (tester) async {
    final scene = _scene();
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    final batch = [_candle(1), _candle(2)];

    pipeline.replace(batch);
    batch
      ..clear()
      ..add(_candle(99));
    pipeline.start();

    expect(scene.data.list.map((item) => item.ts), [1, 2]);
  });

  testWidgets('dispose 后不能重新启动或接收任务', (tester) async {
    final scene = _scene();
    var mergedCount = 0;
    var computedCount = 0;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      onCandlesMerged: ({required replace}) => mergedCount++,
      onComputed: () => computedCount++,
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.dispose();
    pipeline.invalidateAll();
    pipeline.recompute(scene.calculator);
    pipeline.replace([_candle(1), _candle(2)]);
    pipeline.start();
    await tester.pump(const Duration(seconds: 1));

    expect(scene.data.isEmpty, isTrue);
    expect(mergedCount, 0);
    expect(computedCount, 0);
    expect(scene.calculator.computeCount, 0);
  });

  testWidgets('仅输出低频数据合并耗时日志', (tester) async {
    final scene = _scene();
    final logger = _RecordingLogger();
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      logger: logger,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    logger.entries.clear();

    pipeline.replace([_candle(1), _candle(2)]);

    var merge = logger.entries.singleWhere((entry) => entry.msg.startsWith('Merge:::'));
    expect(merge.level, FlexiLogLevel.debug);
    expect(merge.tag, 'KlineDataPipeline');
    expect(merge.msg, contains('kind:replace key:${scene.data.key} candles:2 range:'));
    expect(merge.msg, matches(RegExp(r'spent:\d+μs$')));

    logger.entries.clear();
    pipeline.updateLatest([_candle(2), _candle(3)]);
    expect(logger.entries.where((entry) => entry.msg.startsWith('Merge:::')), isEmpty);

    pipeline.prependHistory([_candle(0), _candle(1)]);
    merge = logger.entries.singleWhere((entry) => entry.msg.startsWith('Merge:::'));
    expect(merge.msg, contains('kind:prependHistory'));
  });

  testWidgets('输出指标计算耗时日志', (tester) async {
    final scene = _scene();
    final logger = _RecordingLogger();
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      logger: logger,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);

    final compute = logger.entries.singleWhere((entry) => entry.msg.startsWith('Compute:::'));
    expect(compute.level, FlexiLogLevel.debug);
    expect(compute.tag, 'KlineDataPipeline');
    expect(compute.msg, contains('key:${scene.data.key} dirty:'));
    expect(compute.msg, contains('requested:0 calculators:1'));
    expect(compute.msg, matches(RegExp(r'spent:\d+μs$')));
  });

  testWidgets('零 Calculator 时不输出指标计算日志', (tester) async {
    final manager = IndicatorPaintObjectManager(
      configuration: FakeFlexiKlineConfiguration(),
    );
    manager.mountIndicators(
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: const [],
      subIndicators: const [],
      context: FakePaintContext(),
    );
    final data = KlineData(_spec);
    final logger = _RecordingLogger();
    addTearDown(data.dispose);
    addTearDown(manager.dispose);
    final pipeline = KlineDataPipeline(
      data,
      manager,
      logger: logger,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();

    expect(logger.entries.where((entry) => entry.msg.startsWith('Compute:::')), isEmpty);
  });

  testWidgets('同时间戳 latest 立即合并但等到 500ms 节拍才计算', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
      elapsed: () => elapsed,
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    scene.calculator.computeCount = 0;

    pipeline.updateLatest([_candle(2)]);

    expect(scene.data.list.map((item) => item.ts), [1, 2]);
    expect(scene.calculator.computeCount, 0);
    elapsed = const Duration(milliseconds: 499);
    await tester.pump(elapsed);
    expect(scene.calculator.computeCount, 0);
    elapsed = const Duration(milliseconds: 500);
    await tester.pump(const Duration(milliseconds: 1));
    expect(scene.calculator.computeCount, 1);
  });
  testWidgets('isIdle 在 latest 已合并、节拍计算前为 false, 算完后恢复 true', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
      elapsed: () => elapsed,
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    expect(pipeline.isIdle, isTrue, reason: 'replace 同步合并并立即计算');

    pipeline.updateLatest([_candle(2)]);
    expect(scene.data.list.map((item) => item.ts), [1, 2]);
    expect(pipeline.isIdle, isFalse, reason: '已合并但待节拍计算');

    elapsed = const Duration(milliseconds: 500);
    await tester.pump(const Duration(milliseconds: 500));
    expect(pipeline.isIdle, isTrue);
  });

  testWidgets('新时间戳 latest 合并后立即计算一次', (tester) async {
    final scene = _scene();
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    scene.calculator.computeCount = 0;

    pipeline.updateLatest([_candle(2), _candle(3)]);

    expect(scene.data.list.map((item) => item.ts), [1, 2, 3]);
    expect(scene.calculator.computeCount, 1);
    expect(scene.calculator.lastReset, isFalse);
    // 最新端更新只弄脏尾段: [1, 3) 覆盖 ts=2 并追加 ts=3, 终点等于数据长度.
    expect(scene.calculator.lastRange, (range: const Range(1, 3), length: 3));
  });

  testWidgets('history 合并后立即计算，不等待下一节拍', (tester) async {
    final scene = _scene();
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    await tester.pump();
    scene.calculator.computeCount = 0;

    pipeline.prependHistory([_candle(0), _candle(1)]);
    await tester.pump();

    expect(scene.data.list.map((item) => item.ts), [0, 1, 2]);
    expect(scene.calculator.computeCount, 1);
  });

  testWidgets('合并跨过节拍时，合并完成后立即计算', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    var crossTick = false;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      elapsed: () => elapsed,
      onCandlesMerged: ({required replace}) {
        if (crossTick) elapsed = const Duration(milliseconds: 600);
      },
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    scene.calculator.computeCount = 0;

    crossTick = true;
    pipeline.updateLatest([_candle(2), _candle(3)]);

    expect(scene.data.list.map((item) => item.ts), [1, 2, 3]);
    expect(scene.calculator.computeCount, 1);
  });

  testWidgets('计算跨过下一节拍时丢弃该拍，并先合并期间到达的数据', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    late final KlineDataPipeline pipeline;
    pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      elapsed: () => elapsed,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    scene.calculator.computeCount = 0;
    scene.calculator.indicator.onCompute = () {
      scene.calculator.indicator.onCompute = null;
      elapsed = const Duration(milliseconds: 1200);
      pipeline.updateLatest([_candle(3), _candle(4)]);
    };

    pipeline.updateLatest([_candle(2)]);
    elapsed = const Duration(milliseconds: 500);
    await tester.pump(elapsed);

    expect(scene.data.list.map((item) => item.ts), [1, 2, 3, 4]);
    expect(scene.calculator.computeCount, 1);
    elapsed = const Duration(milliseconds: 1499);
    await tester.pump(const Duration(milliseconds: 299));
    expect(scene.calculator.computeCount, 1);
    elapsed = const Duration(milliseconds: 1500);
    await tester.pump(const Duration(milliseconds: 1));
    expect(scene.calculator.computeCount, 2);
  });

  testWidgets('urgent 计算失败后无后续事件也会在下一节拍恢复', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      elapsed: () => elapsed,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    scene.calculator.indicator.throwOnCompute = true;
    scene.calculator.computeCount = 0;

    expect(
      () => pipeline.recompute(scene.calculator),
      throwsStateError,
    );
    scene.calculator.indicator.throwOnCompute = false;

    elapsed = const Duration(milliseconds: 499);
    await tester.pump(elapsed);
    expect(scene.calculator.computeCount, 1);
    elapsed = const Duration(milliseconds: 500);
    await tester.pump(const Duration(milliseconds: 1));
    expect(scene.calculator.computeCount, 2);
    expect(scene.calculator.lastReset, isTrue);
  });

  testWidgets('urgent 失败后的 latest 不立即重试', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      elapsed: () => elapsed,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    scene.calculator.indicator.throwOnCompute = true;
    scene.calculator.computeCount = 0;
    expect(pipeline.invalidateAll, throwsStateError);
    scene.calculator.indicator.throwOnCompute = false;

    pipeline.updateLatest([_candle(2), _candle(3)]);

    expect(scene.data.list.map((item) => item.ts), [1, 2, 3]);
    expect(scene.calculator.computeCount, 1);
    elapsed = const Duration(milliseconds: 500);
    await tester.pump(elapsed);
    expect(scene.calculator.computeCount, 2);
    expect(scene.calculator.lastReset, isTrue);
  });

  testWidgets('增量计算失败后的新 latest 等到下一节拍重试', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    final pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      elapsed: () => elapsed,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    scene.calculator.computeCount = 0;
    scene.calculator.indicator.throwOnCompute = true;

    expect(
      () => pipeline.updateLatest([_candle(2), _candle(3)]),
      throwsStateError,
    );
    scene.calculator.indicator.throwOnCompute = false;

    pipeline.updateLatest([_candle(3), _candle(4)]);

    expect(scene.data.list.map((item) => item.ts), [1, 2, 3, 4]);
    expect(scene.calculator.computeCount, 1);
    elapsed = const Duration(milliseconds: 500);
    await tester.pump(const Duration(milliseconds: 500));
    expect(scene.calculator.computeCount, 2);
  });

  testWidgets('失败请求对应的 Calculator 被删除并复用 slot 后不再执行', (tester) async {
    const oldKey = ComputedIndicatorKey('old');
    const newKey = ComputedIndicatorKey('new');
    final context = FakePaintContext();
    final oldIndicator = SpyComputedIndicator(key: oldKey, log: LifecycleLog());
    final manager = IndicatorPaintObjectManager(
      configuration: FakeFlexiKlineConfiguration(mainChildren: {oldKey}),
    );
    manager.mountIndicators(
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: [oldIndicator],
      subIndicators: const [],
      context: context,
    );
    final data = KlineData(_spec);
    addTearDown(data.dispose);
    addTearDown(manager.dispose);
    final pipeline = KlineDataPipeline(
      data,
      manager,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2)]);
    final oldCalculator = manager.getCalculator(oldKey)! as SpyComputedCalculator;
    oldIndicator.throwOnCompute = true;
    oldCalculator.computeCount = 0;
    expect(() => pipeline.recompute(oldCalculator), throwsStateError);
    final oldSlot = oldCalculator.dataIndex;

    final newIndicator = SpyComputedIndicator(
      key: newKey,
      log: LifecycleLog(),
      autoActivate: true,
    );
    final changes = manager.updateIndicators(
      context: context,
      oldCandle: TestCandleIndicator(),
      newCandle: TestCandleIndicator(),
      oldTime: TestTimeIndicator(),
      newTime: TestTimeIndicator(),
      oldMainIndicators: [oldIndicator],
      newMainIndicators: [newIndicator],
      oldSubIndicators: const [],
      newSubIndicators: const [],
    );
    for (final key in changes.main) {
      manager.addMainPaintObject(key, context);
    }
    final newCalculator = manager.getCalculator(newKey)! as SpyComputedCalculator;
    expect(newCalculator.dataIndex, oldSlot);

    expect(pipeline.invalidateAll, returnsNormally);

    expect(newCalculator.computeCount, 1);
    expect(oldCalculator.computeCount, 1);
  });

  testWidgets('urgent 计算跨过已安排节拍时取消旧节拍', (tester) async {
    final scene = _scene();
    var elapsed = Duration.zero;
    addTearDown(scene.data.dispose);
    addTearDown(scene.manager.dispose);
    late final KlineDataPipeline pipeline;
    pipeline = KlineDataPipeline(
      scene.data,
      scene.manager,
      elapsed: () => elapsed,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(2), _candle(3)]);
    scene.calculator.computeCount = 0;

    pipeline.updateLatest([_candle(3)]);
    scene.calculator.indicator.onCompute = () {
      scene.calculator.indicator.onCompute = null;
      elapsed = const Duration(milliseconds: 1200);
      pipeline.updateLatest([_candle(4), _candle(5)]);
    };
    pipeline.prependHistory([_candle(1), _candle(2)]);

    expect(scene.data.list.map((item) => item.ts), [1, 2, 3, 4, 5]);
    expect(scene.calculator.computeCount, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(scene.calculator.computeCount, 2);
  });

  testWidgets('新 latest 追加到尾部后，先前被弄脏的蜡烛仍参与计算', (tester) async {
    const key = ComputedIndicatorKey('shift');
    final ranges = <Range>[];
    final manager = IndicatorPaintObjectManager(
      configuration: FakeFlexiKlineConfiguration(mainChildren: {key}),
    );
    manager.mountIndicators(
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: [_RangeRecordingIndicator(key: key, log: LifecycleLog(), ranges: ranges)],
      subIndicators: const [],
      context: FakePaintContext(),
    );
    final data = KlineData(_spec);
    addTearDown(data.dispose);
    addTearDown(manager.dispose);
    // 冻结时钟，使 500ms 节拍不触发，隔离出「脏区挂起未算」的窗口。
    final pipeline = KlineDataPipeline(
      data,
      manager,
      elapsed: () => Duration.zero,
      onCandlesMerged: ({required replace}) {},
      onComputed: () {},
    );
    addTearDown(pipeline.dispose);
    pipeline.start();
    pipeline.replace([_candle(1), _candle(2), _candle(3)]);
    ranges.clear();

    // 同 ts 更新尾部：不触发 urgent，脏区 Range(2,3) 挂起，尚未计算。
    pipeline.updateLatest([_candle(3)]);
    expect(ranges, isEmpty);

    // 新 ts 追加：ts=4 追加到 index 3，ts=3 仍在 index 2（尾部追加不移动已有下标），urgent 立即计算。
    pipeline.updateLatest([_candle(4)]);

    expect(ranges.any((r) => r.start <= 2 && 2 < r.end), isTrue, reason: '被弄脏的尾部蜡烛(index 2)必须被重算，ranges=$ranges');
  });

  /// 增量区间契约：非全量时 `range.end == data.length`，起点是累计脏区的最小起点；
  /// 期间有过 prependHistory / replace 则必须全量。
  /// updateLatest 弄脏的是首个 `ts >= batch.first` 的下标到末尾，期望按合并前的数据推出。
  group('incremental dirty range', () {
    testWidgets('随机合并序列下，每次计算的区间都等于累计脏区', tags: 'property', (tester) async {
      const runs = 30;
      const opsPerRun = 40;
      for (var run = 0; run < runs; run++) {
        final rng = Random(500 + run);
        const key = ComputedIndicatorKey('dirty');
        final calls = <({Range range, bool reset, int length})>[];
        final manager = IndicatorPaintObjectManager(
          configuration: FakeFlexiKlineConfiguration(mainChildren: {key}),
        );
        manager.mountIndicators(
          candle: TestCandleIndicator(),
          time: TestTimeIndicator(),
          mainIndicators: [_CallRecordingIndicator(key: key, log: LifecycleLog(), calls: calls)],
          subIndicators: const [],
          context: FakePaintContext(),
        );
        final data = KlineData(_spec);
        var elapsed = Duration.zero;
        final pipeline = KlineDataPipeline(
          data,
          manager,
          elapsed: () => elapsed,
          onCandlesMerged: ({required replace}) {},
          onComputed: () {},
        );
        pipeline.start();
        pipeline.replace([for (var ts = 100; ts < 120; ts++) _candle(ts)]);
        calls.clear();

        var expectFull = false;
        int? expectStart;
        final log = <String>[];
        void verifyNewCalls(int before) {
          for (final call in calls.skip(before)) {
            final context = 'run#$run ops=$log call=$call';
            if (expectFull) {
              expect(call.reset, isTrue, reason: '合并过 prependHistory/replace 后必须全量. $context');
            } else {
              expect(call.reset, isFalse, reason: context);
              expect(call.range.end, call.length, reason: '增量区间必须以 data.length 收尾. $context');
              expect(call.range.start, expectStart, reason: '起点必须是累计脏区的最小起点. $context');
            }
            expectFull = false;
            expectStart = null;
          }
        }

        for (var op = 0; op < opsPerRun; op++) {
          final before = calls.length;
          final first = data.list.first.ts;
          final latest = data.list.last.ts;
          switch (rng.nextInt(5)) {
            case 0:
              log.add('same');
              expectStart = math.min(expectStart ?? data.length, data.length - 1);
              pipeline.updateLatest([_candle(latest)]);
            case 1:
              final count = 1 + rng.nextInt(3);
              log.add('new$count');
              expectStart = math.min(expectStart ?? data.length, data.length);
              pipeline.updateLatest([for (var i = 1; i <= count; i++) _candle(latest + i)]);
            case 2:
              final overlap = 1 + rng.nextInt(math.min(3, data.length));
              final count = rng.nextInt(3);
              log.add('overlap$overlap+$count');
              final batch = [for (var ts = latest - overlap + 1; ts <= latest + count; ts++) _candle(ts)];
              final tailStart = data.list.indexWhere((m) => m.ts >= batch.first.timestamp);
              expectStart = math.min(expectStart ?? data.length, tailStart);
              pipeline.updateLatest(batch);
            case 3:
              final count = 1 + rng.nextInt(5);
              log.add('prepend$count');
              expectFull = true;
              pipeline.prependHistory([for (var ts = first - count; ts < first; ts++) _candle(ts)]);
            default:
              final start = rng.nextInt(1000);
              log.add('replace');
              expectFull = true;
              pipeline.replace([for (var ts = start; ts < start + 5 + rng.nextInt(20); ts++) _candle(ts)]);
          }
          verifyNewCalls(before);
          if (rng.nextBool()) {
            final beforeTick = calls.length;
            elapsed += const Duration(milliseconds: 600);
            await tester.pump(const Duration(milliseconds: 600));
            log.add('tick');
            verifyNewCalls(beforeTick);
          }
        }
        expect(calls, isNotEmpty, reason: 'run#$run 至少要发生一次计算, 否则用例空转');
        pipeline.dispose();
        manager.dispose();
        data.dispose();
      }
    });
  });
}

/// 记录每次 compute 的区间、是否全量与当时的数据长度。
class _CallRecordingIndicator extends SpyComputedIndicator {
  _CallRecordingIndicator({required super.key, required super.log, required this.calls});

  final List<({Range range, bool reset, int length})> calls;

  @override
  IndicatorCalculator createCalculator(int dataIndex) => _CallRecordingCalculator(this, dataIndex);
}

class _CallRecordingCalculator extends IndicatorCalculator<_CallRecordingIndicator> {
  _CallRecordingCalculator(super.indicator, super.dataIndex);

  @override
  void compute(KlineData data, Range range, {bool reset = false}) {
    indicator.calls.add((range: range, reset: reset, length: data.length));
  }
}

/// 记录每次 compute 实际覆盖区间的指标，用于验证脏区索引映射。
class _RangeRecordingIndicator extends SpyComputedIndicator {
  _RangeRecordingIndicator({required super.key, required super.log, required this.ranges});

  final List<Range> ranges;

  @override
  IndicatorCalculator createCalculator(int dataIndex) => _RangeRecordingCalculator(this, dataIndex);
}

class _RangeRecordingCalculator extends IndicatorCalculator<_RangeRecordingIndicator> {
  _RangeRecordingCalculator(super.indicator, super.dataIndex);

  @override
  void compute(KlineData data, Range range, {bool reset = false}) {
    indicator.ranges.add(reset ? data.computableRange : range);
  }
}

final class _RecordingLogger implements IFlexiLogger {
  final entries = <({FlexiLogLevel level, String tag, String msg})>[];

  @override
  bool get debugMode => true;

  @override
  void log(
    FlexiLogLevel level,
    String tag,
    String msg, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    entries.add((level: level, tag: tag, msg: msg));
  }
}
