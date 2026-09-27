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

/// Slot 操作模型与随机生成器
///
/// 用于 [IndicatorPaintObjectManager] 的 slot 管理属性测试。
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';

// ---------------------------------------------------------------------------
// 操作模型：Register 或 Recycle
// ---------------------------------------------------------------------------

/// Slot 操作的 sealed 类型
sealed class TestSlotOp {
  const TestSlotOp(this.key);
  final ComputedIndicatorKey key;
}

/// 注册操作
class TestRegisterOp extends TestSlotOp {
  const TestRegisterOp(super.key);
  @override
  String toString() => 'Register(${key.id})';
}

/// 回收操作
class TestRecycleOp extends TestSlotOp {
  const TestRecycleOp(super.key);
  @override
  String toString() => 'Recycle(${key.id})';
}

// ---------------------------------------------------------------------------
// 随机生成函数
// ---------------------------------------------------------------------------

/// 生成随机 ComputedIndicatorKey（id 范围限制在 key_0 ~ key_9，
/// 保证操作序列中有足够的 key 碰撞以触发回收复用场景）
ComputedIndicatorKey randomSlotKey(Random rng) {
  return ComputedIndicatorKey('key_${rng.nextInt(10)}');
}

/// 生成随机操作序列（长度 1 ~ 50，Register 和 Recycle 混合）
List<TestSlotOp> randomSlotOps(Random rng) {
  final len = 1 + rng.nextInt(50);
  return List.generate(len, (_) {
    final key = randomSlotKey(rng);
    return rng.nextBool() ? TestRegisterOp(key) : TestRecycleOp(key);
  });
}
