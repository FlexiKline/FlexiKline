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
///
/// 主要负责:
/// 1. 根据 Widget 声明的指标初始化绘制对象（两层模型：声明层 + 激活层）
/// 2. 管理 DataIndicator 的 slot 分配与回收
/// 3. 负责指标对象的创建/销毁
/// 4. 管理副图指标绘制对象队列
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

  /// 动态维护指标计算数据存储位置
  ///
  /// 仅对 [DataIndicatorKey]（数据指标）分配 slot。
  final Map<DataIndicatorKey, int> _indicatorDataIndexs = {};

  /// 已回收的 slot index 队列，按 FIFO 顺序复用
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

  /// 主区指标配置构造器
  final Map<IIndicatorKey, Indicator> _mainIndicatorBuilders = {};

  /// 副区指标配置构造器
  final Map<IIndicatorKey, Indicator> _subIndicatorBuilders = {};

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

  bool hasRegisteredInMain(IIndicatorKey key) {
    return _mainIndicatorBuilders.containsKey(key) || key == candleIndicatorKey;
  }

  bool hasRegisteredInSub(IIndicatorKey key) {
    return _subIndicatorBuilders.containsKey(key) || key == timeIndicatorKey;
  }

  int? getIndicatorDataIndex(DataIndicatorKey key) {
    return _indicatorDataIndexs[key];
  }

  int get indicatorCount => _indicatorDataIndexs.length;

  /// 注册 [DataIndicatorKey] 列表，为每个 key 分配 slot。
  ///
  /// 优先从 [_recycledSlots] 复用已回收的 slot index；
  /// 已注册的 key 会被跳过。
  int registerDataIndicatorKeys(List<DataIndicatorKey> keys) {
    for (final key in keys) {
      if (_indicatorDataIndexs.containsKey(key)) continue;
      final int slot;
      if (_recycledSlots.isNotEmpty) {
        slot = _recycledSlots.removeFirst();
      } else {
        slot = _indicatorDataIndexs.length;
      }
      _indicatorDataIndexs[key] = slot;
      logi('registerDataIndicatorKey $key:$slot');
    }
    return _indicatorDataIndexs.length;
  }

  /// 回收 [DataIndicatorKey] 的 slot。
  ///
  /// 将 slot index 加入 [_recycledSlots] 以供后续复用，
  /// 不清理蜡烛数据中对应位置的值（惰性清理，下次复用时自然覆盖）。
  void recycleDataIndicatorSlot(DataIndicatorKey key) {
    final index = _indicatorDataIndexs.remove(key);
    if (index != null) {
      _recycledSlots.addLast(index);
      logi('recycleDataIndicatorSlot $key:$index');
    }
  }

  /// 首次全量同步（initState 时调用）
  ///
  /// 注册 [DataIndicatorKey] → 分配 slot → 缓存 [Indicator]
  /// → 创建 candle/time [PaintObject]（不创建 main/sub PaintObject）。
  void syncAllIndicators({
    required CandleBaseIndicator candle,
    required TimeBaseIndicator time,
    required List<Indicator> mainIndicators,
    required List<Indicator> subIndicators,
    required IPaintContext context,
  }) {
    // 1. 收集所有 DataIndicatorKey 并注册 slot
    final dataKeys = <DataIndicatorKey>[
      for (final indicator in mainIndicators)
        if (indicator.key is DataIndicatorKey) indicator.key as DataIndicatorKey,
      for (final indicator in subIndicators)
        if (indicator.key is DataIndicatorKey) indicator.key as DataIndicatorKey,
    ];
    registerDataIndicatorKeys(dataKeys);

    // 2. 缓存所有 Indicator 实例到 _declaredIndicators
    for (final indicator in mainIndicators) {
      _mainIndicatorBuilders[indicator.key] = indicator;
    }
    for (final indicator in subIndicators) {
      _subIndicatorBuilders[indicator.key] = indicator;
    }

    // 3. 创建 candle/time PaintObject（系统必须）
    _candlePaintObject = _createAndInitPaintObject(candle, context) as CandleBasePaintObject;
    _timePaintObject = _createAndInitPaintObject(time, context) as TimeBasePaintObject;
  }

  /// 增量同步（didUpdateWidget 时调用）
  ///
  /// 1. candle/time 无条件更新（E1 策略）
  /// 2. diff main 声明集合
  /// 3. diff sub 声明集合
  void syncIndicators({
    required IPaintContext context,
    required CandleBaseIndicator oldCandle,
    required CandleBaseIndicator newCandle,
    required TimeBaseIndicator oldTime,
    required TimeBaseIndicator newTime,
    required List<Indicator> oldMainIndicators,
    required List<Indicator> newMainIndicators,
    required List<Indicator> oldSubIndicators,
    required List<Indicator> newSubIndicators,
  }) {
    // 1. E1 无条件更新 candle
    _candlePaintObject.doDidUpdateIndicator(newCandle);

    // 2. E1 无条件更新 time
    _timePaintObject.doDidUpdateIndicator(newTime);

    // 3. diff main 声明集合
    _mainDiffAndSync(
      context: context,
      oldIndicators: oldMainIndicators,
      newIndicators: newMainIndicators,
    );

    // 4. diff sub 声明集合
    _subDiffAndSync(
      context: context,
      oldIndicators: oldSubIndicators,
      newIndicators: newSubIndicators,
    );

    logi('syncIndicators 完成: indicatorCount=$indicatorCount');
  }

  /// 基于 key set 的 diff 同步指标声明集合。
  ///
  /// - 移除的指标：回收 slot + 从 [_declaredIndicators] 删除 +
  ///   如果已激活（PaintObject 存在）则销毁 PaintObject
  /// - 新增的指标：注册 slot + 缓存到 [_declaredIndicators]
  ///   （不自动激活，不创建 PaintObject）
  /// - 配置变化的指标（key 相同，实例不同）：更新 [_declaredIndicators] 缓存 +
  ///   如果已激活则调用 [PaintObject.doDidUpdateIndicator]
  void _mainDiffAndSync({
    required IPaintContext context,
    required List<Indicator> oldIndicators,
    required List<Indicator> newIndicators,
  }) {
    final oldMap = {for (final ind in oldIndicators) ind.key: ind};
    final newMap = {for (final ind in newIndicators) ind.key: ind};

    // Phase 1 — 移除：在 old 中但不在 new 中
    for (final key in oldMap.keys) {
      if (newMap.containsKey(key)) continue;

      // 回收 DataIndicatorKey 的 slot
      if (key is DataIndicatorKey) {
        recycleDataIndicatorSlot(key);
      }

      // 从声明缓存中删除
      _mainIndicatorBuilders.remove(key);

      // 如果已激活（PaintObject 存在），销毁 PaintObject
      final result = _mainPaintObject.deletePaintObject(key);

      logi('_mainDiffAndSync: 移除指标 $key > $result');
    }

    // Phase 2 — 新增 + 变化
    for (final entry in newMap.entries) {
      final key = entry.key;
      final newIndicator = entry.value;

      if (!oldMap.containsKey(key)) {
        // 新增指标：注册 slot + 缓存（不自动激活）
        if (key is DataIndicatorKey) {
          registerDataIndicatorKeys([key]);
        }
        _mainIndicatorBuilders[key] = newIndicator;
        logi('_mainDiffAndSync: 新增指标 $key $indicatorCount');
      } else {
        // key 相同：更新缓存 + 如果已激活则 doDidUpdateIndicator
        _mainIndicatorBuilders[key] = newIndicator;

        // 检查是否已激活
        final paintObject = _mainPaintObject.getChildPaintObject(key);
        if (paintObject != null) {
          paintObject.doDidUpdateIndicator(newIndicator);
          logi('_mainDiffAndSync: 更新指标 $key');
        }
      }
    }
  }

  /// 基于 key set 的 diff 同步指标声明集合。
  ///
  /// - 移除的指标：回收 slot + 从 [_declaredIndicators] 删除 +
  ///   如果已激活（PaintObject 存在）则销毁 PaintObject
  /// - 新增的指标：注册 slot + 缓存到 [_declaredIndicators]
  ///   （不自动激活，不创建 PaintObject）
  /// - 配置变化的指标（key 相同，实例不同）：更新 [_declaredIndicators] 缓存 +
  ///   如果已激活则调用 [PaintObject.doDidUpdateIndicator]
  void _subDiffAndSync({
    required List<Indicator> oldIndicators,
    required List<Indicator> newIndicators,
    required IPaintContext context,
  }) {
    final oldMap = {for (final ind in oldIndicators) ind.key: ind};
    final newMap = {for (final ind in newIndicators) ind.key: ind};

    // Phase 1 — 移除：在 old 中但不在 new 中
    for (final key in oldMap.keys) {
      if (newMap.containsKey(key)) continue;

      // 回收 DataIndicatorKey 的 slot
      if (key is DataIndicatorKey) {
        recycleDataIndicatorSlot(key);
      }

      // 从声明缓存中删除
      _subIndicatorBuilders.remove(key);

      // 如果已激活（PaintObject 存在），销毁 PaintObject
      final result = removeSubPaintObject(key);

      logi('_subDiffAndSync: 移除指标 $key > $result');
    }

    // Phase 2 — 新增 + 变化
    for (final entry in newMap.entries) {
      final key = entry.key;
      final newIndicator = entry.value;

      if (!oldMap.containsKey(key)) {
        // 新增指标：注册 slot + 缓存（不自动激活）
        if (key is DataIndicatorKey) {
          registerDataIndicatorKeys([key]);
        }
        _subIndicatorBuilders[key] = newIndicator;
        logi('_subDiffAndSync: 新增指标 $key $indicatorCount');
      } else {
        // key 相同：更新缓存 + 如果已激活则 doDidUpdateIndicator
        _subIndicatorBuilders[key] = newIndicator;

        // 检查是否已激活
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

  /// 创建并初始化 PaintObject
  PaintObject _createAndInitPaintObject<T extends Indicator>(
    T indicator,
    IPaintContext context,
  ) {
    final paintObject = indicator.createPaintObject();

    paintObject._indicator = indicator;
    paintObject.__context = context;

    // paintObject 已经混入了 KlineLog，所以直接设置
    if (context is FlexiLog) {
      paintObject.logger = (context as FlexiLog).logger;
    }

    return paintObject;
  }

  /// 初始化主区/副区指标
  ///
  /// 1. 创建 MainPaintObject（空壳）
  /// 2. 将 syncAllIndicators 已创建的 candle PaintObject 追加到主区
  /// 3. 从 [FlexiKlineConfig.mainIndicator.children] 读取持久化 key，
  ///    调用 [addMainPaintObject] 从 [_declaredIndicators] 创建 PaintObject
  /// 4. 从 [FlexiKlineConfig.sub] 读取持久化 key，
  ///    调用 [addSubPaintObject] 创建 PaintObject
  void init(IPaintContext context) {
    final mainIndicator = flexiKlineConfig.mainIndicator;

    // 1. 创建 MainPaintObject（空壳）
    _mainPaintObject = MainPaintObject();
    _mainPaintObject._indicator = mainIndicator.copyWith();
    _mainPaintObject.__context = context;
    if (context is FlexiLog) {
      _mainPaintObject.logger = (context as FlexiLog).logger;
    }

    // 2. 将 syncAllIndicators 已创建的 candle PaintObject 追加到主区
    _mainPaintObject.appendPaintObject(_candlePaintObject);

    // 3. 从持久化 key 恢复主区指标
    for (final key in mainIndicator.children) {
      addMainPaintObject(key, context);
    }

    // 4. 从持久化 key 恢复副区指标
    for (final key in flexiKlineConfig.sub) {
      addSubPaintObject(key, context);
    }
    _isInitialized = true;
  }

  /// 主区指标操作 ///
  /// 在主区中添加 [key] 指定的指标
  ///
  /// 从 [_declaredIndicators] 缓存中获取 Indicator 实例，
  /// 创建 PaintObject 并添加到主区绘制队列。
  /// 如果 key 不在 [_declaredIndicators] 中，静默跳过并记录警告。
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

    final indicator = _mainIndicatorBuilders[key];
    if (indicator == null) return null;

    final newObj = _createAndInitPaintObject(indicator, context);
    _mainPaintObject.appendPaintObject(newObj);
    return newObj;
  }

  /// 在已载入主区绘制对象中, 删除[key]指定的绘制对象
  bool removeMainPaintObject(IIndicatorKey key) {
    return _mainPaintObject.deletePaintObject(key);
  }

  /// 副区指标操作 ///
  /// 在副区中添加 [key] 指定的指标
  ///
  /// 从 [_declaredIndicators] 缓存中获取 Indicator 实例，
  /// 创建 PaintObject 并添加到副区绘制队列。
  /// 如果 key 不在 [_declaredIndicators] 中，静默跳过并记录警告。
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

    final indicator = _subIndicatorBuilders[key];
    if (indicator == null) return null;

    final newObj = _createAndInitPaintObject(indicator, context);
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

  /// 获取[key]指定的指标配置实例（先查主区, 再查副区）
  /// 1. 先从当前载入的绘制对象中查找
  /// 2. 如果未载入, 则从配置缓存中加载[key]对应的指标
  T? getIndicator<T extends Indicator>(IIndicatorKey key) {
    if (hasRegisteredInMain(key)) {
      Indicator? indicator = mainPaintObject.getChildIndicator(key);
      indicator ??= _mainIndicatorBuilders[key];
      return indicator is T ? indicator : null;
    } else if (hasRegisteredInSub(key)) {
      Indicator? indicator = subPaintObjects.firstWhereOrNull((obj) => obj.key == key)?.indicator;
      indicator ??= _subIndicatorBuilders[key];
      return indicator is T ? indicator : null;
    }
    return null;
  }

  /// 更新[indicator]指标配置
  ///
  /// WIS v4 模型下，指标配置由 Widget 参数声明，
  /// 配置变更走 Widget params → didUpdateWidget → syncIndicators 路径。
  /// 此方法仅保留运行时更新已激活 PaintObject 的能力，不再持久化。
  @Deprecated('WIS v4 模型下，指标配置由 Widget 参数声明，'
      '配置变更走 Widget params → didUpdateWidget → syncIndicators 路径。'
      '请勿再通过 updateIndicator 持久化指标配置。')
  bool updateIndicator<T extends Indicator>(T indicator, [bool forceSave = false]) {
    final key = indicator.key;
    if (hasRegisteredInMain(key)) {
      return mainPaintObject.updateChildIndicator(indicator);
    } else if (hasRegisteredInSub(key)) {
      final object = subPaintObjects.firstWhereOrNull((obj) => obj.key == key);
      if (object != null) {
        object.doDidUpdateIndicator(indicator);
        return true;
      }
    }
    return false;
  }

  /// 收集当前指标的计算参数
  /// 考虑在主区/副区同时存在的指标.
  // @Deprecated('废弃, 由PaintObject执行precompute')
  // Map<IIndicatorKey, dynamic> getIndicatorCalcParams() {
  //   final calcParams = mainPaintObject.getCalcParams();
  //   for (final object in subPaintObjects) {
  //     final params = object.getCalcParams();
  //     if (params.isEmpty) continue;
  //     calcParams.addAll(params);
  //   }
  //   return calcParams;
  // }

  void restoreHeight() {
    mainPaintObject.restoreSize();
    for (final object in subPaintObjects) {
      object.restoreHeight();
    }
  }

  /// 保存 FlexiKlineConfig（Activation_State + 布局信息）。
  /// 不再持久化单个指标配置。
  void storeFlexiKlineConfig({
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
    // 不再调用 mainPaintObject.doStoreConfig() 和 sub doStoreConfig()
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
