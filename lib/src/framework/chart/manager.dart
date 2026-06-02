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

/// [PaintObject] 管理器。
///
/// 负责声明指标缓存、激活对象创建，以及 ComputedIndicator slot 分配。
final class IndicatorPaintObjectManager with FlexiLog {
  IndicatorPaintObjectManager({
    required this.configuration,
    int subIndicatorMaxCount = defaultSubIndicatorMaxCount,
    IFlexiLogger? logger,
  }) {
    this.logger = logger;
    _flexiKlineConfig = configuration.getFlexiKlineConfig();
    _subPaintObjectQueue = FixedHashQueue<PaintObject>(subIndicatorMaxCount);
  }

  @override
  String get logTag => 'IndicatorPaintObjectManager';

  final IConfiguration configuration;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  late FlexiKlineConfig _flexiKlineConfig;
  FlexiKlineConfig get flexiKlineConfig => _flexiKlineConfig;

  /// ComputedIndicator 计算数据的 slot 映射。
  ///
  /// 仅对 [ComputedIndicatorKey]（数据指标）分配 slot。
  final Map<ComputedIndicatorKey, int> _computedDataIndexes = {};

  /// 已回收的 slot，按 FIFO 复用。
  final Queue<int> _recycledSlots = Queue<int>();

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

  /// 主区指标声明注册表。
  final Map<IIndicatorKey, Indicator> _mainIndicatorRegistry = {};

  /// 副区指标声明注册表。
  final Map<IIndicatorKey, Indicator> _subIndicatorRegistry = {};

  Iterable<IIndicatorKey>? _supportMainIndicatorKeys;
  Iterable<IIndicatorKey> get supportMainIndicatorKeys {
    return _supportMainIndicatorKeys ??= _mainIndicatorRegistry.keys;
  }

  Iterable<IIndicatorKey>? _supportSubIndicatorKeys;
  Iterable<IIndicatorKey> get supportSubIndicatorKeys {
    return _supportSubIndicatorKeys ??= _subIndicatorRegistry.keys;
  }

  Iterable<IIndicatorKey> get mainIndicatorKeys {
    return _mainPaintObject.children.map((obj) => obj.key);
  }

  Iterable<IIndicatorKey> get subIndicatorKeys {
    return _subPaintObjectQueue.map((obj) => obj.key);
  }

  bool hasRegisteredInMain(IIndicatorKey key) {
    return _mainIndicatorRegistry.containsKey(key) || key == candleIndicatorKey;
  }

  bool hasRegisteredInSub(IIndicatorKey key) {
    return _subIndicatorRegistry.containsKey(key) || key == timeIndicatorKey;
  }

  int? getComputedDataIndex(ComputedIndicatorKey key) {
    return _computedDataIndexes[key];
  }

  int get computedDataCount => _computedDataIndexes.length;

  /// 注册 [ComputedIndicatorKey] 列表，为每个 key 分配 slot。
  ///
  /// 优先从 [_recycledSlots] 复用已回收的 slot index；
  /// 已注册的 key 会被跳过。
  int allocateComputedDataIndexes(List<ComputedIndicatorKey> keys) {
    for (final key in keys) {
      if (_computedDataIndexes.containsKey(key)) continue;
      final int slot;
      if (_recycledSlots.isNotEmpty) {
        slot = _recycledSlots.removeFirst();
      } else {
        slot = _computedDataIndexes.length;
      }
      _computedDataIndexes[key] = slot;
      logi('allocateComputedDataIndex $key:$slot');
    }
    return _computedDataIndexes.length;
  }

  /// 回收 [ComputedIndicatorKey] 的 slot。
  ///
  /// 将 slot index 加入 [_recycledSlots] 以供后续复用，
  /// 不清理蜡烛数据中对应位置的值（惰性清理，下次复用时自然覆盖）。
  void releaseComputedDataIndex(ComputedIndicatorKey key) {
    final index = _computedDataIndexes.remove(key);
    if (index != null) {
      _recycledSlots.addLast(index);
      logi('releaseComputedDataIndex $key:$index');
    }
  }

