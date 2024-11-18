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

class IndicatorObject<T extends Indicator>
    implements Comparable<IndicatorObject> {
  IndicatorObject(this._indicator, this.context);

  late T? _indicator;

  final IPaintContext context;

  T get indicator => _indicator!;

  @override
  int compareTo(IndicatorObject<Indicator> other) {
    // TODO: implement compareTo
    throw UnimplementedError();
  }
}

/// PaintObject
/// 通过实现对应的接口, 实现Chart的配置, 计算, 绘制, Cross
// @immutable
abstract class PaintObject<T extends Indicator>
    implements IPaintBoundingBox, IPaintDataInit, IPaintObject, IPaintDelegate {
  PaintObject({
    required T indicator,
  }) : _indicator = indicator;

  T? _indicator;

  T get indicator => _indicator!;

  // 父级PaintObject. 主要用于给其他子级PaintObject限定范围.
  PaintObject? _parent;

  bool get hasParentObject => _parent != null;

  @mustCallSuper
  void dispose() {
    _indicator = null;
    _parent = null;
  }

  @protected
  @override
  void paintExtraAboveChart(Canvas canvas, Size size) {}
}

/// PaintObjectProxy
/// 通过参数KlineBindingBase 混入对setting和state的代理
abstract class PaintObjectProxy<T extends Indicator> extends PaintObject
    with KlineLog, ControllerProxyMixin {
  PaintObjectProxy({
    required IPaintContext controller,
    required T super.indicator,
  }) {
    this.controller = controller;
    if (controller is KlineLog) {
      loggerDelegate = (controller as KlineLog).loggerDelegate;
    }
  }

  @override
  T get indicator => super.indicator as T;

  @override
  String get logTag => '${super.logTag}\t${indicator.key.toString()}';
}

/// PaintObjectBox
/// 通过混入边界计算与数据初始化计算, 简化PaintObject接口.
abstract class SinglePaintObjectBox<T extends SinglePaintObjectIndicator>
    extends PaintObjectProxy with PaintObjectBoundingMixin, DataInitMixin {
  SinglePaintObjectBox({
    required super.controller,
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

/// 多个Indicator组合绘制
/// 主要实现接口遍历转发.
class MultiPaintObjectBox<T extends MultiPaintObjectIndicator>
    extends PaintObjectProxy with PaintObjectBoundingMixin, DataInitMixin {
  MultiPaintObjectBox({
    required super.controller,
    required T super.indicator,
  });

  @override
  T get indicator => super.indicator as T;

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
    for (var child in indicator.children) {
      final childPaintObject = child.paintObject;
      if (childPaintObject == null) continue;
      final ret = childPaintObject.doInitState(
        newSlot,
        start: start,
        end: end,
        reset: reset,
      );
      if (ret != null && child.paintMode == PaintMode.combine) {
        setMinMax(ret.clone());
      }
    }

    for (var child in indicator.children) {
      if (child.paintMode == PaintMode.combine) {
        child.paintObject?.setMinMax(minMax);
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

        if (indicator.needUpdateLayout(tipsHeight)) {
          indicator.updateLayout(tipsHeight: tipsHeight);
        }
      }
      for (var child in indicator.children) {
        child.paintObject?.paintChart(canvas, size);
      }
    } else {
      for (var child in indicator.children) {
        child.paintObject?.paintChart(canvas, size);
      }
      if (!isCrossing) {
        doPaintTips(canvas, model: klineData.latest);
      }
    }

    for (var child in indicator.children) {
      child.paintObject?.paintExtraAboveChart(canvas, size);
    }
  }

  @protected
  @nonVirtual
  @override
  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    if (indicator.drawBelowTipsArea) {
      if (isCrossing) {
        final tipsHeight = doPaintTips(canvas, offset: offset, model: model);

        if (indicator.needUpdateLayout(tipsHeight)) {
          indicator.updateLayout(tipsHeight: tipsHeight);
        }
      }
      for (var child in indicator.children) {
        child.paintObject?.onCross(canvas, offset);
      }
    } else {
      for (var child in indicator.children) {
        child.paintObject?.onCross(canvas, offset);
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
    for (var child in indicator.children) {
      final size = child.paintObject?.paintTips(
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
    for (var child in indicator.children) {
      child.paintObject?.dispose();
    }
    super.dispose();
  }
}
