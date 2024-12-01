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

  /// 动态维护指标计算数据存储位置
  final Map<IIndicatorKey, int> _indicatorDataIndexs = {};

  late final MultiPaintObjectBox _mainPaintObject;

  late final FixedHashQueue<PaintObject> _subPaintObjectQueue;

  PaintObject? _timePaintObject;

  ITimeRectConfig? get timeRectConfig {
    if (_timePaintObject != null && _timePaintObject is ITimeRectConfig) {
      return _timePaintObject as ITimeRectConfig;
    }
    return null;
  }

  MultiPaintObjectBox get mainPaintObject => _mainPaintObject;

  Iterable<PaintObject> get subPaintObjects {
    final objects = _subPaintObjectQueue;
    if (_timePaintObject != null && timeRectConfig != null) {
      if (timeRectConfig!.position == DrawPosition.bottom) {
        return [...objects, _timePaintObject!];
      } else if (timeRectConfig!.position == DrawPosition.middle) {
        return [_timePaintObject!, ...objects];
      }
    }
    return objects;
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
      _indicatorDataIndexs[key] = _indicatorDataIndexs.length;
    }
  }

  int? getIndicatorDataIndex(IIndicatorKey key) {
    return _indicatorDataIndexs.getItem(key);
  }

  /// 初始化指标
  /// 1. 确认指标数据在[CandleModel]的[CalculateData]中的index.
  /// 2. 初始化主区绘制对象, 初始化副区绘制对象队列
  /// 3. 从配置中加载缓存的主/副区指标.
  void initState(IPaintContext context) {
    /// 注册指标构造器
    _indicatorDataIndexs.clear();
    final mainIndicators = configuration.customMainIndicatorBuilders();
    for (final MapEntry(key: key, value: builder) in mainIndicators.entries) {
      registerMainIndicatorBuilder(key, builder);
    }
    final subIndicators = configuration.customMainIndicatorBuilders();
    for (final MapEntry(key: key, value: builder) in subIndicators.entries) {
      registerSubIndicatorBuilder(key, builder);
    }

    /// 构造主区/副区
    _mainPaintObject = MultiPaintObjectBox(
      context: context,
      indicator: MultiPaintObjectIndicator(
        key: IndicatorType.main,
        name: IndicatorType.main.label,
        height: context.settingConfig.mainRect.height,
        padding: context.settingConfig.mainPadding,
        drawBelowTipsArea: context.settingConfig.mainDrawBelowTipsArea,
      ),
    );

    _subPaintObjectQueue = FixedHashQueue<SinglePaintObjectBox>(
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
        'initState catch an exception!',
        error: error,
        stackTrace: stack,
      );
    }

    /// TODO: 加载历史指标配置
    // final mainIndciatorKeys = configuration.
  }

  Indicator? _createPaintIndicator(
    IIndicatorKey key,
    IPaintContext context,
  ) {
    try {
      if (_mainIndicatorBuilders.containsKey(key)) {
        return _mainIndicatorBuilders[key]?.call(context.settingConfig);
      } else if (_subIndicatorBuilders.containsKey(key)) {
        return _subIndicatorBuilders[key]?.call(context.settingConfig);
      }
    } catch (error, stack) {
      loge(
        'createPaintIndicator($key) catch an exception!',
        error: error,
        stackTrace: stack,
      );
    }
    return null;
  }

  /// 在主图中添加指标
  bool addIndicatorInMain(IIndicatorKey key, IPaintContext context) {
    final indicator = _createPaintIndicator(key, context);
    if (indicator == null) return false;
    final object = indicator.createPaintObject(context);
    _mainPaintObject.appendPaintObject(object);
    return true;
  }

  /// 删除主图中[key]指定的指标
  bool delIndicatorInMain(IIndicatorKey key) {
    return _mainPaintObject.deletePaintObject(key);
  }

  bool addIndicatorInSub(IIndicatorKey key, IPaintContext context) {
    final indicator = _createPaintIndicator(key, context);
    if (indicator == null) return false;
    final object = indicator.createPaintObject(context);
    final oldObj = _subPaintObjectQueue.append(object);
    oldObj?.dispose();
    return true;
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
  /// TODO: 后续优化: manager中不会出现具体指标参数逻辑.
  /// 且像subBoll和boll参数有可能不一致. 此处应有业务控制.
  Map<IIndicatorKey, dynamic> getIndicatorCalcParams() {
    final calcParams = mainPaintObject.getCalcParams();
    for (final object in subPaintObjects) {
      final params = object.getCalcParams();
      if (params.isEmpty) continue;
      if (object.key == IndicatorType.subBoll) {
        calcParams.putIfAbsent(
          IndicatorType.boll,
          params[IndicatorType.subBoll],
        );
      } else if (object.key == IndicatorType.subSar) {
        calcParams.putIfAbsent(
          IndicatorType.sar,
          params[IndicatorType.subSar],
        );
      } else {
        calcParams.addAll(params);
      }
    }
    return calcParams;
  }

  void dispose() {
    mainPaintObject.dispose();
    for (var indicator in subPaintObjects) {
      indicator.dispose();
    }
    _timePaintObject?.dispose();
    _subPaintObjectQueue.clear();
  }
}
