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
    scene.data.replace([_candle(2), _candle(1)], slotCount: scene.manager.computedDataCapacity);
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
    final batch = [_candle(2), _candle(1)];

    pipeline.replace(batch);
    batch
      ..clear()
      ..add(_candle(99));
    pipeline.start();

    expect(scene.data.list.map((item) => item.ts), [2, 1]);
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
    pipeline.replace([_candle(2), _candle(1)]);
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

    pipeline.replace([_candle(2), _candle(1)]);

    var merge = logger.entries.singleWhere((entry) => entry.msg.startsWith('Merge:::'));
    expect(merge.level, FlexiLogLevel.debug);
    expect(merge.tag, 'KlineDataPipeline');
    expect(merge.msg, contains('kind:replace key:${scene.data.key} candles:2 range:'));
    expect(merge.msg, matches(RegExp(r'spent:\d+μs$')));

    logger.entries.clear();
    pipeline.updateLatest([_candle(3), _candle(2)]);
    expect(logger.entries.where((entry) => entry.msg.startsWith('Merge:::')), isEmpty);

    pipeline.appendHistory([_candle(1), _candle(0)]);
    merge = logger.entries.singleWhere((entry) => entry.msg.startsWith('Merge:::'));
    expect(merge.msg, contains('kind:appendHistory'));
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
    pipeline.replace([_candle(2), _candle(1)]);

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
    pipeline.replace([_candle(2), _candle(1)]);
    scene.calculator.computeCount = 0;

    pipeline.updateLatest([_candle(2)]);

    expect(scene.data.list.map((item) => item.ts), [2, 1]);
    expect(scene.calculator.computeCount, 0);
    elapsed = const Duration(milliseconds: 499);
    await tester.pump(elapsed);
    expect(scene.calculator.computeCount, 0);
    elapsed = const Duration(milliseconds: 500);
    await tester.pump(const Duration(milliseconds: 1));
    expect(scene.calculator.computeCount, 1);
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
    pipeline.replace([_candle(2), _candle(1)]);
    scene.calculator.computeCount = 0;

    pipeline.updateLatest([_candle(3), _candle(2)]);

    expect(scene.data.list.map((item) => item.ts), [3, 2, 1]);
    expect(scene.calculator.computeCount, 1);
    expect(scene.calculator.lastReset, isFalse);
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
    pipeline.replace([_candle(2), _candle(1)]);
    await tester.pump();
    scene.calculator.computeCount = 0;

    pipeline.appendHistory([_candle(1), _candle(0)]);
    await tester.pump();

    expect(scene.data.list.map((item) => item.ts), [2, 1, 0]);
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
    pipeline.replace([_candle(2), _candle(1)]);
    scene.calculator.computeCount = 0;

    crossTick = true;
    pipeline.updateLatest([_candle(3), _candle(2)]);

    expect(scene.data.list.map((item) => item.ts), [3, 2, 1]);
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
    pipeline.replace([_candle(2), _candle(1)]);
    scene.calculator.computeCount = 0;
    scene.calculator.indicator.onCompute = () {
      scene.calculator.indicator.onCompute = null;
      elapsed = const Duration(milliseconds: 1200);
      pipeline.updateLatest([_candle(4), _candle(3)]);
    };

    pipeline.updateLatest([_candle(2)]);
    elapsed = const Duration(milliseconds: 500);
    await tester.pump(elapsed);

    expect(scene.data.list.map((item) => item.ts), [4, 3, 2, 1]);
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
    pipeline.replace([_candle(2), _candle(1)]);
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
    pipeline.replace([_candle(2), _candle(1)]);
    scene.calculator.indicator.throwOnCompute = true;
    scene.calculator.computeCount = 0;
    expect(pipeline.invalidateAll, throwsStateError);
    scene.calculator.indicator.throwOnCompute = false;

    pipeline.updateLatest([_candle(3), _candle(2)]);

    expect(scene.data.list.map((item) => item.ts), [3, 2, 1]);
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
    pipeline.replace([_candle(2), _candle(1)]);
    scene.calculator.computeCount = 0;
    scene.calculator.indicator.throwOnCompute = true;

    expect(
      () => pipeline.updateLatest([_candle(3), _candle(2)]),
      throwsStateError,
    );
    scene.calculator.indicator.throwOnCompute = false;

    pipeline.updateLatest([_candle(4), _candle(3)]);

    expect(scene.data.list.map((item) => item.ts), [4, 3, 2, 1]);
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
    pipeline.replace([_candle(2), _candle(1)]);
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
    pipeline.replace([_candle(3), _candle(2)]);
    scene.calculator.computeCount = 0;

    pipeline.updateLatest([_candle(3)]);
    scene.calculator.indicator.onCompute = () {
      scene.calculator.indicator.onCompute = null;
      elapsed = const Duration(milliseconds: 1200);
      pipeline.updateLatest([_candle(5), _candle(4)]);
    };
    pipeline.appendHistory([_candle(2), _candle(1)]);

    expect(scene.data.list.map((item) => item.ts), [5, 4, 3, 2, 1]);
    expect(scene.calculator.computeCount, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(scene.calculator.computeCount, 2);
  });

  testWidgets('新 latest 插入后累积脏区随索引后移，被弄脏的蜡烛仍参与计算', (tester) async {
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
    pipeline.replace([_candle(3), _candle(2), _candle(1)]);
    ranges.clear();

    // 同 ts 更新头部：不触发 urgent，脏区 Range(0,1) 挂起，尚未计算。
    pipeline.updateLatest([_candle(3)]);
    expect(ranges, isEmpty);

    // 新 ts 插入：ts=3 蜡烛从 index 0 移到 index 1，urgent 立即计算。
    pipeline.updateLatest([_candle(4)]);

    expect(ranges.any((r) => r.start <= 1 && 1 < r.end), isTrue, reason: '被弄脏并后移到 index 1 的蜡烛必须被重算，ranges=$ranges');
  });
}

/// 记录每次 compute 实际覆盖区间的指标，用于验证脏区索引平移。
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
