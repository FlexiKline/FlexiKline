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
    onPaintObjectDragCancel();
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
      onPaintObjectDragCancel();
      _paintObjectManager.notifySpecChanged(oldSpec);
    }
    // 换标的才交还 Y 轴: 另一个标的的价格区间没有意义。换周期不退出——同一标的的同一段
    // 价格, 用户调过的视野应当保留。判据必须是 symbol 而非 spec.key, 后者把 interval
    // 一起编码, 用它会把换周期误判成换标的。
    if (isMounted && klineData.spec.symbol != oldSpec.symbol) {
      exitChartZoom();
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
      // 平滑期放宽裁剪: 插值中的区间滞后于可见数据, 新进入的蜡烛会落在区间外, 而折线图一族
      // 本就以 `correct: false` 绘制, 裁在主区边缘会看起来被削掉一刀。
      //
      // 缩放态不放宽: 区间由用户接管、不做插值(见 [PaintObjectGeometryStateMixin.smoothMinMax]),
      // 而 `onChartMove` 无条件写 `_panSmoothFactor`, 于是缩放态平移必然满足 `< 1.0` —— 为一个
      // 不可能发生的平滑放宽裁剪, 只会让缩放放大后溢出的蜡烛画进副区。
      //
      // 判据取 `hasZoomMinMax` 而非 `isChartZooming`: 前者与 `doUpdateVisibleMinMax` 的分支同源,
      // 后者在命中滑竿时即置位、早于区间写入, 那之间主区仍走自动路径。
      final smoothing = _panSmoothFactor < 1.0 && !mainPaintObject.hasZoomMinMax;
      canvas.clipRect(smoothing ? canvasRect : mainRect);
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

  /// 有结束事件的连续平移: 按帧间位移增量移动图表。
  ///
  /// [delta] 是本帧相对上一帧的位移, 由手势层的 session 差分得出 —— 帧间增量的基准属于
  /// 一轮手势, 只有手势层知道它何时开始与结束。无结束事件的离散平移走 [onChartPanStep],
  /// 两者的分工判据是有没有结束事件, 不是量纲(见该方法注释)。
  void onChartMove(Offset delta, {double smoothFactor = 1.0}) {
    if (delta == Offset.zero) return;
    // logd('onChartMove ${DateTime.now().format(HHmmssSSS)} delta:$delta smoothFactor:$smoothFactor');

    _panSmoothFactor = smoothFactor;

    bool changed = _setPaintDxOffset(paintDxOffset + delta.dx);

    // 消费 dy 的条件是「Y 轴已由用户接管」这个模型状态, 而不是手势类型或输入设备: 自动模式
    // 下纵向位移对图表没有意义, 缩放态下它平移价格区间。守卫放在这里而非手势层, 于是同一条
    // 平移路径在两种模式、所有输入设备下都成立。
    if (isChartZooming && delta.dy != 0) {
      changed = _shiftZoomMinMaxByDy(delta.dy) || changed;
    }

    if (changed) {
      markRepaintChart();
      markRepaintDraw();
    } else if (smoothFactor < 1.0) {
      // offset 被 clamp 未变化时, 仍需触发重绘以继续 smoothMinMax 收敛
      markRepaintChart();
    }
  }

  /// 按像素位移平移主区可见价格区间; 跨度不变。
  ///
  /// 平移不需要快照: 加法可精确累加, 且 [MinMax.shift] 保持跨度不变, 因此 `dyFactor`
  /// 全程恒定, 逐帧累加与按总位移一次算是同一个结果。
  ///
  /// 向下拖动([dyDelta] > 0)时区间上移, 内容随手指下移 —— `valueToDy` 里固定价格的 dy
  /// 要增大, 就需要 min 增大。
  bool _shiftZoomMinMaxByDy(double dyDelta) {
    final object = mainPaintObject;
    final factor = object.dyFactor;
    if (factor <= 0 || !factor.isFinite) return false;

    final priceDelta = dyDelta / factor;
    if (priceDelta == 0 || !priceDelta.isFinite) return false;

    final next = object.minMax.clone();
    next.shift(priceDelta);
    object.setZoomMinMax(next);
    return true;
  }

  /// 平移结束(包括惯性平移完成后), 重置平滑因子并触发一次精确重绘
  void onPanEnd() {
    logd('onPanEnd');
    _panSmoothFactor = 1.0;
    markRepaintChart(reset: true);
  }

  /// signal 通道(横向滚轮、Web 触控板双指横滑)的一次性横向平移: 每个事件自成一段。
  ///
  /// 与 [onChartMove] 的分工在于有没有结束事件。后者服务连续拖动, 结束时机只有手势层知道,
  /// loadMore 检查因此留给手势层在 [onPanEnd] 之后调; signal 没有结束事件, 检查只能每个事件
  /// 做一次, 所以收进这里 —— 留给调用方就是每个调用点都要记得补一遍。
  ///
  /// 同理不写 `_panSmoothFactor`: 离散事件之间没有可插值的连续位移。它由上一次拖动或动画
  /// 结束时的 [onPanEnd] 归位, 到这里恒为 1.0。
  ///
  /// 返回 [paintDxOffset] 是否变化, 贴在边界上继续同向滑即为 false。调用方据此跳过 Cross
  /// 重吸附 —— `startCandleDx` 没变就不必重算。
  bool onChartPanStep(double dxDelta) {
    if (!dxDelta.isFinite || dxDelta == 0) return false;

    final changed = _setPaintDxOffset(paintDxOffset + dxDelta);
    if (changed) {
      markRepaintChart();
      markRepaintDraw();
    }

    // 不按 [changed] 收窄: 贴在历史边界上继续左滑恰恰是最该加载的时刻, 那时 offset 已被夹住
    // 不变; 反向滑离阈值区也要走一遍, 否则 loading 状态退不回 none。
    checkAndLoadMoreCandlesWhenPanEnd();
    return changed;
  }

  /// X 轴缩放: 按**累积比例的帧间增量**调整蜡烛宽度。
  ///
  /// 输入是「相对手势起点的累积比例」的连续流, 调用方差分后传入本帧增量。双指捏合与桌面
  /// 触控板 `PointerPanZoom` 走这条 —— 判据是口径而非设备: 同一块触控板在 Web 上给出的是
  /// 单次比值, 那边走 [onChartScaleTo]。
  ///
  /// 增量口径下不需要方向短路: 已在界上还继续同向时 clamp 使宽度不变, 由下面的等值检查
  /// 拦住; 而按累积比例判方向会在「累积放大后开始收拢」的第一帧误挡反向缩放。
  void onChartScaleBy(
    double scaleDelta, {
    required ScalePosition position,
    required double focalDx,
  }) {
    if (!gestureConfig.enableScale) return;
    _applyCandleWidth(
      candleWidth + scaleDelta * gestureConfig.scaleSpeed,
      position: position,
      focalDx: focalDx,
    );
  }

  /// X 轴缩放: 按**单次比值倍率**调整蜡烛宽度。
  ///
  /// 输入是「本次事件的独立比值」, 每个事件自成一次完整缩放。滚轮(`exp(-dy/signalScaleFactor)`
  /// 产出)与 Web 触控板 `PointerScaleEvent` 走这条。
  void onChartScaleTo(
    double factor, {
    required ScalePosition position,
    required double focalDx,
  }) {
    if (!gestureConfig.enableScale) return;
    _applyCandleWidth(
      candleWidth * factor,
      position: position,
      focalDx: focalDx,
    );
  }

  /// 两条缩放链共用的应用点: 夹取目标宽度, 并按锚定位置修正 [paintDxOffset]。
  ///
  /// 收敛成一个方法而不是让两条链各写一遍, 是为了让「界与锚定行为一致」成为结构保证。
  void _applyCandleWidth(
    double target, {
    required ScalePosition position,
    required double focalDx,
  }) {
    final newWidth = target.clamp(candleMinWidth, candleMaxWidth);
    if (newWidth == candleWidth) return;

    final scaleFactor = (newWidth + candleSpacing) / candleActualWidth;
    // logd('_applyCandleWidth candleWidth:$candleWidth>$newWidth; factor:$scaleFactor');

    /// 更新蜡烛宽度
    _setCandleWidth(newWidth);

    double newDxOffset;
    switch (position) {
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
          final dxRight = mainChartWidth - focalDx;
          newDxOffset = (dxRight + paintDxOffset) * scaleFactor - dxRight;
        } else {
          final widthHalf = mainChartWidthHalf;
          newDxOffset = (widthHalf + paintDxOffset) * scaleFactor - widthHalf;
        }
        break;
    }

    // logd('_applyCandleWidth paintDxOffset:$paintDxOffset > $newDxOffset');
    _setPaintDxOffset(newDxOffset);

    markRepaintChart();
    markRepaintDraw();
  }

  // 蜡烛图缩放结束
  void onChartScaleEnd() {
    _setCandleWidth(candleWidth, sync: true);
  }

  /// 退出指标图的缩放, Y 轴交还给可见数据自动适配。
  ///
  /// [isChartZooming] 置 false 的唯一入口 —— 它与清除缩放区间是同一件事, 不能分开发生,
  /// 否则会留下「按钮已消失、Y 轴仍锁着」的失同步状态。
  void exitChartZoom() {
    _isChartStartZoom.value = false;
    _zoomFactor = 1.0;
    _endChartZoomSession();
    // 没有缩放区间可清就没有画面变化, 直接返回省掉一次空重绘。
    if (!mainPaintObject.hasZoomMinMax) return;
    mainPaintObject.clearZoomMinMax();
    markRepaintChart(reset: true);
    markRepaintDraw();
  }

  /// 触摸端本轮 zoom 手势的锚点: 按下时的区间快照、手指距主图区底部的距离、按下时的累计倍率。
  ///
  /// 三者同生同灭, 打包成 record: 非空即代表「本轮可以缩放」。
  /// 每帧基于快照重算而不逐帧累乘 —— 累乘会随节流丢帧漂移, 也表达不了「拖回起点即还原」。
  ({MinMax minMax, double distanceFromBottom, double factor})? _chartZoomAnchor;

  /// 可见价格跨度相对「用户接管 Y 轴那一刻的自动跨度」的倍率, [exitChartZoom] 归 1。
  ///
  /// 界只读这个账本, 不读实时区间: 后者无论在哪个时刻读都可能已被缩过(触摸先缩、滚轮后缩
  /// 就会), 那正是基准污染的来源。缩放态下平移不改跨度, 所以倍率与跨度互为常数倍。
  double _zoomFactor = 1.0;

  /// 本轮已应用的缩放系数, 用于跳过重复的同系数更新。
  ///
  /// 不能改成「系数接近 1 就跳过」: 快照口径下 `coeff == 1` 恰恰表示「手指回到起点、
  /// 区间应还原为快照」, 跳过会把上一帧的区间留下。
  double? _chartZoomAppliedCoeff;

  void _endChartZoomSession() {
    _chartZoomAnchor = null;
    _chartZoomAppliedCoeff = null;
  }

  double _clampZoomFactor(double factor) {
    return factor.clamp(minZoomSpanRatio, maxZoomSpanRatio);
  }

  /// 缩放区间的唯一写入点, 触摸与非触摸共用: 把目标倍率夹进界内, 换算成相对 [from] 的系数
  /// 写入。返回是否写入。
  ///
  /// [from] 与 [fromFactor] 必须同源 —— 非触摸传当前区间与当前倍率(增量口径), 触摸传本轮
  /// 快照与快照倍率(快照口径)。两种口径的差异全在这两个入参上, 界因此对两端一致。
  ///
  /// 越界**钳制**而非拒绝: 拒绝会让区间不变, 于是同一个事件反复被拒形成不动点, 连反向输入
  /// 也被封死。与 [onChartScale] 夹取蜡烛宽度同源。
  bool _applyZoomFactor(
    double target, {
    required MinMax from,
    required double fromFactor,
  }) {
    if (!target.isFinite || target <= 0) return false;
    if (from.isZero || from.isSame) return false;

    final clamped = _clampZoomFactor(target);
    final next = from.clone();
    next.scaleAroundCenter(clamped / fromFactor);

    // 有界倍率已经保证候选有限, 这里只是让唯一写入点的契约不依赖界配得是否合理:
    // 非有限区间会让 dyFactor 变 NaN, 连纵向平移一起死, 且无法从手势恢复。
    if (!next.max.toDouble().isFinite || !next.min.toDouble().isFinite) return false;

    _zoomFactor = clamped;
    mainPaintObject.setZoomMinMax(next);
    markRepaintChart();
    markRepaintDraw();
    return true;
  }

  /// 设置指标图中用于缩放操作的滑竿区域。
  ///
  /// [rect] 必须是 canvas 坐标, 与手势位置同一坐标系(主区 topLeft 恒为原点), 会被夹取到
  /// [canvasRect] 内。传入其他坐标系的矩形不会被转换、只会被夹坏 —— 判定滑竿命中的地方有
  /// 四处(落点归属、滚轮缩放、光标提示、[onChartZoomStart]), 坐标系必须在这里就对齐, 任何
  /// 单点补偿都救不回来: 落点归属在最前面, 它判不中就走不到后面。
  void setChartZoomSlideBarRect(Rect rect) {
    if (rect.isEmpty || rect.isInfinite) return;
    assert(
      rect.overlaps(mainRect),
      'chartZoomSlideBarRect must be in canvas coordinates and overlap mainRect. '
      'Got $rect, mainRect=$mainRect.',
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _chartZoomSlideBarRect.value = rect.clampRect(canvasRect);
    });
  }

  @override
  void reportChartZoomSlideBarRect(Rect rect) {
    if (!gestureConfig.useCustomZoomRect) {
      setChartZoomSlideBarRect(rect);
    }
  }

  /// 检测是否开始指标图缩放, 命中滑竿则同时取本轮的区间快照与起点。
  ///
  /// 返回 false 时**不改** [isChartZooming]: 置 false 会在「已处于缩放态、本轮又没抓到滑竿」
  /// 时留下 `isChartZooming == false` 而缩放区间还在的失同步状态 —— 退出按钮消失、Y 轴却
  /// 锁着, 用户看不到复位入口。交还 Y 轴只有 [exitChartZoom] 一条路径。
  bool onChartZoomStart(Offset position) {
    if (!gestureConfig.enableZoom || chartZoomSlideBarRect.isEmpty) return false;
    if (!chartZoomSlideBarRect.include(position)) return false;

    final distanceFromBottom = mainChartRect.distanceFromBottom(position.dy);
    final current = mainPaintObject.minMax;
    // 取不到锚点就不算开始: 本轮缩放注定是空操作, 不该让退出按钮亮起来。
    if (distanceFromBottom == null || current.isZero) return false;

    _chartZoomAnchor = (
      minMax: current.clone(),
      distanceFromBottom: distanceFromBottom,
      factor: _zoomFactor,
    );
    _isChartStartZoom.value = true;
    return true;
  }

  /// 非触摸端(滚轮、Web 触控板捏合)的增量口径缩放: 直接对当前区间乘系数, 不需要 anchor。
  ///
  /// 无 pointer session 的设备每个事件自成一次完整手势, 累乘天然成立 —— signal 通道不节流,
  /// 每事件完整送达, 不存在丢帧漂移。
  bool onChartZoomStep(double coeff) {
    if (!gestureConfig.enableZoom) return false;
    if (!coeff.isFinite || coeff <= 0) return false;

    final target = _zoomFactor * coeff;
    // 已贴在界上还继续同向滚: 目标被夹回当前倍率, 区间不会变, 省掉一次空重绘。反向输入的
    // 目标一定落回界内, 走不到这里。快照口径不能照抄这个早退: 那里系数为 1 表示要还原为快照。
    if (_clampZoomFactor(target) == _zoomFactor && mainPaintObject.hasZoomMinMax) {
      return false;
    }

    if (!_applyZoomFactor(target, from: mainPaintObject.minMax, fromFactor: _zoomFactor)) return false;
    _isChartStartZoom.value = true;
    return true;
  }

  /// 非触摸端 Y 轴滚轮的每像素灵敏度(对数空间), 由触摸端口径派生。
  ///
  /// 触摸端的标定是「手指走完主图区高度得到倍率 [GestureConfig.maxZoomPerGesture]」, 折成
  /// 每像素即 `ln(M) / H`; 让滚轮用同一个值, 同样的位移在两端才得到同样的倍率。
  ///
  /// 派生而非独立配置: 它与 `maxZoomPerGesture` 表达同一个感知量, 再给一个旋钮会让两端手感
  /// 随配置漂移。`GestureConfig.signalScaleFactor` 因此只服务 X 轴。
  ///
  /// `maxZoomPerGesture` 夹在 `[1.2, 20]` 故 `ln(M) > 0`; 布局未就绪时回退到 X 轴那套口径。
  double get signalZoomCoeffPerPixel {
    final height = mainChartHeight;
    if (height <= 0) return 1 / gestureConfig.signalScaleFactor;
    return math.log(gestureConfig.maxZoomPerGesture) / height;
  }

  /// 触摸端滑竿拖拽: 按手指相对起点的位移缩放可见价格区间的跨度。
  ///
  /// 改的是价格→像素映射的分母(可见区间), 分子(主图区像素高度)全程不动。系数取自 TradingView
  /// price scale 的口径: 「距底部距离」的比值, 用比值而非差值是为了与主图区高度无关。
  ///
  /// 软化项 `s` 等于把主图区在底边外虚拟延长一段, 手指到不了那个虚拟底边, 于是: 比值不会在
  /// 贴近底边时除零; 系数恒落在 `[1 / M, M]` 且恒为正(负系数会让 max/min 互换、Y 轴翻转);
  /// 两侧同加保住「手指回到起点即系数为 1」这个不动点, 只加分母会让它偏移。
  ///
  /// 缩放的不动点是区间中点而非手指 —— 手指位置只决定幅度。所以这是「旋钮」不是「捏合」。
  void onChartZoomUpdate(double dy) {
    final anchor = _chartZoomAnchor;
    if (anchor == null) return;

    final distanceFromBottom = mainChartRect.distanceFromBottom(dy);
    if (distanceFromBottom == null) return;

    final soften = mainChartHeight / (gestureConfig.maxZoomPerGesture - 1);
    final coeff = (anchor.distanceFromBottom + soften) / (distanceFromBottom + soften);
    if (_chartZoomAppliedCoeff == coeff) return;

    // 记账在写入成功之后: 候选被挡掉时若已记下系数, 用户略微回拖会因「这个系数见过」被跳过。
    if (_applyZoomFactor(anchor.factor * coeff, from: anchor.minMax, fromFactor: anchor.factor)) {
      _chartZoomAppliedCoeff = coeff;
    }
  }

  /// 结束本轮 zoom 手势。
  ///
  /// 只清会话, 不退出缩放态 —— 用户接管 Y 轴之后只有显式复位(退出按钮)才交还自动模式。
  /// 例外是本轮没有产生任何缩放(点一下滑竿就抬手): 那种情况不该留下一个需要复位的状态。
  void onChartZoomEnd() {
    if (mainPaintObject.hasZoomMinMax) {
      _endChartZoomSession();
      return;
    }
    exitChartZoom();
  }

  /// 按位置把点击分派给主区或副区，首个消费者终止分发。
  ///
  /// 主区子对象在几何上层叠, 顺序由 [MainPaintObject.doHandleTap] 按反向绘制顺序决定;
  /// 副区各占独立 subRect, 同一位置只可能落进一个, 因此正序遍历即可。
  ///
  /// Cross 自身的点击（tooltip 项）由 CrossBinding.onTap 在本方法之前消费, 不会到这里,
  /// 所以「PaintObject 消费点击 => 关闭 crossing」可以无条件成立。
  @override
  bool onTap(Offset position) {
    if (super.onTap(position)) return true;
    final handled = mainRect.include(position)
        ? mainPaintObject.doHandleTap(position)
        : subPaintObjects.any((object) => object.handleTap(position));
    if (handled) requestCancelCross();
    return handled;
  }

  /// PaintObject 拖动 ///

  PaintObject? _draggingObject;

  /// 是否有绘制对象正在被拖动。手势层据此短路蜡烛图平移与 cross 更新。
  bool get isPaintObjectDragging => _draggingObject != null;

  /// 询问 [position] 是否存在可拖动的绘制对象，不产生任何状态变更。
  ///
  /// 命中规则与 [onPaintObjectDragStart] 严格同源，只是不认领。
  bool hitTestPaintObjectDrag(Offset position) {
    if (_draggingObject != null) return false;
    return mainRect.include(position)
        ? mainPaintObject.doHitTestDragStart(position)
        : subPaintObjects.any((object) => object.hitTestDragStart(position));
  }

  /// 询问可绘制对象是否认领 [position] 位置发起的拖动，命中规则与 [onTap] 一致。
  bool onPaintObjectDragStart(Offset position) {
    if (_draggingObject != null) return false;
    final object = mainRect.include(position)
        ? mainPaintObject.doHandleDragStart(position)
        : subPaintObjects.firstWhereOrNull((object) => object.handleDragStart(position));
    if (object == null) return false;
    logd('onPaintObjectDragStart ${object.key} > $position');
    _draggingObject = object;
    requestCancelCross();
    return true;
  }

  void onPaintObjectDragUpdate(Offset position, Offset delta) {
    _draggingObject?.handleDragUpdate(position, delta);
  }

  void onPaintObjectDragEnd() {
    final object = _draggingObject;
    _draggingObject = null;
    object?.handleDragEnd();
  }

  @override
  void onPaintObjectDragCancel() {
    final object = _draggingObject;
    if (object == null) return;
    _draggingObject = null;
    object.handleDragCancel();
  }

  /// 释放 ChartBinding 对 [object] 的持有：当前只有拖动归属。
  @override
  void requestReleasePaintObject(PaintObject object) {
    super.requestReleasePaintObject(object);
    // 带对象守卫: 传入对象不是当前拖动所有者时不能误取消他人的拖动。
    if (identical(_draggingObject, object)) onPaintObjectDragCancel();
  }
}
