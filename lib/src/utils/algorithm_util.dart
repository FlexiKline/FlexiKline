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

/// 按比例压缩singal手势数据
///
/// 参考[gesture_test.dart]测试数据.
/// y = Fn(x, k);
double? scaledSingal(double x, double k, {double kMax = 30}) {
  double sign = x.sign;
  x = x.abs();
  if (x < 1) {
    debugPrint('zp::: scaledSingal x must be >= 1');
    return null;
  }

  // 归一化 k
  double kNorm = (k - 1) / (kMax - 1);

  // 使用对数函数处理 x，并结合 Sigmoid 函数
  double y = 1 / (1 + math.exp(-kNorm * (math.log(x) - 1)));

  return y * sign;
}

/// 缩放减速
/// 主要用于触摸设备上的缩放操作.
double scaledDecelerate(double scale) {
  if (scale == 1) return scale;
  return math.log(scale) + 1;
}

/// 根据[velocity]计算惯性平移的时间
///
/// 确认继续平移时间 (利用log指数函数特点: 随着自变量velocity的增大，函数值的增长速度逐渐减慢)
/// 测试当限定参数[maxDuration]等于1000(1秒时), [velocity]带入后结果变化为:
/// 100000 > 1151.29; 10000 > 921.03; 9000 > 910.49; 5000 > 851.71; 2000 > 760.09; 800 > 668.46; 100 > 460.51
int calcuInertialPanDuration(double velocity, {required int maxDuration}) {
  final v = math.max(1, velocity.abs());
  if (v == 1) return 0;
  return (math.log(v) * maxDuration / 10).round().clamp(0, maxDuration);
}
