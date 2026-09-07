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
    _pipeline = _createPipeline(_klineData);
  }

  @override
  void initState() {
    super.initState();
    logd('initState state');
  }

  @override
  void dispose() {
    _pipeline.dispose();
    super.dispose();
    logd('dispose state');
    _klineSpecNotifier.dispose();
    _loadingStateNotifier.dispose();
    _isFirstCandleMovedOffScreenNotifier.dispose();
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

  /// 广播当前 [klineData] 的 spec 变更。
  ///
  /// 调用前 [klineData] 已切换为新数据，其 spec 即新值；此处捕获旧 spec 供下游 diff，
  /// 先对齐 notifier 与 interval（使两者与 [klineData] 一致），再触发 [onKlineSpecChanged]。
  void _notifySpecChange() {
    final oldSpec = _klineSpecNotifier.value;
    final newSpec = klineData.spec;
    logd('_notifySpecChange $newSpec');
    _klineSpecNotifier.value = newSpec;
    _intervalNotifier.value = newSpec.interval;
    onKlineSpecChanged(oldSpec);
  }

  /// 广播当前 [klineData] 的加载状态。
  void _notifyLoadingState() {
    logd('_notifyLoadingState ${klineData.loadingState}');
    _loadingStateNotifier.value = klineData.loadingState;
  }

  late final FIFOHashMap<String, KlineData> _klineDataCache;
  KlineData _klineData = KlineData.empty;

  @override
  KlineData get klineData => _klineData;

  /// 当前 K 线数据缓存 key。
  String get klineDataKey => klineData.key;

  KlineDataPipeline _createPipeline(KlineData data) {
    return KlineDataPipeline(
      data,
      _paintObjectManager,
      interval: calculationInterval,
      logger: logger,
      onCandlesMerged: _onCandlesMerged,
      onComputed: _onComputed,
    );
  }

  @override
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
  void constrainPaintDxOffset() {
    // 用当前区间重新约束当前偏移，把越界的旧值收回合法区间。
    _setPaintDxOffset(_paintDxOffset);
  }

  @override
  @protected
  void syncComputedSlotCapacity() {
    // 当前数据：按最新容量扩容已有蜡烛的 slots。
    klineData.rebuildSlots(computedDataCapacity);
    // 其余缓存：指标声明已变，其 slot 值已陈旧，直接丢弃，下次切换重新加载。
    evictInactiveKlineDataCache();
    _pipeline.invalidateAll();
  }

  /// 设置当前KlineData:
  /// 1. 通知timeInterval变更
  /// 2. 初始化首根蜡烛绘制位置于屏幕右侧[getInitPaintDxOffset]指定处.
  /// 3. 重绘图表
  /// 4. 取消Cross绘制(如果有)
  void _setKlineData(KlineData data, {bool resetPaintDxOffset = true}) {
    if (!identical(_klineData, data)) {
      _pipeline.dispose();
      _klineData = data;
      _pipeline = _createPipeline(data);
      if (isMounted) _pipeline.start();
    }
    _notifySpecChange();
    _notifyLoadingState();
    if (resetPaintDxOffset && isMounted) {
      _setPaintDxOffset(getInitPaintDxOffset());
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

  /// 绘制偏移的唯一写入点: 夹取到合法区间, 并同步「首根蜡烛已移出屏幕」通知。
  /// 返回偏移是否真的变化: 贴在边界上继续同向平移即为 false, 调用方据此跳过重绘。
  bool _setPaintDxOffset(double value) {
    final newOffset = clampPaintDxOffset(value);
    if (newOffset == _paintDxOffset) return false;
    _paintDxOffset = newOffset;
    _isFirstCandleMovedOffScreenNotifier.value = newOffset > 0;
    return true;
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
      _setPaintDxOffset(end);
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
    _setKlineData(data);
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
        _notifyLoadingState();
      }
    } else {
      _klineDataCache.getItem(specKey)?.updateState(state: KlineLoadingState.none);
    }
  }

  /// 完整替换[spec]对应的蜡烛数据.
  void replaceKlineData(KlineSpec spec, List<ICandleModel> list) {
    if (!_acceptKlineDataUpdate(spec, list)) return;
    _pipeline.replace(list);
  }

  /// 更新[spec]对应的最新方向蜡烛数据.
  void updateLatestKlineData(KlineSpec spec, List<ICandleModel> list) {
    if (!_acceptKlineDataUpdate(spec, list)) return;
    _pipeline.updateLatest(list);
  }

  /// 追加[spec]对应的历史方向蜡烛数据.
  void appendHistoryKlineData(KlineSpec spec, List<ICandleModel> list) {
    if (!_acceptKlineDataUpdate(spec, list)) return;
    _pipeline.appendHistory(list);
  }

  bool _acceptKlineDataUpdate(KlineSpec spec, List<ICandleModel> list) {
    if (spec.key != klineDataKey) {
      logd('ignore inactive KlineData update: ${spec.key}');
      return false;
    }
    if (list.isEmpty) {
      stopLoading(spec: spec);
      return false;
    }
    stopLoading(spec: klineData.spec);
    return true;
  }

  void _onCandlesMerged({required bool replace}) {
    if (replace) {
      _setKlineData(klineData);
      return;
    }
    _notifySpecChange();
    markRepaintAll();
  }

  void _onComputed() {
    markRepaintAll();
  }

  /// 启动流水线并处理挂载前暂存的数据.
  @override
  void flushPendingKlineData() {
    _pipeline.start();
  }
}
