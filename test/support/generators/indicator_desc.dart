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

/// v2.2.0 三类型指标描述模型与随机生成器
///
/// 提供 [IndicatorKind] 枚举、[IndicatorDesc] 描述类、便捷构造函数、
/// key 转换、实例创建及属性测试用随机生成函数。
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';

import '../doubles/test_indicators.dart';

// ---------------------------------------------------------------------------
// 指标类型枚举
// ---------------------------------------------------------------------------

/// v2.2.0 指标种类，与 lib 三分类一致。
enum IndicatorKind {
  direct,
  computed,
  // ignore: constant_identifier_names
  external_;

  /// key 前缀
  String get prefix => switch (this) {
        direct => 'direct',
        computed => 'computed',
        external_ => 'external',
      };
}

// ---------------------------------------------------------------------------
// 指标描述模型
// ---------------------------------------------------------------------------

/// 指标描述：种类 + 唯一 id + height。
class IndicatorDesc {
  const IndicatorDesc(this.kind, this.id, [this.height = 100]);
  final IndicatorKind kind;
  final int id;
  final double height;

  /// key 的字符串标识
  String get keyToken => '${kind.prefix}_$id';

  @override
  String toString() => '$keyToken(h=$height)';
}

// ---------------------------------------------------------------------------
// 便捷构造
// ---------------------------------------------------------------------------

/// 创建 direct 类型描述
IndicatorDesc direct(int id, [double h = 100]) =>
    IndicatorDesc(IndicatorKind.direct, id, h);

/// 创建 computed 类型描述
IndicatorDesc computed(int id, [double h = 100]) =>
    IndicatorDesc(IndicatorKind.computed, id, h);

/// 创建 external 类型描述
// ignore: non_constant_identifier_names
IndicatorDesc external_(int id, [double h = 80]) =>
    IndicatorDesc(IndicatorKind.external_, id, h);

/// 创建 direct 类型 key
DirectIndicatorKey directKey(int id) => DirectIndicatorKey('direct_$id');

/// 创建 computed 类型 key
ComputedIndicatorKey computedKey(int id) => ComputedIndicatorKey('computed_$id');

/// 创建 external 类型 key
ExternalIndicatorKey externalKey(int id) => ExternalIndicatorKey('external_$id');

// ---------------------------------------------------------------------------
// Key / Indicator 转换
// ---------------------------------------------------------------------------

/// 从描述获取 [IIndicatorKey]
IIndicatorKey descToKey(IndicatorDesc d) => switch (d.kind) {
      IndicatorKind.direct => directKey(d.id),
      IndicatorKind.computed => computedKey(d.id),
      IndicatorKind.external_ => externalKey(d.id),
    };

/// 根据描述创建具体的 [Indicator] 实例
Indicator createIndicator(IndicatorDesc d) => switch (d.kind) {
      IndicatorKind.direct => TestDirectIndicator(
          key: directKey(d.id),
          height: d.height,
        ),
      IndicatorKind.computed => TestComputedIndicator(
          key: computedKey(d.id),
          height: d.height,
        ),
      IndicatorKind.external_ => TestExternalIndicator(
          key: externalKey(d.id),
          height: d.height,
        ),
    };

// ---------------------------------------------------------------------------
// 随机工具
// ---------------------------------------------------------------------------

/// 真随机子集：shuffle 后取随机 k 个，修复旧 .take(n) 前缀偏差。
List<T> randomSubset<T>(Random rng, List<T> source) {
  final copy = [...source]..shuffle(rng);
  final k = rng.nextInt(source.length + 1);
  return copy.take(k).toList();
}

// ---------------------------------------------------------------------------
// 随机指标生成（默认只含 computed + external；Direct 单测）
// ---------------------------------------------------------------------------

/// 生成随机指标描述（固定 height=100）
IndicatorDesc randomIndicatorDesc(Random rng) {
  final kind = rng.nextBool() ? IndicatorKind.computed : IndicatorKind.external_;
  final id = rng.nextInt(20);
  return IndicatorDesc(kind, id);
}

/// 生成随机指标描述（带随机 height）
IndicatorDesc randomIndicatorDescWithHeight(Random rng) {
  final kind = rng.nextBool() ? IndicatorKind.computed : IndicatorKind.external_;
  final id = rng.nextInt(20);
  final height = 50.0 + rng.nextInt(150);
  return IndicatorDesc(kind, id, height);
}

/// 生成随机指标描述列表（去重 key，长度 0~8）
List<IndicatorDesc> randomIndicatorList(
  Random rng, [
  IndicatorDesc Function(Random)? generator,
]) {
  final gen = generator ?? randomIndicatorDesc;
  final len = rng.nextInt(9);
  final list = List.generate(len, (_) => gen(rng));
  final seen = <String>{};
  return list.where((d) => seen.add(d.keyToken)).toList();
}

/// 生成 main + sub 两个指标列表（确保 key 不重复）
({List<IndicatorDesc> main, List<IndicatorDesc> sub}) randomMainSub(
  Random rng, [
  IndicatorDesc Function(Random)? generator,
]) {
  final mainDescs = randomIndicatorList(rng, generator);
  final subDescs = randomIndicatorList(rng, generator);
  final mainKeys = mainDescs.map((d) => d.keyToken).toSet();
  final sub = subDescs.where((d) => !mainKeys.contains(d.keyToken)).toList();
  return (main: mainDescs, sub: sub);
}
