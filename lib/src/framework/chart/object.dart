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

/// IndicatorObject: 保存Indicator配置
/// 提供[Indicator]的所有属性
abstract class IndicatorObject<T extends Indicator>
    implements
        Comparable<IndicatorObject<T>>,
        IPaintBoundingBox,
        IPaintDataInit,
        IPaintObject {
  IndicatorObject(this._indicator, this._context);

  // ignore: prefer_final_fields
  T _indicator;
  final IPaintContext _context;

  T get indicator => _indicator;

  IIndicatorKey get key => _indicator.key;
  double get height => _indicator.height;
  EdgeInsets get padding => _indicator.padding;
  PaintMode get paintMode => _indicator.paintMode;
  int get zIndex => _indicator.zIndex;
  dynamic get calcParams => _indicator.calcParam;

  @override
  int compareTo(IndicatorObject<T> other) {
    return indicator.zIndex.compareTo(other.indicator.zIndex);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is IndicatorObject && key == other.key);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ key.hashCode;
}

/// PaintObject
/// 通过混入边界计算与数据初始化计算, 简化PaintObject接口.
/// 1. 定义PaintObject行为: 通过实现对应的接口, 实现Chart的配置, 计算, 绘制, Cross
/// 2. [_parent]保存当前绘制对象的父级
abstract class PaintObject<T extends Indicator> extends IndicatorObject
    with KlineLog, PaintObjectBoundingMixin, PaintObjectDataInitMixin {
  PaintObject({
    required T indicator,
    required IPaintContext context,
  })  : _dataIndex = context.getDataIndex(indicator.key),
        super(indicator, context) {
    if (context is KlineLog) {
      loggerDelegate = (context as KlineLog).loggerDelegate;
    }
  }

  // 当前绘制对象的指标计算数据存储下标
  final int? _dataIndex;
  int get dataIndex => _dataIndex ?? -1;

  @override
  T get indicator => super.indicator as T;

  // 父级PaintObject. 主要用于给其子级PaintObject限定范围.
  PaintObject? _parent;

  bool get hasParentObject => _parent != null;

  // 指标配置发生变改
  @mustCallSuper
  @protected
  void didUpdateIndicator(covariant T oldIndicator) {
    final newCalcParam = indicator.calcParam;
    if (oldIndicator.calcParam != newCalcParam && newCalcParam != null) {
      precompute(klineData.computableRange, reset: true);
    }
  }

  @mustCallSuper
  @protected
  void dispose() {
    final json = indicator.toJson();
    assert(() {
      logi('dispose > PaintOjbect[$key] > $json');
      return true;
    }());
    _context.setConfig(key.id, json);
    _parent = null;
  }

  @protected
  @override
  void paintExtraAboveChart(Canvas canvas, Size size) {}

  @override
  void precompute(Range range, {bool reset = false}) {}

  @override
  String get logTag => '${super.logTag}\t${indicator.key.toString()}';
}

/// PaintObjectBox
abstract class PaintObjectBox<T extends PaintObjectIndicator>
    extends PaintObject {
  PaintObjectBox({
    required super.context,
    required T super.indicator,
  });

  @override
  T get indicator => _indicator as T;
}

/// 蜡烛图绘制对象
abstract class CandleBasePaintObject<T extends CandleBaseIndicator>
    extends PaintObject {
  CandleBasePaintObject({
    required super.context,
    required T super.indicator,
  });

  @override
  T get indicator => _indicator as T;
}

/// 时间轴指标绘制对象
abstract class TimeBasePaintObject<T extends TimeBaseIndicator>
    extends PaintObject {
  TimeBasePaintObject({
    required super.context,
    required T super.indicator,
  });

  DrawPosition get position => indicator.position;

  @override
  T get indicator => _indicator as T;
}

/// 主区绘制对象
final class MainPaintObject<T extends MainPaintObjectIndicator>
    extends PaintObject {
  MainPaintObject({
    required super.context,
    required T super.indicator,
  })  : children = SortableHashSet<PaintObject>.from([]),
        _initialPadding = indicator.padding;

  final SortableHashSet<PaintObject> children;
  final EdgeInsets _initialPadding;

  @override
  T get indicator => _indicator as T;

  @override
  int get dataIndex => -1;

  bool get drawBelowTipsArea => indicator.drawBelowTipsArea;

  Size get size => indicator.size;

  @override
  Rect get drawableRect {
    return _drawableRect ??= Rect.fromLTWH(0, 0, size.width, size.height);
  }

  @override
  void precompute(Range range, {bool reset = false}) {
    for (var object in children) {
      object.precompute(range, reset: reset);
    }
  }

  @override
  MinMax? initState(int start, int end) {
    return minMax;
  }

  @override
  void paintChart(Canvas canvas, Size size) {}

  @override
  void onCross(Canvas canvas, Offset offset, {CandleModel? model}) {}

  @override
  Size? paintTips(
    Canvas canvas, {
    CandleModel? model,
    Offset? offset,
    Rect? tipsRect,
  }) {
    return topRect.size;
  }

  @override
  void dispose() {
    for (var object in children) {
      object.dispose();
    }
    children.clear();
    super.dispose();
  }
}