  /// 挂载 Widget 声明的指标，并恢复已激活的主区/副区指标。
  void mountIndicators({
    required CandleBaseIndicator candle,
    required TimeBaseIndicator time,
    required List<Indicator> mainIndicators,
    required List<Indicator> subIndicators,
    required PaintContext context,
  }) {
    if (_isInitialized) {
      logw('mountIndicators: already initialized, skip re-mount.');
      return;
    }
    // 收集 ComputedIndicatorKey 并分配 slot。
    final dataKeys = <ComputedIndicatorKey>[
      for (final indicator in mainIndicators)
        if (indicator.key is ComputedIndicatorKey) indicator.key as ComputedIndicatorKey,
      for (final indicator in subIndicators)
        if (indicator.key is ComputedIndicatorKey) indicator.key as ComputedIndicatorKey,
    ];
    allocateComputedDataIndexes(dataKeys);

    // 缓存声明层指标。
    for (final indicator in mainIndicators) {
      _mainIndicatorRegistry[indicator.key] = indicator;
    }
    for (final indicator in subIndicators) {
      _subIndicatorRegistry[indicator.key] = indicator;
    }

    // 创建系统级 PaintObject。
    _candlePaintObject = _inflateIndicator<CandleBaseIndicator, CandleBasePaintObject>(candle, context);
    _timePaintObject = _inflateIndicator<TimeBaseIndicator, TimeBasePaintObject>(time, context);

    // 隔离运行时 indicator，避免布局更新污染配置尺寸。
    final mainIndicator = flexiKlineConfig.mainIndicator.copyWith();
    _mainPaintObject = _inflateIndicator<MainPaintObjectIndicator, MainPaintObject>(mainIndicator, context);

    // 恢复已激活指标。
    _mainPaintObject.appendPaintObject(_candlePaintObject);

    for (final key in mainIndicator.children) {
      addMainPaintObject(key, context);
    }

    for (final key in flexiKlineConfig.sub) {
      addSubPaintObject(key, context);
    }
    _isInitialized = true;
  }

  /// 按 Widget 新旧声明增量同步指标。
  void updateIndicators({
    required PaintContext context,
    required CandleBaseIndicator oldCandle,
    required CandleBaseIndicator newCandle,
    required TimeBaseIndicator oldTime,
    required TimeBaseIndicator newTime,
    required List<Indicator> oldMainIndicators,
    required List<Indicator> newMainIndicators,
    required List<Indicator> oldSubIndicators,
    required List<Indicator> newSubIndicators,
  }) {
    // candle/time 无条件更新。
    _candlePaintObject.doDidUpdateIndicator(newCandle);

    _timePaintObject.doDidUpdateIndicator(newTime);

    // 同步主区声明集合。
    _mainDiffAndSync(
      context: context,
      oldIndicators: oldMainIndicators,
      newIndicators: newMainIndicators,
    );

    // 同步副区声明集合。
    _subDiffAndSync(
      context: context,
      oldIndicators: oldSubIndicators,
      newIndicators: newSubIndicators,
    );

    logi('updateIndicators 完成: computedDataCount=$computedDataCount');
  }

  /// 同步主区声明集合；新增只缓存，不自动激活。
  void _mainDiffAndSync({
    required PaintContext context,
    required List<Indicator> oldIndicators,
    required List<Indicator> newIndicators,
  }) {
    final oldMap = {for (final ind in oldIndicators) ind.key: ind};
    final newMap = {for (final ind in newIndicators) ind.key: ind};

    // 移除：回收 slot、删除缓存和已激活对象。
    for (final key in oldMap.keys) {
      if (newMap.containsKey(key)) continue;

      if (key is ComputedIndicatorKey) {
        releaseComputedDataIndex(key);
      }

      _mainIndicatorRegistry.remove(key);

      final result = _mainPaintObject.removePaintObject(key);

      logi('_mainDiffAndSync: 移除指标 $key > $result');
    }

    // 新增或更新：维护声明缓存，已激活对象同步配置。
    for (final entry in newMap.entries) {
      final key = entry.key;
      final newIndicator = entry.value;

      if (!oldMap.containsKey(key)) {
        if (key is ComputedIndicatorKey) {
          allocateComputedDataIndexes([key]);
        }
        _mainIndicatorRegistry[key] = newIndicator;
        logi('_mainDiffAndSync: 新增指标 $key $computedDataCount');
      } else {
        _mainIndicatorRegistry[key] = newIndicator;

        final paintObject = _mainPaintObject.getChildPaintObject(key);
        if (paintObject != null) {
          paintObject.doDidUpdateIndicator(newIndicator);
          logi('_mainDiffAndSync: 更新指标 $key');
        }
      }
    }
  }

