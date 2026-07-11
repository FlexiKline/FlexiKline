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

abstract class KlineBindingBase with FlexiLog implements PaintContext, DrawContext {
  @override
  String get logTag => 'Controller';

  final IConfiguration configuration;

  /// 是否自动保存 Kline 配置。
  final bool autoSave;

  /// 初始布局模式。默认 [FlexiLayoutMode.adapt]（覆盖大多数场景）。
  final FlexiLayoutMode _initialLayoutMode;

  /// Fixed 模式下的初始画布尺寸（主区 + 副区），可为空。
  ///
  /// 父级能提供有限宽高约束时可不传；父级高度无限时（如滚动容器内），
  /// 需传入该值或在首次 fixed 渲染前调用 `setFixedLayoutMode`。
  final Size? _initialFixedSize;

  /// KlineData 缓存容量。
  final int? klineDataCacheCapacity;

  /// 副区指标最大数量。
  final int subIndicatorMaxCount;

  /// 指标绘制对象管理器。
  final IndicatorPaintObjectManager _paintObjectManager;

  final OverlayDrawObjectManager _drawObjectManager;

  KlineBindingBase({
    required this.configuration,
    this.autoSave = true,
    FlexiLayoutMode initialLayoutMode = FlexiLayoutMode.adapt,
    Size? initialFixedSize,
    this.subIndicatorMaxCount = defaultSubIndicatorMaxCount,
    IFlexiLogger? logger,
    this.klineDataCacheCapacity,
  })  : _initialLayoutMode = initialLayoutMode,
        _initialFixedSize = initialFixedSize,
        _paintObjectManager = IndicatorPaintObjectManager(
          configuration: configuration,
          subIndicatorMaxCount: subIndicatorMaxCount,
          logger: logger,
        ),
        _drawObjectManager = OverlayDrawObjectManager(
          configuration: configuration,
          logger: logger,
        ) {
    logd('construct');
    this.logger = logger;
    init();
  }

  @protected
  @mustCallSuper
  void init() {
    logd('init base');
  }

  @protected
  @mustCallSuper
  void initState() {
    logd('initState base');
  }

  @protected
  @mustCallSuper
  void dispose() {
    logd('dispose base');
    if (autoSave) storeFlexiKlineConfig();
    _paintObjectManager.dispose();
    _drawObjectManager.dispose();
  }

  @protected
  @mustCallSuper
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    logd('onThemeChanged base');
    storeFlexiKlineConfig();
  }

  @protected
  @mustCallSuper
  void onLanguageChanged() {
    logd('onLanguageChanged base');
  }

  @protected
  @mustCallSuper
  void onKlineSpecChanged(KlineSpec oldSpec) {
    logd('onKlineSpecChanged base');
  }

  @protected
  @mustCallSuper
  bool onTap(Offset position) {
    logd('onTap base');
    return false;
  }

  @override
  IFlexiKlineTheme get theme => configuration.theme;

  @override
  Map<String, dynamic>? getConfig(String key) {
    return configuration.getConfig(key);
  }

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) {
    return configuration.setConfig(key, value);
  }

  /// 保存当前 FlexiKline 配置。
  void storeFlexiKlineConfig({
    bool storeDrawOverlays = true,
  });

  /// 请求重绘 Grid 图层。
  @protected
  void markRepaintGrid();

  /// 请求重绘 Chart 图层。
  @protected
  void markRepaintChart({bool reset = false});

  /// 请求重绘 Cross 图层。
  @protected
  void markRepaintCross();

  /// 请求重绘 Draw 图层。
  @protected
  void markRepaintDraw();

  /// 处理 Widget 挂载前暂存的数据。由 StateBinding 实现，view 层在 initState 后调用。
  void flushPendingKlineData();

  /// 按当前 [computedDataCapacity] 重建当前 KlineData 的 slots，并使其余缓存失效。
  ///
  /// 在 computed 指标声明增长（slot 容量高水位上升）后调用，确保当前数据能容纳
  /// 新增高位指标；其余缓存数据因指标声明已变、其 slot 值已陈旧，统一丢弃，
  /// 下次切换时重新加载。由 StateBinding 实现。
  @protected
  void syncComputedSlotCapacity();
}

/// KlineController 内部访问扩展。
extension on KlineBindingBase {
  FlexiKlineConfig get flexiKlineConfig {
    return _paintObjectManager.flexiKlineConfig;
  }

  MainPaintObject get mainPaintObject {
    return _paintObjectManager.mainPaintObject;
  }

  CandleBasePaintObject get candlePaintObject {
    return _paintObjectManager.candlePaintObject;
  }

  TimeBasePaintObject get timePaintObject {
    return _paintObjectManager.timePaintObject;
  }

  Iterable<PaintObject> get subPaintObjects {
    return _paintObjectManager.subPaintObjects;
  }
}

/// FlexiKline Controller 生命周期状态，借鉴 Flutter `_ElementLifecycle`。
///
/// ```
/// initial ──mountIndicators()──▶ mounted ──dispose()──▶ disposed
/// ```
enum FlexiKlineLifecycle {
  /// 构造完成，`init()` 已执行，PaintObject 尚未创建。
  initial,

  /// `mountIndicators()` 完成，PaintObject 就绪，可正常运行。
  mounted,

  /// `dispose()` 已调用，资源已释放。
  disposed;

  /// 是否处于 [FlexiKlineLifecycle.mounted] 状态。
  bool get isMounted => this == FlexiKlineLifecycle.mounted;
}

/// Kline 状态通知。
class FlexiStateNotifier<T> extends ValueNotifier<T> {
  FlexiStateNotifier(super.value);

  bool _silent = false;

  @override
  void notifyListeners() {
    if (_silent) return;
    super.notifyListeners();
  }

  /// 静默赋值，不触发 [notifyListeners]。
  /// 用于 build 阶段设置初始值，避免触发订阅者 setState。
  void setSilently(T val) {
    _silent = true;
    value = val;
    _silent = false;
  }

  void updateValue(T val) {
    value = val;
    super.notifyListeners();
  }
}
