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
/// 1. 根据配置初始化指标绘制对象.
/// 2. 管理所有指标构造器
/// 3. 负责指标对象的创建/销毁
/// 4. 管理副图指标绘制对象队列
final class IndicatorPaintObjectManager with KlineLog {
  IndicatorPaintObjectManager({
    required this.configuration,
    int subIndicatorMaxCount = defaultSubIndicatorMaxCount,
    ILogger? logger,
  }) {
    loggerDelegate = logger;
    // 注册指标构造器(仅在构建时, 使用一次)
    _indicatorDataIndexs.clear();
    final mainIndicators = configuration.mainIndicatorBuilders;
    for (final MapEntry(key: key, value: builder) in mainIndicators.entries) {
      _registerMainIndicatorBuilder(key, builder);
    }
    final subIndicators = configuration.subIndicatorBuilders;
    for (final MapEntry(key: key, value: builder) in subIndicators.entries) {
      _registerSubIndicatorBuilder(key, builder);
    }
    _flexiKlineConfig = configuration.getFlexiKlineConfig();
    _subPaintObjectQueue = FixedHashQueue<PaintObjectBox>(subIndicatorMaxCount);
  }

  @override
  String get logTag => 'IndicatorPaintObjectManager';

  final IConfiguration configuration;
  late FlexiKlineConfig _flexiKlineConfig;
  FlexiKlineConfig get flexiKlineConfig => _flexiKlineConfig;

  /// 动态维护指标计算数据存储位置.
  /// 注: 仅能通过[configuration]配置去计算指标计算数据存储位置.
  final Map<IIndicatorKey, int> _indicatorDataIndexs = {
    // candleIndicatorKey: 0,
    // timeIndicatorKey: 1,
  };

  late final FixedHashQueue<PaintObject> _subPaintObjectQueue;

  late final MainPaintObject _mainPaintObject;

  late final CandleBasePaintObject _candlePaintObject;
  late final TimeBasePaintObject _timePaintObject;

  MainPaintObject get mainPaintObject => _mainPaintObject;

  CandleBasePaintObject get candlePaintObject => _candlePaintObject;
  TimeBasePaintObject get timePaintObject => _timePaintObject;

  Iterable<PaintObject> get subPaintObjects {
    final objects = _subPaintObjectQueue;
    switch (timePaintObject.position) {
      case DrawPosition.middle:
        return [_timePaintObject, ...objects];
      case DrawPosition.bottom:
        return [...objects, _timePaintObject];
    }
  }

  /// 主区指标配置构造器
  final Map<IIndicatorKey, IndicatorBuilder> _mainIndicatorBuilders = {};

  /// 副区指标配置构造器
  final Map<IIndicatorKey, IndicatorBuilder> _subIndicatorBuilders = {};

  Iterable<IIndicatorKey>? _supportMainIndicatorKeys;
  Iterable<IIndicatorKey> get supportMainIndicatorKeys {
    return _supportMainIndicatorKeys ??= _mainIndicatorBuilders.keys;
  }

  Iterable<IIndicatorKey>? _supportSubIndicatorKeys;
  Iterable<IIndicatorKey> get supportSubIndicatorKeys {
    return _supportSubIndicatorKeys ??= _subIndicatorBuilders.keys;
  }

  Iterable<IIndicatorKey> get mainIndicatorKeys {
    return _mainPaintObject.children.map((obj) => obj.key);
  }

  Iterable<IIndicatorKey> get subIndicatorKeys {
    return _subPaintObjectQueue.map((obj) => obj.key);
  }

  void _registerMainIndicatorBuilder(
    IIndicatorKey key,
    IndicatorBuilder builder,
  ) {
    _mainIndicatorBuilders[key] = builder;
    _supportMainIndicatorKeys = null;
    if (!_indicatorDataIndexs.containsKey(key)) {
      logi('registerMainIndicatorBuilder $key:${_indicatorDataIndexs.length}');
      _indicatorDataIndexs[key] = _indicatorDataIndexs.length;
    }
  }

  void _registerSubIndicatorBuilder(
    IIndicatorKey key,
    IndicatorBuilder builder,
  ) {
    _subIndicatorBuilders[key] = builder;
    _supportSubIndicatorKeys = null;
    if (!_indicatorDataIndexs.containsKey(key)) {
      logi('registerSubIndicatorBuilder $key:${_indicatorDataIndexs.length}');
      _indicatorDataIndexs[key] = _indicatorDataIndexs.length;
    }
  }

  bool hasRegisteredInMain(IIndicatorKey key) {
    return _mainIndicatorBuilders.containsKey(key) || key == candleIndicatorKey;
  }

  bool hasRegisteredInSub(IIndicatorKey key) {
    return _subIndicatorBuilders.containsKey(key) || key == timeIndicatorKey;
  }

