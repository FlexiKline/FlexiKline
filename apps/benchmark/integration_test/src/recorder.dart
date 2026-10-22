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

import 'dart:io' show ProcessInfo;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scenario.dart';

/// 跑一个窗口并收集原始 [FrameTiming], 返回写进 reportData 的数据, 时间单位 us。
///
/// `rss` / `maxRss` 为窗口结束时的进程常驻内存与峰值(字节)。
Future<Map<String, Object>> recordWindow(
  ScenarioContext ctx,
  Future<void> Function() action,
) async {
  // 引擎可能按秒批量上报 FrameTiming: 先等旧的报完, 动作结束后等新的报完(同 watchPerformance)。
  await Future<void>.delayed(const Duration(seconds: 2));
  final timings = <FrameTiming>[];
  final TimingsCallback collect = timings.addAll;
  SchedulerBinding.instance.addTimingsCallback(collect);
  ctx.startWindow();
  await action();
  for (var i = 0; i < 10 && timings.isEmpty; i++) {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  await Future<void>.delayed(const Duration(seconds: 1));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  // 没有帧的窗口不能静默出数: 失败后 driver 不写 frames.json, 编排脚本把这次运行记为失败。
  expect(timings, isNotEmpty, reason: '前置：窗口内要收到帧时间');
  return {
    'frames': timings.length,
    'build': [for (final t in timings) t.buildDuration.inMicroseconds],
    'raster': [for (final t in timings) t.rasterDuration.inMicroseconds],
    if (ctx.ops.isNotEmpty) 'ops': [...ctx.ops],
    'rss': ProcessInfo.currentRss,
    'maxRss': ProcessInfo.maxRss,
  };
}
