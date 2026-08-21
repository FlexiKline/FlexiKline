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

part of 'core.dart';

/// 负责绘制蜡烛图以及相关指标图
mixin ChartBinding on KlineBindingBase, SettingBinding, StateBinding {
  @override
  void init() {
    super.init();
    logd('init chart');
  }

  @override
  void initState() {
    super.initState();
    logd('initState chart');
    if (settingConfig.autoStartLastPriceCountDownTimer) {
      startLastPriceCountDownTimer();
    }
  }

  @override
  void dispose() {
    // 先静默放弃选中态, 使 super.dispose() 中的 PaintObject 释放不再触发通知与重绘.
    _isDragging = false;
    _selectedObjectNotifier.setSilently(null);
    super.dispose();
    logd('dispose chart');
    _repaintChart.dispose();
    _selectedObjectNotifier.dispose();
    _isChartStartZoom.dispose();
    _chartZoomSlideBarRect.dispose();
    _lastPriceCountDownTimer?.cancel();
    _lastPriceCountDownTimer = null;
  }

  @override
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    super.onThemeChanged(oldTheme);
    if (!isMounted) return;
    for (final paintObject in [mainPaintObject, ...subPaintObjects]) {
      paintObject.doDidChangeTheme();
    }
  }

  @override
  void onKlineSpecChanged(KlineSpec oldSpec) {
    super.onKlineSpecChanged(oldSpec);
    // 仅 symbol/interval（spec.key）变化才通知 external 重载业务数据。
    if (klineData.spec.key != oldSpec.key) {
      // 业务数据即将重载, 选中的绘制目标不再有效。
      deselectPaintObject();
      _paintObjectManager.notifySpecChanged(oldSpec);
    }
  }

  final ValueNotifier<int> _repaintChart = ValueNotifier(0);
  final _isChartStartZoom = ValueNotifier<bool>(false);
  final _chartZoomSlideBarRect = ValueNotifier(Rect.zero);

  Listenable get repaintChart => _repaintChart;
  void _markRepaintChart() {
    _repaintChart.value++;
  }

  ValueListenable<bool> get isChartZoomingListenable => _isChartStartZoom;

  @override
  bool get isChartZooming => isChartZoomingListenable.value;

  ValueListenable<Rect> get chartZoomSlideBarRectListenable {
    return _chartZoomSlideBarRect;
  }

  @override
  Rect get chartZoomSlideBarRect => _chartZoomSlideBarRect.value;

  /// Latest Price ///
  Timer? _lastPriceCountDownTimer;
  @protected
  void markRepaintLastPrice({bool latestPriceUpdated = false}) {
    // 最新价已更新, 且首根蜡烛在可视区域内.
    // _reset = latestPriceUpdated && paintDxOffset <= 0;
    _markRepaintChart();
  }

  /// 控制 doUpdateVisibleMinMax 操作是否重置计算结果
  bool _reset = false;

  /// 平移过程中Y轴平滑插值因子
  /// 1.0 = 精确值(无平滑), 0.15 = 平滑过渡
  double _panSmoothFactor = 1.0;

  /// 触发重绘蜡烛线.
  @override
  @protected
  void markRepaintChart({bool reset = false}) {
    _reset = _reset || reset;
    _markRepaintChart();
  }

  @override
  @protected
  void requestRepaint() => markRepaintChart();

  @protected
  void startLastPriceCountDownTimer() {
    _lastPriceCountDownTimer?.cancel();
    markRepaintLastPrice();
    _lastPriceCountDownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        markRepaintLastPrice();
      },
    );
  }

  DateTime _lastPaintTime = DateTime.now();
  int get diffTime {
    // 计算两次绘制时间差
    return _lastPaintTime.difference(_lastPaintTime = DateTime.now()).inMilliseconds.abs();
  }

  void paintChart(Canvas canvas, Size size) {
    // logd('$diffTime paintChart >>>>');
    if (!isMounted || !klineData.canPaintChart) {
      logd('chartBinding paintChart data is being prepared!');
      return;
    }

    calculatePaintChartRange();
    int paneIndex = mainPaneIndex;

    /// overlay 是否允许绘制在主图 rect 之外
    final allowOverlayOutsideMainRect = settingConfig.allowOverlayOutsideMainRect;
    try {
      /// 保存画布状态
      canvas.save();
      canvas.clipRect(_panSmoothFactor >= 1.0 ? mainRect : canvasRect);
      mainPaintObject.doUpdateVisibleMinMax(
        paneIndex++,
        start: klineData.start,
        end: klineData.end,
        reset: _reset,
        panSmoothFactor: _panSmoothFactor,
      );
      mainPaintObject.doPaintChart(
        canvas,
        size,
      );

      if (!allowOverlayOutsideMainRect) {
        mainPaintObject.doPaintOverlay(canvas, size);
      }
    } finally {
      /// 恢复画布状态
      canvas.restore();
    }

    for (final paintObject in subPaintObjects) {
      /// 更新副区指标可见区间状态.
      paintObject.doUpdateVisibleMinMax(
        paneIndex++,
        start: klineData.start,
        end: klineData.end,
        reset: _reset,
        panSmoothFactor: _panSmoothFactor,
      );

      /// 绘制副区的指标图
      paintObject.doPaintChart(canvas, size);

      paintObject.doPaintOverlay(canvas, size);
    }

    if (allowOverlayOutsideMainRect) {
      mainPaintObject.doPaintOverlay(canvas, size);
    }

    if (_reset) _reset = false;
  }

  /// 惯性平移前检查是否需要加载更多
  /// [panDistance] 惯性平移距离, [panDuration] 惯性时长(ms)
  /// 越过 loadMore 阈值 → [KlineLoadingState.loadMore](静默预加载)
  /// 越过 max → [KlineLoadingState.loadingMore](展示 loading)
  void checkAndLoadMoreCandlesWhenPanEnd({
    double? panDistance,
    int? panDuration,
  }) {
    final oldState = klineData.loadingState;
    if (oldState == KlineLoadingState.initLoading) {
      logw('checkAndLoadMoreCandlesWhenPanEnd currently in init, no loadMore');
      return;
    }

    panDistance ??= 0;
    // 计算提前触发LoadMore的偏移量
    final loadMoreDistanceOffset =
        gestureConfig.loadMoreWhenNoEnoughDistance ?? gestureConfig.loadMoreWhenNoEnoughCandles * candleActualWidth;

    logd(
      'checkAndLoadMoreCandlesWhenPanEnd(panDistance:$panDistance, panDuration:$panDuration) => length:${klineData.length}, paintDxOffset:$paintDxOffset, maxPaintDxOffset:$maxPaintDxOffset, loadMoreDistanceOffset:$loadMoreDistanceOffset',
    );

    final destination = paintDxOffset + panDistance;
    final loadMoreMinPaintDxOffset = maxPaintDxOffset - loadMoreDistanceOffset;

    KlineLoadingState newState;
    if (destination > loadMoreMinPaintDxOffset) {
      if (destination >= maxPaintDxOffset) {
        newState = KlineLoadingState.loadingMore;
      } else {
        newState = KlineLoadingState.loadMore;
      }
    } else if (oldState.isLoadMore) {
      newState = KlineLoadingState.loadMore;
    } else {
      newState = KlineLoadingState.none;
    }

    klineData.updateState(state: newState);
    logd('checkAndLoadMoreCandlesWhenPanEnd new loading state:$newState');

    if (newState == KlineLoadingState.loadingMore && panDuration != null) {
      Future.delayed(
        // Duration(milliseconds: panDuration),
        Duration.zero,
        _notifyLoadingState,
      );
    } else {
      _notifyLoadingState();
    }

    if (!oldState.isLoadMore && newState.isLoadMore) {
      if (settingConfig.autoLoadMoreData) {
        onLoadMoreCandles?.call(klineData.getLoadMoreSpec());
      }
    }
  }

  void onChartMove(GestureData data, [double smoothFactor = 1.0]) {
    if (!data.moved) return;
    // logd('onChartMove ${DateTime.now().format(HHmmssSSS)} data:$data smoothFactor:$smoothFactor');

    _panSmoothFactor = smoothFactor;

    bool changed = false;
    final newDxOffset = clampPaintDxOffset(paintDxOffset + data.dxDelta);
    if (newDxOffset != paintDxOffset) {
      paintDxOffset = newDxOffset;
      changed = true;
    }

    double dyDelta;
    if (data.isMove && (dyDelta = data.dyDelta) != 0) {
      final newPadding = mainPadding.copyWith(
        top: mainPadding.top + dyDelta,
        bottom: mainPadding.bottom - dyDelta,
      );
      if (newPadding.top > mainSize.height || newPadding.bottom > mainSize.height) {
        return;
      }

      changed = mainPaintObject.doUpdateLayout(padding: newPadding) || changed;
    }

    if (changed) {
      markRepaintChart();
      markRepaintDraw();
    } else if (smoothFactor < 1.0) {
      // offset 被 clamp 未变化时, 仍需触发重绘以继续 smoothMinMax 收敛
      markRepaintChart();
    }
  }

  /// 平移结束(包括惯性平移完成后), 重置平滑因子并触发一次精确重绘
  void onPanEnd() {
    logd('onPanEnd');
    _panSmoothFactor = 1.0;
    markRepaintChart(reset: true);
  }

  /// 蜡烛图缩放中...
  void onChartScale(GestureData data) {
    if (!gestureConfig.enableScale) return;

    double? newWidth;
    if (data.scaled) {
      // 处理触摸设备的缩放逻辑.
      if (data.scale > 1 && candleWidth >= candleMaxWidth) return;
      if (data.scale < 1 && candleWidth <= candleMinWidth) return;

      final dxGrowth = data.scaleDelta * gestureConfig.scaleSpeed;
      newWidth = (candleWidth + dxGrowth).clamp(
        candleMinWidth,
        candleMaxWidth,
      );
    } else if (data.isSignal) {
      // 处理鼠标滚轴滚动/触控板向上向下的缩放逻辑.
      newWidth = (candleWidth + data.scale).clamp(
        candleMinWidth,
        candleMaxWidth,
      );
    }

    if (newWidth == null || newWidth == candleWidth) return;

    final scaleFactor = (newWidth + candleSpacing) / candleActualWidth;
    // logd('onChartScale candleWidth:$candleWidth>$newWidth; factor:$scaleFactor');

    /// 更新蜡烛宽度
    _setCandleWidth(newWidth);

    double newDxOffset;
    switch (data.initPosition) {
      case ScalePosition.right:
        if (paintDxOffset <= 0) {
          newDxOffset = paintDxOffset; // 固定右侧空白
        } else {
          newDxOffset = paintDxOffset * scaleFactor;
        }
        break;
      case ScalePosition.left:
        final chartWidth = mainChartWidth;
        newDxOffset = (chartWidth + paintDxOffset) * scaleFactor - chartWidth;
        break;
      case ScalePosition.auto:
      case ScalePosition.middle:
        if (paintDxOffset <= 0) {
          final dxRight = mainChartWidth - data.offset.dx;
          newDxOffset = (dxRight + paintDxOffset) * scaleFactor - dxRight;
        } else {
          final widthHalf = mainChartWidthHalf;
          newDxOffset = (widthHalf + paintDxOffset) * scaleFactor - widthHalf;
        }
        break;
    }

    if (newDxOffset != paintDxOffset) {
      // logd('handleScale paintDxOffset:$paintDxOffset > $newDxOffset');
      paintDxOffset = newDxOffset;
    }

    markRepaintChart();
    markRepaintDraw();
  }

  // 蜡烛图缩放结束
  void onChartScaleEnd() {
    _setCandleWidth(candleWidth, sync: true);
  }

  /// 退出指标图的缩放
  void exitChartZoom() {
    _isChartStartZoom.value = false;
    final changed = mainPaintObject.doUpdateLayout(
      padding: mainOriginPadding,
    );
    markRepaintChart(reset: changed);
    markRepaintDraw();
  }

  /// 设置指标图中用于缩放操作的滑竿区域
  /// 注: 此区域是相对于mainRect
  void setChartZoomSlideBarRect(Rect rect) {
    if (!rect.isEmpty && !rect.isInfinite) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _chartZoomSlideBarRect.value = rect.clampRect(canvasRect);
      });
    }
  }

  @override
  void reportChartZoomSlideBarRect(Rect rect) {
    if (!gestureConfig.isManualSetZoomRect) {
      setChartZoomSlideBarRect(rect);
    }
  }

  /// 检测是否开始指标图缩放
  /// [isConvert] 是否转换为canvas区域坐标
  bool onChartZoomStart(Offset position, [bool isConvert = true]) {
    if (!gestureConfig.enableZoom || chartZoomSlideBarRect.isEmpty) return false;
    if (isConvert) position += chartZoomSlideBarRect.topLeft;
    return _isChartStartZoom.value = chartZoomSlideBarRect.include(position);
  }

  /// 指标图缩放更新
  void onChartZoomUpdate(GestureData data) {
    double delta = data.dyDelta / 2;
    if (delta == 0) return;
    if (delta > 0 && (!canSetMainSize(mainSize) || mainMinSize.height > (mainChartHeight + mainOriginPadding.height))) {
      logw(
        'onChartZoomUpdate > cannot zoom($delta), mainSize:$mainSize is smaller than the minSize:$mainMinSize',
      );
      return;
    }

    delta = delta * gestureConfig.zoomSpeed;
    final newPadding = mainPadding.copyWith(
      top: mainPadding.top + delta,
      bottom: mainPadding.bottom + delta,
    );
    if (newPadding.top > mainSize.height || newPadding.bottom > mainSize.height) {
      return;
    }

    final changed = mainPaintObject.doUpdateLayout(padding: newPadding);
    if (changed) {
      markRepaintChart();
      markRepaintDraw();
    }
  }

  void onChartZoomEnd() {
    if (mainOriginPadding == mainPadding) {
      exitChartZoom();
    }
  }

  @override
  bool onTap(Offset position) {
    if (super.onTap(position)) return true;

    // 主区与副区在几何上互斥(mainRect 即 mainPaintObject.drawableRect, subRect 在其下方),
    // 按位置直接定位目标集合, 无需经 MainPaintObject 转发。
    // 用 paintableChildren 而非 children: 线图模式下被隐藏的主区指标不参与命中。
    final objects = mainRect.include(position) ? mainPaintObject.paintableChildren : subPaintObjects;

    for (final paintObject in objects) {
      switch (paintObject.handleTap(position)) {
        case PaintTapResult.ignored:
          continue;
        case PaintTapResult.handled:
          // 消费点击但不需要选中态 => 顺带放弃当前选中的目标。
          deselectPaintObject();
          return true;
        case PaintTapResult.selected:
          _selectPaintObject(paintObject);
          return true;
      }
    }

    // 本次点击无人认领 => 放弃选中态, 让后续 cross 接手。
    deselectPaintObject();
    return false;
  }

  /// PaintObject 选中态 ///

  /// 当前选中的绘制对象。选中态由框架持有, 同一时刻最多一个。
  ///
  /// 对象内部选中了哪个元素（如订单指标的哪条止盈线）由绘制对象自行维护,
  /// 并应将相关渲染判断门控在 [PaintObject.isSelected] 上。
  final _selectedObjectNotifier = FlexiStateNotifier<PaintObject?>(null);

  /// 选中对象变化, 供宿主 Widget 联动（如工具条显隐）。
  ValueListenable<PaintObject?> get selectedPaintObjectListenable {
    return _selectedObjectNotifier;
  }

  /// 有效选中对象: 当前不可绘制时(线图模式下被隐藏的主区指标)视为未选中。
  ///
  /// 与 [selectedPaintObjectListenable] 的区别: 后者是原始选中, 不因可见性
  /// 变化而改变; 本 getter 参与手势判定。隐藏不使对象出树, 因此选中态刻意
  /// 保留, 放大回蜡烛图即恢复。
  PaintObject? get _activeSelectedObject {
    final object = _selectedObjectNotifier.value;
    if (object == null) return null;
    return mainPaintObject.isPaintable(object) ? object : null;
  }

  @override
  bool get hasSelectedPaintObject => _activeSelectedObject != null;

  @override
  bool isSelectedPaintObject(PaintObject object) {
    return identical(_selectedObjectNotifier.value, object);
  }

  /// 授予选中态。private: 唯一调用点是 [onTap] 的三值分发。
  void _selectPaintObject(PaintObject object) {
    if (isSelectedPaintObject(object)) return;
    _cancelDragIfNeeded();
    // 直接赋值而非 updateValue: 上面已保证值必然变化, 不需要「值未变也通知」的语义。
    _selectedObjectNotifier.value = object;
    // 选中即一次性取消 cross; 非触摸设备再由 hover 事件的持续早退保证其不被重新拉起。
    requestCancelCross();
    markRepaintChart();
  }

  @override
  void requestDeselectPaintObject(PaintObject object) {
    if (!isSelectedPaintObject(object)) return;
    deselectPaintObject();
  }

  @override
  void deselectPaintObject() {
    if (_selectedObjectNotifier.value == null) return;
    _cancelDragIfNeeded();
    _selectedObjectNotifier.value = null;
    markRepaintChart();
  }

  /// PaintObject 拖动 ///

  /// 不变量: 为 true 时 [_selectedObjectNotifier] 必然非空。
  bool _isDragging = false;

  /// 是否有绘制对象正在被拖动。手势层据此短路蜡烛图平移与 cross 更新。
  bool get isPaintObjectDragging => _isDragging;

  /// 询问当前选中对象是否认领 [position] 位置发起的拖动。
  ///
  /// 未选中任何对象或已在拖动中时直接返回 false, 由蜡烛图平移接手。
  bool onPaintObjectDragStart(Offset position) {
    if (_isDragging) return false;
    // 有效选中而非原始选中: 不可绘制的对象不参与手势。
    final object = _activeSelectedObject;
    if (object == null) return false;
    if (!object.handleDragStart(position)) return false;
    logd('onPaintObjectDragStart ${object.key} > $position');
    _isDragging = true;
    return true;
  }

  void onPaintObjectDragUpdate(GestureData data) {
    if (!_isDragging) return;
    _activeSelectedObject?.handleDragUpdate(data.offset, data.delta);
  }

  void onPaintObjectDragEnd() {
    if (!_isDragging) return;
    _isDragging = false;
    _activeSelectedObject?.handleDragEnd();
  }

  void onPaintObjectDragCancel() => _cancelDragIfNeeded();

  void _cancelDragIfNeeded() {
    if (!_isDragging) return;
    _isDragging = false;
    // 用原始选中: 对象若在拖动途中变为不可绘制, 仍必须收到回滚回调。
    _selectedObjectNotifier.value?.handleDragCancel();
  }
}
