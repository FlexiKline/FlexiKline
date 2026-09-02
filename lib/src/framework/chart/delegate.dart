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
    if (context.canUpdateLayoutHeight) {
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

  MinMax? doUpdateVisibleMinMax(
    int newPaneIndex, {
    required int start,
    required int end,
    bool reset = false,
    double panSmoothFactor = 1.0,
  }) {
    if (reset || newPaneIndex != paneIndex) {
      resetPaintBounding(paneIndex: newPaneIndex);
      _minMax = null;
      _dyFactor = null;
    }

    // 数据范围未变、已有minMax、且平滑已完成时, 跳过重算
    if (!reset && _start == start && _end == end && _minMax != null && _smoothMinMax == null) {
      _dyFactor = null;
      return _minMax;
    }

    _start = start;
    _end = end;
    _minMax = null;
    final ret = computeVisibleMinMax(start, end);

    if (ret != null) {
      setMinMax(ret);
      smoothMinMax(smoothFactor: panSmoothFactor);
    }

    _dyFactor = null;
    return _minMax;
  }

  void doPaintChart(Canvas canvas, Size size) {
    paint(canvas, size);

    if (!context.isCrossing) {
      paintTips(
        canvas,
        model: klineData.latest,
        tipsRect: drawableRect,
      );
    }
  }

  void doPaintOverlay(Canvas canvas, Size size) {
    paintOverlay(canvas, size);
  }

  void doPaintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    paintCross(canvas, offset, model: model);

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

  /// 框架内部：保证 initState 仅触发一次。
  void doInitState() {
    if (_initialized) return;
    _initialized = true;
    initState();
  }

  /// 框架内部：进树触发 didAttach（带去重）。
  void doAttach() {
    if (_attached) return;
    _attached = true;
    didAttach();
  }

  /// 框架内部：出树触发 didDetach（仅在已 attach 时）。
  void doDetach() {
    if (!_attached) return;
    _attached = false;
    didDetach();
  }

  /// 框架内部：被加入绘制树时调用。
  void onEnterTree() => doAttach();

  /// 框架内部：被移出绘制树时调用。
  /// 先让各 Binding 释放对本对象的持有，再触发 didDetach，最后按 [keepAlive] 决定是否真销毁。
  void onExitTree() {
    // 框架侧持有本对象的引用(当前是拖动归属, 后续可能是 hover / 焦点等)由各 Binding
    // 自行释放, 本处不逐项枚举。
    if (_mounted) context.requestReleasePaintObject(this);
    doDetach();
    if (!keepAlive) dispose();
  }

  /// 框架内部：转发依赖变化。
  void doDidChangeDependencies(KlineSpec oldSpec) {
    didChangeDependencies(oldSpec);
  }
}

