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
    logd("init chart");
  }

  @override
  void initState() {
    super.initState();
    logd('initState indicator');
    startLastPriceCountDownTimer();
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose indicator');
    _repaintChart.dispose();
    _isChartStartZoom.dispose();
    _chartZoomSlideBarRect.dispose();
    _lastPriceCountDownTimer?.cancel();
    _lastPriceCountDownTimer = null;
  }

  @override
  void onThemeChanged([covariant IFlexiKlineTheme? oldTheme]) {
    super.onThemeChanged(oldTheme);
    for (var paintObject in [mainPaintObject, ...subPaintObjects]) {
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

  //// Latest Price ////
  Timer? _lastPriceCountDownTimer;
  @protected
  void markRepaintLastPrice({bool latestPriceUpdated = false}) {
    // 最新价已更新, 且首根蜡烛在可视区域内.
    // _reset = latestPriceUpdated && paintDxOffset <= 0;
    _markRepaintChart();
  }

  /// 控制doInitState操作是否重置计算结果
  bool _reset = false;

  /// 触发重绘蜡烛线.
  @override
  @protected
  void markRepaintChart({bool reset = false}) {
    _reset = reset;
    _markRepaintChart();
  }

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

    calculateCandleDrawIndex();
    int solt = mainIndicatorSlot;

    try {
      /// 保存画布状态
      canvas.save();
      canvas.clipRect(mainRect);
      mainPaintObject.doInitState(
        solt++,
        start: curKlineData.start,
        end: curKlineData.end,
        reset: _reset,
      );
      mainPaintObject.doPaintChart(canvas, size);
    } finally {
      /// 恢复画布状态
      canvas.restore();
    }

    for (var paintObject in subPaintObjects) {
      /// 初始化副区指标数据.
      paintObject.doInitState(
        solt++,
        start: curKlineData.start,
        end: curKlineData.end,
        reset: _reset,
      );

      /// 绘制副区的指标图
      paintObject.doPaintChart(canvas, size);
    }

    if (_reset) _reset = false;
  }

  /// 当前平移结束(惯性平移之前)时,检查并加载更多蜡烛数据
  /// [panDistance] 代表数据将要惯性平移的距离
  /// [panDuration] 代表数据将要惯性平移的时长(单们ms)
  /// [loadMoreDistanceOffset]的计算规则: [gestureConfig.loadMoreWhenNoEnoughDistance] 优先 [gestureConfig.loadMoreWhenNoEnoughCandles]
  /// 以[paintDxOffset]为基础继续平移[panDistance],
  ///   1. 当大于最大平移宽度[maxPaintDxOffset]减去[loadMoreDistanceOffset]的距离时, 请求状态为[RequestState.loadMore], 提前加载更多历史数据, 此时不展示loading.
  ///   2. 当大于最大平移宽度[maxPaintDxOffset]时, 请求状态为[RequestState.loadingMore], 提前加载更多历史数据, 等待[panDuration]ms展示loading.
  ///   3. 否则, 请求状态为[RequestState.none], 取消loading的展示.
  void checkAndLoadMoreCandlesWhenPanEnd({
    double? panDistance,
    int? panDuration,
  }) {
    final oldState = curKlineData.req.state;
    if (oldState == RequestState.initLoading) {
      logw('checkAndLoadMoreCandlesWhenPanEnd currently in init, no loadMore');
      return;
    }

    panDistance ??= 0;
    // 计算提前触发LoadMore的偏移量
    final loadMoreDistanceOffset = gestureConfig.loadMoreWhenNoEnoughDistance ??
        gestureConfig.loadMoreWhenNoEnoughCandles * candleActualWidth;

    logd(
      'checkAndLoadMoreCandlesWhenPanEnd(panDistance:$panDistance, panDuration:$panDuration) => length:${curKlineData.length}, paintDxOffset:$paintDxOffset, maxPaintDxOffset:$maxPaintDxOffset, loadMoreDistanceOffset:$loadMoreDistanceOffset',
    );

    final destination = paintDxOffset + panDistance;
    final loadMoreMinPaintDxOffset = maxPaintDxOffset - loadMoreDistanceOffset;

    RequestState newState;
    if (destination > loadMoreMinPaintDxOffset) {
      if (destination >= maxPaintDxOffset) {
        newState = RequestState.loadingMore;
      } else {
        newState = RequestState.loadMore;
      }
    } else if (oldState.isLoadMore) {
      newState = RequestState.loadMore;
    } else {
      newState = RequestState.none;
    }

    final request = curKlineData.updateState(state: newState);
    logd('checkAndLoadMoreCandlesWhenPanEnd new candle request:$request');

    if (newState == RequestState.loadingMore && panDuration != null) {
      Future.delayed(
        // Duration(milliseconds: panDuration),
        Duration.zero,
        () => _updateCandleRequestListener(request),
      );
    } else {
      _updateCandleRequestListener(request);
    }

    if (!oldState.isLoadMore && newState.isLoadMore) {
      onLoadMoreCandles?.call(request);
    }
  }

  void onChartMove(GestureData data) {
    if (!data.moved) return;

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
    }
  }

  /// 蜡烛图缩放中...
  void onChartScale(GestureData data) {
    double? newWidth;

    if (data.scaled) {
      // 处理触摸设备的缩放逻辑.
      if (data.scale > 1 && candleWidth >= candleMaxWidth) return;
      if (data.scale < 1 && candleWidth <= settingConfig.pixel) return;

      final dxGrowth = data.scaleDelta * gestureConfig.scaleSpeed;
      newWidth = (candleWidth + dxGrowth).clamp(
        settingConfig.pixel,
        candleMaxWidth,
      );
    } else if (data.isSignal) {
      // 处理鼠标滚轴滚动/触控板向上向下的缩放逻辑.
      newWidth = (candleWidth + data.scale).clamp(
        settingConfig.pixel,
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _chartZoomSlideBarRect.value = rect;
    });
  }

  /// 检测是否开始指标图缩放
  /// [isConvert] 是否转换为canvas区域坐标
  bool onChartZoomStart(Offset position, [bool isConvert = true]) {
    if (chartZoomSlideBarRect.isEmpty) return false;
    if (isConvert) position += chartZoomSlideBarRect.topLeft;
    return _isChartStartZoom.value = chartZoomSlideBarRect.include(position);
  }

  /// 指标图缩放更新
  void onChartZoomUpdate(GestureData data) {
    double delta = data.dyDelta / 2;
    if (delta == 0) return;
    if (delta > 0 &&
        (!canSetMainSize() || mainMinSize.height > (mainChartHeight + mainOriginPadding.height))) {
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
    for (var paintObject in [mainPaintObject, ...subPaintObjects]) {
      if (paintObject.handleTap(position)) return true;
    }
    return false;
  }
}
