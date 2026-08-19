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

/// 负责 FlexiKline 的设置、布局与指标配置。
mixin SettingBinding on KlineBindingBase {
  @override
  void init() {
    super.init();
    logd('init setting');
    _candleWidth = settingConfig.candleWidth;
    _layoutModeNotifier = FlexiStateNotifier<FlexiLayoutMode>(_initialLayoutMode);
    if (_initialLayoutMode == FlexiLayoutMode.fixed) {
      assert(
        _initialFixedSize == null || _initialFixedSize.height.isFinite,
        'initialFixedSize.height must be finite when provided in fixed layout mode. '
        'Width can be resolved from parent constraints, but height cannot in scrollable parents.',
      );
      _fixedSize = _initialFixedSize;
    }
    _lifecycleNotifier = FlexiStateNotifier(FlexiKlineLifecycle.initial);
    _canvasRectNotifier = FlexiStateNotifier(Rect.zero);
    _subIndicatorHeightsNotifier = FlexiStateNotifier<List<double>>(const []);
  }

  @override
  void initState() {
    super.initState();
    logd('initState setting');
    _layoutFixedGeometry();
    // build 阶段不能触发 listener 通知，用 setSilently 写入初始值，
    // 订阅者 build 时直接读到正确值。
    _canvasRectNotifier.setSilently(canvasRect);
    _subIndicatorHeightsNotifier.setSilently(getSubIndicatorHeights().toList(growable: false));
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose setting');
    _lifecycleNotifier.value = FlexiKlineLifecycle.disposed;
    _lifecycleNotifier.dispose();
    _layoutModeNotifier.dispose();
    _canvasRectNotifier.dispose();
    _subIndicatorHeightsNotifier.dispose();
  }

  /// 蜡烛宽度
  late double _candleWidth;
  double? _candleSpacing;

  /// Controller 生命周期状态 listenable。
  late final FlexiStateNotifier<FlexiKlineLifecycle> _lifecycleNotifier;
  ValueListenable<FlexiKlineLifecycle> get lifecycleListenable => _lifecycleNotifier;

  /// 副区指标高度变化 listenable（不含时间轴）。
  late final FlexiStateNotifier<List<double>> _subIndicatorHeightsNotifier;
  ValueListenable<List<double>> get subIndicatorHeightsListenable => _subIndicatorHeightsNotifier;
  void _updateSubIndicatorHeights() {
    _subIndicatorHeightsNotifier.value = getSubIndicatorHeights().toList(growable: false);
  }

  /// 图表画布区域变化 listenable。
  late final FlexiStateNotifier<Rect> _canvasRectNotifier;
  ValueListenable<Rect> get canvasRectListenable {
    return _canvasRectNotifier;
  }

  /// 当前布局模式。
  /// 初始值由 [KlineBindingBase.initialLayoutMode] 决定。
  late final FlexiStateNotifier<FlexiLayoutMode> _layoutModeNotifier;

  /// 布局模式变化 listenable，Widget 层通过 [ValueListenableBuilder] 订阅。
  ValueListenable<FlexiLayoutMode> get layoutModeListenable => _layoutModeNotifier;

  /// fixed 模式下的画布固定尺寸（主区 + 副区）。
  Size? _fixedSize;

  FlexiLayoutMode get layoutMode => _layoutModeNotifier.value;
  bool get isFixedLayoutMode => layoutMode == FlexiLayoutMode.fixed;

  @override
  bool get canUpdateLayoutHeight => layoutMode == FlexiLayoutMode.adapt;

  Size? get fixedSize => isFixedLayoutMode ? _fixedSize : null;

  /// 主区绘制区域。
  @override
  Rect get mainRect {
    if (isFixedLayoutMode && _fixedSize != null) {
      return Offset.zero & Size(_fixedSize!.width, _fixedSize!.height - subRectHeight);
    }
    return mainPaintObject.drawableRect;
  }

  /// 整个画布区域（主区 + 副区）。
  @override
  Rect get canvasRect {
    if (isFixedLayoutMode && _fixedSize != null) {
      return Offset.zero & _fixedSize!;
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.top,
      mainRect.width,
      mainRect.height + subRectHeight,
    );
  }

  double get canvasWidth => canvasRect.width;
  double get canvasHeight => canvasRect.height;

  /// 副区绘制区域。
  @override
  Rect get subRect {
    if (isFixedLayoutMode && _fixedSize != null) {
      final fixedSize = _fixedSize!;
      return Rect.fromLTRB(
        0,
        fixedSize.height - subRectHeight,
        fixedSize.width,
        fixedSize.height,
      );
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.bottom,
      mainRect.right,
      mainRect.bottom + subRectHeight,
    );
  }

  /// 时间轴区域。
  @override
  Rect get timeRect {
    return timePaintObject.drawableRect;
  }

  /// 缩放过程中按主区高度比例调整 padding。
  EdgeInsets? _zoomMainPaddingByScale(double scale) {
    if (!isChartZooming || scale == 1) return null;
    return mainPadding.copyWith(
      top: mainPadding.top * scale,
      bottom: mainPadding.bottom * scale,
    );
  }

  /// 当前 fixed 画布的最小合法尺寸。
  Size get _minFixedCanvasSize {
    double subMinHeight = 0;
    if (isMounted) {
      subMinHeight = timePaintObject.indicator.height + settingConfig.subMinHeight * subIndicatorKeys.length;
    }
    return Size(mainMinSize.width, mainMinSize.height + subMinHeight);
  }

  /// 主区最小尺寸。
  Size get mainMinSize => settingConfig.mainMinSize;

  /// 主区当前尺寸。
  Size get mainSize => mainPaintObject.size;

  /// 是否可以应用主区尺寸。
  bool canSetMainSize(Size size) {
    return size.gt(mainMinSize);
  }

  /// fixed 下重新分配副区高度，并同步主区尺寸。
  bool _layoutFixedGeometry() {
    if (!isFixedLayoutMode || _fixedSize == null || !isMounted) return false;
    _layoutFixedSubHeights();

    final size = mainRect.size;
    if (size.equals(mainSize)) return false;
    return mainPaintObject.doUpdateLayout(
      size: size,
      padding: _zoomMainPaddingByScale(size.height / mainSize.height),
    );
  }

  /// fixed 画布是否能容纳当前已激活指标。
  bool _canApplyFixedSize(Size size, {bool debugAssert = true}) {
    final minSize = _minFixedCanvasSize;
    final valid = size.width >= minSize.width && size.height >= minSize.height;
    if (debugAssert) {
      assert(
        valid,
        'Fixed canvas size is too small. '
        'It must be at least mainMinSize + subMinHeight * activeSubIndicatorCount.',
      );
    }
    return valid;
  }

  /// 将 adapt 下的主区尺寸同步到配置；fixed 是临时布局，不持久化。
  void _syncMainSizeToConfig([Size? newSize]) {
    if (isFixedLayoutMode) return;
    final configSize = flexiKlineConfig.mainIndicator.size;
    newSize ??= mainPaintObject.size;
    if (newSize != configSize) {
      flexiKlineConfig.mainIndicator = flexiKlineConfig.mainIndicator.copyWith(size: newSize);
    }
  }

  /// 通知画布变化并触发相关图层重绘。
  void _notifyCanvasSizeChanged({bool force = false}) {
    _syncMainSizeToConfig();
    _canvasRectNotifier.value = canvasRect;
    if (force) _canvasRectNotifier.notifyListeners();
    markRepaintChart(reset: force);
    markRepaintCross();
    markRepaintGrid();
  }

  /// 副区指标变化后的统一同步入口。
  void _onSubIndicatorsChanged() {
    final changed = _layoutFixedGeometry();
    _notifyCanvasSizeChanged(force: changed || isFixedLayoutMode);
    _updateSubIndicatorHeights();
  }

  /// 设置主区尺寸。拖拽分隔线和模式切换都会走这里。
  ///
  /// fixed 切回 adapt 时的副区临时高度，由 [setAdaptLayoutMode] 负责清理。
  bool setMainSize(Size size, {bool restore = false}) {
    if (!canSetMainSize(size)) return false;
    if (!isMounted) {
      _syncMainSizeToConfig(size);
      return true;
    }
    if (size.equals(mainSize)) return false;
    final changed = mainPaintObject.doUpdateLayout(
      size: size,
      padding: _zoomMainPaddingByScale(size.height / mainSize.height),
    );
    if (restore && !isFixedLayoutMode) {
      _paintObjectManager.restoreHeight();
    }
    _notifyCanvasSizeChanged(force: changed);
    return true;
  }

  /// 切换到 adapt。宽度可由父约束传入，高度沿用当前或配置主区高度。
  ///
  /// 从 fixed 切回时会清理副区临时高度。
  bool setAdaptLayoutMode({double? width}) {
    if (width != null && width < mainMinSize.width) return false;

    Size size;
    final prevLayoutMode = layoutMode;
    if (isFixedLayoutMode) {
      // fixed -> adapt：从配置恢复主区尺寸。
      final configSize = flexiKlineConfig.mainIndicator.size;
      size = Size(width ?? configSize.width, configSize.height);
      _fixedSize = null;
      _layoutModeNotifier.value = FlexiLayoutMode.adapt;
    } else {
      // adapt 内只更新宽度，不切换模式。
      final height = mainPaintObject.height;
      size = Size(width ?? mainPaintObject.size.width, height);
    }

    return setMainSize(size, restore: prevLayoutMode == FlexiLayoutMode.fixed);
  }

  /// 切换到 fixed，画布尺寸固定为 [fixedSize]。
  ///
  /// 父约束有限时由 Widget 自动调用；滚动容器中需业务侧提供可见尺寸。
  /// fixed 下副区会在固定总高度内分配，且不低于 [SettingConfig.subMinHeight]。
  bool setFixedLayoutMode(Size fixedSize) {
    if (!fixedSize.isFinite) return false;
    if (!_canApplyFixedSize(fixedSize)) return false;

    if (layoutMode == FlexiLayoutMode.fixed) {
      // fixed 内只更新尺寸，不切换模式。
      if (fixedSize.equals(_fixedSize)) return true;
      _fixedSize = fixedSize;
    } else {
      // adapt -> fixed：先保存 adapt 尺寸，退出 fixed 时用于恢复。
      _syncMainSizeToConfig();
      _fixedSize = fixedSize;
      _layoutModeNotifier.value = FlexiLayoutMode.fixed;
    }

    // mount 前只记录 fixedSize，首次布局在 initState/build 约束驱动时完成。
    if (!isMounted) return true;

    final changed = _layoutFixedGeometry();
    _notifyCanvasSizeChanged(force: changed);
    return true;
  }

  /// fixed 下分配副区高度。
  ///
  /// 以原始 [Indicator.height] 为基准，保证重复调用时结果稳定。
  /// 压缩值写入 `_tmpHeight`，不会污染持久化配置。
  void _layoutFixedSubHeights() {
    assert(layoutMode == FlexiLayoutMode.fixed && _fixedSize != null);
    final fixedHeight = _fixedSize!.height;
    final fixedSubObjects = subPaintObjects.where((object) => object.key != timeIndicatorKey).toList(growable: false);

    // 时间轴固定使用配置高度，不参与普通副区分配与 _tmpHeight 压缩。
    final timeHeight = timePaintObject.indicator.height;
    // 始终以原始高度计算，避免基于上次压缩结果继续压缩。
    final originalSubHeight = fixedSubObjects.fold(0.0, (total, object) => total + object.indicator.height);
    final availableSubHeight = fixedHeight - mainMinSize.height - timeHeight;

    if (fixedSubObjects.every((object) => object.indicator.height >= settingConfig.subMinHeight) &&
        originalSubHeight <= availableSubHeight) {
      for (final object in fixedSubObjects) {
        object.doUpdateLayout(height: object.indicator.height);
      }
      return;
    }

    // 先保底，再按超出最小高度的部分分配剩余空间。
    if (originalSubHeight <= 0 || availableSubHeight <= 0) return;
    final minHeight = settingConfig.subMinHeight;
    final distributableHeight = math.max(0.0, availableSubHeight - minHeight * fixedSubObjects.length);
    final flexibleHeightTotal = fixedSubObjects.fold(
      0.0,
      (total, object) => total + math.max(0.0, object.indicator.height - minHeight),
    );
    for (final object in fixedSubObjects) {
      final flexibleHeight = math.max(0.0, object.indicator.height - minHeight);
      final extra = flexibleHeightTotal > 0 ? distributableHeight * flexibleHeight / flexibleHeightTotal : 0.0;
      final height = minHeight + extra;
      object.doUpdateLayout(height: height);
    }
  }

  @protected
  double get subRectHeight {
    return subPaintObjects.fold(0.0, (total, e) => total + e.height);
  }

  /// 当前副区指标高度列表；[includeTime] 控制是否包含时间轴。
  Iterable<double> getSubIndicatorHeights([bool includeTime = false]) {
    return subPaintObjects.mapNonNullList(
      (object) => (includeTime || object.key != timeIndicatorKey) ? object.height : null,
    );
  }

  /// 主区当前 padding。
  EdgeInsets get mainPadding => mainPaintObject.padding;

  /// 主区原始 padding。
  EdgeInsets get mainOriginPadding => mainPaintObject.indicator.padding;

  /// 主图区域。
  Rect get mainChartRect => mainPaintObject.chartRect;

  /// 主图区域宽。
  double get mainChartWidth => mainChartRect.width;

  /// 主图区域高。
  double get mainChartHeight => mainChartRect.height;

  /// 主图区域宽度的半值.
  double get mainChartWidthHalf => mainChartWidth / 2;

  /// 主图区域左边界值
  double get mainChartLeft => mainChartRect.left;

  /// 主图区域右边界值
  double get mainChartRight => mainChartRect.right;

  /// 主图区域上边界值
  double get mainChartTop => mainChartRect.top;

  /// 主图区域下边界值
  double get mainChartBottom => mainChartRect.bottom;

  /// 主图区域最少留白宽度。
  double get minPaintBlankWidth {
    return mainChartWidth * settingConfig.minPaintBlankRate.clamp(0, 0.9);
  }

  /// 最小蜡烛宽度[1, 50]
  double get candleMinWidth => settingConfig.candleMinWidth;

  /// 最大蜡烛宽度[1, 50]
  double get candleMaxWidth => math.max(candleMinWidth, settingConfig.candleMaxWidth);

  /// 单根蜡烛宽度，限制在 [candleMinWidth] ~ [candleMaxWidth]。
  @override
  double get candleWidth => _candleWidth;
  void _setCandleWidth(double width, {bool sync = false}) {
    _candleWidth = width;
    if (!settingConfig.isFixedCandleSpacing) _candleSpacing = null;
    if (sync) {
      settingConfig = settingConfig.copyWith(
        candleWidth: width.clamp(candleMinWidth, candleMaxWidth),
      );
    }
  }

  /// 蜡烛间距 [candleFixedSpacing] 优先于 [candleSpacingParts]
  @override
  double get candleSpacing {
    if (settingConfig.isFixedCandleSpacing) {
      return settingConfig.candleFixedSpacing!;
    }
    if (_candleSpacing != null && _candleSpacing! > 0) return _candleSpacing!;
    _candleSpacing = candleWidth / settingConfig.spacingCandleParts;
    _candleSpacing!.clamp(
      candleMinWidth,
      math.max(candleMinWidth, candleWidthHalf),
    );
    return _candleSpacing!;
  }

  /// 单根蜡烛所占据实际宽度
  @override
  double get candleActualWidth => candleWidth + candleSpacing;

  /// 单根蜡烛实际宽度（含间距）的一半
  @override
  double get candleWidthHalf => candleActualWidth / 2;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (mainChartWidth / candleActualWidth).ceil();

  /// PaintObject 已创建且 Controller 处于 mounted。
  bool get isMounted => _paintObjectManager.isInitialized && _lifecycleNotifier.value.isMounted;

  /// 主区已注册指标 key；默认过滤 External 业务指标，[includeExternal]=true 则全返回。
  Iterable<IIndicatorKey> getSupportMainIndicatorKeys([bool includeExternal = false]) {
    if (includeExternal) return _paintObjectManager.supportMainIndicatorKeys;
    return _paintObjectManager.supportMainIndicatorKeys.where((key) => key is! ExternalIndicatorKey);
  }

  /// 副区已注册指标 key；默认过滤 External 业务指标，[includeExternal]=true 则全返回。
  Iterable<IIndicatorKey> getSupportSubIndicatorKeys([bool includeExternal = false]) {
    if (includeExternal) return _paintObjectManager.supportSubIndicatorKeys;
    return _paintObjectManager.supportSubIndicatorKeys.where((key) => key is! ExternalIndicatorKey);
  }

  Iterable<IIndicatorKey> get mainIndicatorKeys {
    return _paintObjectManager.mainIndicatorKeys;
  }

  Iterable<IIndicatorKey> get subIndicatorKeys {
    return _paintObjectManager.subIndicatorKeys;
  }

  @override
  int? getComputedDataIndex(ComputedIndicatorKey key) {
    return _paintObjectManager.getComputedDataIndex(key);
  }

  @override
  int get computedDataCapacity => _paintObjectManager.computedDataCapacity;

  @override
  double calculatePaneTop(int paneIndex) {
    double top = 0;
    final list = subPaintObjects.toList(growable: false);
    if (paneIndex >= 0 && paneIndex < list.length) {
      for (int i = 0; i < paneIndex; i++) {
        top += list[i].height;
      }
    }
    return top;
  }

  // Indicator 操作

  /// 挂载 Widget 声明的指标。
  void mountIndicators({
    required CandleBaseIndicator candle,
    required TimeBaseIndicator time,
    required List<Indicator> mainIndicators,
    required List<Indicator> subIndicators,
  }) {
    _paintObjectManager.mountIndicators(
      candle: candle,
      time: time,
      mainIndicators: mainIndicators,
      subIndicators: subIndicators,
      context: this,
    );
    _lifecycleNotifier.value = FlexiKlineLifecycle.mounted;
  }

  /// 按 Widget 新旧声明增量同步指标。
  void updateIndicators({
    required CandleBaseIndicator oldCandle,
    required CandleBaseIndicator newCandle,
    required TimeBaseIndicator oldTime,
    required TimeBaseIndicator newTime,
    required List<Indicator> oldMainIndicators,
    required List<Indicator> newMainIndicators,
    required List<Indicator> oldSubIndicators,
    required List<Indicator> newSubIndicators,
  }) {
    final oldComputedDataCapacity = computedDataCapacity;
    final indicatorChanges = _paintObjectManager.updateIndicators(
      oldCandle: oldCandle,
      newCandle: newCandle,
      oldTime: oldTime,
      newTime: newTime,
      oldMainIndicators: oldMainIndicators,
      newMainIndicators: newMainIndicators,
      oldSubIndicators: oldSubIndicators,
      newSubIndicators: newSubIndicators,
      context: this,
    );
    final capacityGrew = computedDataCapacity > oldComputedDataCapacity;
    var invalidatedAll = false;
    if (capacityGrew) {
      syncComputedSlotCapacity();
      invalidatedAll = true;
    } else if (indicatorChanges.slotLayoutChanged) {
      evictInactiveKlineDataCache();
      _pipeline.invalidateAll();
      invalidatedAll = true;
    }
    if (!invalidatedAll && indicatorChanges.recompute.isNotEmpty) {
      for (final key in indicatorChanges.recompute) {
        final calculator = _paintObjectManager.getCalculator(key);
        if (calculator != null) _pipeline.recompute(calculator);
      }
      evictInactiveKlineDataCache();
    }
    for (final key in indicatorChanges.main) {
      showMainIndicator(key);
    }
    for (final key in indicatorChanges.sub) {
      showSubIndicator(key);
    }
  }

  /// 指标是否在主区声明集合中。
  bool hasRegisteredInMain(IIndicatorKey key) {
    return _paintObjectManager.hasRegisteredInMain(key);
  }

  /// 指标是否在副区声明集合中。
  bool hasRegisteredInSub(IIndicatorKey key) {
    return _paintObjectManager.hasRegisteredInSub(key);
  }

  bool hasRegistered(IIndicatorKey key) {
    return hasRegisteredInMain(key) || hasRegisteredInSub(key);
  }

  /// 在主图中显示指标。
  bool showMainIndicator(IIndicatorKey key) {
    final newObj = _paintObjectManager.addMainPaintObject(key, this);
    if (newObj == null) return false;
    if (key is ComputedIndicatorKey) {
      final calculator = _paintObjectManager.getCalculator(key);
      if (calculator != null) {
        evictInactiveKlineDataCache();
        _pipeline.recompute(calculator);
      }
    }
    markRepaintChart(reset: true);
    markRepaintCross();
    return true;
  }

  /// 在主图中隐藏指标。
  bool hideMainIndicator(IIndicatorKey key) {
    if (!_paintObjectManager.removeMainPaintObject(key)) return false;
    markRepaintChart(reset: true);
    markRepaintCross();
    return true;
  }

  /// 主图是否已添加 [key] 指标。
  bool hasAddedMainIndicator(IIndicatorKey key) {
    return mainIndicatorKeys.contains(key);
  }

  /// 在副图中显示指标。
  bool showSubIndicator(IIndicatorKey key) {
    final newObj = _paintObjectManager.addSubPaintObject(key, this);
    if (newObj == null) return false;
    if (isFixedLayoutMode && _fixedSize != null && !_canApplyFixedSize(_fixedSize!, debugAssert: false)) {
      _paintObjectManager.removeSubPaintObject(key);
      logw('showSubIndicator failed: fixed canvas size is too small for $key.');
      return false;
    }
    if (key is ComputedIndicatorKey) {
      final calculator = _paintObjectManager.getCalculator(key);
      if (calculator != null) {
        evictInactiveKlineDataCache();
        _pipeline.recompute(calculator);
      }
    }
    _onSubIndicatorsChanged();
    return true;
  }

  /// 在副图中隐藏指标。
  bool hideSubIndicator(IIndicatorKey key) {
    if (!_paintObjectManager.removeSubPaintObject(key)) return false;
    _onSubIndicatorsChanged();
    return true;
  }

  /// 副图是否已添加 [key] 指标。
  bool hasAddedSubIndicator(IIndicatorKey key) {
    return subIndicatorKeys.contains(key);
  }

  // Config
  /// 保存当前 FlexiKline 配置。
  @override
  void storeFlexiKlineConfig({
    bool storeDrawOverlays = true,
  }) {
    _paintObjectManager.storeFlexiKlineConfig();
    if (storeDrawOverlays && drawConfig.enable) {
      _drawObjectManager.storeDrawOverlaysConfig();
    }
  }

  /// SettingConfig
  @override
  SettingConfig get settingConfig => flexiKlineConfig.setting;
  set settingConfig(SettingConfig config) {
    flexiKlineConfig.setting = config;
    markRepaintChart();
    markRepaintCross();
  }

  void updateSettingConfig(FlexiUpdater<SettingConfig> builder) {
    settingConfig = builder(settingConfig);
  }

  /// GestureConfig
  @override
  GestureConfig get gestureConfig => flexiKlineConfig.gesture;
  set gestureConfig(GestureConfig config) {
    flexiKlineConfig.gesture = config;
    markRepaintChart();
    markRepaintCross();
  }

  void updateGestureConfig(FlexiUpdater<GestureConfig> builder) {
    gestureConfig = builder(gestureConfig);
  }

  /// GridConfig
  @override
  GridConfig get gridConfig => flexiKlineConfig.grid;
  set gridConfig(GridConfig config) {
    flexiKlineConfig.grid = config;
    markRepaintChart();
    markRepaintCross();
    markRepaintGrid();
  }

  void updateGridConfig(FlexiUpdater<GridConfig> builder) {
    gridConfig = builder(gridConfig);
  }

  /// CrossConfig
  @override
  CrossConfig get crossConfig => flexiKlineConfig.cross;
  set crossConfig(CrossConfig config) {
    flexiKlineConfig.cross = config;
    markRepaintChart();
    markRepaintCross();
  }

  void updateCrossConfig(FlexiUpdater<CrossConfig> builder) {
    crossConfig = builder(crossConfig);
  }

  /// DrawConfig
  @override
  DrawConfig get drawConfig => flexiKlineConfig.draw;
  set drawConfig(DrawConfig config) {
    flexiKlineConfig.draw = config;
    markRepaintChart();
    markRepaintDraw();
  }

  void updateDrawConfig(FlexiUpdater<DrawConfig> builder) {
    drawConfig = builder(drawConfig);
  }

  /// 获取蜡烛图指标配置
  T getCandleIndicator<T extends CandleBaseIndicator>() {
    return candlePaintObject.indicator as T;
  }

  /// 获取时间轴指标配置
  T getTimeIndicator<T extends TimeBaseIndicator>() {
    return timePaintObject.indicator as T;
  }
}
