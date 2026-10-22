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
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scenario.dart';

/// 一个窗口的首末帧号与窗口结束时记下的数据。
typedef _Window = ({int first, int last, List<int> ops, int rss, int maxRss});

/// 连续跑 [count] 个计时窗口并收集原始 [FrameTiming], 返回每个窗口写进 reportData 的数据, 时间单位 us。
///
/// 整个场景只挂一次回调, 窗口之间不等待: 每个窗口记下首末帧的引擎帧号, 按 [FrameTiming.frameNumber] 分帧。
/// 帧号与 Dart 侧 `frameData.frameNumber` 是同一个引擎计数(2026-10-22 已在 iOS、Android 真机核对), 不依赖时钟,
/// [prepare] 与驱动结束后的空帧落在窗口外。`rss` / `maxRss` 为窗口结束时的进程常驻内存与峰值(字节)。
Future<List<Map<String, Object>>> recordWindows(
  ScenarioContext ctx,
  int count,
  Future<void> Function() prepare,
  Future<void> Function() drive,
) async {
  final timings = <FrameTiming>[];
  var reported = -1;
  void collect(List<FrameTiming> batch) {
    timings.addAll(batch);
    for (final t in batch) {
      if (t.frameNumber > reported) reported = t.frameNumber;
    }
  }

  int frameNumber() => PlatformDispatcher.instance.frameData.frameNumber;
  SchedulerBinding.instance.addTimingsCallback(collect);
  final windows = <_Window>[];
  for (var w = 0; w < count; w++) {
    await prepare();
    // prepare 可能改数据(history 重置), 等它的合并与计算全部完成, 这些帧不计入窗口。
    await ctx.settle();
    final first = frameNumber() + 1;
    ctx.startWindow();
    await drive();
    windows.add((
      first: first,
      last: frameNumber(),
      ops: [...ctx.ops],
      rss: ProcessInfo.currentRss,
      maxRss: ProcessInfo.maxRss,
    ));
  }
  // 引擎按批上报 FrameTiming: 等到最后一个窗口的末帧报上来, 最多 10s。
  for (var i = 0; i < 100 && reported < windows.last.last; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  SchedulerBinding.instance.removeTimingsCallback(collect);

  Map<String, Object> report(_Window w) {
    final frames = [
      for (final t in timings)
        if (t.frameNumber >= w.first && t.frameNumber <= w.last) t,
    ];
    // 没有帧的窗口不能静默出数: 失败后 driver 不写 frames.json, 编排脚本把这次运行记为失败。
    expect(frames, isNotEmpty, reason: '前置：窗口内要收到帧时间');
    return {
      'frames': frames.length,
      'build': [for (final t in frames) t.buildDuration.inMicroseconds],
      'raster': [for (final t in frames) t.rasterDuration.inMicroseconds],
      if (w.ops.isNotEmpty) 'ops': w.ops,
      'rss': w.rss,
      'maxRss': w.maxRss,
    };
  }

  return [for (final w in windows) report(w)];
}
