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

part of 'indicator.dart';

/// 指标计算器。
///
/// 读取传入 [KlineData] 的 OHLCV，把计算结果写入 `data.list[i].slots[dataIndex]`。
/// 不含任何 Flutter / Canvas / PaintObject 依赖，因此：
/// 1. 只操作传入的 [KlineData]（不再依赖全局"当前数据"），是后台 spec 预加载的前提；
/// 2. 与渲染解耦，可脱离绘制系统单测，也是未来搬入 isolate 的结构前提。
///
/// 由声明层 [ComputedIndicator.createCalculator] 创建、[IndicatorPaintObjectManager]
/// 在 `dataIndex` 确认后缓存；[KlineDataPipeline] 遍历 `visibleCalculators` 驱动计算。
abstract class IndicatorCalculator<T extends ComputedIndicator> {
  IndicatorCalculator(this.indicator, this.dataIndex);

  /// 声明层指标配置（携带 calcParam 等）。
  final T indicator;

  /// 计算结果在 [FlexiCandleModel.slots] 中的存储下标，由 manager 注入。
  final int dataIndex;

  /// 在 [range] 上计算并写入 slots。
  ///
  /// [reset] 为 true 时应先清空 [dataIndex] 槽位再整段计算。
  void compute(KlineData data, Range range, {bool reset = false});
}
