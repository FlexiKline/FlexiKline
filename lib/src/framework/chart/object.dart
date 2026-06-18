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

/// IndicatorObject: 保存 Indicator 配置
///
/// 提供 [Indicator] 的所有属性。
abstract class IndicatorObject<T extends Indicator>
    implements Comparable<IndicatorObject<T>>, IPaintBounding, IPaintState {
  IndicatorObject();

  T? _indicator;
  PaintContext? _context;

  /// 获取创建此对象的 Indicator
  T get indicator {
    assert(_indicator != null, 'indicator 尚未设置，请确保已通过框架创建');
    return _indicator!;
  }

  /// 绘制上下文（挂载后可用）。
  PaintContext get context {
    assert(_context != null, 'context 尚未设置，请确保已通过框架创建');
    return _context!;
  }

  IIndicatorKey get key => indicator.key;

  /// 常用配置。
  SettingConfig get settingConfig => context.settingConfig;
  GridConfig get gridConfig => context.gridConfig;
  CrossConfig get crossConfig => context.crossConfig;

  /// 当前 K 线数据。
  KlineData get klineData => context.klineData;

  /// 当前绘制偏移。
  double get paintDxOffset => context.paintDxOffset;
  double get startCandleDx => context.startCandleDx;

  /// 蜡烛绘制尺寸。
  double get candleWidth => context.candleWidth;
  double get candleSpacing => context.candleSpacing;
  double get candleActualWidth => context.candleActualWidth;
  double get candleWidthHalf => context.candleWidthHalf;

  /// 当前主题。
  IFlexiKlineTheme get theme => context.theme;

  double? _tmpHeight;
  double get height => _tmpHeight ?? indicator.height;

  EdgeInsets? _tmpPadding;
  EdgeInsets get padding => _tmpPadding ?? indicator.padding;

  PaintMode get paintMode => indicator.paintMode;
  int get zIndex => indicator.zIndex;

  @override
  int compareTo(IndicatorObject other) {
    return indicator.zIndex.compareTo(other.indicator.zIndex);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is IndicatorObject && key == other.key);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ key.hashCode;
}

/// PaintObject
///
/// 通过混入边界计算与数据初始化计算，简化 PaintObject 接口。
/// 1. 定义 PaintObject 行为：通过实现对应的接口，实现 Chart 的配置、计算、绘制、Cross。
/// 2. [_parent] 保存当前绘制对象的父级。
abstract class PaintObject<T extends Indicator<IIndicatorKey>> extends IndicatorObject<T>
    with FlexiLog, PaintStyleMixin<T>, PaintObjectBoundingMixin<T>, PaintObjectGeometryStateMixin<T>
    implements IPaintObject, IPaintLifecycle {
  // 父级 PaintObject，主要用于给其子级 PaintObject 限定范围。
  PaintObject? _parent;

  bool get hasParentObject => _parent != null;

  /// 将 PaintObject 挂载到绘制系统。
  /// 子类可 override 此方法在挂载时做额外初始化，但必须先调用 `super.mount()`。
  @mustCallSuper
  @protected
  void mount(T indicator, PaintContext context) {
    assert(!_mounted, 'PaintObject(${indicator.key}) 已经 mount，不能重复调用');
    _mounted = true;
    _indicator = indicator;
    _context = context;
  }

  bool _mounted = false;
  bool _initialized = false;
  bool _attached = false;

  /// 业务/一次性初始化。mount 之后由框架触发一次。
  ///
  /// 此时几何（drawableRect/paneIndex/minMax）尚未生效；依赖几何的逻辑应放到 [didAttach]。
  @protected
  @mustCallSuper
  @override
  void initState() {}

  /// K 线依赖（spec.key：symbol/interval）变化时回调，参数为旧 spec。
  @protected
  @override
  void didChangeDependencies(KlineSpec oldSpec) {}

  /// 指标配置发生变改
  @protected
  void didUpdateIndicator(covariant T oldIndicator) {
    // 基类不处理 precompute，由 ComputedPaintObject 处理
  }

  @protected
  void didChangeTheme() {}

  /// 进入绘制树（几何首次有效）时回调。默认无操作。
  @protected
  @override
  void didAttach() {}

  /// 离开绘制树时回调。默认无操作。
  @protected
  @override
  void didDetach() {}

  /// 出树时是否保活（不 dispose、由 manager 留缓存复用）。
  ///
  /// 注意：若 [ComputedPaintObject] 复写为 `true`，隐藏后其 compute slot 会随对象一起保留，
  /// 直到 controller `dispose()` 才释放。多指标/大数据场景需评估常驻内存占用。
  @override
  bool get keepAlive => false;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @mustCallSuper
  @protected
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _parent = null;
  }

  @protected
  @override
  void paintOverlay(Canvas canvas, Size size) {}

  @override
  void paintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {}

  /// 处理 Tap 事件
  ///
  /// 注：自行处理 [position] 位置的点击事件。
  bool handleTap(Offset position) => false;

  /// 触发重新绘制
  void setState([VoidCallback? fn]) {
    final Object? result = fn?.call() as dynamic;
    assert(() {
      if (result is Future) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() callback argument returned a Future.'),
          ErrorDescription(
            'The setState() method on $this was called with a closure or method that '
            'returned a Future. Maybe it is marked as "async".',
          ),
          ErrorHint(
            'Instead of performing asynchronous work inside a call to setState(), first '
            'execute the work (without updating the widget state), and then synchronously '
            'update the state inside a call to setState().',
          ),
        ]);
      }
      // We ignore other types of return values so that you can do things like:
      //   setState(() => x = 3);
      return true;
    }());
    context.requestRepaint();
  }

  @override
  String get logTag => indicator.key.toString();
}

