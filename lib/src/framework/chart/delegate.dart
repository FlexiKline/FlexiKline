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
  void setHeight(double height) {
    if (isAllowUpdateHeight) {
      _tmpHeight = null;
      // indicator中只保留正常布局模式/适配模式下的高度, 其他模式会根据当前父布局自适应.
      indicator.height = height;
    } else {
      _tmpHeight = height;
    }
  }

  void restoreHeight() {
    _tmpHeight = null;
  }

  void setPadding(EdgeInsets padding) {
    _tmpPadding = padding;
  }

  /// 更新布布局参数
  bool doUpdateLayout({
    double? height,
    EdgeInsets? padding,
    bool reset = false,
  }) {
    bool hasChange = reset;
    if (height != null && height > 0 && height != this.height) {
      setHeight(height);
      hasChange = true;
    }

    if (padding != null && padding != this.padding) {
      setPadding(padding);
      hasChange = true;
    }

    if (hasChange) resetPaintBounding();
    return hasChange;
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

  void doDidUpdateIndicator(T newIndicator) {
    final T oldIndicator = indicator;
    _indicator = newIndicator;
    didUpdateIndicator(oldIndicator);
  }

  void doDidChangeTheme() {
    didChangeTheme();
  }

  Future<bool> doStoreConfig() {
    return _context.setConfig(key.id, indicator.toJson());
  }
}

extension MainPaintDelegateExt<T extends MainPaintObjectIndicator> on MainPaintObject<T> {
  @protected
  void setSize(Size size) {
    if (isAllowUpdateHeight) {
      _tmpSize = null;
      indicator.size = size;
    } else {
      _tmpSize = size;
    }
    setHeight(size.height);
  }

  void restoreSize() {
    _tmpSize = null;
    _tmpHeight = null;
  }

  void setMinMax(MinMax val) {
    if (_minMax == null) {
      _minMax = val;
    } else {
      _minMax!.updateMinMax(val);
    }
  }

  bool doUpdateLayout({
    Size? size,
    EdgeInsets? padding,
    bool reset = false,
  }) {
    bool hasChange = reset;
    if (padding != null && padding != this.padding) {
      setPadding(padding);
      hasChange = true;
    }
    if (size != null && size != this.size) {
      setSize(size);
      hasChange = true;
    }
    if (hasChange) resetPaintBounding();

    for (var object in children) {
      final childChange = object.doUpdateLayout(
        height: object.paintMode.isCombine ? height : null,
        padding: object.paintMode.isCombine ? padding : null,
        reset: reset,
      );
      hasChange = hasChange || childChange;
    }

    return hasChange;
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

  /// 是否首先绘制Tips区域
  /// 1. drawBelowTipsArea标识为true
  /// 2. 当前不处在Zooming中时
  bool get isFirstDrawTipsArea {
    return indicator.drawBelowTipsArea && !_context.isStartZoomChart;
  }

  void doPaintChart(Canvas canvas, Size size) {
    if (isFirstDrawTipsArea) {
      // 1.1 如果设置总是要在Tips区域下绘制指标图, 则要首先绘制完所有Tips.
      if (!isCrossing) {
        final tipsHeight = doPaintTips(canvas, model: klineData.latest);

        if (indicator.padding.top + tipsHeight != padding.top) {
          doUpdateLayout(
            padding: indicator.padding.copyWith(
              top: indicator.padding.top + tipsHeight,
            ),
          );
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
    if (isFirstDrawTipsArea) {
      if (isCrossing) {
        final tipsHeight = doPaintTips(canvas, offset: offset, model: model);

        if (indicator.padding.top + tipsHeight != padding.top) {
          doUpdateLayout(
            padding: indicator.padding.copyWith(
              top: indicator.padding.top + tipsHeight,
            ),
          );
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

extension MainPaintManagerExt<T extends MainPaintObjectIndicator> on MainPaintObject<T> {
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

  Indicator? getChildIndicator(IIndicatorKey key) {
    return getChildPaintObject(key)?.indicator;
  }

  bool updateChildIndicator(Indicator indicator) {
    final paintObject = getChildPaintObject(indicator.key);
    if (paintObject != null) {
      paintObject.doDidUpdateIndicator(indicator);
      return true;
    }
    return false;
  }

  Future<bool> doStoreConfig() async {
    await _context.setConfig(key.id, indicator.toJson());
    for (var object in children) {
      object.doStoreConfig();
    }
    return true;
  }
}
