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

/// 场景的定义与驱动上下文。
///
/// 场景名 `<动作>/<装配>`, 是结果文件与对照表的键: 新增只追加, 已有名称不改。
/// 每个驱动必须带「操作生效」的前置断言(拖动后偏移变化、捏合后蜡烛宽变化等):
/// 手势没生效时帧很空, 不拦住就会产出一组看起来很快的假数据。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_benchmark/src/chart.dart';
import 'package:flexi_kline_benchmark/src/constants.dart';
import 'package:flexi_kline_benchmark/src/preset.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' show StatefulElement;
import 'package:flutter_test/flutter_test.dart';

import 'compat.dart';

/// 每个计时窗口的时长。
const windowDuration = Duration(seconds: int.fromEnvironment('WINDOW_SECONDS', defaultValue: 6));

/// 一个场景: [drive] 在窗口时长内反复执行操作; [prepare] 在每个窗口开始前执行, 它产生的帧不计入。
final class Scenario {
  const Scenario(
    this.preset,
    this.drive, {
    this.features = const {},
    this.candles = benchCandleCount,
    this.prepare,
  });

  final BenchPreset preset;
  final Set<BenchFeature> features;
  final int candles;
  final Future<void> Function(ScenarioContext ctx) drive;
  final Future<void> Function(ScenarioContext ctx)? prepare;
}

/// 驱动需要的全部上下文; 需要新东西时加字段, 不改驱动签名。
final class ScenarioContext {
  ScenarioContext(this.tester, this.refreshRate);

  final WidgetTester tester;

  /// 实测刷新率; 手势按它出事件, 高刷下每个 vsync 都有输入。
  final double refreshRate;

  /// 当前窗口里每次操作的耗时(us), 含义由驱动定义(见各驱动注释)。
  final ops = <int>[];

  final _window = Stopwatch();
  var _limit = windowDuration;

  /// 开始一段驱动: 清空操作耗时并计时; 预热用更短的 [duration]。
  void startWindow([Duration duration = windowDuration]) {
    ops.clear();
    _limit = duration;
    _window
      ..reset()
      ..start();
  }

  /// 时长未到; 驱动每完成一次完整操作检查一次, 所以可能略超时长。
  bool get running => _window.elapsed < _limit;

  /// startup 会换掉图表, 每次都重新取。
  ///
  /// 不用 `tester.state`: 它是受 guard 的 API, 在未完成的手势(如 history 拖动中途触发操作)期间调用会冲突。
  BenchChartState get chart => (find.byType(BenchChart).evaluate().single as StatefulElement).state as BenchChartState;

  FlexiKlineController get controller => chart.controller;

  /// 图表内坐标转成屏幕坐标。
  Offset toGlobal(Offset local) => tester.getRect(find.byType(BenchChart)).topLeft + local;

  /// 主图内一点(屏幕坐标); [fx] / [fy] 为 0..1 的比例。
  Offset mainPoint(double fx, [double fy = 0.5]) {
    final main = controller.mainRect;
    return toGlobal(Offset(main.left + main.width * fx, main.top + main.height * fy));
  }

  /// 等下一帧画完; 没有待画的帧时会排一帧, 所以逐帧驱动的循环与 vsync 同步。
  Future<void> nextFrame() => SchedulerBinding.instance.endOfFrame;

  /// 等数据变更完全生效(合并与计算都完成)后的那一帧画完, 最多 120 帧。
  ///
  /// 可在手势进行中调用(history 边拖边加载), 所以只用不受 test guard 约束的 API(`expectSync`)。
  Future<void> settle() async {
    await nextFrame();
    for (var i = 0; i < 120 && !isDataSettled(controller); i++) {
      await nextFrame();
    }
    expectSync(isDataSettled(controller), isTrue, reason: '前置：数据流水线要在 120 帧内完成');
  }

  /// 记一次操作耗时: [op] 开始到 [settle] 完成。
  Future<void> timeOp(void Function() op) async {
    final watch = Stopwatch()..start();
    op();
    await settle();
    ops.add(watch.elapsedMicroseconds);
  }
}
