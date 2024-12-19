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

  int? _dataIndex;
  // 注: 如果PaintObject被创建了, 其DataIndex必然有值.
  int get dataIndex => _dataIndex ??= _context.getDataIndex(indicator.key)!;

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
/// 1. 定义PaintObject行为: 通过实现对应的接口, 实现Chart的配置, 计算, 绘制, Cross
/// 2. [_parent]保存当前绘制对象的父级
abstract class PaintObject<T extends Indicator> extends IndicatorObject
    with KlineLog, PaintObjectBoundingMixin, PaintObjectDataInitMixin {
  PaintObject({
    required T indicator,
    required IPaintContext context,
  }) : super(indicator, context) {
    if (context is KlineLog) {
      loggerDelegate = (context as KlineLog).loggerDelegate;
    }
  }

  // 父级PaintObject. 主要用于给其子级PaintObject限定范围.
  PaintObject? _parent;

  bool get hasParentObject => _parent != null;

  @mustCallSuper
  void dispose() {
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
/// 通过混入边界计算与数据初始化计算, 简化PaintObject接口.
abstract class SinglePaintObjectBox<T extends SinglePaintObjectIndicator>
    extends PaintObject {
  SinglePaintObjectBox({
    required super.context,
    required T super.indicator,
  });

  @override
  T get indicator => super.indicator as T;
}

/// 多个[PaintObject]组合绘制
/// 主要实现接口遍历转发.
class MultiPaintObjectBox<T extends MultiPaintObjectIndicator>
    extends PaintObject {
  MultiPaintObjectBox({
    required super.context,
    required T super.indicator,
    // Iterable<T> children = const [],
  })  : children = SortableHashSet<PaintObject>.from([]),
        _initialPadding = indicator.padding;

  final SortableHashSet<PaintObject> children;
  final EdgeInsets _initialPadding;

  @override
  T get indicator => super.indicator as T;

  @override
  int get dataIndex => -1;

  bool get drawBelowTipsArea => indicator.drawBelowTipsArea;

  /// 当前[tipsHeight]是否需要更新布局参数
  bool _needUpdateLayout(double tipsHeight) {
    return _initialPadding.top + tipsHeight != padding.top;
  }

  @nonVirtual
  @override
  bool updateLayout({
    double? height,
    EdgeInsets? padding,
    bool reset = false,
    double? tipsHeight,
  }) {
    if (drawBelowTipsArea && tipsHeight != null) {
      // 如果tipsHeight不为空, 说明是绘制过程中动态调整, 只需要在MultiPaintObjectIndicator原padding基础上增加即可.
      padding = _initialPadding.copyWith(
        top: _initialPadding.top + tipsHeight,
      );
    }
    bool hasChange = super.updateLayout(
      height: height,
      padding: padding,
      reset: reset,
    );
    for (var object in children) {
      final childChange = object.updateLayout(
        height: object.paintMode.isCombine ? this.height : null,
        padding: object.paintMode.isCombine ? this.padding : null,
        reset: reset,
      );
      hasChange = hasChange || childChange;
    }
    return hasChange;
  }

  void appendPaintObjects(Iterable<PaintObject> objects) {
    for (var object in objects) {
      appendPaintObject(object);
    }
  }

  void appendPaintObject(PaintObject object) {
    // 使用前先解绑: 释放[paintObject]parentObject与数据.
    object.dispose();
    object._parent = this;
    object.updateLayout(
      height: object.paintMode.isCombine ? height : null,
      padding: object.paintMode.isCombine ? padding : null,
    );
    final old = children.append(object);
    old?.dispose();
  }

  bool deletePaintObject(IIndicatorKey key) {
    bool hasRemove = false;
    children.removeWhere((object) {
      if (object.key == key) {
        object.dispose();
        hasRemove = true;
        return true;
      }
      return false;
    });
    return hasRemove;
  }

  @nonVirtual
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
    // return Size(topRect.width, nextTipsRect.top - topRect.top);
    return topRect.size;
  }

  @override
  @mustCallSuper
  void dispose() {
    for (var object in children) {
      object.dispose();
    }
    children.clear();
    super.dispose();
  }
}
