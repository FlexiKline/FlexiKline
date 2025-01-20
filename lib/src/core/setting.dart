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
mixin SettingBinding on KlineBindingBase
    implements ISetting, IGrid, IChart, ICross, IDraw {
  @override
  void init() {
    super.init();
    logd("init setting");
    final mainIndicator = _flexiKlineConfig.mainIndicator;
    _layoutMode = NormalLayoutMode(mainIndicator.size);
    _paintObjectManager.init(
      this,
      mainIndicator: mainIndicator,
      initSubIndicatorKeys: _flexiKlineConfig.sub,
    );
    _canvasSizeChangeListener = KlineStateNotifier(canvasRect);
    _candleWidth = settingConfig.candleWidth;
  }

  @override
  void initState() {
    super.initState();
    logd("initState setting");
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose setting");
    _canvasSizeChangeListener.dispose();
  }

  @override
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    super.onThemeChanged(oldTheme);
  }

  /// 蜡烛宽度
  late double _candleWidth;
  double? _candleSpacing;

  /// KlineData整个图表区域大小变化监听器
  late final KlineStateNotifier<Rect> _canvasSizeChangeListener;
  @override
  ValueListenable<Rect> get canvasSizeChangeListener {
    return _canvasSizeChangeListener;
  }

  void _invokeSizeChanged({bool force = false}) {
    if (_layoutMode is FixedLayoutMode) {
      final mainSize = mainRect.size;
      if (mainSize != mainPaintObject.size) {
        final updated = mainPaintObject.doUpdateLayout(size: mainSize);
        force = updated || force;
      }
    }
    _canvasSizeChangeListener.value = canvasRect;
    if (force) _canvasSizeChangeListener.notifyListeners();
    markRepaintChart(reset: force);
    markRepaintCross();
  }

  late LayoutMode _layoutMode;
  bool get isFixedLayoutMode => _layoutMode is FixedLayoutMode;
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

  /// 主区域最小宽高
  Size get mainMinSize => settingConfig.mainMinSize;

  /// 主区域大小设置
  void setMainSize(Size size) {
    if (!(size > mainMinSize)) return;
    if (size == _layoutMode.mainSize) return;
    _layoutMode.mainSize = size;
    final changed = mainPaintObject.doUpdateLayout(size: size);
    _invokeSizeChanged(force: changed);
  }

  /// 自适应[FlexiKlineWidget]所在父组件的布局的变化
  /// 注: 仅适配主区的宽度变化
  /// 这主要是通过[FlexiKlineWidget]的autoAdaptLayout配置决定, 并会导致无法手动调整[FlexiKlineWidget]的宽度.
  void setAdaptLayoutMode(double width) {
    if (width < mainMinSize.width) return;
    if (_layoutMode is AdaptLayoutMode &&
        (_layoutMode as AdaptLayoutMode).mainSize.width == width) {
      return;
    }
    _layoutMode = _layoutMode.adaptMode(width);
    final changed = mainPaintObject.doUpdateLayout(size: _layoutMode.mainSize);
    _invokeSizeChanged(force: changed);
  }

  /// 进入正常布局模式
  /// [size] 代表正常布局大小
  /// [limitSize] 代表当前Kline所在正常布局模式下的最大宽高, 如果指定, 则校正当前Kline宽高不能大于此宽高.
  void setNormalLayoutMode({Size? size, Size? limitSize}) {
    size ??= _layoutMode.mainSize;
    if (limitSize != null) {
      size = Size(
        size.width.clamp(mainMinSize.width, limitSize.width),
        size.height.clamp(mainMinSize.height, limitSize.height),
      );
    }
    if (size == mainPaintObject.size) return;
    _layoutMode = _layoutMode.normalMode(size);
    final changed = mainPaintObject.doUpdateLayout(size: _layoutMode.mainSize);
    _invokeSizeChanged(force: changed);
  }

  /// 设置Kline固定大小(主要在全屏或横屏场景中使用此API)
  /// 当设置[_fixedCanvasRect]后, 主区高度=[_fixedCanvasRect]的总高度 - [subRectHeight]副区所有指标高度
  /// [size] 当前Kline主区+副区的大小.
  /// 注: 设置是临时的, 并不会更新到配置中.
  void setFixedLayoutMode(Size size) {
    if (!(size > mainMinSize)) return;
    if (_layoutMode is FixedLayoutMode &&
        (_layoutMode as FixedLayoutMode).fixedSize == size) {
      return;
    }

    _layoutMode = _layoutMode.fixedMode(size);
    final changed = mainPaintObject.doUpdateLayout(size: mainRect.size);
    _invokeSizeChanged(force: changed);
  }

  @protected
  double get subRectHeight {
    double totalHeight = 0.0;
    for (final indicator in subPaintObjects) {
      totalHeight += indicator.height;
    }
    return totalHeight;
  }

  /// 主图区域大小
  Rect get mainChartRect {
    final mainPadding = mainPaintObject.padding;
    return Rect.fromLTRB(
      mainRect.left + mainPadding.left,
      mainRect.top + mainPadding.top,
      mainRect.right - mainPadding.right,
      mainRect.bottom - mainPadding.bottom,
    );
  }

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

  /// 最大蜡烛宽度[1, 50]
  double get candleMaxWidth => settingConfig.candleMaxWidth;

  /// 单根蜡烛宽度, 限制范围1[pixel] ~ [candleMaxWidth] 之间
  @override
  double get candleWidth => _candleWidth;
  _setCandleWidth(double width, {bool sync = false}) {
    _candleWidth = width;
    if (!settingConfig.isFixedCandleSpacing) _candleSpacing = null;
    if (sync) {
      settingConfig = settingConfig.copyWith(
        candleWidth: width.clamp(
          settingConfig.pixel,
          candleMaxWidth,
        ),
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
    _candleSpacing!.clamp(settingConfig.pixel, candleWidthHalf);
    return _candleSpacing!;
  }

  /// 单根蜡烛所占据实际宽度
  @override
  double get candleActualWidth => candleWidth + candleSpacing;

  /// 单根蜡烛的一半
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
    return _paintObjectManager.mainIndciatorKeys;
  }

  Iterable<IIndicatorKey> get subIndicatorKeys {
    return _paintObjectManager.subIndicatorKeys;
  }

  @override
  int? getDataIndex(IIndicatorKey key) {
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

  ///// Indicator operation /////

  bool hasRegisterInMain(IIndicatorKey key) {
    return _paintObjectManager.hasRegisterInMain(key);
  }

  bool hasRegisterInSub(IIndicatorKey key) {
    return _paintObjectManager.hasRegisterInSub(key);
  }

  bool hasRegisterIndicator(IIndicatorKey key) {
    return hasRegisterInMain(key) || hasRegisterInSub(key);
  }

  /// 在主图中添加指标
  void addIndicatorInMain(IIndicatorKey key) {
    final newObj = _paintObjectManager.addPaintObjectInMain(key, this);
    if (newObj != null) {
      // TODO: 后续优化执行时机
      newObj.precompute(curKlineData.computableRange, reset: true);
      markRepaintChart(reset: true);
      markRepaintCross();
    }
  }

  /// 删除主图中[key]指定的指标
  void delIndicatorInMain(IIndicatorKey key) {
    if (_paintObjectManager.delPaintObjectInMain(key)) {
      markRepaintChart(reset: true);
      markRepaintCross();
    }
  }

  /// 在副图中添加指标
  void addIndicatorInSub(IIndicatorKey key) {
    final newObj = _paintObjectManager.addPaintObjectInSub(key, this);
    if (newObj != null) {
      // TODO: 后续优化执行时机
      newObj.precompute(curKlineData.computableRange, reset: true);
      _flexiKlineConfig.sub.add(key);
      _invokeSizeChanged();
    }
  }

  /// 删除副图[key]指定的指标
  void delIndicatorInSub(IIndicatorKey key) {
    if (_paintObjectManager.delPaintObjectInSub(key)) {
      _flexiKlineConfig.sub.remove(key);
      _invokeSizeChanged();
    }
  }

  /// 恢复所有注册的指标配置为默认
  bool restoreAllIndicator() {
    return _paintObjectManager.restoreAllIndicator();
  }

  /// 恢复[key]指定的指标配置为默认
  bool restoreIndicator(IIndicatorKey key) {
    return _paintObjectManager.restoreIndicator(key);
  }

  //// Config ////

  FlexiKlineConfig? __flexiKlineConfig;
  FlexiKlineConfig get _flexiKlineConfig {
    if (__flexiKlineConfig == null) {
      final config = configuration.getFlexiKlineConfig();
      __flexiKlineConfig = config;
    }
    return __flexiKlineConfig!;
  }

  /// 保存当前FlexiKline配置到本地
  @override
  void storeFlexiKlineConfig() {
    _flexiKlineConfig.mainIndicator = mainPaintObject.indicator.copyWith(
      size: _layoutMode.mainSize,
    );
    _flexiKlineConfig.sub = _paintObjectManager.subIndicatorKeys.toSet();
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
  }

  /// SettingConfig
  @override
  SettingConfig get settingConfig => _flexiKlineConfig.setting;
  set settingConfig(SettingConfig config) {
    _flexiKlineConfig.setting = config;
    markRepaintChart();
    markRepaintCross();
  }

  /// SettingConfig
  @override
  GestureConfig get gestureConfig => _flexiKlineConfig.gesture;
  set gestureConfig(GestureConfig config) {
    _flexiKlineConfig.gesture = config;
    markRepaintChart();
    markRepaintCross();
  }

  /// GridConfig
  @override
  GridConfig get gridConfig => _flexiKlineConfig.grid;
  set gridConfig(GridConfig config) {
    _flexiKlineConfig.grid = config;
    markRepaintChart();
    markRepaintCross();
    markRepaintGrid();
  }

  /// CrossConfig
  @override
  CrossConfig get crossConfig => _flexiKlineConfig.cross;
  set crossConfig(CrossConfig config) {
    _flexiKlineConfig.cross = config;
    markRepaintChart();
    markRepaintCross();
  }

  /// DrawConfig
  @override
  DrawConfig get drawConfig => _flexiKlineConfig.draw;
  set drawConfig(DrawConfig config) {
    _flexiKlineConfig.draw = config;
    markRepaintChart();
    markRepaintDraw();
  }

  /// 获取[key]指定的指标实例
  /// 1. 如果已载入, 则直接返回绘制对象的指标实例
  /// 2. 如果示载入, 则从本地缓存中加载, 并创建指标实现.
  T? getIndicator<T extends Indicator>(IIndicatorKey key) {
    return _paintObjectManager.getIndicator(key);
  }

  /// 更新[indicator]指标配置
  /// 1. 如果已载入, 则更新当前绘制对象的指标
  /// 2. 如果未载入, 则保存到本地缓存中, 以备后续使用
  bool updateIndicator<T extends Indicator>(T indicator) {
    final updated = _paintObjectManager.updateIndicator(indicator);
    if (updated) markRepaintChart();
    return updated;
  }
}