extension MainPaintDelegateExt<T extends MainPaintObjectIndicator> on MainPaintObject<T> {
  @protected
  void setSize(Size size) {
    if (context.canUpdateLayoutHeight) {
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

  /// 清除自身及所有子指标的 _dyFactor 缓存, 强制下次绘制重算
  void invalidateDyFactor() {
    _dyFactor = null;
    for (final object in paintableChildren) {
      object._dyFactor = null;
    }
  }

  void updateMinMax(MinMax val) {
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

    for (final object in paintableChildren) {
      final childChange = object.doUpdateLayout(
        height: object.paintMode.isCombine ? height : null,
        padding: object.paintMode.isCombine ? padding : null,
        reset: reset,
      );
      hasChange = hasChange || childChange;
    }

    return hasChange;
  }

  MinMax? doUpdateVisibleMinMax(
    int newPaneIndex, {
    required int start,
    required int end,
    bool reset = false,
    double panSmoothFactor = 1.0,
  }) {
    if (reset || newPaneIndex != paneIndex) {
      resetPaintBounding(paneIndex: newPaneIndex);
      _minMax = null;
      _dyFactor = null;
    }

    final zoomMinMax = _zoomMinMax;
    if (zoomMinMax != null) {
      return _updateVisibleMinMaxInZoom(
        zoomMinMax,
        newPaneIndex,
        start: start,
        end: end,
        reset: reset,
      );
    }

    // 数据范围未变、已有minMax、且平滑已完成时, 跳过重算
    if (!reset && _start == start && _end == end && _minMax != null && _smoothMinMax == null) {
      invalidateDyFactor();
      return _minMax;
    }

    _start = start;
    _end = end;
    _minMax = null;
    for (final object in paintableChildren) {
      final ret = object.doUpdateVisibleMinMax(
        newPaneIndex,
        start: start,
        end: end,
        reset: reset,
      );
      if (ret != null && object.paintMode == PaintMode.combine) {
        updateMinMax(ret.clone());
      }
    }

    smoothMinMax(smoothFactor: panSmoothFactor);

    invalidateDyFactor();
    return _minMax;
  }

  /// 缩放态下更新可见区间: 子对象照常重算, 但主区不采纳合并结果。
  ///
  /// 子对象那一遍不能省, 两个理由:
  /// 1. [PaintMode.alone] 子对象(如 Volume)拥有独立坐标体系, 其区间既不合并进主区也不被
  ///    主区覆盖, 必须每帧跟随可见数据自动重算, 否则缩放态平移会让它按过期区间缩放。
  /// 2. 蜡烛的 [computeVisibleMinMax] 顺带刷新最高/最低价标签所依赖的缓存, 早退会让标签
  ///    在平移后匹配不到任何蜡烛而消失。
  ///
  /// 合并与平滑都跳过: 合并结果本就要丢弃, 平滑见 [smoothMinMax] 的适用边界。
  MinMax _updateVisibleMinMaxInZoom(
    MinMax zoomMinMax,
    int newPaneIndex, {
    required int start,
    required int end,
    required bool reset,
  }) {
    _start = start;
    _end = end;
    // 缩放态下 _minMax 无意义: 恒为 null, 退出时才由自动路径重建。
    _minMax = null;

    for (final object in paintableChildren) {
      object.doUpdateVisibleMinMax(
        newPaneIndex,
        start: start,
        end: end,
        reset: reset,
      );
    }

    _dyFactor = null;
    return zoomMinMax;
  }

  /// 是否首先绘制Tips区域
  /// 1. drawBelowTipsArea标识为true
  /// 2. 当前不处在Zooming中时
  bool get isFirstDrawTipsArea {
    return indicator.drawBelowTipsArea && !context.isChartZooming;
  }

  /// 按视觉层级从上到下分发点击，首个返回 true 的对象消费事件并终止分发。
  bool doHandleTap(Offset position) {
    return reversedPaintableChildren.any((object) => object.handleTap(position));
  }

  /// 按视觉层级从上到下询问是否存在可拖动对象，与 [doHandleDragStart] 同序且无副作用。
  bool doHitTestDragStart(Offset position) {
    return reversedPaintableChildren.any((object) => object.hitTestDragStart(position));
  }

  /// 按视觉层级从上到下寻找认领拖动的对象，首个返回 true 的对象终止分发。
  PaintObject? doHandleDragStart(Offset position) {
    return reversedPaintableChildren.firstWhereOrNull(
      (object) => object.handleDragStart(position),
    );
  }

  void doPaintChart(Canvas canvas, Size size) {
    if (isFirstDrawTipsArea) {
      // 如果设置总是要在Tips区域下绘制指标图, 则要首先绘制完所有Tips.
      // doPaintTips 内部同步 _tipsAreaHeight, 子对象随后取到的 chartRect 已让出 tips 区域。
      if (!context.isCrossing) {
        doPaintTips(canvas, model: klineData.latest);
      }
      for (final object in paintableChildren) {
        object.paint(canvas, size);
      }
    } else {
      for (final object in paintableChildren) {
        object.paint(canvas, size);
      }
      if (!context.isCrossing) {
        doPaintTips(canvas, model: klineData.latest);
      }
    }
  }

  void doPaintOverlay(Canvas canvas, Size size) {
    for (final object in paintableChildren) {
      object.paintOverlay(canvas, size);
    }
  }

  void doPaintCross(Canvas canvas, Offset offset, {FlexiCandleModel? model}) {
    if (isFirstDrawTipsArea) {
      if (context.isCrossing) {
        doPaintTips(canvas, offset: offset, model: model);
      }
      for (final object in paintableChildren) {
        object.paintCross(canvas, offset, model: model);
      }
    } else {
      for (final object in paintableChildren) {
        object.paintCross(canvas, offset, model: model);
      }
      if (context.isCrossing) {
        doPaintTips(canvas, offset: offset, model: model);
      }
    }
  }

  /// 逐个绘制子指标的 Tips, 并把总高同步进 [_tipsAreaHeight]。
  ///
  /// 累计高度即汇总结果, 无需先存进各子对象再求和。量化只在汇总结果上做一次: 逐子项取整会
  /// 累积每项不足 1px 的浪费(N 个指标最多 N px), 汇总后取整的误差恒小于 1px 且与子项个数无关。
  ///
  /// 量化是双向同步的前提: 它让同一视觉状态每帧得到同一离散值, 稳定态因此提前 return、不触发
  /// 边界缓存失效。没有量化, 每帧按实测值回写就是 commit 1ed90ce 修掉的那种绘制期抖动。
  void doPaintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset}) {
    double height = 0;
    for (final object in paintableChildren) {
      final size = object.paintTips(
        canvas,
        model: model,
        offset: offset,
        tipsRect: shiftNextTipsRect(height),
      );
      if (size != null) height += size.height;
    }

    // drawBelowTipsArea 为 false 时 Tips 叠加绘制在图表之上, 不让出区域。
    final double next = indicator.drawBelowTipsArea ? height.ceilToDouble() : 0;
    if (next == _tipsAreaHeight) return;
    _tipsAreaHeight = next;
    resetPaintBounding();
    // combine 子对象与主区共享 chartRect, 同步让出同样的高度。
    for (final object in children) {
      object._tipsAreaHeight = next;
      object.resetPaintBounding();
    }
  }
}

