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

abstract class KlineBindingBase with FlexiLog implements ISetting, IPaintContext, IDrawContext {
  @override
  String get logTag => 'Controller';

  final IConfiguration configuration;

  /// 对于Kline的操作是否自动保存到本地配置中.
  /// 包括: dispose; 增删指标; 调整参数等等.
  final bool autoSave;

  /// klineData数据缓存容量
  /// 一个FlexiKlineController允许最多维护的KlineData个数.
  final int? klineDataCacheCapacity;

  /// 指标绘制对象管理
  final IndicatorPaintObjectManager _paintObjectManager;

  final OverlayDrawObjectManager _drawObjectManager;

  KlineBindingBase({
    required this.configuration,
    this.autoSave = true,
    int subIndicatorMaxCount = defaultSubIndicatorMaxCount,
    IFlexiLogger? logger,
    this.klineDataCacheCapacity,
  })  : _paintObjectManager = IndicatorPaintObjectManager(
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

  KlineBindingBase get instance => this;

  T getInstance<T extends KlineBindingBase>(T instance) {
    return instance;
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
}

/// KlineController内部扩展
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
  disposed,
}

/// [FlexiKlineLifecycle] 便捷扩展。
extension FlexiKlineLifecycleExt on FlexiKlineLifecycle {
  /// 是否处于 [FlexiKlineLifecycle.mounted] 状态。
  bool get isMounted => this == FlexiKlineLifecycle.mounted;
}

/// Kline状态通知
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
