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

/// 数据与装配变化类场景: 推送、切换、加载历史、增删指标、冷启动、大数据量。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_benchmark/src/app.dart';
import 'package:flexi_kline_benchmark/src/constants.dart';
import 'package:flexi_kline_benchmark/src/data/candles.dart';
import 'package:flexi_kline_benchmark/src/preset.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../gestures.dart';
import '../scenario.dart';
import 'interaction.dart' show pan;

final dataScenarios = <String, Scenario>{
  // 只跑 full: full 的推送与冷启动包含 base 的全部工作。
  'realtime/full': const Scenario(BenchPreset.full, _realtime),
  'startup/full': const Scenario(BenchPreset.full, _startup),
  'switch/full': const Scenario(BenchPreset.full, _switch),
  'history/full': const Scenario(BenchPreset.full, _history, prepare: _resetData),
  'indicators/full': const Scenario(BenchPreset.full, _indicators),
  'memory/full': const Scenario(BenchPreset.full, pan, candles: 20000),
};

/// 视图静止, 每 100ms 推一次最新蜡烛。
Future<void> _realtime(ScenarioContext ctx) async {
  final controller = ctx.controller;
  var tick = 0;
  final length = controller.klineData.length;
  while (ctx.running) {
    controller.updateLatestKlineData(benchSpec, [benchTick(controller.klineData.latest!, tick++)]);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(controller.klineData.length, greaterThan(length), reason: '前置：推送要合并出新蜡烛');
}

/// 反复冷启动图表: 卸掉旧图表, 再挂一个全新的(新 controller、新数据)。
///
/// 操作耗时 = `pumpWidget` 到画出蜡烛的那一帧结束; 帧统计里也含卸载那一帧。
Future<void> _startup(ScenarioContext ctx) async {
  final widget = ctx.chart.widget;
  while (ctx.running) {
    await ctx.tester.pumpWidget(const SizedBox());
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final watch = Stopwatch()..start();
    await ctx.tester.pumpWidget(
      BenchApp(
        key: UniqueKey(),
        preset: widget.preset,
        features: widget.features,
        candles: widget.candles,
      ),
    );
    final controller = ctx.controller;
    bool painted() => controller.isMounted && controller.klineData.isNotEmpty;
    for (var i = 0; i < 10 && !painted(); i++) {
      await ctx.nextFrame();
    }
    expect(painted(), isTrue, reason: '前置：启动后要挂载并合并出蜡烛');
    // 等合并与计算全部生效(isDataSettled), 再多一帧确保蜡烛已画出。
    await ctx.settle();
    ctx.ops.add(watch.elapsedMicroseconds);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

/// 在两个品种之间来回切换, 每次整段替换数据并重算全部指标, 之后静置 1s。
///
/// 操作耗时 = 切换调用到数据完全生效后的那一帧结束(见 [ScenarioContext.timeOp])。
Future<void> _switch(ScenarioContext ctx) async {
  final controller = ctx.controller;
  final lists = {
    benchSpec: benchCandles(),
    benchAltSpec: benchCandles(count: benchAltCandleCount, offset: 100000),
  };
  var next = controller.klineDataKey == benchSpec.key ? benchAltSpec : benchSpec;
  while (ctx.running) {
    await ctx.timeOp(() {
      controller.switchKlineData(next);
      controller.replaceKlineData(next, lists[next]!);
    });
    expect(controller.klineDataKey, next.key, reason: '前置：切换后当前数据要是目标品种');
    expect(controller.klineData.length, lists[next]!.length, reason: '前置：切换后要替换成目标数据');
    await Future<void>.delayed(const Duration(seconds: 1));
    next = next == benchSpec ? benchAltSpec : benchSpec;
  }
}

/// 每个窗口回到初始数据, 否则加载历史让数据量在窗口间持续增长。
Future<void> _resetData(ScenarioContext ctx) async => ctx.controller.replaceKlineData(benchSpec, benchCandles());

/// 左右往返拖动; 朝历史方向的那一笔拖到 300ms 时追加 500 根更早的蜡烛, 模拟边拖边加载更多。
///
/// 操作耗时与 switch 同口径: 追加调用到数据完全生效后的那一帧结束(见 [ScenarioContext.timeOp]);
/// 纯合并与计算的开销由 L1 的 `merge/append-history` 与 `precompute` 覆盖。
Future<void> _history(ScenarioContext ctx) async {
  final controller = ctx.controller;
  var toHistory = true;
  while (ctx.running) {
    final stroke = ctx.drag(ctx.mainPoint(toHistory ? 0.2 : 0.8), ctx.mainPoint(toHistory ? 0.8 : 0.2));
    if (toHistory) {
      final length = controller.klineData.length;
      final batch = benchCandles(count: 500, offset: length);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await ctx.timeOp(() => controller.appendHistoryKlineData(benchSpec, batch));
      await stroke;
      expect(controller.klineData.length, length + batch.length, reason: '前置：加载历史要合并出新蜡烛');
    } else {
      await stroke;
    }
    toHistory = !toHistory;
  }
}

/// 来回显示 / 隐藏全部副区指标(与用户从指标菜单开关一致), 每次之后静置 1s。
///
/// 操作耗时 = 开关调用到数据完全生效后的那一帧结束, 显示时含新增指标的整段计算(见 [ScenarioContext.timeOp])。
Future<void> _indicators(ScenarioContext ctx) async {
  final controller = ctx.controller;
  final keys = ctx.chart.subKeys;
  while (ctx.running) {
    final shown = controller.getSubIndicatorHeights().isNotEmpty;
    await ctx.timeOp(() {
      for (final key in keys) {
        shown ? controller.hideSubIndicator(key) : controller.showSubIndicator(key);
      }
    });
    expect(controller.getSubIndicatorHeights().isNotEmpty, isNot(shown), reason: '前置：开关要改变副区指标显示');
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
