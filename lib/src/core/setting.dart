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

/// 负责FlexiKline的各种设置与配置的获取.
mixin SettingBinding on KlineBindingBase implements ISetting, IGrid, IChart, ICross, IDraw {
  @override
  void init() {
    super.init();
    logd('init setting');
    _candleWidth = settingConfig.candleWidth;
    _layoutMode = NormalLayoutMode(flexiKlineConfig.mainIndicator.size);
    _canvasSizeChangeListener = FlexiStateNotifier(Rect.zero);
    _subHeightListListener = FlexiStateNotifier<List<double>>(const []);
  }

  @override
  void initState() {
    super.initState();
    logd('initState setting');
    _canvasSizeChangeListener.value = canvasRect;
    _subHeightListListener.value = getSubIndiatorHeights().toList(growable: false);
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose setting');
    _canvasSizeChangeListener.dispose();
    _subHeightListListener.dispose();
  }

  /// 蜡烛宽度
  late double _candleWidth;
  double? _candleSpacing;

  /// 副区指标图高度变化监听(不包括时间轴高度)
  late final ValueNotifier<List<double>> _subHeightListListener;
  ValueListenable<List<double>> get subHeightListListener => _subHeightListListener;
  void _updateSubHeightList() {
    _subHeightListListener.value = getSubIndiatorHeights().toList(growable: false);
  }

  /// KlineData整个图表区域大小变化监听器
  late final FlexiStateNotifier<Rect> _canvasSizeChangeListener;
  @override
  ValueListenable<Rect> get canvasSizeChangeListener {
    return _canvasSizeChangeListener;
  }

  /// 当前布局模式.
  /// 初始值为NormalLayoutMode(mainIndicator.size)
  late LayoutMode _layoutMode;

  LayoutMode get layoutMode => _layoutMode;
  bool get isFixedLayoutMode => _layoutMode is FixedLayoutMode;
  @override
  bool get isAllowUpdateLayoutHeight {
    if (layoutMode is NormalLayoutMode) return true;
    return layoutMode is AdaptLayoutMode;
  }

  Size? get fixedSize {
    if (!isFixedLayoutMode) return null;
    return (_layoutMode as FixedLayoutMode).fixedSize;
  }

  /// 主区大小
  @override
  Rect get mainRect {
    if (_layoutMode is FixedLayoutMode) {
      final size = (_layoutMode as FixedLayoutMode).fixedSize;
      return Offset.zero & Size(size.width, size.height - subRectHeight);
    }
    return mainPaintObject.drawableRect;
  }

  /// 整个画布区域大小 = 主区 + 副区
  @override
  Rect get canvasRect {
    if (_layoutMode is FixedLayoutMode) {
      return Offset.zero & (_layoutMode as FixedLayoutMode).fixedSize;
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.top,
      // math.max(mainRect.width, subRect.width),
      mainRect.width, // 整个图表宽度完全由mainRect决定
      mainRect.height + subRectHeight,
    );
  }

  double get canvasWidth => canvasRect.width;
  double get canvasHeight => canvasRect.height;

  /// 副区大小
  @override
  Rect get subRect {
    if (_layoutMode is FixedLayoutMode) {
      final size = (_layoutMode as FixedLayoutMode).fixedSize;
      return Rect.fromLTRB(
        0,
        size.height - subRectHeight,
        size.width,
        size.height,
      );
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.bottom,
      mainRect.right,
      mainRect.bottom + subRectHeight,
    );
  }

  /// TimeIndicator区域大小
  @override
  Rect get timeRect {
    return timePaintObject.drawableRect;
  }

  /// 如果已是zoom缩放图表时, 需要按比例[scale]缩放Padding.
  EdgeInsets? _zoomMainPaddingByScale(double scale) {
    if (!isStartZoomChart || scale == 1) return null;
    return mainPadding.copyWith(
      top: mainPadding.top * scale,
      bottom: mainPadding.bottom * scale,
    );
  }

  /// 主区域最小宽高
  Size get mainMinSize => settingConfig.mainMinSize;

  /// 主区域当前大小
  Size get mainSize => mainPaintObject.size;

  /// 是否能设置主区域大小
  bool canSetMainSize([Size? size]) {
    return (size ?? mainSize).gt(mainMinSize);
    // todo: 有小误差(0.12)
  }

  void _invokeSizeChanged({bool force = false}) {
    if (_layoutMode is FixedLayoutMode) {
      final size = mainRect.size;
      if (!size.equlas(mainSize)) {
        final updated = mainPaintObject.doUpdateLayout(
          size: size,
          padding: _zoomMainPaddingByScale(size.height / mainSize.height),
        );
        force = updated || force;
      }
    }
    _canvasSizeChangeListener.value = canvasRect;
    if (force) _canvasSizeChangeListener.notifyListeners();
    markRepaintChart(reset: force);
    markRepaintCross();
    markRepaintGrid();
  }

  /// 设置绘制区域大小.
  bool setCanvasSize(Size size) {
    return setMainSize(Size(size.width, size.height - subRectHeight));
  }

  /// 主区域大小设置
  bool setMainSize(Size size) {
    if (!canSetMainSize(size) || size == mainSize) return false;
    switch (_layoutMode) {
      case NormalLayoutMode():
      case AdaptLayoutMode():
        _layoutMode = _layoutMode.update(size);
      case FixedLayoutMode():
      // _layoutMode = _layoutMode.updateMainSize(size);
    }
    final changed = mainPaintObject.doUpdateLayout(
      size: size,
      padding: _zoomMainPaddingByScale(size.height / mainSize.height),
    );
    _invokeSizeChanged(force: changed);
    return true;
  }

  /// 进入正常布局模式
  /// [size] 代表正常布局大小
  /// [limitSize] 代表当前Kline所在正常布局模式下的最大宽高, 如果指定, 则校正当前Kline宽高不能大于此宽高.
  void setNormalLayoutMode(Size? size, [Size? limitSize]) {
    size ??= _layoutMode.mainSize;
    if (limitSize != null) {
      size = Size(
        size.width.clamp(
          mainMinSize.width,
          math.max(mainMinSize.width, limitSize.width),
        ),
        size.height.clamp(
          mainMinSize.height,
          math.max(mainMinSize.height, limitSize.height),
        ),
      );
    }
    if (_layoutMode.isNormal) {
      _layoutMode = _layoutMode.update(size);
    } else {
      _layoutMode = NormalLayoutMode(size);
    }

    if (size == mainSize) return;
    final changed = mainPaintObject.doUpdateLayout(
      size: size,
      padding: _zoomMainPaddingByScale(size.height / mainSize.height),
    );
    // 将所有副区对象恢复正常布局下的高度.
    _paintObjectManager.restoreHeight();
    _invokeSizeChanged(force: changed);
  }

  /// 自适应[FlexiKlineWidget]所在父组件的布局的变化
  /// 注: 仅适配主区的宽度变化
  /// 这主要是通过[FlexiKlineWidget]的autoAdaptLayout配置决定, 并会导致无法手动调整[FlexiKlineWidget]的宽度.
  bool setAdaptLayoutMode(Size size) {
    if (!canSetMainSize(size)) return false;

    if (_layoutMode.isAdapt) {
      if ((_layoutMode as AdaptLayoutMode).mainSize == size) {
        return true;
      }
      _layoutMode = _layoutMode.update(size);
    } else {
      _layoutMode = AdaptLayoutMode(size, _layoutMode);
    }

    final changed = mainPaintObject.doUpdateLayout(size: _layoutMode.mainSize);
    _invokeSizeChanged(force: changed);
    return true;
  }

  /// 设置Kline固定大小(主要在全屏或横屏场景中使用此API)
  /// 当设置[_fixedCanvasRect]后, 主区高度=[_fixedCanvasRect]的总高度 - [subRectHeight]副区所有指标高度
  /// [fixedSize] 当前Kline主区+副区的大小.
  /// 注: 设置是临时的, 并不会更新到配置中.
  bool setFixedLayoutMode(Size fixedSize) {
    if (!canSetMainSize(fixedSize)) return false;

    final oldMainHeight = mainRect.height;
    if (_layoutMode.isFixed) {
      if ((_layoutMode as FixedLayoutMode).fixedSize == fixedSize) {
        return true;
      }
      _layoutMode = _layoutMode.update(fixedSize);
    } else {
      _layoutMode = FixedLayoutMode(fixedSize, _layoutMode);
    }
    final changed = mainPaintObject.doUpdateLayout(
      size: mainRect.size,
      padding: _zoomMainPaddingByScale(mainRect.height / oldMainHeight),
    );
    _invokeSizeChanged(force: changed);
    return true;
  }

  bool exitCurrentLayoutMode() {
    final prevMode = _layoutMode.prevMode;
    switch (prevMode) {
      case null:
        return true;
      case NormalLayoutMode():
        setNormalLayoutMode(prevMode.mainSize);
        return true;
      case AdaptLayoutMode():
        return setAdaptLayoutMode(prevMode.mainSize);
      case FixedLayoutMode():
        return false;
    }
  }

  @protected
  double get subRectHeight {
    return subPaintObjects.fold(0.0, (total, e) => total + e.height);
  }

  /// 获取当前副区指标高度列表
  /// [includeTime] 是否包含时间轴高度
  Iterable<double> getSubIndiatorHeights([bool includeTime = false]) {
    return subPaintObjects.mapNonNullList(
      (object) => (includeTime || object.key != timeIndicatorKey) ? object.height : null,
    );
  }

  /// 主区当前Padding
  EdgeInsets get mainPadding => mainPaintObject.padding;

  /// 主区原始配置Padding
  EdgeInsets get mainOriginPadding => mainPaintObject.indicator.padding;

  /// 主图区域大小
  Rect get mainChartRect => mainPaintObject.chartRect;

  /// 主图区域宽.
  double get mainChartWidth => mainChartRect.width;

  /// 主图区域高.
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

  /// 主图区域最少留白宽度比例.
  double get minPaintBlankWidth {
    return mainChartWidth * settingConfig.minPaintBlankRate.clamp(0, 0.9);
  }

  /// 最小蜡烛宽度[1, 50]
  double get candleMinWidth => settingConfig.candleMinWidth;

  /// 最大蜡烛宽度[1, 50]
  double get candleMaxWidth => math.max(candleMinWidth, settingConfig.candleMaxWidth);

  /// 单根蜡烛宽度, 限制范围[candleMinWidth] ~ [candleMaxWidth] 之间
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

  Iterable<IIndicatorKey> get supportMainIndicatorKeys {
    return _paintObjectManager.supportMainIndicatorKeys;
  }

  Iterable<IIndicatorKey> get supportSubIndicatorKeys {
    return _paintObjectManager.supportSubIndicatorKeys;
  }

  Iterable<IIndicatorKey> get mainIndicatorKeys {
    return _paintObjectManager.mainIndicatorKeys;
  }

  Iterable<IIndicatorKey> get subIndicatorKeys {
    return _paintObjectManager.subIndicatorKeys;
  }

  @override
  int? getDataIndex(DataIndicatorKey key) {
    return _paintObjectManager.getIndicatorDataIndex(key);
  }

  @override
  int get indicatorCount => _paintObjectManager.indicatorCount;

  @override
  double calculateIndicatorTop(int slot) {
    double top = 0;
    final list = subPaintObjects.toList(growable: false);
    if (slot >= 0 && slot < list.length) {
      for (int i = 0; i < slot; i++) {
        top += list[i].height;
      }
    }
    return top;
  }

  /// Indicator operation ///

  /// 挂载所有指标（Widget initState 时调用），委托给 [IndicatorPaintObjectManager.mountIndicators]。
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
  }

  /// 增量更新指标（Widget didUpdateWidget 时调用），委托给 [IndicatorPaintObjectManager.updateIndicators]。
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
    _paintObjectManager.updateIndicators(
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
  }

  /// 处理 Widget 挂载前暂存的待处理数据（mountIndicators + controller.initState 之后调用）。
  ///
  /// 使用已确定的 indicatorCount 合并 _waitingData，对所有已激活指标执行 precompute，
  /// 并触发 markRepaintChart。由 StateBinding mixin 实现。
  void flushPendingKlineData() {}

  /// 检查指标是否在主区声明集合中
  bool hasRegisteredInMain(IIndicatorKey key) {
    return _paintObjectManager.hasRegisteredInMain(key);
  }

  /// 检查指标是否在副区声明集合中
  bool hasRegisteredInSub(IIndicatorKey key) {
    return _paintObjectManager.hasRegisteredInSub(key);
  }

  bool hasRegistered(IIndicatorKey key) {
    return hasRegisteredInMain(key) || hasRegisteredInSub(key);
  }

  /// 在主图中激活指标
  void addMainIndicator(IIndicatorKey key) {
    final newObj = _paintObjectManager.addMainPaintObject(key, this);
    if (newObj != null) {
      // 优化执行时机
      if (newObj is IComputablePainter) {
        (newObj as IComputablePainter).precompute(curKlineData.computableRange, reset: true);
      }
      markRepaintChart(reset: true);
      markRepaintCross();
    }
  }

  /// 在主图中隐藏指标
  void removeMainIndicator(IIndicatorKey key) {
    if (_paintObjectManager.removeMainPaintObject(key)) {
      markRepaintChart(reset: true);
      markRepaintCross();
    }
  }

  /// 是否已添加主图[key]指定的指标
  bool hasAddedMainIndicator(IIndicatorKey key) {
    return mainIndicatorKeys.contains(key);
  }

  /// 在副图中激活指标
  void addSubIndicator(IIndicatorKey key) {
    final newObj = _paintObjectManager.addSubPaintObject(key, this);
    if (newObj != null) {
      // 优化执行时机
      if (newObj is IComputablePainter) {
        (newObj as IComputablePainter).precompute(curKlineData.computableRange, reset: true);
      }
      _invokeSizeChanged();
      _updateSubHeightList();
    }
  }

  /// 在副图中隐藏指标
  void removeSubIndicator(IIndicatorKey key) {
    if (_paintObjectManager.removeSubPaintObject(key)) {
      _invokeSizeChanged();
      _updateSubHeightList();
    }
  }

  /// 是否已添加副图[key]指定的指标
  bool hasAddedSubIndicator(IIndicatorKey key) {
    return subIndicatorKeys.contains(key);
  }

  /// Config ///
  /// 保存当前FlexiKline配置到本地
  @override
  void storeFlexiKlineConfig({
    bool storeDrawOverlays = true,
  }) {
    _paintObjectManager.storeFlexiKlineConfig(
      layoutMode: layoutMode,
    );
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