  int? getIndicatorDataIndex(IIndicatorKey key) {
    return _indicatorDataIndexs.getItem(key);
  }

  int get indicatorCount => _indicatorDataIndexs.length;

  /// 初始化主区/副区指标
  /// 1. 确认指标数据在[CandleModel]的[CalculateData]中的index.
  /// 2. 初始化主区绘制对象, 初始化副区绘制对象队列
  /// 3. 从配置中加载缓存的主/副区指标.
  void init(IPaintContext context) {
    final mainIndicator = flexiKlineConfig.mainIndicator;
    _mainPaintObject = MainPaintObject(
      context: context,
      indicator: mainIndicator.copyWith(),
    );

    /// 配置默认指标蜡烛图指标和时间指标
    try {
      final candle = configuration.candleIndicatorBuilder.call(
        configuration.getConfig(candleIndicatorKey.id),
      );
      _candlePaintObject = candle.createPaintObject(context);
      _mainPaintObject.appendPaintObject(_candlePaintObject);

      final time = configuration.timeIndicatorBuilder.call(
        configuration.getConfig(timeIndicatorKey.id),
      );
      _timePaintObject = time.createPaintObject(context);
    } catch (error, stack) {
      loge(
        'init catch an exception!',
        error: error,
        stackTrace: stack,
      );
    }

    /// 加载历史选中过的指标
    for (var key in mainIndicator.children) {
      addMainPaintObject(key, context);
    }
    for (var key in flexiKlineConfig.sub) {
      addSubPaintObject(key, context);
    }
  }

  /// 更新FlexiKline配置与指标配置.
  void updateFlexiKlineConfig(
    IPaintContext context, {
    bool updateIndicator = true,
  }) {
    _flexiKlineConfig = configuration.getFlexiKlineConfig();
    if (!updateIndicator) return;

    /// 配置默认指标蜡烛图指标和时间指标
    final mainIndicator = flexiKlineConfig.mainIndicator;
    try {
      mainPaintObject.doDidUpdateIndicator(mainIndicator.copyWith(
        size: mainPaintObject.size,
      ));

      final candle = configuration.candleIndicatorBuilder.call(
        configuration.getConfig(candleIndicatorKey.id),
      );
      candlePaintObject.doDidUpdateIndicator(candle);

      final time = configuration.timeIndicatorBuilder.call(
        configuration.getConfig(timeIndicatorKey.id),
      );
      timePaintObject.doDidUpdateIndicator(time);
    } catch (error, stack) {
      loge(
        'updateFlexiKlineConfig catch an exception!',
        error: error,
        stackTrace: stack,
      );
    }

    final newMainKeys = mainIndicator.children;
    for (final key in supportMainIndicatorKeys) {
      if (newMainKeys.contains(key)) {
        addMainPaintObject(key, context, reset: true);
      } else {
        removeMainPaintObject(key);
      }
    }

    final newSubKeys = flexiKlineConfig.sub;
    for (final key in supportSubIndicatorKeys) {
      if (newSubKeys.contains(key)) {
        addSubPaintObject(key, context, reset: true);
      } else {
        removeSubPaintObject(key);
      }
    }
  }

  /// 主区指标操作 ///
  /// 在主区中添加[key]指定的指标
  PaintObject? addMainPaintObject(
    IIndicatorKey key,
    IPaintContext context, {
    bool reset = false,
  }) {
    if (!hasRegisteredInMain(key)) {
      logw('addMainPaintObject $key not registered yet.');
      return null;
    }

    if (reset) {
      removeMainPaintObject(key);
    } else {
      final object = _mainPaintObject.getChildPaintObject(key);
      if (!reset && object != null) {
        logw('addMainPaintObject $key is loaded, cannot be added!');
        return null;
      }
    }

    final indicator = configuration.getIndicator(
      key,
      builder: _mainIndicatorBuilders[key],
    );
    if (indicator == null) return null;
    final newObj = indicator.createPaintObject(context);
    _mainPaintObject.appendPaintObject(newObj);
    return newObj;
  }

  /// 在已载入主区绘制对象中, 删除[key]指定的绘制对象
  bool removeMainPaintObject(IIndicatorKey key) {
    return _mainPaintObject.deletePaintObject(key);
  }

  /// 副区指标操作 ///
  /// 在副区中添加[key]指定的指标
  PaintObject? addSubPaintObject(
    IIndicatorKey key,
    IPaintContext context, {
    bool reset = false,
  }) {
    if (!hasRegisteredInSub(key)) {
      logw('addSubPaintObject $key not registered yet.');
      return null;
    }

    if (reset) {
      removeSubPaintObject(key);
    } else {
      final object = _subPaintObjectQueue.firstWhereOrNull(
        (obj) => obj.key == key,
      );
      if (object != null) {
        logw('addSubPaintObject $key is loaded, cannot be added!');
        return null;
      }
    }

    final indicator = configuration.getIndicator(
      key,
      builder: _subIndicatorBuilders[key],
    );
    if (indicator == null) return null;
    final newObj = indicator.createPaintObject(context);
    flexiKlineConfig.sub.add(key);
    final oldObj = _subPaintObjectQueue.append(newObj);
    oldObj?.dispose();
    return newObj;
  }

