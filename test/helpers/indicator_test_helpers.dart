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

/// 指标属性测试的公共模型、Glados 生成器和辅助函数
///
/// 供 `sync_all_indicators_test.dart`、`activate_indicator_test.dart`、
/// `sync_indicators_test.dart` 等属性测试共用。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:glados/glados.dart';

import 'test_indicators.dart';
import 'test_kline_config.dart';

// ---------------------------------------------------------------------------
// 指标描述模型
// ---------------------------------------------------------------------------

/// 指标类型枚举
enum IndicatorType { data, business }

/// 指标描述：类型 + 唯一 id + height
///
/// [height] 用于区分同 key 不同配置的实例（syncIndicators diff 场景）。
/// 不需要区分配置时可忽略（默认 100）。
class IndicatorDesc {
  const IndicatorDesc(this.type, this.id, [this.height = 100]);
  final IndicatorType type;
  final int id;
  final double height;

  @override
  String toString() => '${type.name}_$id(h=$height)';
}

// ---------------------------------------------------------------------------
// Glados 生成器
// ---------------------------------------------------------------------------

/// 生成随机指标描述（固定 height = 100）
final indicatorDescGen = any.choose([IndicatorType.data, IndicatorType.business]).bind(
  (type) => any.intInRange(0, 20).map((id) => IndicatorDesc(type, id)),
);

/// 生成随机指标描述（带随机 height）
final indicatorDescWithHeightGen = any.choose([IndicatorType.data, IndicatorType.business]).bind(
  (type) => any.intInRange(0, 20).bind(
        (id) => any.intInRange(50, 200).map(
              (h) => IndicatorDesc(type, id, h.toDouble()),
            ),
      ),
);

/// 生成随机指标描述列表（去重 key，长度 0~8）
Generator<List<IndicatorDesc>> indicatorListGen([
  Generator<IndicatorDesc>? descGen,
]) {
  final gen = descGen ?? indicatorDescGen;
  return any.intInRange(0, 9).bind(
        (len) => any.listWithLength(len, gen).map((list) {
          final seen = <String>{};
          return list.where((desc) => seen.add('${desc.type.name}_${desc.id}')).toList();
        }),
      );
}

/// 生成 main + sub 两个指标列表（确保 key 不重复）
Generator<({List<IndicatorDesc> main, List<IndicatorDesc> sub})> mainSubGen([
  Generator<IndicatorDesc>? descGen,
]) {
  final listGen = indicatorListGen(descGen);
  return listGen.bind(
    (mainDescs) => listGen.map((subDescs) {
      final mainKeys = mainDescs.map((d) => '${d.type.name}_${d.id}').toSet();
      final filteredSub = subDescs.where((d) => !mainKeys.contains('${d.type.name}_${d.id}')).toList();
      return (main: mainDescs, sub: filteredSub);
    }),
  );
}

// ---------------------------------------------------------------------------
// 辅助函数
// ---------------------------------------------------------------------------

/// 根据描述创建具体的 [Indicator] 实例
Indicator createIndicator(IndicatorDesc desc) {
  switch (desc.type) {
    case IndicatorType.data:
      return TestDataIndicator(
        key: DataIndicatorKey('data_${desc.id}'),
        height: desc.height,
      );
    case IndicatorType.business:
      return TestBusinessIndicator(
        key: BusinessIndicatorKey('biz_${desc.id}'),
        height: desc.height,
      );
  }
}

/// 从描述获取 [IIndicatorKey]
IIndicatorKey descToKey(IndicatorDesc desc) {
  switch (desc.type) {
    case IndicatorType.data:
      return DataIndicatorKey('data_${desc.id}');
    case IndicatorType.business:
      return BusinessIndicatorKey('biz_${desc.id}');
  }
}

/// 创建 [IndicatorPaintObjectManager] 实例
IndicatorPaintObjectManager createManager([TestFlexiKlineConfiguration? config]) {
  return IndicatorPaintObjectManager(
    configuration: config ?? TestFlexiKlineConfiguration(),
  );
}
