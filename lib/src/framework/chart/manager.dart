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
    ILogger? logger,
  }) {
    loggerDelegate = logger;
  }

  final IConfiguration configuration;

  @override
  String get logTag => 'IndicatorPaintObjectManager';

  /// 动态维护指标计算数据存储位置.
  /// 注: 仅能通过[configuration]配置去计算指标计算数据存储位置.
  final Map<IIndicatorKey, int> _indicatorDataIndexs = {
    // candleIndicatorKey: 0,
    // timeIndicatorKey: 1,
  };

  late final FixedHashQueue<PaintObject> _subPaintObjectQueue;

  late final MainPaintObject _mainPaintObject;

  late final TimeBasePaintObject _timePaintObject;

  MainPaintObject get mainPaintObject => _mainPaintObject;

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

  Iterable<IIndicatorKey> get mainIndciatorKeys {
    return _mainPaintObject.children.map((obj) => obj.key);
  }

  Iterable<IIndicatorKey> get subIndicatorKeys {
    return _subPaintObjectQueue.map((obj) => obj.key);
  }

  void registerMainIndicatorBuilder(
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

  void registerSubIndicatorBuilder(
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

  int? getIndicatorDataIndex(IIndicatorKey key) {
    return _indicatorDataIndexs.getItem(key);
  }

  int get indicatorCount => _indicatorDataIndexs.length;

  /// 初始化指标
  /// 1. 确认指标数据在[CandleModel]的[CalculateData]中的index.
  /// 2. 初始化主区绘制对象, 初始化副区绘制对象队列
  /// 3. 从配置中加载缓存的主/副区指标.
  void init(
    IPaintContext context, {
    required MainPaintObjectIndicator mainIndicator,
    Set<IIndicatorKey> initSubIndicatorKeys = const {},
  }) {
    /// 注册指标构造器
    _indicatorDataIndexs.clear();
    final mainIndicators = configuration.mainIndicatorBuilders();
    for (final MapEntry(key: key, value: builder) in mainIndicators.entries) {
      registerMainIndicatorBuilder(key, builder);
    }
    final subIndicators = configuration.subIndicatorBuilders();
    for (final MapEntry(key: key, value: builder) in subIndicators.entries) {
      registerSubIndicatorBuilder(key, builder);
    }

    /// 构造主区/副区
    _mainPaintObject = MainPaintObject(
      context: context,
      indicator: mainIndicator,
    );

    _subPaintObjectQueue = FixedHashQueue<PaintObjectBox>(
      context.settingConfig.subChartMaxCount,
    );

    /// 配置默认指标蜡烛图指标和时间指标
    try {
      final setting = context.settingConfig;
      final candle = configuration.candleIndicatorBuilder.call(setting);
      final candleObject = candle.createPaintObject(context);
      _mainPaintObject.appendPaintObject(candleObject);

      final time = configuration.timeIndicatorBuilder.call(setting);
      _timePaintObject = time.createPaintObject(context);
    } catch (error, stack) {
      loge(
        'init catch an exception!',
        error: error,
        stackTrace: stack,
      );
    }

    /// 加载历史选中过的指标
    for (var key in mainIndicator.indicatorKeys) {
      addIndicatorInMain(key, context);
    }
    for (var key in initSubIndicatorKeys) {
      addIndicatorInSub(key, context);
    }
  }

  Indicator? _createMainPaintIndicator(
    IIndicatorKey key,
    IPaintContext context,
  ) {
    try {
      if (_mainIndicatorBuilders.containsKey(key)) {
        return _mainIndicatorBuilders[key]?.call(context.settingConfig);
      }
    } catch (error, stack) {
      loge(
        '_createMainPaintIndicator($key) catch an exception!',
        error: error,
        stackTrace: stack,
      );
    }
    return null;
  }

  Indicator? _createSubPaintIndicator(
    IIndicatorKey key,
    IPaintContext context,
  ) {
    try {
      if (_subIndicatorBuilders.containsKey(key)) {
        return _subIndicatorBuilders[key]?.call(context.settingConfig);
      }
    } catch (error, stack) {
      loge(
        '_createSubPaintIndicator($key) catch an exception!',
        error: error,
        stackTrace: stack,
      );
    }
    return null;
  }

  /// 在主图中添加指标
  PaintObject? addIndicatorInMain(IIndicatorKey key, IPaintContext context) {
    final indicator = _createMainPaintIndicator(key, context);
    if (indicator == null) return null;
    final object = indicator.createPaintObject(context);
    _mainPaintObject.appendPaintObject(object);
    return object;
  }

  /// 删除主图中[key]指定的指标
  bool delIndicatorInMain(IIndicatorKey key) {
    return _mainPaintObject.deletePaintObject(key);
  }

  PaintObject? addIndicatorInSub(IIndicatorKey key, IPaintContext context) {
    final indicator = _createSubPaintIndicator(key, context);
    if (indicator == null) return null;
    final object = indicator.createPaintObject(context);
    final oldObj = _subPaintObjectQueue.append(object);
    oldObj?.dispose();
    return object;
  }

  bool delIndicatorInSub(IIndicatorKey key) {
    bool hasRemove = false;
    _subPaintObjectQueue.removeWhere((obj) {
      if (obj.indicator.key == key) {
        obj.dispose();
        hasRemove = true;
        return true;
      }
      return false;
    });
    return hasRemove;
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

  void dispose() {
    mainPaintObject.dispose();
    // _timePaintObject.dispose();
    for (var indicator in subPaintObjects) {
      indicator.dispose();
    }
    _subPaintObjectQueue.clear();
  }
}
