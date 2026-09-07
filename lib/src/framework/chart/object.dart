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

/// PaintObject / Indicator 配置的运行时宿主, 提供排序、相等性和主题回调。
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

  EdgeInsets get padding => indicator.padding;

  /// 本对象几何计算要让出的 tips 区域高度; 0 表示不让出。
  ///
  /// 绘制期产物, 不参与序列化。主区在 [MainPaintDelegateExt.doPaintTips] 汇总子指标实测
  /// 高度、量化后写入, 并同步下发给所有子对象——combine 子对象与主区共享 chartRect,
  /// 必须让出同样的高度。副区指标无人写入, 恒为 0, 其 tips 叠加绘制在图表之上。
  ///
  /// 与 tips 高度写入 [padding] 的旧实现不同: 绘制期不再回写布局, 收缩也不需要在激活集合
  /// 变化等离散时机记得复位——汇总每帧无条件同步, 量化保证稳定态不触发边界缓存失效。
  double _tipsAreaHeight = 0;

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

  /// 主题变化时回调。
  ///
  /// 子类和 mixin 可 override 此方法清理主题派生的缓存资源（如画笔、颜色），
  /// 但必须调用 `super.didChangeTheme()`。
  @protected
  @mustCallSuper
  void didChangeTheme() {}
}

