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

  /// 挂载所有指标（Widget initState 时调用）
  ///
  /// 将声明层的 Indicator 配置挂载为运行时的 PaintObject：
  /// 1. 注册 [DataIndicatorKey] → 分配 slot
  /// 2. 缓存所有 Indicator 实例
  /// 3. 创建系统级 PaintObject（candle/time/main）
  /// 4. 从持久化 key 恢复已选中的主区/副区指标
  void mountIndicators({
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

    // 2. 缓存所有 Indicator 实例
    for (final indicator in mainIndicators) {
      _mainIndicatorBuilders[indicator.key] = indicator;
    }
    for (final indicator in subIndicators) {
      _subIndicatorBuilders[indicator.key] = indicator;
    }

    // 3. 创建系统级 PaintObject（candle/time/main）
    _candlePaintObject = _inflateIndicator<CandleBaseIndicator, CandleBasePaintObject>(candle, context);
    _timePaintObject = _inflateIndicator<TimeBaseIndicator, TimeBasePaintObject>(time, context);

    final mainIndicator = flexiKlineConfig.mainIndicator;
    _mainPaintObject = _inflateIndicator<MainPaintObjectIndicator, MainPaintObject>(mainIndicator, context);

    // 4. 将 candle 追加到主区，并从持久化 key 恢复已选中指标
    _mainPaintObject.appendPaintObject(_candlePaintObject);

    for (final key in mainIndicator.children) {
      addMainPaintObject(key, context);
    }

    for (final key in flexiKlineConfig.sub) {
      addSubPaintObject(key, context);
    }
    _isInitialized = true;
  }

  /// 增量更新指标（didUpdateWidget 时调用）
  ///
  /// 1. candle/time 无条件更新（E1 策略）
  /// 2. diff main 声明集合
  /// 3. diff sub 声明集合
  void updateIndicators({
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

    logi('updateIndicators 完成: indicatorCount=$indicatorCount');
  }

  /// 基于 key set 的 diff 同步主区指标声明集合。
  ///
  /// - 移除：回收 slot + 从 [_mainIndicatorBuilders] 删除 + 销毁已激活的 PaintObject
  /// - 新增：注册 slot + 缓存到 [_mainIndicatorBuilders]（不自动激活）
  /// - 变化（key 相同）：更新缓存 + 已激活则调用 [PaintObject.doDidUpdateIndicator]
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

  /// 基于 key set 的 diff 同步副区指标声明集合。
  ///
  /// - 移除：回收 slot + 从 [_subIndicatorBuilders] 删除 + 销毁已激活的 PaintObject
  /// - 新增：注册 slot + 缓存到 [_subIndicatorBuilders]（不自动激活）
  /// - 变化（key 相同）：更新缓存 + 已激活则调用 [PaintObject.doDidUpdateIndicator]
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

  /// 将 [Indicator] 实例化为 PaintObject 并挂载，类比 Flutter 的 inflateWidget + Element.mount。
  /// 泛型 [P] 指定期望的 PaintObject 子类型，避免调用方手动 cast。
  P _inflateIndicator<T extends Indicator, P extends PaintObject>(
    T indicator,
    IPaintContext context,
  ) {
    final paintObject = indicator.createPaintObject();
    paintObject.mount(indicator, context);
    return paintObject as P;
  }

  /// 在主区中添加 [key] 指定的指标。
  ///
  /// 从 [_mainIndicatorBuilders] 缓存中获取 Indicator，inflate 后追加到主区绘制队列。
  /// key 未注册时静默跳过并记录警告。
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

    final newObj = _inflateIndicator(indicator, context);
    _mainPaintObject.appendPaintObject(newObj);
    return newObj;
  }

  /// 在已载入主区绘制对象中, 删除[key]指定的绘制对象
  bool removeMainPaintObject(IIndicatorKey key) {
    return _mainPaintObject.deletePaintObject(key);
  }

  /// 在副区中添加 [key] 指定的指标。
  ///
  /// 从 [_subIndicatorBuilders] 缓存中获取 Indicator，inflate 后追加到副区绘制队列。
  /// key 未注册时静默跳过并记录警告。
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

    final newObj = _inflateIndicator(indicator, context);
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