  /// 在已载入副区绘制对象中, 删除[key]指定的绘制对象
  bool removeSubPaintObject(IIndicatorKey key) {
    bool hasRemove = false;
    _subPaintObjectQueue.removeWhere((obj) {
      if (obj.indicator.key == key) {
        obj.dispose();
        hasRemove = true;
        flexiKlineConfig.sub.remove(key);
        return true;
      }
      return false;
    });
    return hasRemove;
  }

  /// 获取主区[key]指定的指标配置实例
  /// 1. 先从当前载入的指标中查找
  /// 2. 如果不存在, 则从配置缓存中加载[key]对应的指标
  T? getIndicator<T extends Indicator>(IIndicatorKey key) {
    if (hasRegisteredInMain(key)) {
      Indicator? indicator = mainPaintObject.getChildIndicator(key);
      indicator ??= configuration.getIndicator(
        key,
        builder: _mainIndicatorBuilders[key],
      );
      return indicator is T ? indicator : null;
    } else if (hasRegisteredInSub(key)) {
      final object = subPaintObjects.firstWhereOrNull((obj) => obj.key == key);
      var indicator = object?.indicator;
      indicator ??= configuration.getIndicator(
        key,
        builder: _subIndicatorBuilders[key],
      );
      return indicator is T ? indicator : null;
    }
    return null;
  }

  bool updateIndicator<T extends Indicator>(T indicator) {
    final key = indicator.key;
    if (hasRegisteredInMain(key)) {
      bool updated = mainPaintObject.updateChildIndicator(indicator);
      if (!updated) {
        updated = configuration.saveIndicator(indicator);
      }
      return updated;
    } else if (hasRegisteredInSub(key)) {
      final object = subPaintObjects.firstWhereOrNull((obj) => obj.key == key);
      if (object != null) {
        object.doDidUpdateIndicator(indicator);
        return true;
      } else {
        return configuration.saveIndicator(indicator);
      }
    }
    return false;
  }

  bool restoreIndicator(IIndicatorKey key) {
    configuration.delIndicator(key);
    final indicator = configuration.getIndicator(key);
    if (indicator != null) {
      return updateIndicator(indicator);
    }
    return false;
  }

  bool restoreAllIndicator() {
    bool result = false;
    for (var key in [...supportMainIndicatorKeys, ...supportSubIndicatorKeys]) {
      result = restoreIndicator(key) && result;
    }
    return result;
  }

  /// 收集当前指标的计算参数
  /// 考虑在主区/副区同时存在的指标.
  @Deprecated('废弃, 由PaintObject执行precompute')
  Map<IIndicatorKey, dynamic> getIndicatorCalcParams() {
    final calcParams = mainPaintObject.getCalcParams();
    for (final object in subPaintObjects) {
      final params = object.getCalcParams();
      if (params.isEmpty) continue;
      calcParams.addAll(params);
    }
    return calcParams;
  }

  void restoreHeight() {
    mainPaintObject.restoreSize();
    for (var object in subPaintObjects) {
      object.restoreHeight();
    }
  }

  /// 保存所有FlexiKline配置及主区和副区的指标设置.
  /// [storeIndicators] 是否存储主区指标和副区指标的设置.
  /// [layoutMode] 布局模式; 注: 仅保存NormalLayoutMode模式下的宽高 和 非移动设备时AdaptLayoutMode模式下的宽高.
  void storeFlexiKlineConfig({
    bool storeIndicators = true,
    required LayoutMode layoutMode,
  }) {
    flexiKlineConfig.sub = subIndicatorKeys.toSet();
    final configMainSize = flexiKlineConfig.mainIndicator.size;
    flexiKlineConfig.mainIndicator = mainPaintObject.indicator.copyWith(
      size: switch (layoutMode) {
        NormalLayoutMode() => mainPaintObject.size,
        AdaptLayoutMode() => PlatformUtil.isMobile ? configMainSize : mainPaintObject.size,
        FixedLayoutMode() => configMainSize,
      },
    );
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
    if (storeIndicators) {
      mainPaintObject.doStoreConfig();
      for (var object in subPaintObjects) {
        object.doStoreConfig();
      }
    }
  }

  void dispose() {
    mainPaintObject.dispose();
    for (var object in subPaintObjects) {
      object.dispose();
    }
    _subPaintObjectQueue.clear();
  }
}
