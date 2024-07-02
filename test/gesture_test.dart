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

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

/// 当用户松手时速度比较大，算出来这个衰减率会比较接近于0，衰减得比较快，因为需要很强的衰减才能让滚动停止下来；
/// 反之速度比较小，这个衰减率就会比较接近于1，因为减太快的话还没滚动到指定位置就停了。
void main() {
  late final TestVSync vsync;
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    vsync = const TestVSync();
  });

  test('onPointerSignal scrollDelta convert to GestureData.scale', () {
    double scaledSingal(double x, double k, {double kMax = 30}) {
      if (x < 1) {
        throw ArgumentError('x must be >= 1');
      }

      // 归一化 k
      double kNorm = (k - 1) / (kMax - 1);

      // 使用对数函数处理 x，并结合 Sigmoid 函数
      double y = 1 / (1 + math.exp(-kNorm * (math.log(x) - 1)));

      return y * 10;
    }

    List<double> xValues = [1, 4, 8, 10, 50, 100, 200, 300, 400, 500];
    List<double> kValues = [1, 2, 3, 4, 5, 6, 7, 9, 10];

    for (double x in xValues) {
      for (double k in kValues) {
        double y = scaledSingal(x, k);
        print('x: $x, k: $k, y: $y');
      }
    }
  });

  test('Animation+Curve+Tween', () {
    // 动画控制器: 负责整个动画的行进过程，即控制动画的开始、结束、循环，以及时长
    final controller = AnimationController(
      vsync: vsync,
      value: 0,
      duration: const Duration(seconds: 1),
    );

    // Animation是具有状态的对象，它保存了当前的映射值和当前的运行状态（动画完成、中断）等
    //  Curves: 减速动画> 负责动画的变化速率，即作用在Tween的中间值上的函数f(x)，避免生硬的动画过程
    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.decelerate,
    );
    curvedAnimation.addListener(() {
      debugPrint('zp: curvedAnimation:${curvedAnimation.value}');
    });

    // Tween与Animation不同，Tween是一个无状态的对象，它只包含begin和end值。
    // 负责起始值到目标值的数据生成，可以是0-1，也可以是1-100，也可以是Red-Blue，总之就是数据的变化
    final tweenAnimation = Tween(begin: 0, end: 100).animate(controller);
    tweenAnimation.addListener(() {
      debugPrint('zp: curvedAnimation:${tweenAnimation.value}');
    });

    controller.addListener(() {
      debugPrint('zp: controller:${controller.value}');
    });

    debugPrint('forward');
    controller.forward();
  });

  test('FrictionSimulation', () {
    // 创建一个 FrictionSimulation
    final double position = 0.0;
    final double velocity = 900 / 100; // 初始速度
    // final double drag = 0.00135; // 摩擦力

    final simulation = FrictionSimulation.through(
      0, // 初始位置
      500, // 结束位置
      velocity,
      1,
    );

// 模拟运动，获取不同时间点的位置
    double time = 0.0; // 时间
    double nextPosition = 0.0;
    while (!simulation.isDone(time)) {
      // 模拟 1000ms 的运动过程
      final newVal = simulation.x(time); // 获取时间点 time 的位置
      final diff = newVal - nextPosition;
      nextPosition = newVal;
      print('Position at time $time: $nextPosition, diff:$diff');

      time += 16; // 增加时间步长
    }
  });
}
