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
  IPaintContext? __context;

  /// 获取创建此对象的 Indicator
  T get indicator {
    assert(_indicator != null, 'indicator 尚未设置，请确保已通过框架创建');
    return _indicator!;
  }

  /// 获取绘制上下文
  IPaintContext get _context {
    assert(__context != null, 'context 尚未设置，请确保已通过框架创建');
    return __context!;
  }

  IIndicatorKey get key => indicator.key;

  double? _tmpHeight;
  double get height => _tmpHeight ?? indicator.height;

  EdgeInsets? _tmpPadding;
  EdgeInsets get padding => _tmpPadding ?? indicator.padding;

  PaintMode get paintMode => indicator.paintMode;
  int get zIndex => indicator.zIndex;
  dynamic get calcParams => indicator.calcParam;

  /// 当前指标所使用的涨跌颜色
  Color get longColor => theme.long;
  Color get shortColor => theme.short;

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

  @visibleForTesting
  @protected
  @Deprecated('警告：这是仅用于测试的函数，严禁在生产环境中调用 (This is a test-only method. DO NOT use in production.)')
  void init(IPaintContext context, T indicator) {
    _indicator = indicator;
    __context = context;
  }
}

/// PaintObject
///
/// 通过混入边界计算与数据初始化计算，简化 PaintObject 接口。
/// 1. 定义 PaintObject 行为：通过实现对应的接口，实现 Chart 的配置、计算、绘制、Cross。
/// 2. [_parent] 保存当前绘制对象的父级。
abstract class PaintObject<T extends Indicator<IIndicatorKey>> extends IndicatorObject<T>
    with FlexiLog, PaintObjectBoundingMixin<T>, PaintObjectStateMixin<T>
    implements IPaintObject {
  // 父级 PaintObject，主要用于给其子级 PaintObject 限定范围。
  PaintObject? _parent;

  bool get hasParentObject => _parent != null;

  /// 指标配置发生变改
  @mustCallSuper
  @protected
  void didUpdateIndicator(covariant T oldIndicator) {
    // 基类不处理 precompute，由 DataPaintObject 处理
  }

  @protected
  void didChangeTheme() {}

  @mustCallSuper
  @protected
  void dispose() {
    _parent = null;
  }

  @protected
  @override
  void paintExtraAboveChart(Canvas canvas, Size size) {}

  @override
  void onCross(Canvas canvas, Offset offset) {}

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
    _context.requestRepaint();
  }

  @override
  String get logTag => indicator.key.toString();
}

/// 普通指标绘制对象，不占 slot，无需预计算。
///
/// 内置的 Candle、Time、Volume 等均基于此，自定义指标也可继承。
abstract class NormalPaintObject<T extends NormalIndicator> extends PaintObject<T> implements IBasePainter {}

/// 数据指标绘制对象
///
/// 用于 KDJ、MACD、MA 等需要 precompute 并写入 FlexiCandleModel.slots 的指标。
/// 持有 [dataIndex]，用于在 slots 中存取计算数据。
abstract class DataPaintObject<T extends DataIndicator> extends PaintObject<T>
    with PaintObjectComputableMixin<T>
    implements IComputablePainter {
  /// 当前绘制对象的指标计算数据存储下标
  ///
  /// 用于在 FlexiCandleModel.slots 中存取计算数据。
  /// 延迟初始化，在首次访问时计算。
  int get dataIndex {
    return _dataIndex ??= _context.getDataIndex(indicator.key) ?? -1;
  }

  int? _dataIndex;

  /// 指标配置发生变改
  @mustCallSuper
  @override
  @protected
  void didUpdateIndicator(covariant T oldIndicator) {
    super.didUpdateIndicator(oldIndicator);
    if (shouldPrecompute(oldIndicator)) {
      precompute(klineData.computableRange, reset: true);
    }
  }
}

/// 业务指标绘制对象
///
/// 用于 Trade 等由业务数据或用户操作驱动的指标，不占 slot。
/// 子类可按需 override [loadBusinessData] 加载业务数据。
abstract class BusinessPaintObject<T extends BusinessIndicator> extends PaintObject<T> implements IBusinessPainter {
  /// 加载业务数据
  ///
  /// 框架在适当时机（如首次显示、数据刷新）调用。
  /// 子类按需 override 实现具体加载逻辑。
  @override
  @protected
  void loadBusinessData() {}
}

/// 蜡烛图绘制对象
///
/// 使用 [NormalIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class CandleBasePaintObject<T extends CandleBaseIndicator> extends NormalPaintObject<T> {
  /// 获取当前蜡烛图的绘制类型
  FlexiChartType getChartType();

  /// 是否在蜡烛图类型为线图时隐藏指标
  bool get hideIndicatorsWhenLineChart => false;

  @nonVirtual
  void moveToInitialPosition() {
    (_context as StateBinding).moveToInitialPosition();
  }

  @nonVirtual
  void updateZoomSlideBarRect(Rect rect) {
    if (!gestureConfig.isManualSetZoomRect) {
      (_context as ChartBinding).setChartZoomSlideBarRect(rect);
    }
  }
}

/// 时间轴指标绘制对象
///
/// 使用 [NormalIndicatorKey]，属于基础/系统指标，不占 slot。
abstract class TimeBasePaintObject<T extends TimeBaseIndicator> extends NormalPaintObject<T> {
  DrawPosition get position => indicator.position;
}

/// 主区绘制对象
///
/// 使用 [NormalIndicatorKey]，属于基础/系统指标，不占 slot。
/// [children] 存储主区内的所有子绘制对象。
final class MainPaintObject<T extends MainPaintObjectIndicator> extends PaintObject<T> implements IComputablePainter {
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
    return candleObject.hideIndicatorsWhenLineChart && candleObject.getChartType().isLine;
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
  bool shouldPrecompute(MainPaintObjectIndicator oldIndicator) {
    if (oldIndicator.children != indicator.children) {
      return true;
    }
    return false;
  }

  /// 委托子对象的 precompute 方法
  ///
  /// MainPaintObject 本身不需要 precompute，但需要将调用委托给子对象。
  @override
  void precompute(Range range, {bool reset = false}) {
    for (final computable in children.whereType<IComputablePainter>()) {
      computable.precompute(range, reset: reset);
    }
  }

  @override
  void didChangeTheme() {
    for (final object in children) {
      object.didChangeTheme();
    }
  }

  @override
  MinMax? initState(int start, int end) {
    return minMax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {}

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
