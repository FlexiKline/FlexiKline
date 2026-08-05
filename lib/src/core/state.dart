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

part of 'core.dart';

/// LoadMore接口
///
/// 加载[spec]指定范围内的历史数据.
typedef OnLoadMoreCandles = Future<void> Function(KlineSpec spec);

/// 将蜡烛图从[begin]动画移动到[end].
typedef MoveToPositionCallback = Future<bool> Function(
  double begin,
  double end,
);

/// 状态管理: 负责数据的管理, 缓存, 切换, 计算.
mixin StateBinding on KlineBindingBase, SettingBinding {
  @override
  void init() {
    super.init();
    logd('init state');
    _klineDataCache = FIFOHashMap(capacity: klineDataCacheCapacity);
  }

  @override
  void initState() {
    super.initState();
    logd('initState state');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose state');
    _klineSpecNotifier.dispose();
    _loadingStateNotifier.dispose();
    _isFirstCandleMovedOffScreenNotifier.dispose();
    _isMultiTouchNotifier.dispose();
    _intervalNotifier.dispose();
    _paintRangeNotifier.dispose();
    _klineDataCache.forEach((key, data) {
      data.dispose();
    });
    _klineData = KlineData.empty;
    _klineDataCache.clear();
    onLoadMoreCandles = null;
    moveToPositionCallback = null;
  }

  /// 加载更多回调
  OnLoadMoreCandles? onLoadMoreCandles;

  /// 蜡烛图位置动画回调，由手势Widget在挂载后注入.
  MoveToPositionCallback? moveToPositionCallback;

  /// 首根蜡烛是否移出屏幕 listenable。
  final _isFirstCandleMovedOffScreenNotifier = ValueNotifier(false);
  ValueListenable<bool> get isFirstCandleMovedOffScreenListenable {
    return _isFirstCandleMovedOffScreenNotifier;
  }

  /// 当前是否处于多指触摸（双指缩放）状态.
  final _isMultiTouchNotifier = ValueNotifier<bool>(false);
  ValueListenable<bool> get isMultiTouchListenable => _isMultiTouchNotifier;
  void setMultiTouch(bool value) {
    if (_isMultiTouchNotifier.value != value) {
      _isMultiTouchNotifier.value = value;
    }
  }

  /// 当前 KlineData 的 TimeInterval listenable。
  final _intervalNotifier = ValueNotifier<ITimeInterval?>(null);
  ValueListenable<ITimeInterval?> get intervalListenable => _intervalNotifier;

  /// KlineSpec 变化 notifier。
  final _klineSpecNotifier = ValueNotifier<KlineSpec>(KlineData.empty.spec);

  /// 加载状态变化 notifier。
  final _loadingStateNotifier = ValueNotifier<KlineLoadingState>(KlineLoadingState.none);

  @override
  ValueListenable<KlineSpec> get klineSpecListenable => _klineSpecNotifier;

  @override
  ValueListenable<KlineLoadingState> get loadingStateListenable => _loadingStateNotifier;

  /// 当前 KlineData 绘制范围 listenable。
  final _paintRangeNotifier = ValueNotifier<Range?>(null);

  ValueListenable<Range?> get paintRangeListenable {
    return _paintRangeNotifier;
  }

  void _notifySpecChange(KlineSpec spec) {
    logd('_notifySpecChange $klineDataKey, spec:$spec');
    if (spec.key == klineDataKey) {
      onKlineSpecChanged(_klineSpecNotifier.value);
      _klineSpecNotifier.value = spec;
      _intervalNotifier.value = spec.interval;
    }
  }

  void _notifyLoadingState(KlineLoadingState state, String key) {
    logd('_notifyLoadingState key:$key, state:$state');
    if (key == klineDataKey) {
      _loadingStateNotifier.value = state;
    }
  }

  late final FIFOHashMap<String, KlineData> _klineDataCache;
  KlineData _klineData = KlineData.empty;

  @override
  KlineData get klineData => _klineData;

  /// 当前 K 线数据缓存 key。
  String get klineDataKey => klineData.key;

  void evictInactiveKlineDataCache() {
    final retainedKey = klineDataKey;
    _klineDataCache.removeWhere((key, data) {
      if (key != retainedKey) {
        data.dispose();
        return true;
      }
      return false;
    });
  }

  @override
  @protected
  void syncComputedSlotCapacity() {
    // 当前数据：按最新容量扩容已有蜡烛的 slots。
    klineData.rebuildSlots(computedDataCapacity);
    // 其余缓存：指标声明已变，其 slot 值已陈旧，直接丢弃，下次切换重新加载。
    evictInactiveKlineDataCache();
  }

  /// 设置当前KlineData:
  /// 1. 通知timeInterval变更
  /// 2. 初始化首根蜡烛绘制位置于屏幕右侧[getInitPaintDxOffset]指定处.
  /// 3. 重绘图表
  /// 4. 取消Cross绘制(如果有)
  void _setKlineData(KlineData data, {bool resetPaintDxOffset = true}) {
    _klineData = data;
    _notifySpecChange(data.spec);
    _notifyLoadingState(data.loadingState, data.key);
    if (resetPaintDxOffset && isMounted) {
      paintDxOffset = getInitPaintDxOffset();
    }
    markRepaintChart(reset: true);
    markRepaintDraw();
    requestCancelCross();
  }

  /// 最大绘制宽度
  double get maxPaintWidth => klineData.length * candleActualWidth;

  @override
  FlexiCandleModel? dxToCandle(double dx) {
    final index = dxToIndex(dx);
    return klineData.get(index);
  }

  /// 将[dx]转换为当前绘制区域对应的蜡烛的下标.
  @override
  int? dxToIndex(double dx) {
    return mainPaintObject.dxToIndex(dx).toInt();
  }

  /// 将[index]转换为当前绘制区域对应的X轴坐标.
  @override
  double? indexToDx(int index, {bool check = false}) {
    return mainPaintObject.indexToDx(index, check: check);
  }

  /// 将 [index] 转换为蜡烛中心的 X 坐标。
  double? indexToCandleDx(int index, {bool check = false}) {
    final dx = indexToDx(index, check: false);
    if (dx == null) return null;

    final candleDx = dx - candleWidthHalf;
    if (check && !mainChartRect.includeDx(candleDx)) return null;
    return candleDx;
  }

  /// 将[dx]精确转换为蜡烛的时间戳ts, 差异部分补充到ts中.
  @override
  int? dxToTimestamp(double dx) {
    final indexValue = mainPaintObject.dxToIndex(dx);
    // if (indexValue == null) return null;
    final ts = klineData.indexToTimestamp(indexValue);
    return ts;
  }

  /// 将时间戳[ts]精确转换为dx坐标, 并将差异部分汇总到dx中.
  @override
  double? timestampToDx(int ts) {
    final indexValue = klineData.timestampToIndex(ts);
    if (indexValue == null) return null;
    final dx = mainPaintObject.indexToDx(indexValue, check: false);
    return dx;
  }

  @override
  double valueToDy(FlexiNum value, {bool correct = false}) {
    return mainPaintObject.valueToDy(value, correct: correct);
  }

  @override
  FlexiNum? dyToValue(double dy, {bool check = false}) {
    return mainPaintObject.dyToValue(dy, check: check);
  }

  @override
  double candleValueToDy(FlexiNum value, {bool correct = false}) {
    return candlePaintObject.valueToDy(value, correct: correct);
  }

  @override
  FlexiNum? dyToCandleValue(double dy, {bool check = false}) {
    return candlePaintObject.dyToValue(dy, check: check);
  }

  /// 当前canvas绘制区域起始蜡烛右部dx值.
  @override
  double get startCandleDx {
    if (paintDxOffset == 0) {
      return mainChartRight;
    } else if (paintDxOffset > 0) {
      return mainChartRight + paintDxOffset % candleActualWidth;
    } else {
      return mainChartRight + paintDxOffset;
    }
  }

  /// 画布是否可以从右向左进行平移.
  bool get canPanRTL => paintDxOffset > minPaintDxOffset;

  /// 画布是否可以从左向右进行平移.
  bool get canPanLTR {
    return paintDxOffset < maxPaintDxOffset;
  }

  double _paintDxOffset = 0;

  /// 代表当前绘制区域相对于startIndex右侧的偏移量.
  /// 1. 当为零时(默认) : 说明首根蜡烛在Canvas右边界展示.
  /// 2. 当为负数时     : 代表首根蜡烛到Canvas右边界的距离.
  /// 3. 当为正数时     : 说明首根蜡烛已向右移出Canvas.
  ///     移出右边界的蜡烛数量 = (paintDxOffset / candleActualWidth).floor()
  ///     绘制起始蜡烛的向右边界外的偏移 = paintDxOffset % candleActualWidth;
  @override
  double get paintDxOffset => _paintDxOffset;
  set paintDxOffset(double val) {
    _paintDxOffset = clampPaintDxOffset(val);
    _isFirstCandleMovedOffScreenNotifier.value = _paintDxOffset > 0;
  }

  /// PaintDxOffset的最小值
  double get minPaintDxOffset {
    return math.min(
      maxPaintWidth - mainChartWidth,
      -minPaintBlankWidth,
    );
  }

  /// PaintDxOffset的最大值
  double get maxPaintDxOffset {
    return maxPaintWidth - (mainChartWidth - minPaintBlankWidth);
  }

  /// 矫正PaintDxOffset的范围
  double clampPaintDxOffset(double dxOffset) {
    return dxOffset.clamp(minPaintDxOffset, maxPaintDxOffset);
  }

  double getInitPaintDxOffset() {
    return math.min(
      maxPaintWidth - mainChartWidth, // 不足一屏, 首根蜡烛偏移量等于首根蜡烛右边长度.
      -settingConfig.firstCandleInitOffset, // 满足一屏时, 首根蜡烛相对于主绘制区域最小的偏移量
    );
  }

  /// 将视口移动到[target]对应的绘制偏移.
  ///
  /// 优先通过[moveToPositionCallback]走动画; 无回调时立即更新[paintDxOffset]并重绘.
  /// 返回动画是否完整完成.
  Future<bool> _moveToPaintDxOffset(double target) async {
    if (!isMounted) return false;

    final begin = paintDxOffset;
    final end = clampPaintDxOffset(target);

    final callback = moveToPositionCallback;
    if (callback != null) {
      return callback(begin, end);
    }

    if ((begin - end).abs() >= precisionError) {
      paintDxOffset = end;
      markRepaintChart(reset: true);
      markRepaintDraw();
    }
    return true;
  }

  /// 移动到不晚于[dateTime]的最近一根已加载蜡烛.
  ///
  /// 数据充足时目标蜡烛居中; 靠近数据两端时沿用当前绘制边界.
  /// 未挂载、无数据、动画中断或目标蜡烛发生变化时返回null.
  ///
  /// 成功时返回目标蜡烛在当前[KlineData]中的下标.
  Future<int?> moveToDateTime(DateTime dateTime) async {
    if (!isMounted || klineData.isEmpty || mainChartWidth <= 0) {
      return null;
    }

    final data = klineData;
    final index = data.indexAtOrBefore(
      dateTime.millisecondsSinceEpoch,
    );
    if (index == null) return null;
    final targetTimestamp = data.get(index)?.ts;
    if (targetTimestamp == null) return null;

    final target = index * candleActualWidth + candleWidthHalf - mainChartWidthHalf;
    requestCancelCross();
    if (!await _moveToPaintDxOffset(target)) return null;
    if (!isMounted || !identical(klineData, data)) return null;
    if (klineData.get(index)?.ts != targetTimestamp) return null;
    return index;
  }

  /// 请求移动蜡烛图回到初始位置。
  @override
  void requestMoveToInitialPosition() {
    if (!isMounted) return;
    unawaited(_moveToPaintDxOffset(getInitPaintDxOffset()));
  }

  /// 计算绘制蜡烛图的范围
  void calculatePaintChartRange() {
    if (paintDxOffset > 0) {
      final startIndex = (paintDxOffset / candleActualWidth).floor();
      final diff = paintDxOffset % candleActualWidth;
      final maxCount = ((mainChartWidth + diff) / candleActualWidth).round();
      klineData.ensureStartAndEndIndex(
        startIndex,
        maxCount,
      );
    } else {
      int maxCount;
      if (settingConfig.alwaysCalculateScreenOfCandlesIfEnough) {
        // 1: 当前[start, end]不足一屏蜡烛时, 向后取一屏蜡烛数据来计算最大最小
        maxCount = maxCandleCount;
      } else {
        // 2: 取当前可见蜡烛来计算最大最小. 四舍五入
        final offsetIndex = (paintDxOffset.abs() / candleActualWidth).round();
        maxCount = maxCandleCount - offsetIndex;
      }
      klineData.ensureStartAndEndIndex(
        0,
        maxCount,
      );
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _paintRangeNotifier.value = klineData.paintIndexRange;
    });
  }

  /// 切换[spec]规格指定的蜡烛数据
  /// [spec] 待切换的[KlineSpec]
  /// [useCacheFirst] 是否优先使用缓存. 注: 如果有缓存数据(说明之前加载过), loading不会展示.
  /// [useCachePaintDxOffset] 是否仍使用缓存的绘制位置(如果当前没有切换请求);
  /// return
  ///   1. true:  代表使用了缓存, [klineData] 的加载状态为 [KlineLoadingState.none], 不展示 loading
  ///   2. false: 代表未使用缓存; 且 [klineData] 数据会被清空(如果有).
  bool switchKlineData(
    KlineSpec spec, {
    ComputeMode computeMode = ComputeMode.fast,
    bool useCacheFirst = true,
    bool useCachePaintDxOffset = false,
  }) {
    KlineData? data = _klineDataCache[spec.key];

    if (useCacheFirst && data != null && data.isNotEmpty) {
      // 如果优先使用缓存且缓存数据不为空时, 设置缓存为当前KlineData, 同时结束loading状态.
      _setKlineData(
        data,
        resetPaintDxOffset: spec.key != klineDataKey ? true : useCachePaintDxOffset,
      );
      return true;
    }

    // 清理历史缓存数据.
    data?.dispose();

    // 重置当前KlineData为[spec]规格指定的KlineData, 并更新到缓存中.
    data = KlineData(
      spec,
      loadingState: KlineLoadingState.initLoading,
      computeMode: computeMode,
      logger: logger,
    );
    final old = _klineDataCache.append(spec.key, data);
    if (old != null) Future(() => old.dispose());
    _klineData = data;
    _notifySpecChange(data.spec);
    _notifyLoadingState(KlineLoadingState.initLoading, data.key);
    return false;
  }

  /// 停止加载状态
  /// [spec] 待停止的[KlineSpec]
  /// [specKey] 待停止的[KlineSpec]的key
  void stopLoading({KlineSpec? spec, String? specKey}) {
    specKey ??= spec?.key;
    if (specKey == null) return;
    if (specKey == klineDataKey) {
      if (klineData.loadingState != KlineLoadingState.none) {
        klineData.updateState(state: KlineLoadingState.none);
        _notifyLoadingState(KlineLoadingState.none, specKey);
      }
    } else {
      _klineDataCache.getItem(specKey)?.updateState(state: KlineLoadingState.none);
    }
  }

  /// 更新[list]到[spec]规格指定的[KlineData]中
  Future<void> updateKlineData(
    KlineSpec spec,
    List<ICandleModel> list, {
    bool reset = false,
  }) async {
    // 数据为空, 无需要更新.
    if (list.isEmpty) {
      stopLoading(spec: spec);
      return;
    }

    final data = _klineDataCache[spec.key];
    if (data == null) {
      logw('updateKlineData: cannot found klineData by $spec');
      return;
    }

    reset = reset || data.isEmpty;

    stopLoading(spec: data.spec);

    await _schedulePrecomputeKlineData(
      data,
      newList: list,
      reset: reset,
    );

    if (spec.key == klineDataKey) {
      if (reset) {
        _setKlineData(data);
      } else {
        _notifySpecChange(data.spec);
        // final newLen = data.length;
        // if (paintDxOffset < 0 && newLen > oldLen) {
        //   /// 当数据合并后
        //   /// 1. 如果paintDxOffset > 0 说明满足一屏, 且最新蜡烛被用户移动到绘制区域外面, 无需调整偏移量paintDxOffset, 重绘时, 仍按此偏移量计算后, 当前首根蜡烛向左移动一个蜡烛.
        //   /// 2. 如果paintDxOffset == 0 说明当前最新蜡烛在屏幕第一位(最右边)展示. 无需调整偏移量paintDxOffset, 重绘时calculateCandleIndexAndOffset, 会计算startIndex = 0;
        //   /// 2. 如果paintDxOffset < 0 说明未满足一屏, 需要减小偏移量, 以保证新数据能够展示.
        //   ///    注: 如果调整后 paintDxOffset > 0 则要置为0, 以保证最新蜡烛在最右边展示.
        //   paintDxOffset = math.min(
        //     0,
        //     paintDxOffset + (newLen - oldLen) * candleActualWidth,
        //   );
        // }

        markRepaintChart();
        markRepaintCross();
        markRepaintDraw();
      }
    }
  }

  /// 开始预计算Kline指标数据
  /// [data] 待计算的Kline蜡烛数据
  /// [newList] 待计算的蜡烛数据范围
  /// [reset] 是否重置[data],
  /// 1. true: 重新计算[data]的指标数据;
  /// 2. false: 仅计算[data]与[newList]合并后的部分.
  /// 数据合并更新结果的处理:
  /// 1. 对于历史数据追加, 像EMA这类依赖于历史数据会适时考虑从头计算.
  /// 2. 对于实时数据更新, 会仅计算[newList]部分.
  Future<void> _schedulePrecomputeKlineData(
    KlineData data, {
    List<ICandleModel> newList = const [],
    bool reset = false,
  }) async {
    if (!reset && newList.isEmpty && !data.hasWaitingData) {
      // 无需计算; 直接返回
      return;
    }

    // Widget 未挂载完成前，mainPaintObject 尚未初始化。
    // 此时只暂存数据，等 flushPendingKlineData 统一处理。
    if (!isMounted) {
      data.enqueueWaitingData(newList);
      return;
    }

    final beginTime = DateTime.now().millisecondsSinceEpoch;
    final precomputeLabel = 'Precompute-$beginTime-${newList.length}-$reset';

    logd('startPrecompute Begin: $precomputeLabel');

    /// 使用scheduleTask方式运行预计算
    await SchedulerBinding.instance.scheduleTask(
      () => data.precomputeKlineData(
        slotCount: computedDataCapacity,
        newList: newList,
        mainPaintObjects: mainPaintObject.children,
        subPaintObjects: subPaintObjects,
        reset: reset,
      ),
      Priority.animation,
      debugLabel: precomputeLabel,
    );
    logd(
      'startPrecompute End:$precomputeLabel spent:${DateTime.now().millisecondsSinceEpoch - beginTime}ms',
    );
  }

  /// 刷新挂载前暂存的待处理数据
  ///
  /// 在 FlexiKlineWidget.initState 完成（mountIndicators + controller.initState 之后）时调用。
  /// 检查 [klineData] 中是否有未合并的 `_waitingData`，若有则使用当前已确定的
  /// [computedDataCapacity] 合并数据并对所有已激活指标执行 precompute，最后触发 markRepaintChart。
  ///
  /// 场景：Widget 挂载前调用 switchKlineData 和 updateKlineData，数据暂存到 _waitingData；
  /// Widget initState 完成后调用此方法，使用已确定的 computedDataCapacity 处理暂存数据。
  @override
  void flushPendingKlineData() {
    // 检查当前 KlineData 是否有待合并的数据
    if (!klineData.hasWaitingData) {
      logd('flushPendingKlineData: no waiting data');
      return;
    }

    logd('flushPendingKlineData: flushing ${klineData.waitingDataLength} pending data');

    // 使用当前 computedDataCapacity 合并数据并执行 precompute
    _schedulePrecomputeKlineData(
      klineData,
      newList: const [],
      reset: false,
    ).then((_) {
      // precompute 完成后触发重绘
      markRepaintChart();
    });
  }
}