/// 所有指标绘制对象的基类, 混入边界计算、几何状态与画笔缓存。
abstract class PaintObject<T extends Indicator<IIndicatorKey>> extends IndicatorObject<T>
    with FlexiLog, PaintStyleMixin<T>, PaintObjectBoundingMixin<T>, PaintObjectGeometryStateMixin<T>
    implements IPaintObject, IPaintLifecycle {
  // 父级 PaintObject，主要用于给其子级 PaintObject 限定范围。
  PaintObject? _parent;

  bool get hasParentObject => _parent != null;

  /// combine 子对象代理主区的区间: 绘制用的 minMax（含 smooth / zoom）来自 parent,
  /// 自身的 [_minMax] 仅供主区合并使用。alone / 副区走 mixin 默认链。
  @override
  MinMax get minMax {
    if (paintMode.isCombine && _parent != null) {
      return _parent!.minMax;
    }
    return super.minMax;
  }

  /// combine 子对象与主区共享绘制区域, padding 代理 parent 的值,
  /// 保证 [chartRect] / [topRect] / [bottomRect] 与主区一致。
  /// alone / 副区使用自己 [indicator.padding] 的声明值。
  @override
  EdgeInsets get padding {
    if (paintMode.isCombine && _parent != null) {
      return _parent!.padding;
    }
    return super.padding;
  }

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

  /// 默认不产出任何网格线。
  ///
  /// 要与主区竖线对齐的副区指标覆写它, 把 [PaintContext.gridVerticalDxs] 交给
  /// `PaintGridTicksMixin.paintVerticalGridLines` 即可 —— 编排保证主区那一趟已经跑完。
  @protected
  @override
  ({List<double> dxs, List<double> dys}) paintGridLines(Canvas canvas, Size size) {
    return (dxs: const [], dys: const []);
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
  /// 返回 true 表示消费本次点击，框架停止询问后续对象；返回 false 表示未命中，
  /// 框架继续按 zIndex 从高到低询问。选中等业务状态由绘制对象自行维护。
  ///
  /// [position] 已由框架按位置分派: 主区指标只会收到 `mainRect` 内的点击,
  /// 副区指标只会收到 `subRect` 内的点击, 但具体命中区仍需自行判断。命中区
  /// 必须落在本对象所在大区内, 否则收不到对应位置的点击。
  ///
  /// [handleTap]、[hitTestDragStart] 与 [handleDragStart] 均按 zIndex 倒序询问，
  /// 即视觉最上层优先。
  bool handleTap(Offset position) => false;

  /// 询问 [position] 是否落在本对象的可拖动区域内，必须无副作用。
  ///
  /// 仅用于框架在 `PointerDown` 阶段判断是否需要提前抢占手势竞技场——图表嵌在可滚动
  /// 容器内时，单指拖动的接受阈值恒为外层 Scrollable 的两倍，不抢占就永远拿不到手势。
  ///
  /// 每次 `PointerDown` 都会调用，包括最终只是点击或长按的情形，因此不得修改状态、
  /// 触发重绘或产生任何业务回调；[handleDragStart] 才是允许提交副作用的入口。
  ///
  /// 返回 true 不代表拖动已开始，真正的认领仍由 [handleDragStart] 决定，两者判据应当
  /// 一致（建议抽成共用的私有方法）；不一致时框架会白抢一次手势，表现为该次拖动既不
  /// 滚动外层也不平移图表，下一次手势恢复正常。
  ///
  /// 默认返回 false：只重写 [handleDragStart] 的指标在非滚动容器内行为不变，但在可
  /// 滚动容器内拿不到手势。
  bool hitTestDragStart(Offset position) => false;

  /// 处理拖动开始。框架按 zIndex 从高到低询问当前位置所属大区内的可绘制对象。
  ///
  /// 返回 true 认领本次拖动：框架随后抑制蜡烛图平移、惯性平移、loadMore 检查
  /// 与 cross 更新, 并把后续的 [handleDragUpdate] / [handleDragEnd] /
  /// [handleDragCancel] 只发给本对象。
  ///
  /// 返回 false 必须不保留拖动副作用，框架会继续询问后续对象。
  bool handleDragStart(Offset position) => false;

  /// 处理拖动中。
  ///
  /// [position] 为当前指针的 canvas 坐标, [delta] 为相对上一次的增量。
  /// 框架不对 [position] 做区域钳制, 需要时自行使用 `clampDyInChart` 等。
  void handleDragUpdate(Offset position, Offset delta) {}

  /// 处理拖动正常结束, 应在此提交结果。
  void handleDragEnd() {}

  /// 处理拖动被打断（指针取消、多指介入、进入 cross/手绘、本对象退出绘制树）,
  /// 应在此回滚未提交状态。
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
abstract class CandleBasePaintObject<T extends CandleBaseIndicator> extends DirectPaintObject<T>
    with PaintGridTicksMixin {
  /// 获取当前蜡烛图的绘制类型
  FlexiChartType resolveChartType();

  /// 是否在蜡烛图类型为线图时隐藏指标
  bool get hideMainIndicatorsInLineChartMode => false;

  /// 绘制主区网格线: 先竖线, 后横线, 一趟画完并交出两个方向的位置。
  ///
  /// 由框架在主区可见区间就绪之后、遍历主区子对象之前调用, 于是这里没有「哪些线现在能画」
  /// 的分支: `nice` 横线要的区间此刻已经有了, 横竖各自 resolve 再 paint 即可。
  ///
  /// 数据未就绪那一帧走的是同一个方法, 只是 [resolveHorizontalDys] 内部让 `nice` 退化为
  /// `count` —— 加载态因此是正常路径, 不是骨架兜底。
  @protected
  @override
  ({List<double> dxs, List<double> dys}) paintGridLines(Canvas canvas, Size size) {
    final vertical = indicator.verticalGrid;
    // 产出与绘制分开: `line == null` 只表示主区自己不画, 位置照样要返回 —— 副区可能仍想按
    // 同一位置画, 那时对齐才不必依赖「两处配一样」的约定。横线同理: 线关掉了, 刻度文本仍要
    // 按同一批位置摆。
    final dxs = resolveVerticalDxs(vertical.mode);
    paintVerticalGridLines(canvas, dxs: dxs, line: vertical.line);

    final horizontal = indicator.horizontalGrid;
    final dys = resolveHorizontalDys(horizontal.mode);
    paintHorizontalGridLines(canvas, dys: dys, line: horizontal.line);

    return (dxs: dxs, dys: dys);
  }
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

  /// 本帧主区竖线的 dx 序列, canvas 坐标; 空表示主区未产出竖线。
  ///
  /// 由 [MainPaintDelegateExt.doPaintGridLines] 写入, 经 [PaintContext.gridVerticalDxs]
  /// 只读暴露给副区指标对齐。写入口只有本类 —— 它是框架内部的 `final class`, 宿主绕不过
  /// 蜡烛去改主区的竖线位置。
  List<double> _gridVerticalDxs = const [];

  /// 本帧主区竖线的 dx 序列, 供副区指标对齐; 空表示主区未产出竖线。
  List<double> get gridVerticalDxs => _gridVerticalDxs;

  // ---- Zoom 价格区间（Y 轴由用户接管）----

  /// 缩放态下的价格区间; null 表示由可见数据自动适配。
  ///
  /// 一经设定, 可见区间变化(平移、蜡烛宽度缩放)不重算它, 只有显式复位才交还自动模式。
  /// 权威状态是 [PaintContext.isChartZooming], 本字段是它的数据载体, 两者同置同清。
  ///
  /// combine 子对象通过 [minMax] getter 代理主区, 天然读到本字段;
  /// [PaintMode.alone] 的子对象拥有独立坐标体系, 不受影响。
  MinMax? _zoomMinMax;

  /// 是否已有缩放区间, 即用户是否已接管 Y 轴。
  bool get hasZoomMinMax => _zoomMinMax != null;

  /// 设置缩放区间, 进入用户接管 Y 轴的状态。
  void setZoomMinMax(MinMax val) {
    _zoomMinMax = val;
    _smoothMinMax = null;
    _dyFactor = null;
  }

  /// 清除缩放区间, 交还给可见数据自动适配。
  ///
  /// 同时清 [_minMax]: 缩放态下它未被维护, 留着会让下一帧的早退分支拿到过期区间。
  void clearZoomMinMax() {
    if (_zoomMinMax == null) return;
    _zoomMinMax = null;
    _minMax = null;
    _smoothMinMax = null;
    _dyFactor = null;
  }

  @override
  MinMax get minMax {
    if (_zoomMinMax != null) return _zoomMinMax!;
    return super.minMax;
  }

  /// 参与绘制的子对象，按 zIndex 升序（视觉自下而上）。
  ///
  /// 返回惰性视图而非集合快照：调用方只需顺序遍历，[isPaintable] 才是成员查询入口。
  /// [children] 的增删是「重建缓存列表」而非原地改，因此遍历期间的增删不会打断迭代。
  Iterable<PaintObject> get paintableChildren {
    if (onlyMainChart) {
      return children.where((object) => object.key == candleIndicatorKey);
    }
    return children;
  }

  /// [paintableChildren] 的反向绘制顺序（视觉自上而下），命中分发按此顺序询问。
  Iterable<PaintObject> get reversedPaintableChildren {
    if (onlyMainChart) {
      return children.reversed.where((object) => object.key == candleIndicatorKey);
    }
    return children.reversed;
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
  /// 注: 隐藏并不使对象出树，但不可绘制期间不应参与任何手势。
  bool isPaintable(PaintObject object) {
    if (!children.contains(object)) return true;
    return !onlyMainChart || object.key == candleIndicatorKey;
  }

  @override
  void didChangeTheme() {
    super.didChangeTheme();
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
  void dispose() {
    super.dispose();
    for (final object in children) {
      object.dispose();
    }
    children.clear();
  }
}
