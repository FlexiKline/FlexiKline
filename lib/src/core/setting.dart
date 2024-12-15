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
    _paintObjectManager = IndicatorPaintObjectManager(
      configuration: configuration,
      logger: loggerDelegate,
    )..init(
        this,
        initMainIndicatorKeys: _flexiKlineConfig.main,
        initSubIndicatorKeys: _flexiKlineConfig.sub,
      );
  }

  @override
  void initState() {
    super.initState();
    logd("initState setting");
    initFlexiKlineState();
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose setting");
    _canvasSizeChangeListener.dispose();
    _paintObjectManager.dispose();
  }

  late final IndicatorPaintObjectManager _paintObjectManager;

  /// KlineData整个图表区域大小变化监听器
  final _canvasSizeChangeListener =
      KlineStateNotifier(defaultCanvasRectMinRect);
  @override
  ValueListenable<Rect> get canvasSizeChangeListener {
    return _canvasSizeChangeListener;
  }

  void _invokeSizeChanged() {
    final oldCanvasRect = _canvasSizeChangeListener.value;

    if (_fixedCanvasRect != null) {
      final changed = _updateMainPaintObjectLayoutParam(
        height: mainRect.height,
      );
      if (changed || oldCanvasRect != _fixedCanvasRect) {
        markRepaintChart(reset: true);

        _canvasSizeChangeListener.value = canvasRect;
        _canvasSizeChangeListener.notifyListeners();
      }
    } else {
      if (oldCanvasRect != canvasRect) {
        final changed = _updateMainPaintObjectLayoutParam(
          height: mainRect.height,
        );
        if (changed || oldCanvasRect.width != mainRect.width) {
          markRepaintChart(reset: true);
        }
        _canvasSizeChangeListener.value = canvasRect;
      }
    }

    markRepaintCross();
  }

  Rect? _fixedCanvasRect;
  bool get isFixedSizeMode => _fixedCanvasRect != null;

  /// 整个画布区域大小 = 由主图区域 + 副图区域
  @override
  Rect get canvasRect {
    if (_fixedCanvasRect != null) {
      return _fixedCanvasRect!;
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.top,
      math.max(mainRect.width, subRect.width),
      mainRect.height + subRectHeight,
    );
  }

  double get canvasWidth => canvasRect.width;
  double get canvasHeight => canvasRect.height;

  /// 副图整个区域
  @override
  Rect get subRect {
    if (_fixedCanvasRect != null) {
      return Rect.fromLTRB(
        _fixedCanvasRect!.left,
        _fixedCanvasRect!.bottom - subRectHeight,
        _fixedCanvasRect!.right,
        _fixedCanvasRect!.bottom,
      );
    }
    return Rect.fromLTRB(
      mainRect.left,
      mainRect.bottom,
      mainRect.right,
      mainRect.bottom + subRectHeight,
    );
  }

  /// 主区域大小
  @override
  Rect get mainRect {
    if (_fixedCanvasRect != null) {
      return Rect.fromLTRB(
        _fixedCanvasRect!.left,
        _fixedCanvasRect!.top,
        _fixedCanvasRect!.right,
        _fixedCanvasRect!.bottom - subRectHeight,
      );
    }
    return settingConfig.mainRect;
  }

  /// TimeIndicator区域大小
  @override
  Rect get timeRect {
    final timeConfig = _paintObjectManager.timeRectConfig;
    if (timeConfig == null) return Rect.zero;
    final subRect = this.subRect;
    if (timeConfig.position == DrawPosition.middle) {
      return Rect.fromLTWH(
        subRect.left,
        subRect.top,
        subRect.width,
        timeConfig.height,
      );
    } else if (timeConfig.position == DrawPosition.bottom) {
      return Rect.fromLTWH(
        subRect.left,
        subRect.bottom - timeConfig.height,
        subRect.width,
        timeConfig.height,
      );
    }
    return Rect.zero;
  }

  /// 主区域最小宽高
  Size get mainMinSize => settingConfig.mainMinSize;

  /// 主区域大小设置
  void setMainSize(Size size) {
    if (isFixedSizeMode) return;
    // TODO: 优化: 将mainSize移至mainPaintObject管理.
    settingConfig.setMainRect(size);
    _invokeSizeChanged();
  }

  /// 适配[FlexiKlineWidget]所在布局的变化
  ///
  /// 注: 目前仅考虑适配宽度的变化.
  ///   这将会导致无法手动调整[FlexiKlineWidget]的宽度.
  void adaptLayoutChange(Size size) {
    if (size.width != mainRect.width) {
      setMainSize(Size(size.width, mainRect.height));
    }
  }

  void exitFixedSize() {
    if (_fixedCanvasRect != null) {
      _fixedCanvasRect = null;
      _invokeSizeChanged();
    }
  }

  /// 设置Kline固定大小(主要在全屏或横屏场景中使用此API)
  /// 当设置[_fixedCanvasRect]后, 主区高度=[_fixedCanvasRect]的总高度 - [subRectHeight]副区所有指标高度
  /// [size] 当前Kline主区+副区的大小.
  /// 注: 设置是临时的, 并不会更新到配置中.
  void setFixedSize(Size size) {
    if (size >= settingConfig.mainMinSize) {
      _fixedCanvasRect = Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height,
      );
      _invokeSizeChanged();
    }
  }

  /// 主区padding
  EdgeInsets get mainPadding => settingConfig.mainPadding;

  Rect get mainChartRect => Rect.fromLTRB(
        mainRect.left + mainPadding.left,
        mainRect.top + mainPadding.top,
        mainRect.right - mainPadding.right,
        mainRect.bottom - mainPadding.bottom,
      );

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
  // set candleMaxWidth(double width) {
  //   settingConfig.candleMaxWidth = width.clamp(1.0, 50.0);
  // }

  /// 单根蜡烛宽度, 限制范围1[pixel] ~ [candleMaxWidth] 之间
  @override
  double get candleWidth => settingConfig.candleWidth;
  @protected
  set candleWidth(double width) {
    settingConfig.candleWidth = width.clamp(
      settingConfig.pixel,
      candleMaxWidth,
    );
  }

  /// 单根蜡烛所占据实际宽度
  @override
  double get candleActualWidth => candleWidth + settingConfig.candleSpacing;

  /// 单根蜡烛的一半
  @override
  double get candleWidthHalf => candleActualWidth / 2;

  /// 绘制区域宽度内, 可绘制的蜡烛数
  int get maxCandleCount => (mainChartWidth / candleActualWidth).ceil();

  /// 时间刻度指标配置
  @override
  ITimeRectConfig? get timeRectConfig {
    return _paintObjectManager.timeRectConfig;
  }

  // /// 注册主区指标配置构造器
  // void registerMainIndicatorBuilder(
  //   IIndicatorKey key,
  //   IndicatorBuilder<SinglePaintObjectIndicator> builder,
  // ) {
  //   _paintObjectManager.registerMainIndicatorBuilder(key, builder);
  // }

  // /// 注册副区指标配置构造器
  // void registerSubIndicatorBuilder<T extends Indicator>(
  //   IIndicatorKey key,
  //   IndicatorBuilder<SinglePaintObjectIndicator> builder,
  // ) {
  //   _paintObjectManager.registerSubIndicatorBuilder(key, builder);
  // }

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
  MultiPaintObjectBox get mainPaintObject {
    return _paintObjectManager.mainPaintObject;
  }

  @override
  Iterable<PaintObject> get subPaintObjects {
    return _paintObjectManager.subPaintObjects;
  }

  @override
  int? getDataIndex(IIndicatorKey key) {
    return _paintObjectManager.getIndicatorDataIndex(key);
  }

  @override
  int get indicatorCount => _paintObjectManager.indicatorCount;

  /// 更新主区指标的布局参数
  bool _updateMainPaintObjectLayoutParam({
    double? height,
    EdgeInsets? padding,
  }) {
    bool changed = mainPaintObject.updateLayout(
      height: height,
      padding: padding,
      // reset: true,
    );
    return changed;
  }

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

  @protected
  double get subRectHeight {
    double totalHeight = 0.0;
    for (final indicator in subPaintObjects) {
      totalHeight += indicator.height;
    }
    return totalHeight;
  }

  /// 在主图中添加指标
  void addIndicatorInMain(IIndicatorKey key) {
    final newObj = _paintObjectManager.addIndicatorInMain(key, this);
    if (newObj != null) {
      // TODO: 后续优化执行时机
      newObj.doPrecompute(Range(0, curKlineData.length), reset: true);
      _flexiKlineConfig.main.add(key);
      markRepaintChart(reset: true);
      markRepaintCross();
    }
  }

  /// 删除主图中[key]指定的指标
  void delIndicatorInMain(IIndicatorKey key) {
    if (_paintObjectManager.delIndicatorInMain(key)) {
      _flexiKlineConfig.main.remove(key);
      markRepaintChart(reset: true);
      markRepaintCross();
    }
  }

  /// 在副图中添加指标
  void addIndicatorInSub(IIndicatorKey key) {
    final newObj = _paintObjectManager.addIndicatorInSub(key, this);
    if (newObj != null) {
      // TODO: 后续优化执行时机
      newObj.doPrecompute(Range(0, curKlineData.length), reset: true);
      _flexiKlineConfig.sub.add(key);
      _invokeSizeChanged();
    }
  }

  /// 删除副图[key]指定的指标
  void delIndicatorInSub(IIndicatorKey key) {
    if (_paintObjectManager.delIndicatorInSub(key)) {
      _flexiKlineConfig.sub.remove(key);
      _invokeSizeChanged();
    }
  }

  //// Config ////

  FlexiKlineConfig? __flexiKlineConfig;
  FlexiKlineConfig get _flexiKlineConfig {
    if (__flexiKlineConfig == null) {
      final config = configuration.getFlexiKlineConfig();
      _flexiKlineConfig = config;
    }
    return __flexiKlineConfig!;
  }

  set _flexiKlineConfig(config) {
    // __flexiKlineConfig = config.clone();
    __flexiKlineConfig = config;
  }

  void initFlexiKlineState({bool isInit = false}) {
    /// 修正mainRect大小
    if (mainRect.isEmpty) {
      final initSize = configuration.initialMainSize;
      if (isInit && initSize < settingConfig.mainMinSize) {
        throw Exception('initMainRect(size:$initSize) is invalid!!!');
      }
      settingConfig.setMainRect(initSize);
      _invokeSizeChanged();
    }

    /// TODO: 此处考虑对其他参数的修正
  }

  /// 保存当前FlexiKline配置到本地
  @override
  void storeFlexiKlineConfig() {
    _flexiKlineConfig.main = _paintObjectManager.mainIndciatorKeys.toSet();
    _flexiKlineConfig.sub = _paintObjectManager.subIndicatorKeys.toSet();
    configuration.saveFlexiKlineConfig(_flexiKlineConfig);
  }

  /// 更新[config]到[_flexiKlineConfig]
  @override
  void updateFlexiKlineConfig(FlexiKlineConfig config) {
    if (config.key != _flexiKlineConfig.key) {
      /// 保存当前配置
      storeFlexiKlineConfig();

      /// 使用当前配置更新config
      config.update(_flexiKlineConfig);

      /// 更新当前配置为[config]
      _flexiKlineConfig = config;

      /// 初始化状态
      initFlexiKlineState();

      /// 保存当前配置
      if (autoSave) storeFlexiKlineConfig();
    } else {
      _flexiKlineConfig = config;

      /// 初始化状态
      initFlexiKlineState();

      /// 保存当前配置
      if (autoSave) storeFlexiKlineConfig();
    }
  }

  @override
  @Deprecated('废弃, 由PaintObject执行precompute')
  Map<IIndicatorKey, dynamic> getIndicatorCalcParams() {
    return _paintObjectManager.getIndicatorCalcParams();
  }

  /// SettingConfig
  @override
  SettingConfig get settingConfig => _flexiKlineConfig.setting;
  set settingConfig(SettingConfig config) {
    final isChangeSize = config.mainRect != mainRect;
    _flexiKlineConfig.setting = config;
    initFlexiKlineState();
    if (isChangeSize) {
      _invokeSizeChanged();
    } else {
      markRepaintChart();
      markRepaintCross();
    }
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

  /// TooltipConfig
  @override
  TooltipConfig get tooltipConfig => _flexiKlineConfig.tooltip;
  set tooltipConfig(TooltipConfig config) {
    _flexiKlineConfig.tooltip = config;
    markRepaintChart();
    markRepaintCross();
  }
}
