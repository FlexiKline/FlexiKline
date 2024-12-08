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
class IndicatorObject<T extends Indicator>
    implements Comparable<IndicatorObject<T>> {
  IndicatorObject(this._indicator, this.context);

  // ignore: prefer_final_fields
  T _indicator;
  final IPaintContext context;

  T get indicator => _indicator;

  IIndicatorKey get key => _indicator.key;
  double get height => _indicator.height;
  EdgeInsets get padding => _indicator.padding;
  PaintMode get paintMode => _indicator.paintMode;
  int get zIndex => _indicator.zIndex;
  dynamic get calcParams => _indicator.calcParams;

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
abstract class PaintObject<T extends Indicator> extends IndicatorObject<T>
    with KlineLog, ConfigStateMixin
    implements IPaintBoundingBox, IPaintDataInit, IPaintObject, IPaintDelegate {
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

  // @override
  // T get indicator => super.indicator as T;

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
    extends PaintObject
    with PaintObjectBoundingMixin, PaintObjectDataInitMixin {
  SinglePaintObjectBox({
    required super.context,
    required T super.indicator,
  });

  @override
  T get indicator => super.indicator as T;

  @protected
  @nonVirtual
  @override
  MinMax? doInitState(
    int newSlot, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (reset || newSlot != slot) {
      resetPaintBounding(slot: newSlot);
      _minMax = null;
      _dyFactor = null;
    }

    if (_start != start || _end != end || _minMax == null) {
      _start = start;
      _end = end;
    }

    _minMax = null;
    final ret = initState(start: start, end: end);
    if (ret != null) {
      setMinMax(ret);
    }

    _dyFactor = null;
    return _minMax;
  }

  @protected
  @nonVirtual
  @override
  void doPaintChart(Canvas canvas, Size size) {
    paintChart(canvas, size);

    if (!isCrossing) {
      paintTips(
        canvas,
        model: klineData.latest,
        tipsRect: drawableRect,
      );
    }

    paintExtraAboveChart(canvas, size);
  }

  @protected
  @nonVirtual
  @override
  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    onCross(canvas, offset);

    paintTips(
      canvas,
      offset: offset,
      model: model,
      tipsRect: drawableRect,
    );
  }
}

/// 多个[PaintObject]组合绘制
/// 主要实现接口遍历转发.
class MultiPaintObjectBox<T extends MultiPaintObjectIndicator>
    extends PaintObject
    with PaintObjectBoundingMixin, PaintObjectDataInitMixin {
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
    if (tipsHeight != null) {
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

  @override
  MinMax? initState({required int start, required int end}) {
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

  @nonVirtual
  @override
  void setMinMax(MinMax val) {
    if (_minMax == null) {
      _minMax = val;
    } else {
      _minMax!.updateMinMax(val);
    }
  }

  @protected
  @nonVirtual
  @override
  MinMax? doInitState(
    int newSlot, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (reset || newSlot != slot) {
      resetPaintBounding(slot: newSlot);
      _minMax = null;
      _dyFactor = null;
    }

    if (_start != start || _end != end) {
      _start = start;
      _end = end;
    }

    _minMax = null;
    for (var object in children) {
      final ret = object.doInitState(
        newSlot,
        start: start,
        end: end,
        reset: reset,
      );
      if (ret != null && object.paintMode == PaintMode.combine) {
        setMinMax(ret.clone());
      }
    }

    for (var object in children) {
      if (object.paintMode == PaintMode.combine) {
        object.setMinMax(minMax);
      }
    }

    _dyFactor = null;
    return _minMax;
  }

  @protected
  @nonVirtual
  @override
  void doPaintChart(Canvas canvas, Size size) {
    if (indicator.drawBelowTipsArea) {
      // 1.1 如果设置总是要在Tips区域下绘制指标图, 则要首先绘制完所有Tips.
      if (!isCrossing) {
        final tipsHeight = doPaintTips(
          canvas,
          model: klineData.latest,
        );

        if (_needUpdateLayout(tipsHeight)) {
          updateLayout(tipsHeight: tipsHeight);
        }
      }
      for (var object in children) {
        object.paintChart(canvas, size);
      }
    } else {
      for (var object in children) {
        object.paintChart(canvas, size);
      }
      if (!isCrossing) {
        doPaintTips(canvas, model: klineData.latest);
      }
    }

    for (var object in children) {
      object.paintExtraAboveChart(canvas, size);
    }
  }

  @protected
  @nonVirtual
  @override
  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    if (indicator.drawBelowTipsArea) {
      if (isCrossing) {
        final tipsHeight = doPaintTips(canvas, offset: offset, model: model);

        if (_needUpdateLayout(tipsHeight)) {
          updateLayout(tipsHeight: tipsHeight);
        }
      }
      for (var object in children) {
        object.onCross(canvas, offset);
      }
    } else {
      for (var object in children) {
        object.onCross(canvas, offset);
      }
      if (isCrossing) {
        doPaintTips(canvas, offset: offset, model: model);
      }
    }
  }

  @protected
  @nonVirtual
  double doPaintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    // 每次绘制前, 重置Tips区域大小为0
    double height = 0;
    for (var object in children) {
      final size = object.paintTips(
        canvas,
        model: model,
        offset: offset,
        tipsRect: shiftNextTipsRect(height),
      );
      if (size != null) height += size.height;
    }
    return height;
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
