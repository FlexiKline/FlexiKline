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

/// 配置重载引起的指标激活集合差异。
///
/// 由 [IndicatorPaintObjectManager.reloadFlexiKlineConfig] 产出，交由 Controller 走
/// `show*/hide*` 收敛——激活需要指标重算与布局校验能力，只有 Controller 层具备。
typedef IndicatorActivationDiff = ({
  Set<IIndicatorKey> mainToShow,
  Set<IIndicatorKey> mainToHide,
  Set<IIndicatorKey> subToShow,
  Set<IIndicatorKey> subToHide,
});

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

  /// ComputedIndicator 的计算器缓存，与 [_computedDataIndexes] 平行。
  ///
  /// 在 `dataIndex` 确认后即时创建（见 [_bindCalculator]），slot 回收时同步移除。
  /// 同一批计算器可复用于多份 [KlineData]（dataIndex 布局稳定），是后台预加载的基础。
  final Map<ComputedIndicatorKey, IndicatorCalculator> _calculators = {};

  /// 获取 [key] 对应的计算器。
  IndicatorCalculator? getCalculator(ComputedIndicatorKey key) => _calculators[key];

  /// 当前绘制树里（显示中的）computed 指标的计算器，供计算引擎遍历。
  ///
  /// 顺序与原 precompute 遍历面一致：主区（children 已按 zIndex 有序）后副区。
  Iterable<IndicatorCalculator> get visibleCalculators sync* {
    for (final obj in _mainPaintObject.children.whereType<ComputedPaintObject>()) {
      final c = _calculators[obj.key as ComputedIndicatorKey];
      if (c != null) yield c;
    }
    for (final obj in subPaintObjects.whereType<ComputedPaintObject>()) {
      final c = _calculators[obj.key as ComputedIndicatorKey];
      if (c != null) yield c;
    }
  }

  /// slot 已分配且声明 indicator 就绪后调用，创建/重建计算器。
  void _bindCalculator(ComputedIndicatorKey key, ComputedIndicator indicator) {
    final slot = _computedDataIndexes[key];
    if (slot != null) _calculators[key] = indicator.createCalculator(slot);
  }

  /// 已回收的 slot，按 FIFO 复用。
  final Queue<int> _recycledSlots = Queue<int>();

  /// 已分配过的 slot 容量，只增不减（高水位）。
  ///
  /// 回收 slot 只放回 [_recycledSlots]，不缩减此容量，
  /// 以保证 [computedDataCapacity] 始终大于任意存活指标的 slot 索引。
  int _computedDataCapacity = 0;

  /// keepAlive 常驻对象缓存，按 key 管理。
  /// PaintObject 在 hide 时若 keepAlive=true，则进入此缓存供下次 show 复用。
  final Map<IIndicatorKey, PaintObject> _keepAlivePaintObjects = {};

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

  /// 已分配的 computed data slot 容量（高水位），而非当前存活声明数量。
  ///
  /// 用于给新蜡烛的 slots 数组定长；容量只增不减，
  /// 确保删除中间指标后，仍存活的高位 slot 不会越界。
  int get computedDataCapacity => _computedDataCapacity;

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
        slot = _computedDataCapacity++;
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
    _calculators.remove(key);
    if (index != null) {
      _recycledSlots.addLast(index);
      logi('releaseComputedDataIndex $key:$index');
    }
  }

  /// 挂载 Widget 声明的指标，并恢复已激活的主区/副区指标。
  void mountIndicators({
    required PaintContext context,
    required CandleBaseIndicator candle,
    required TimeBaseIndicator time,
    required List<Indicator> mainIndicators,
    required List<Indicator> subIndicators,
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

    // 缓存声明层指标，并为 computed 指标即时创建计算器。
    for (final indicator in mainIndicators) {
      _mainIndicatorRegistry[indicator.key] = indicator;
      if (indicator is ComputedIndicator) {
        _bindCalculator(indicator.key, indicator);
      }
    }
    for (final indicator in subIndicators) {
      _subIndicatorRegistry[indicator.key] = indicator;
      if (indicator is ComputedIndicator) {
        _bindCalculator(indicator.key, indicator);
      }
    }

    // 创建系统级 PaintObject。
    _candlePaintObject = _inflateIndicator<CandleBaseIndicator, CandleBasePaintObject>(candle, context);
    _timePaintObject = _inflateIndicator<TimeBaseIndicator, TimeBasePaintObject>(time, context);

    // copyWith 隔离 size（值类型字段，独立存储），避免布局更新污染配置尺寸；
    // children 有意与配置共享同一 Set（copyWith 对其传引用、构造函数不复制），
    // 主区激活集合因此实时写入配置，无需在 add/removePaintObject 处额外同步。
    final mainIndicator = flexiKlineConfig.mainIndicator.copyWith();
    _mainPaintObject = _inflateIndicator<MainPaintObjectIndicator, MainPaintObject>(mainIndicator, context);

    // 恢复已激活指标：持久化恢复的 key ∪ autoActivate 声明，去重后入树。
    _mainPaintObject.appendPaintObject(_candlePaintObject);

    final autoMainKeys = mainIndicators.where((i) => i.autoActivate).map((i) => i.key);
    for (final key in {...mainIndicator.children, ...autoMainKeys}) {
      if (key == candleIndicatorKey) continue; // candle 已单独挂载
      if (_mainPaintObject.getChildPaintObject(key) == null) {
        addMainPaintObject(key, context);
      }
    }

    final autoSubKeys = subIndicators.where((i) => i.autoActivate).map((i) => i.key);
    for (final key in {...flexiKlineConfig.sub, ...autoSubKeys}) {
      if (_subPaintObjectQueue.any((object) => object.key == key)) continue;
      addSubPaintObject(key, context);
    }
    _isInitialized = true;
  }

  /// 按 Widget 新旧声明增量同步指标。
  ({
    List<IIndicatorKey> main,
    List<IIndicatorKey> sub,
    List<ComputedIndicatorKey> recompute,
    bool slotLayoutChanged,
  }) updateIndicators({
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
    final oldComputedDataIndexes = Map<ComputedIndicatorKey, int>.of(_computedDataIndexes);

    // candle/time 无条件更新。
    _candlePaintObject.doDidUpdateIndicator(newCandle);

    _timePaintObject.doDidUpdateIndicator(newTime);

    // 参数变化需重算的 computed key（由 controller 驱动 KlineDataPipeline.recompute）。
    final recompute = <ComputedIndicatorKey>[];

    // 同步主区声明集合。
    final mainKeys = _mainDiffAndSync(
      context: context,
      oldIndicators: oldMainIndicators,
      newIndicators: newMainIndicators,
      recompute: recompute,
    );

    // 同步副区声明集合。
    final subKeys = _subDiffAndSync(
      context: context,
      oldIndicators: oldSubIndicators,
      newIndicators: newSubIndicators,
      recompute: recompute,
    );

    final slotLayoutChanged = oldComputedDataIndexes.length != _computedDataIndexes.length ||
        oldComputedDataIndexes.entries.any((entry) => _computedDataIndexes[entry.key] != entry.value);
    logi('updateIndicators 完成: computedDataCapacity=$computedDataCapacity');
    return (
      main: mainKeys,
      sub: subKeys,
      recompute: recompute,
      slotLayoutChanged: slotLayoutChanged,
    );
  }

  /// 同步主区声明集合；新增只缓存，不自动激活。
  ///
  /// 返回本轮需激活的 key（autoActivate 的新增声明，或由 false 翻转为 true 且未激活的更新声明）。
  List<IIndicatorKey> _mainDiffAndSync({
    required PaintContext context,
    required List<Indicator> oldIndicators,
    required List<Indicator> newIndicators,
    required List<ComputedIndicatorKey> recompute,
  }) {
    final toActivate = <IIndicatorKey>[];
    final oldMap = {for (final ind in oldIndicators) ind.key: ind};
    final newMap = {for (final ind in newIndicators) ind.key: ind};

    // 移除：回收 slot、删除缓存和已激活对象。
    for (final key in oldMap.keys) {
      if (newMap.containsKey(key)) continue;

      if (key is ComputedIndicatorKey) {
        releaseComputedDataIndex(key);
      }

      _mainIndicatorRegistry.remove(key);

      final result = disposeMainPaintObject(key);

      logi('_mainDiffAndSync: 移除指标 $key > $result');
    }

    // 新增或更新：维护声明缓存，已激活对象同步配置。
    for (final entry in newMap.entries) {
      final key = entry.key;
      final newIndicator = entry.value;

      if (!oldMap.containsKey(key)) {
        if (key is ComputedIndicatorKey && newIndicator is ComputedIndicator) {
          allocateComputedDataIndexes([key]);
          _bindCalculator(key, newIndicator);
        }
        _mainIndicatorRegistry[key] = newIndicator;
        if (newIndicator.autoActivate) toActivate.add(key);
        logi('_mainDiffAndSync: 新增指标 $key $computedDataCapacity');
      } else {
        final oldIndicator = oldMap[key]!;
        _mainIndicatorRegistry[key] = newIndicator;
        if (key is ComputedIndicatorKey &&
            newIndicator is ComputedIndicator &&
            oldIndicator is ComputedIndicator &&
            newIndicator.shouldRecompute(oldIndicator)) {
          _bindCalculator(key, newIndicator);
          recompute.add(key);
        }
        final paintObject = getMainPaintObject(key, includeKeepAlive: true);
        if (paintObject != null) {
          paintObject.doDidUpdateIndicator(newIndicator);
          logi('_mainDiffAndSync: 更新指标 $key');
        }
        if (!oldIndicator.autoActivate &&
            newIndicator.autoActivate &&
            _mainPaintObject.getChildPaintObject(key) == null) {
          toActivate.add(key);
        }
      }
    }

    return toActivate;
  }

  /// 同步副区声明集合；新增只缓存，不自动激活。
  ///
  /// 返回本轮需激活的 key（autoActivate 的新增声明，或由 false 翻转为 true 且未激活的更新声明）。
  List<IIndicatorKey> _subDiffAndSync({
    required List<Indicator> oldIndicators,
    required List<Indicator> newIndicators,
    required PaintContext context,
    required List<ComputedIndicatorKey> recompute,
  }) {
    final toActivate = <IIndicatorKey>[];
    final oldMap = {for (final ind in oldIndicators) ind.key: ind};
    final newMap = {for (final ind in newIndicators) ind.key: ind};

    // 移除：回收 slot、删除缓存和已激活对象。
    for (final key in oldMap.keys) {
      if (newMap.containsKey(key)) continue;

      if (key is ComputedIndicatorKey) {
        releaseComputedDataIndex(key);
      }

      _subIndicatorRegistry.remove(key);

      final result = disposeSubPaintObject(key);

      logi('_subDiffAndSync: 移除指标 $key > $result');
    }

    // 新增或更新：维护声明缓存，已激活对象同步配置。
    for (final entry in newMap.entries) {
      final key = entry.key;
      final newIndicator = entry.value;

      if (!oldMap.containsKey(key)) {
        if (key is ComputedIndicatorKey && newIndicator is ComputedIndicator) {
          allocateComputedDataIndexes([key]);
          _bindCalculator(key, newIndicator);
        }
        _subIndicatorRegistry[key] = newIndicator;
        if (newIndicator.autoActivate) toActivate.add(key);
        logi('_subDiffAndSync: 新增指标 $key $computedDataCapacity');
      } else {
        final oldIndicator = oldMap[key]!;
        _subIndicatorRegistry[key] = newIndicator;
        if (key is ComputedIndicatorKey &&
            newIndicator is ComputedIndicator &&
            oldIndicator is ComputedIndicator &&
            newIndicator.shouldRecompute(oldIndicator)) {
          _bindCalculator(key, newIndicator);
          recompute.add(key);
        }
        final paintObject = getSubPaintObject(key, includeKeepAlive: true);
        if (paintObject != null) {
          paintObject.doDidUpdateIndicator(newIndicator);
          logi('_subDiffAndSync: 更新指标 $key');
        }
        if (!oldIndicator.autoActivate &&
            newIndicator.autoActivate &&
            _subPaintObjectQueue.every((object) => object.key != key)) {
          toActivate.add(key);
        }
      }
    }

    return toActivate;
  }

  /// 将 [Indicator] 实例化为 [PaintObject] 并挂载。
  P _inflateIndicator<T extends Indicator, P extends PaintObject>(
    T indicator,
    PaintContext context,
  ) {
    final paintObject = indicator.createPaintObject();
    paintObject.mount(indicator, context);
    paintObject.doInitState();
    return paintObject as P;
  }

  /// 解析激活对象来源：缓存命中复用常驻对象，否则现场 inflate。
  PaintObject? _resolvePaintObject(Indicator indicator, PaintContext context) {
    final cached = _keepAlivePaintObjects[indicator.key];
    if (cached != null) return cached;
    return _inflateIndicator(indicator, context);
  }

  /// 查找主区指标 [key] 的 PaintObject。
  ///
  /// 优先返回主区绘制树中的激活对象；[includeKeepAlive] 为 true 时，
  /// 若树中没有则回退到 keepAlive 缓存（可能是已 detach 的常驻对象）。
  PaintObject? getMainPaintObject(IIndicatorKey key, {bool includeKeepAlive = false}) {
    final obj = _mainPaintObject.getChildPaintObject(key);
    if (obj != null) return obj;
    return includeKeepAlive ? _keepAlivePaintObjects[key] : null;
  }

  /// 强制销毁主区指标 [key]（含缓存中已 detach 的 keepAlive 对象），不受 [PaintObject.keepAlive] 影响。
  ///
  /// 用于声明移除等需要彻底销毁的场景；与 [removeMainPaintObject] 的隐藏保活相区别。
  bool disposeMainPaintObject(IIndicatorKey key) {
    final obj = getMainPaintObject(key, includeKeepAlive: true);
    final removed = _mainPaintObject.removePaintObject(key);
    _keepAlivePaintObjects.remove(key);
    if (obj != null && !obj.isDisposed) obj.dispose();
    return obj != null || removed;
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

    final newObj = _resolvePaintObject(indicator, context);
    if (newObj == null) return null;
    _mainPaintObject.appendPaintObject(newObj);
    return newObj;
  }

  /// 删除已激活的主区指标。
  bool removeMainPaintObject(IIndicatorKey key) {
    final obj = _mainPaintObject.getChildPaintObject(key);
    if (obj != null && obj.keepAlive) _keepAlivePaintObjects[key] = obj;
    return _mainPaintObject.removePaintObject(key);
  }

  /// 查找副区指标 [key] 的 PaintObject。
  ///
  /// 优先返回副区绘制队列中的激活对象；[includeKeepAlive] 为 true 时，
  /// 若队列中没有则回退到 keepAlive 缓存（可能是已 detach 的常驻对象）。
  PaintObject? getSubPaintObject(IIndicatorKey key, {bool includeKeepAlive = false}) {
    final obj = _subPaintObjectQueue.firstWhereOrNull((object) => object.key == key);
    if (obj != null) return obj;
    return includeKeepAlive ? _keepAlivePaintObjects[key] : null;
  }

  /// 强制销毁副区指标 [key]（含缓存中已 detach 的 keepAlive 对象），不受 [PaintObject.keepAlive] 影响。
  ///
  /// 用于声明移除等需要彻底销毁的场景；与 [removeSubPaintObject] 的隐藏保活相区别。
  bool disposeSubPaintObject(IIndicatorKey key) {
    final obj = getSubPaintObject(key, includeKeepAlive: true);
    final removed = removeSubPaintObject(key);
    _keepAlivePaintObjects.remove(key);
    if (obj != null && !obj.isDisposed) obj.dispose();
    return obj != null || removed;
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

    final newObj = _resolvePaintObject(indicator, context);
    if (newObj == null) return null;
    flexiKlineConfig.sub.add(key);
    // 容量满且新元素不在队列时，队首将被驱逐；FixedHashQueue 不返回被驱逐项，需先退树。
    if (_subPaintObjectQueue.length >= _subPaintObjectQueue.fixedCapacity && !_subPaintObjectQueue.contains(newObj)) {
      if (_subPaintObjectQueue.isNotEmpty) {
        final evicted = _subPaintObjectQueue.first;
        if (evicted.keepAlive) _keepAlivePaintObjects[evicted.key] = evicted;
        // 被驱逐的 key 必须同步摘出配置：配置是激活集合的实时镜像，
        // 留着会让 sub 超出队列容量，reload 的差异永不收敛（每次补一个又驱逐一个）。
        flexiKlineConfig.sub.remove(evicted.key);
        evicted.onExitTree();
      }
    }
    final oldObj = _subPaintObjectQueue.append(newObj);
    // 就地替换：keepAlive=false 走 dispose，keepAlive=true 入缓存保活。
    if (oldObj != null) {
      if (oldObj.keepAlive) _keepAlivePaintObjects[oldObj.key] = oldObj;
      oldObj.onExitTree();
    }
    // 进树钩子：external 触发 didAttach。
    newObj.onEnterTree();
    return newObj;
  }

  /// 删除已激活的副区指标。
  ///
  /// 返回值只表示"是否从绘制队列摘除"；配置侧无条件清理，使历史持久化数据里
  /// 因驱逐而残留的 key 也能被显式隐藏清除。
  bool removeSubPaintObject(IIndicatorKey key) {
    bool hasRemove = false;
    _subPaintObjectQueue.removeWhere((obj) {
      if (obj.indicator.key == key) {
        if (obj.keepAlive) _keepAlivePaintObjects[key] = obj;
        obj.onExitTree();
        hasRemove = true;
        return true;
      }
      return false;
    });
    flexiKlineConfig.sub.remove(key);
    return hasRemove;
  }

  void restoreHeight() {
    mainPaintObject.restoreSize();
    for (final object in subPaintObjects) {
      object.restoreHeight();
    }
  }

  /// 落盘当前配置。
  ///
  /// 配置对象始终是运行时状态的实时镜像——激活集合由 add/remove PaintObject 直接写入
  /// 配置的集合（主区 children 与运行时 indicator 共享同一 Set，见 [mountIndicators]），
  /// 主区尺寸由布局路径同步，蜡烛宽度由 Controller 在缩放结束时写回——因此此处不做
  /// 任何状态收集，只把当前配置交给 [configuration] 持久化。
  void storeFlexiKlineConfig() {
    if (!_isInitialized) return;
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
  }

  /// 未挂载时的空差异。
  IndicatorActivationDiff get _emptyActivationDiff => (
        mainToShow: <IIndicatorKey>{},
        mainToHide: <IIndicatorKey>{},
        subToShow: <IIndicatorKey>{},
        subToHide: <IIndicatorKey>{},
      );

  /// 重新载入配置，并让主区运行时 indicator 跟随新配置。
  ///
  /// [config] 为空时由 [configuration] 提供；实现返回共享实例时为自赋值，返回新实例时
  /// 为换指针，两种情况下后续处理相同。
  ///
  /// 返回激活集合差异，由 Controller 走 `show*/hide*` 收敛，以复用其中的指标重算与
  /// 布局校验。未挂载时只替换配置，不触碰绘制树。
  IndicatorActivationDiff reloadFlexiKlineConfig([FlexiKlineConfig? config]) {
    _flexiKlineConfig = config ?? configuration.getFlexiKlineConfig();

    if (!_isInitialized) return _emptyActivationDiff;

    final currentMain = mainIndicatorKeys.toSet();
    final currentSub = subIndicatorKeys.toSet();
    // 目标集合必须是复制的快照：children 就是运行时那个 Set（见 [mountIndicators]），
    // 后续 show/hide 会改它。
    final targetMain = _flexiKlineConfig.mainIndicator.children.where(hasRegisteredInMain).toSet();
    final targetSub = _flexiKlineConfig.sub.where(hasRegisteredInSub).toSet();

    // 不传 children：copyWith 沿用新配置的 children 引用，重建"运行时 indicator 与
    // 配置共享同一 Set"的关系。配置返回共享实例时是自赋值；返回新实例时把运行时接到
    // 新 Set 上——否则 [_flexiKlineConfig] 换了指针而运行时仍改着旧 Set，落盘会陈旧。
    // size 显式保留运行时持久值：它是窗口局部状态，不随配置回灌。取 indicator.size 而非
    // [MainPaintObject.size]，后者是 `_tmpSize ?? indicator.size`，fixed 下会把临时
    // 尺寸写成持久尺寸。
    _mainPaintObject.doDidUpdateIndicator(
      _flexiKlineConfig.mainIndicator.copyWith(size: _mainPaintObject.indicator.size),
    );

    return (
      // candle 由 mountIndicators 直接挂载，来自旧版持久化的配置可能不含它，
      // 不排除会把它判为待隐藏。
      mainToHide: currentMain.difference(targetMain)..remove(candleIndicatorKey),
      mainToShow: targetMain.difference(currentMain),
      subToHide: currentSub.difference(targetSub),
      subToShow: targetSub.difference(currentSub),
    );
  }

  /// K 线 spec.key 变化时，通知 attached 树对象与 detached keepAlive 常驻对象（去重）。
  void notifySpecChanged(KlineSpec oldSpec) {
    // 未初始化时尚无任何 PaintObject（含 late 的 _mainPaintObject），直接跳过。
    if (!_isInitialized) return;
    final targets = <PaintObject>{
      ..._mainPaintObject.children,
      ..._subPaintObjectQueue,
      ..._keepAlivePaintObjects.values,
    };
    for (final obj in targets) {
      obj.doDidChangeDependencies(oldSpec);
    }
  }

  void dispose() {
    if (!_isInitialized) return;
    _isInitialized = false;
    mainPaintObject.dispose();
    for (final object in subPaintObjects) {
      object.dispose();
    }
    _subPaintObjectQueue.clear();
    // keepAlive 常驻缓存：跳过已在绘制树释放阶段 dispose 的对象，避免重复。
    for (final obj in _keepAlivePaintObjects.values) {
      if (!obj.isDisposed) obj.dispose();
    }
    _keepAlivePaintObjects.clear();
  }
}
