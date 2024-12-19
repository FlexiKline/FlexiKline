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
}

extension MultiPaintDelegateExt<T extends MultiPaintObjectIndicator>
    on MultiPaintObjectBox<T> {
  void setMinMax(MinMax val) {
    if (_minMax == null) {
      _minMax = val;
    } else {
      _minMax!.updateMinMax(val);
    }
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

  void doOnCross(Canvas canvas, Offset offset, {CandleModel? model}) {
    if (drawBelowTipsArea) {
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
