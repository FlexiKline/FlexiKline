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

extension PaintDelegateExt<T extends Indicator> on PaintObject<T> {
  /// 更新布布局参数
  bool doUpdateLayout({
    double? height,
    EdgeInsets? padding,
    bool reset = false,
  }) {
    bool hasChange = false;
    if (height != null && height > 0 && height != indicator.height) {
      _indicator.height = height;
      hasChange = true;
    }

    if (padding != null && padding != indicator.padding) {
      _indicator.padding = padding;
      hasChange = true;
    }

    if (reset || hasChange) resetPaintBounding();
    return reset || hasChange;
  }

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

    // TODO: 如果start与end未发生变化, 则蜡烛数据未更新时, 可不用执行initState计算操作. 暂不优化此项, 待数据计算优化完成再考虑.
    _minMax = null;
    final ret = initState(start, end);
    if (ret != null) {
      setMinMax(ret);
    }

    _dyFactor = null;
    return _minMax;
  }

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

  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    onCross(canvas, offset);

    paintTips(
      canvas,
      offset: offset,
      model: model,
      tipsRect: drawableRect,
    );
  }

  void doUpdateIndicator<E extends Indicator>(E indicator) {
    _indicator = indicator;
  }
}

extension MainPaintDelegateExt<T extends MainPaintObjectIndicator>
    on MainPaintObject<T> {
  void setMinMax(MinMax val) {
    if (_minMax == null) {
      _minMax = val;
    } else {
      _minMax!.updateMinMax(val);
    }
  }

  /// 当前[tipsHeight]是否需要更新布局参数
  bool _needUpdateLayout(double tipsHeight) {
    return drawBelowTipsArea && _initialPadding.top + tipsHeight != padding.top;
  }

  bool doUpdateLayout({
    Size? size,
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

    bool hasChange = false;
    if (padding != null && padding != indicator.padding) {
      indicator.padding == padding;
      hasChange = true;
    }
    if (size != null && size != indicator.size) {
      indicator._size = size;
      indicator.height = size.height;
      hasChange = true;
    }

    for (var object in children) {
      final childChange = object.doUpdateLayout(
        height: object.paintMode.isCombine ? height : null,
        padding: object.paintMode.isCombine ? padding : null,
        reset: reset,
      );
      hasChange = hasChange || childChange;
    }

    if (reset || hasChange) resetPaintBounding();
    return reset || hasChange;
  }

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

  void doPaintChart(Canvas canvas, Size size) {
    if (drawBelowTipsArea) {
      // 1.1 如果设置总是要在Tips区域下绘制指标图, 则要首先绘制完所有Tips.
      if (!isCrossing) {
        final tipsHeight = doPaintTips(
          canvas,
          model: klineData.latest,
        );

        if (_needUpdateLayout(tipsHeight)) {
          doUpdateLayout(tipsHeight: tipsHeight);
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

  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    if (drawBelowTipsArea) {
      if (isCrossing) {
        final tipsHeight = doPaintTips(canvas, offset: offset, model: model);

        if (_needUpdateLayout(tipsHeight)) {
          doUpdateLayout(tipsHeight: tipsHeight);
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
}

extension MainPaintManagerExt<T extends MainPaintObjectIndicator>
    on MainPaintObject<T> {
  void appendPaintObjects(Iterable<PaintObject> objects) {
    for (var object in objects) {
      appendPaintObject(object);
    }
  }

  void appendPaintObject(PaintObject object) {
    // 使用前先解绑: 释放[paintObject]parentObject与数据.
    object.dispose();
    object._parent = this;
    // 重置object布局参数为MainPaintObject的
    object.doUpdateLayout(
      height: object.paintMode.isCombine ? height : null,
      padding: object.paintMode.isCombine ? padding : null,
    );
    final old = children.append(object);
    indicator.indicatorKeys.add(object.key);
    old?.dispose();
  }

  bool deletePaintObject(IIndicatorKey key) {
    bool hasRemove = false;
    children.removeWhere((object) {
      if (object.key == key) {
        object.dispose();
        indicator.indicatorKeys.remove(object.key);
        hasRemove = true;
        return true;
      }
      return false;
    });
    return hasRemove;
  }

  PaintObject? getChildPaintObject(IIndicatorKey key) {
    return children.firstWhereOrNull((obj) => obj.key == key);
  }
}
