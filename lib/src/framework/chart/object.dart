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

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;

  /// 处理 Tap 事件
  ///
  /// 注：自行处理 [position] 位置的点击事件。
  ///
  /// 返回值决定框架的后续动作, 见 [PaintTapResult]。只有返回
  /// [PaintTapResult.selected] 才会被授予选中态; 绘制对象无法在其他时机
  /// 自行获得选中态。
  ///
  /// [position] 已由框架按位置分派: 主区指标只会收到 `mainRect` 内的点击,
  /// 副区指标只会收到 `subRect` 内的点击, 但具体命中区仍需自行判断。命中区
  /// 必须落在本对象所在大区内, 否则收不到对应位置的点击。
  ///
  /// 主区内按 zIndex 升序询问, 即视觉最底层的子指标先被询问。
  /// [handleDragStart] 不遍历绘制树, 不受此顺序影响。
  PaintTapResult handleTap(Offset position) => PaintTapResult.ignored;

  /// 是否为框架当前选中的绘制对象。
  ///
  /// 选中态由框架持有（对象粒度）。绘制对象应把所有选中相关的渲染判断门控在
  /// 本 getter 上：框架在任意路径清除选中态后本值即为 false, 对象内部残留的
  /// 选中标识不会被读到, 因此框架不额外提供失选回调。
  bool get isSelected => context.isSelectedPaintObject(this);

  /// 请求放弃选中态；非当前选中对象时无效果。
  ///
  /// 用于 tap 之外的时机（如选中目标已从业务数据中消失）。tap 内部想放弃
  /// 选中态应直接返回 [PaintTapResult.handled], 由框架统一处理。
  void deselect() => context.requestDeselectPaintObject(this);

  /// 处理拖动开始, 仅当前选中且可绘制的对象会被询问。
  ///
  /// 返回 true 认领本次拖动：框架随后抑制蜡烛图平移、惯性平移、loadMore 检查
  /// 与 cross 更新, 并把后续的 [handleDragUpdate] / [handleDragEnd] /
  /// [handleDragCancel] 只发给本对象。
  ///
  /// 注：本回调不遍历绘制树, 因此不存在命中优先级问题。
  bool handleDragStart(Offset position) => false;

  /// 处理拖动中。
  ///
  /// [position] 为当前指针的 canvas 坐标, [delta] 为相对上一次的增量。
  /// 框架不对 [position] 做区域钳制, 需要时自行使用 `clampDyInChart` 等。
  void handleDragUpdate(Offset position, Offset delta) {}

  /// 处理拖动正常结束, 应在此提交结果。
  void handleDragEnd() {}

  /// 处理拖动被打断（指针取消、多指介入、被强制失选）, 应在此回滚未提交状态。
  void handleDragCancel() {}

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
abstract class DirectPaintObject<T extends DirectIndicator> extends PaintObject<T> {}

/// 数据指标绘制对象
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 持有 [dataIndex]，用于在 slots 中存取计算数据。
/// 参数变更由 manager 检测 [ComputedIndicator.shouldRecompute] 并重建 calculator，
/// 再由 controller 驱动 [KlineDataPipeline.recompute]；绘制对象不负责触发重算。
abstract class ComputedPaintObject<T extends ComputedIndicator> extends PaintObject<T> {
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
}

/// 业务指标绘制对象
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 首次激活时创建；隐藏后默认保活（keepAlive=true），重新显示时复用；声明移除时 dispose。
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
final class MainPaintObject<T extends MainPaintObjectIndicator> extends PaintObject<T> {
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

  /// [object] 当前是否会被绘制。
  ///
  /// 线图模式（[onlyMainChart]）下主区仅绘制蜡烛, 其余主区子对象不可绘制;
  /// 非主区子对象（副区）恒可绘制。与 [paintableChildren] 同源, 但为 O(1) 查询。
  ///
  /// 注: 隐藏并不使对象出树, 因此其选中态仍保留(放大回蜡烛图即恢复),
  /// 但不可绘制期间不应参与任何手势。
  bool isPaintable(PaintObject object) {
    if (!children.contains(object)) return true;
    return !onlyMainChart || object.key == candleIndicatorKey;
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
  Size? paintTips(
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