extension MainPaintManagerExt<T extends MainPaintObjectIndicator> on MainPaintObject<T> {
  void appendPaintObjects(Iterable<PaintObject> objects) {
    for (final object in objects) {
      appendPaintObject(object);
    }
  }

  void appendPaintObject(PaintObject object) {
    // 使用前先解绑父级（不销毁，external 需保活）。
    object._parent = this;
    // 重置object布局参数为MainPaintObject的
    object.doUpdateLayout(
      height: object.paintMode.isCombine ? height : null,
      padding: object.paintMode.isCombine ? padding : null,
    );
    final old = children.append(object);
    indicator.children.add(object.key);
    // 被替换对象走多态退树：普通指标 dispose，external 仅 detach 保活。
    old?.onExitTree();
    // 进树钩子：external 触发 didAttach，普通指标 no-op。
    object.onEnterTree();
    // 子指标增删后必须让主区下一帧走完整 [doUpdateVisibleMinMax]。
    // 否则在 start/end 未变时 [MainPaintObject.doUpdateVisibleMinMax] 会早退，新子对象收不到 [setMinMax]，
    // combine 指标（如 MA）仍用默认 [MinMax.zero]，[valueToDy] 会把所有点画在底部一条线上。
    _minMax = null;
    _smoothMinMax = null;
  }

  bool removePaintObject(IIndicatorKey key) {
    bool hasRemove = false;
    children.removeWhere((object) {
      if (object.key == key) {
        object.onExitTree();
        indicator.children.remove(object.key);
        hasRemove = true;
        _tmpHeight = null;
        _tmpPadding = null;
        _minMax = null;
        _smoothMinMax = null;
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
}