/// 普通指标绘制对象，不占 slot，无需预计算。
///
/// 内置的 Candle、Time、Volume 等均基于此，自定义指标也可继承。
abstract class DirectPaintObject<T extends DirectIndicator> extends PaintObject<T> implements IDirectPainter {}

/// 数据指标绘制对象
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 持有 [dataIndex]，用于在 slots 中存取计算数据。
abstract class ComputedPaintObject<T extends ComputedIndicator> extends PaintObject<T>
    with PaintObjectComputedMixin<T>
    implements IComputedPainter {
  int? _dataIndex;

  /// 当前绘制对象的指标计算数据存储下标，用于在 FlexiCandleModel.slots 中存取计算数据。
  /// mount 时由框架注入；若未能获取（如测试 mock），首次访问时懒加载。
  int get dataIndex {
    return _dataIndex ??= context.getComputedDataIndex(indicator.key) ?? -1;
  }

  /// mount 时提前注入 dataIndex，避免首次访问时的懒加载。
  /// 若 context 尚未分配 slot（如测试 mock），保持 null，由 getter 懒加载兜底。
  @visibleForTesting
  @override
  @mustCallSuper
  @protected
  void mount(T indicator, PaintContext context) {
    super.mount(indicator, context);
    _dataIndex = context.getComputedDataIndex(indicator.key);
  }

  /// 指标配置发生变改
  @mustCallSuper
  @override
  @protected
  void didUpdateIndicator(covariant T oldIndicator) {
    super.didUpdateIndicator(oldIndicator);
    if (shouldRecompute(oldIndicator)) {
      this.compute(klineData.computableRange, reset: true);
    }
  }
}

/// 业务指标绘制对象
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 声明即常驻（keepAlive=true）：显示 attach、隐藏 detach 保活、显式移除才 dispose。
/// 子类可按需 override 明确生命周期方法；简单指标可只 override [loadBusinessData]。
abstract class ExternalPaintObject<T extends ExternalIndicator> extends PaintObject<T> implements IExternalPainter {
  /// 业务指标默认常驻，不释放
  @override
  bool get keepAlive => true;

  /// 业务初始化。框架在常驻对象创建后调用一次。
  @protected
  @mustCallSuper
  @override
  void initState() {
    super.initState();
    loadBusinessData();
  }

  /// 简单业务指标的便捷入口；复杂指标应优先 override 明确生命周期方法。
  @protected
  @override
  void loadBusinessData() {}
}

/// 蜡烛图绘制对象
///
/// 使用 [DirectIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class CandleBasePaintObject<T extends CandleBaseIndicator> extends DirectPaintObject<T> {
  /// 获取当前蜡烛图的绘制类型
  FlexiChartType resolveChartType();

  /// 是否在蜡烛图类型为线图时隐藏指标
  bool get hideMainIndicatorsInLineChartMode => false;
}

/// 时间轴指标绘制对象
///
/// 使用 [DirectIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class TimeBasePaintObject<T extends TimeBaseIndicator> extends DirectPaintObject<T> {
  /// 获取当前时间轴的绘制位置
  DrawPosition get position => indicator.position;
}

/// 主区绘制对象
///
/// 使用 [DirectIndicatorKey]，属于基础/系统指标，不占 slot。
/// [children] 存储主区内的所有子绘制对象。
final class MainPaintObject<T extends MainPaintObjectIndicator> extends PaintObject<T> implements IComputedPainter {
  // 需要显式构造函数，因为需要在构造函数体中初始化 children
  MainPaintObject() : super() {
    children = SortableHashSet<PaintObject>.from(
      <PaintObject>[],
      (a, b) => a.compareTo(b),
    );
  }

  late final SortableHashSet<PaintObject> children;

  Set<PaintObject> get paintableChildren {
    if (onlyMainChart) {
      return children.where((object) => object.key == candleIndicatorKey).toSet();
    }
    return children;
  }

  /// 获取蜡烛图绘制对象
  CandleBasePaintObject? get _candlePaintObject {
    return children.whereType<CandleBasePaintObject>().firstWhereOrNull(
          (obj) => obj.key == candleIndicatorKey,
        );
  }

  /// 是否只绘制蜡烛图（隐藏技术指标）
  /// 当蜡烛图配置允许且当前图表类型为线图时返回 true
  bool get onlyMainChart {
    final candleObject = _candlePaintObject;
    if (candleObject == null) return false;
    return candleObject.hideMainIndicatorsInLineChartMode && candleObject.resolveChartType().isLine;
  }

  Size? _tmpSize;
  Size get size => _tmpSize ?? indicator.size;

  @override
  Rect get drawableRect {
    return _drawableRect ??= Offset.zero & size;
  }

  @override
  bool handleTap(Offset position) {
    for (final object in children) {
      if (object.handleTap(position)) return true;
    }
    return false;
  }

  @override
  bool shouldRecompute(MainPaintObjectIndicator oldIndicator) {
    if (oldIndicator.children != indicator.children) {
      return true;
    }
    return false;
  }

  /// 委托子对象的 precompute 方法
  ///
  /// MainPaintObject 本身不需要 precompute，但需要将调用委托给子对象。
  @override
  void compute(Range range, {bool reset = false}) {
    for (final computable in children.whereType<IComputedPainter>()) {
      computable.compute(range, reset: reset);
    }
  }

  @override
  void didChangeTheme() {
    for (final object in children) {
      object.didChangeTheme();
    }
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) {
    return minMax;
  }

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTooltip(
    Canvas canvas, {
    FlexiCandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    return topRect.size;
  }

  @override
  void dispose() {
    super.dispose();
    for (final object in children) {
      object.dispose();
    }
    children.clear();
  }
}
