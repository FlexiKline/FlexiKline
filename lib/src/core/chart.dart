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
mixin ChartBinding on KlineBindingBase, SettingBinding, StateBinding implements IChart {
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
    super.dispose();
    logd('dispose chart');
    _repaintChart.dispose();
    _isChartStartZoom.dispose();
    _chartZoomSlideBarRect.dispose();
    _lastPriceCountDownTimer?.cancel();
    _lastPriceCountDownTimer = null;
  }

  @override
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    super.onThemeChanged(oldTheme);
    for (final paintObject in [mainPaintObject, ...subPaintObjects]) {
      paintObject.doDidChangeTheme();
    }
  }

  final ValueNotifier<int> _repaintChart = ValueNotifier(0);
  final _isChartStartZoom = ValueNotifier<bool>(false);
  final _chartZoomSlideBarRect = ValueNotifier(Rect.zero);

  Listenable get repaintChart => _repaintChart;
  void _markRepaintChart() {
    _repaintChart.value++;
  }

  ValueListenable<bool> get isStartZoomChartListener => _isChartStartZoom;

  @override
  bool get isStartZoomChart => isStartZoomChartListener.value;

  ValueListenable<Rect> get chartZoomSlideBarRectListener {
    return _chartZoomSlideBarRect;
  }

  Rect get chartZoomSlideBarRect => _chartZoomSlideBarRect.value;

  /// Latest Price ///
  Timer? _lastPriceCountDownTimer;
  @protected
  void markRepaintLastPrice({bool latestPriceUpdated = false}) {
    // 最新价已更新, 且首根蜡烛在可视区域内.
    // _reset = latestPriceUpdated && paintDxOffset <= 0;
    _markRepaintChart();
  }

  /// 控制doInitState操作是否重置计算结果
  bool _reset = false;

  /// 平移过程中Y轴平滑插值因子
  /// 1.0 = 精确值(无平滑), 0.15 = 平滑过渡
  double _panSmoothFactor = 1.0;

  /// 触发重绘蜡烛线.
  @override
  @protected
  void markRepaintChart({bool reset = false}) {
    _reset = reset;
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
    if (!curKlineData.canPaintChart) {
      logd('chartBinding paintChart data is being prepared!');
      return;
    }

    calculatePaintChartRange();
    int solt = mainIndicatorSlot;

    /// 绘制额外内容是否在允许在主图绘制区域之外
    final allowPaintExtraOutsideMainRect = settingConfig.allowPaintExtraOutsideMainRect;
    try {
      /// 保存画布状态
      canvas.save();
      canvas.clipRect(_panSmoothFactor >= 1.0 ? mainRect : canvasRect);
      mainPaintObject.doInitState(
        solt++,
        start: curKlineData.start,
        end: curKlineData.end,
        reset: _reset,
        panSmoothFactor: _panSmoothFactor,
      );
      mainPaintObject.doPaintChart(
        canvas,
        size,
      );

      if (!allowPaintExtraOutsideMainRect) {
        mainPaintObject.doPaintExtraAboveChart(canvas, size);
      }
    } finally {
      /// 恢复画布状态
      canvas.restore();
    }

    for (final paintObject in subPaintObjects) {
      /// 初始化副区指标数据.
      paintObject.doInitState(
        solt++,
        start: curKlineData.start,
        end: curKlineData.end,
        reset: _reset,
        panSmoothFactor: _panSmoothFactor,
      );

      /// 绘制副区的指标图
      paintObject.doPaintChart(canvas, size);

      paintObject.doPaintExtraAboveChart(canvas, size);
    }

    if (allowPaintExtraOutsideMainRect) {
      mainPaintObject.doPaintExtraAboveChart(canvas, size);
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
    final oldState = curKlineData.loadingState;
    if (oldState == KlineLoadingState.initLoading) {
      logw('checkAndLoadMoreCandlesWhenPanEnd currently in init, no loadMore');
      return;
    }

    panDistance ??= 0;
    // 计算提前触发LoadMore的偏移量
    final loadMoreDistanceOffset =
        gestureConfig.loadMoreWhenNoEnoughDistance ?? gestureConfig.loadMoreWhenNoEnoughCandles * candleActualWidth;

    logd(
      'checkAndLoadMoreCandlesWhenPanEnd(panDistance:$panDistance, panDuration:$panDuration) => length:${curKlineData.length}, paintDxOffset:$paintDxOffset, maxPaintDxOffset:$maxPaintDxOffset, loadMoreDistanceOffset:$loadMoreDistanceOffset',
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

    curKlineData.updateState(state: newState);
    logd('checkAndLoadMoreCandlesWhenPanEnd new loading state:$newState');

    if (newState == KlineLoadingState.loadingMore && panDuration != null) {
      Future.delayed(
        // Duration(milliseconds: panDuration),
        Duration.zero,
        () => _notifyLoadingState(newState, curDataKey),
      );
    } else {
      _notifyLoadingState(newState, curDataKey);
    }

    if (!oldState.isLoadMore && newState.isLoadMore) {
      if (settingConfig.autoLoadMoreData) {
        onLoadMoreCandles?.call(curKlineData.getLoadMoreSpec());
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
    if (delta > 0 && (!canSetMainSize() || mainMinSize.height > (mainChartHeight + mainOriginPadding.height))) {
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
    for (final paintObject in [mainPaintObject, ...subPaintObjects]) {
      if (paintObject.handleTap(position)) return true;
    }
    return false;
  }
}