  /// 同步副区声明集合；新增只缓存，不自动激活。
  void _subDiffAndSync({
    required List<Indicator> oldIndicators,
    required List<Indicator> newIndicators,
    required PaintContext context,
  }) {
    final oldMap = {for (final ind in oldIndicators) ind.key: ind};
    final newMap = {for (final ind in newIndicators) ind.key: ind};

    // 移除：回收 slot、删除缓存和已激活对象。
    for (final key in oldMap.keys) {
      if (newMap.containsKey(key)) continue;

      if (key is ComputedIndicatorKey) {
        releaseComputedDataIndex(key);
      }

      _subIndicatorRegistry.remove(key);

      final result = removeSubPaintObject(key);

      logi('_subDiffAndSync: 移除指标 $key > $result');
    }

    // 新增或更新：维护声明缓存，已激活对象同步配置。
    for (final entry in newMap.entries) {
      final key = entry.key;
      final newIndicator = entry.value;

      if (!oldMap.containsKey(key)) {
        if (key is ComputedIndicatorKey) {
          allocateComputedDataIndexes([key]);
        }
        _subIndicatorRegistry[key] = newIndicator;
        logi('_subDiffAndSync: 新增指标 $key $computedDataCount');
      } else {
        _subIndicatorRegistry[key] = newIndicator;

        final paintObject = _subPaintObjectQueue.firstWhereOrNull(
          (obj) => obj.key == key,
        );
        if (paintObject != null) {
          paintObject.doDidUpdateIndicator(newIndicator);
          logi('_subDiffAndSync: 更新指标 $key');
        }
      }
    }
  }

  /// 将 [Indicator] 实例化为 [PaintObject] 并挂载。
  P _inflateIndicator<T extends Indicator, P extends PaintObject>(
    T indicator,
    PaintContext context,
  ) {
    final paintObject = indicator.createPaintObject();
    paintObject.mount(indicator, context);
    return paintObject as P;
  }

  /// 在主区中添加 [key] 指定的指标。
  ///
  /// 从 [_mainIndicatorRegistry] 中获取 Indicator，inflate 后追加到主区绘制队列。
  /// key 未注册时静默跳过并记录警告。
  PaintObject? addMainPaintObject(
    IIndicatorKey key,
    PaintContext context, {
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

    final indicator = _mainIndicatorRegistry[key];
    if (indicator == null) return null;

    final newObj = _inflateIndicator(indicator, context);
    _mainPaintObject.appendPaintObject(newObj);
    return newObj;
  }

  /// 删除已激活的主区指标。
  bool removeMainPaintObject(IIndicatorKey key) {
    return _mainPaintObject.removePaintObject(key);
  }

  /// 在副区中添加 [key] 指定的指标。
  ///
  /// 从 [_subIndicatorRegistry] 中获取 Indicator，inflate 后追加到副区绘制队列。
  /// key 未注册时静默跳过并记录警告。
  PaintObject? addSubPaintObject(
    IIndicatorKey key,
    PaintContext context, {
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

    final indicator = _subIndicatorRegistry[key];
    if (indicator == null) return null;

    final newObj = _inflateIndicator(indicator, context);
    flexiKlineConfig.sub.add(key);
    final oldObj = _subPaintObjectQueue.append(newObj);
    oldObj?.dispose();
    return newObj;
  }

  /// 删除已激活的副区指标。
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

  void restoreHeight() {
    mainPaintObject.restoreSize();
    for (final object in subPaintObjects) {
      object.restoreHeight();
    }
  }

  /// 保存当前激活状态和已同步的布局配置。
  void storeFlexiKlineConfig() {
    if (!_isInitialized) return;
    flexiKlineConfig.sub = subIndicatorKeys.toSet();
    flexiKlineConfig.mainIndicator = mainPaintObject.indicator.copyWith(
      size: flexiKlineConfig.mainIndicator.size,
    );
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
  }

  void dispose() {
    if (!_isInitialized) return;
    _isInitialized = false;
    mainPaintObject.dispose();
    for (final object in subPaintObjects) {
      object.dispose();
    }
    _subPaintObjectQueue.clear();
  }
}
