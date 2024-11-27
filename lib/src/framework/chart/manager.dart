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

/// [PaintObject]管理
/// 主要负责:
/// 1. 初始加载Kline时从配置中根据Indicator配置实例化[PaintObject].
/// 2. 将当前Kline的PaintObject关联Indicator持久化到本地
/// 3. 为ChartController提供待绘制的[PaintObject]列表.
/// 4. 管理主区与副区[PaintObject]的顺序/切换/更新/
/// 5. 管理所有[Indicator]配置, 当发生更新时重建[PaintObject]
/// 6. 提供定制[Indicator]的定制功能
final class IndicatorPaintObjectManager with KlineLog {
  IndicatorPaintObjectManager({
    required this.configuration,
    ILogger? logger,
  }) {
    loggerDelegate = logger;
  }

  final IConfiguration configuration;

  @override
  String get logTag => 'IndicatorPaintObjectManager';

  final Map<IIndicatorKey, int> _indicatorDataIndexs = {};

  late final MultiPaintObjectIndicator _mainIndicator;

  late final FixedHashQueue<SinglePaintObjectIndicator> _subRectIndicatorQueue;

  /// 主区类型适配器集合
  final Map<IIndicatorKey, IndicatorTypeAdapter> _indicatorMainTypeAdapters =
      {};

  /// 副区指标类型适配器集合
  final Map<IIndicatorKey, IndicatorTypeAdapter> _indicatorSubTypeAdapters = {};

  Iterable<IIndicatorKey>? _supportMainIndicatorKeys;
  Iterable<IIndicatorKey> get supportMainIndicatorKeys {
    return _supportMainIndicatorKeys ??= _indicatorMainTypeAdapters.keys;
  }

  Iterable<IIndicatorKey>? _supportSubIndicatorKeys;
  Iterable<IIndicatorKey> get supportSubIndicatorKeys {
    return _supportSubIndicatorKeys ??= _indicatorSubTypeAdapters.keys;
  }

  void registerMainIndicatorTypeAdapter<T extends SinglePaintObjectIndicator>(
    IndicatorTypeAdapter<T> adapter,
  ) {
    _indicatorMainTypeAdapters[adapter.indicatorKey] = adapter;
  }

  /// 注册副区指标类型适配器
  /// 注: 考虑降低维护复杂度. 暂不支持[MultiPaintObjectIndicator], 固此处限定使用[SinglePaintObjectIndicator]
  void registerSubIndicatorTypeAdapter<T extends SinglePaintObjectIndicator>(
    IndicatorTypeAdapter<T> adapter,
  ) {
    _indicatorSubTypeAdapters[adapter.indicatorKey] = adapter;
  }

  int? getIndicatorDataIndex(IIndicatorKey key) {
    return _indicatorDataIndexs.getItem(key);
  }

  /// 初始化指标
  /// 1. 确认指标数据在[CandleModel]的[CalculateData]中的index.
  /// 2. 初始化主区绘制对象, 初始化副区绘制对象队列
  /// 3. 从配置中加载缓存的主/副区指标.
  void initState(IPaintContext context) {
    _indicatorDataIndexs.clear();
    int index = 0;
    for (var key in [...supportMainIndicatorKeys, ...supportSubIndicatorKeys]) {
      _indicatorDataIndexs[key] = index++;
    }

    _mainIndicator = MultiPaintObjectIndicator(
      key: IndicatorType.main,
      name: IndicatorType.main.label,
      height: context.settingConfig.mainRect.height,
      padding: context.settingConfig.mainPadding,
      drawBelowTipsArea: context.settingConfig.mainDrawBelowTipsArea,
    );
    _subRectIndicatorQueue = FixedHashQueue<SinglePaintObjectIndicator>(
      context.settingConfig.subChartMaxCount,
    );
  }
}
