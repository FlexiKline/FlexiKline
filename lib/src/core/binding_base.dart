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

  /// 初始布局模式。默认 [FlexiLayoutMode.adapt]（覆盖大多数场景）。
  final FlexiLayoutMode _initialLayoutMode;

  /// Fixed 模式下的初始画布尺寸（主区 + 副区），可为空。
  ///
  /// 父级能提供有限宽高约束时可不传；父级高度无限时（如滚动容器内），
  /// 需传入该值或在首次 fixed 渲染前调用 `setFixedLayoutMode`。
  final Size? _initialFixedSize;

  /// KlineData 缓存容量。
  final int? klineDataCacheCapacity;

  /// latest 指标计算的固定节拍。
  final Duration calculationInterval;

  /// 副区指标最大数量。
  final int subIndicatorMaxCount;

  /// 指标绘制对象管理器。
  final IndicatorPaintObjectManager _paintObjectManager;

  /// 绘制工具对象管理器。
  final OverlayDrawObjectManager _drawObjectManager;

  /// 蜡烛合并与指标计算流水线，由 [StateBinding.init] 初始化。
  late KlineDataPipeline _pipeline;

  KlineBindingBase({
    required this.configuration,
    FlexiLayoutMode initialLayoutMode = FlexiLayoutMode.adapt,
    Size? initialFixedSize,
    this.subIndicatorMaxCount = defaultSubIndicatorMaxCount,
    IFlexiLogger? logger,
    this.klineDataCacheCapacity,
    this.calculationInterval = const Duration(milliseconds: 500),
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
    // 不在此落盘：时机由业务侧决定（见 `SettingBinding.storeFlexiKlineConfig`）。
    // 多个 Controller 共享同一份配置时，自动落盘会让从属侧用自己的运行时状态覆盖对侧。
    _paintObjectManager.dispose();
    _drawObjectManager.dispose();
  }

  @protected
  @mustCallSuper
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    logd('onThemeChanged base');
    // 不在此落盘：主题变化只让各 PaintObject / DrawObject 重建主题派生资源，
    // 不修改 [FlexiKlineConfig] 的任何字段。
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

  /// 取消当前 PaintObject 拖动并通知认领对象回滚临时状态。
  void onPaintObjectDragCancel();

  /// 释放框架对 [object] 的持有：退树与对象主动中止交互共用本通道。
  ///
  /// 框架侧任何按对象粒度持有的引用（当前是 ChartBinding 的拖动归属）都应在本方法的
  /// 覆写中释放。覆写方必须先调 `super`，由 mixin 链保证每个 Binding 只清理自己持有
  /// 的部分；每个覆写都必须带对象身份守卫，不能误释放他人的持有。
  @mustCallSuper
  @override
  void requestReleasePaintObject(PaintObject object) {
    logd('requestReleasePaintObject base ${object.key}');
  }

  /// 请求重绘 Chart / Cross / Draw 三个绘制层（不含 Grid）。
  ///
  /// 用于数据合并、指标计算完成等需要整体刷新绘制层的场景。
  @protected
  void markRepaintAll() {
    markRepaintChart();
    markRepaintCross();
    markRepaintDraw();
  }

  /// 处理 Widget 挂载前暂存的数据。由 StateBinding 实现，view 层在 initState 后调用。
  void flushPendingKlineData();

  /// 按当前 [computedDataCapacity] 重建当前 KlineData 的 slots，并使其余缓存失效。
  ///
  /// 在 computed 指标声明增长（slot 容量高水位上升）后调用，确保当前数据能容纳
  /// 新增高位指标；其余缓存数据因指标声明已变、其 slot 值已陈旧，统一丢弃，
  /// 下次切换时重新加载。由 StateBinding 实现。
  @protected
  void syncComputedSlotCapacity();

  /// 丢弃非当前的缓存 KlineData（指标声明/参数变更后其 slot 值已陈旧），
  /// 下次切换时重新加载。由 StateBinding 实现。
  void evictInactiveKlineDataCache();

  /// 把当前绘制偏移约束回合法区间。由 StateBinding 实现。
  ///
  /// `paintDxOffset` 的取值区间由 `maxPaintWidth`（数据量 × 单根蜡烛实际宽度）、
  /// 主图宽度与最小留白共同决定，因此下列任一变化都可能让当前偏移越界：
  /// 蜡烛宽度改变、数据量减少、主图变宽、`minPaintBlankRate` 改变。
  ///
  /// 手势路径在赋值 `paintDxOffset` 时已顺带夹取；非赋值路径（如
  /// `syncFlexiKlineConfig` 直接换掉蜡烛宽度）改变了区间却没有新偏移可赋，
  /// 需要主动调用本方法，否则越界的旧偏移会让用户只能向一个方向平移才能恢复。
  @protected
  void constrainPaintDxOffset();
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

  /// 赋值并保证恰好通知一次。
  ///
  /// 与直接赋值 [value] 的区别: 当新值与旧值 `==` 时（典型场景是同一实例被
  /// 就地修改, 如 draw 的 [Point] 被 `onUpdateDrawPoint` 改写）,
  /// [ValueNotifier] 的 setter 会静默早退, 本方法仍会通知一次。
  ///
  /// 若新值必然与旧值不同, 直接赋值 [value] 即可, 无需本方法。
  void updateValue(T val) {
    if (value == val) {
      notifyListeners();
    } else {
      value = val;
    }
  }
}
