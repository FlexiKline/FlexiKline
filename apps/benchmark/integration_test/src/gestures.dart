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

/// 按刷新率出事件的手势原语。
///
/// 速度一律按「像素 / 秒」给: 不同刷新率下手指速度相同, 只是事件更密。
library;

import 'package:flutter_test/flutter_test.dart';

import 'scenario.dart';

extension BenchGestures on ScenarioContext {
  /// 一笔 [duration] 的匀速拖动。
  Future<void> drag(
    Offset from,
    Offset to, {
    Duration duration = const Duration(seconds: 1),
  }) => tester.timedDragFrom(from, to - from, duration, frequency: refreshRate);

  /// 按住 [gesture] 以 [velocity](像素 / 秒)逐帧移动 [duration]。
  Future<void> moveFor(TestGesture gesture, Offset velocity, Duration duration) async {
    final frames = (duration.inMicroseconds * refreshRate / 1e6).round();
    final step = velocity / refreshRate;
    for (var i = 0; i < frames; i++) {
      await gesture.moveBy(step);
      await nextFrame();
    }
  }

  /// 双指以 [center] 为中点横向开合: 指间距在 [near] 与 [far] 之间往返一次, 单程 [half]。
  ///
  /// [onFrame] 每帧回调一次, 供驱动记录前置断言需要的状态。
  Future<void> pinch(
    Offset center, {
    required double near,
    required double far,
    Duration half = const Duration(milliseconds: 500),
    void Function()? onFrame,
  }) async {
    final a = await tester.startGesture(center - Offset(near / 2, 0), pointer: 11);
    final b = await tester.startGesture(center + Offset(near / 2, 0), pointer: 12);
    final frames = (half.inMicroseconds * refreshRate / 1e6).round();
    for (final sign in const [1.0, -1.0]) {
      final step = sign * (far - near) / 2 / frames;
      for (var i = 0; i < frames; i++) {
        await a.moveBy(Offset(-step, 0));
        await b.moveBy(Offset(step, 0));
        await nextFrame();
        onFrame?.call();
      }
    }
    await a.up();
    await b.up();
    await nextFrame();
  }
}
