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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../constant.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 状态管理: 负责数据的管理, 缓存, 切换, 计算
mixin StateBinding
    on KlineBindingBase, SettingBinding
    implements IState, IChart, ICross {
  @override
  void initState() {
    super.initState();
    logd('initState state');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose state');
    timeBarListener.dispose();
    loadingListener.dispose();
    _klineDataCache.forEach((key, data) {
      data.dispose();
    });
    _klineDataCache.clear();
  }

  /// 当KlineData的TimeBar的监听器
  final timeBarListener = ValueNotifier<TimeBar?>(null);

  /// KlineData数据加载loading状态监听器
  final loadingListener = ValueNotifier<bool>(false);

  ComputeMode _computeMode = ComputeMode.fast;
  // ComputeMode get computeMode => _computeMode;
  set computeMode(mode) {
    if (mode != _computeMode) {
      _computeMode = mode;
      _startPrecomputeKlineData(
        curKlineData,
        reset: true,
      );
    }
  }

  final Map<String, KlineData> _klineDataCache = {};
  KlineData _curKlineData = KlineData.empty;
  @override
  KlineData get curKlineData => _curKlineData;

  /// 设置当前KlineData:
  /// 1. 通知timeBar变更
  /// 2. 初始化首根蜡烛绘制位置于屏幕右侧[initPaintDxOffset]指定处.
  /// 3. 重绘图表
  /// 4. 取消Cross绘制(如果有)
  void setCurKlineData(KlineData data) {
    _curKlineData = data;
    timeBarListener.value = data.req.timeBar;
    initPaintDxOffset();
    markRepaintChart(reset: true);
    cancelCross();
  }

  @override
  bool get canPaintChart => curKlineData.canPaintChart;

  /// 数据缓存Key
  String get curDataKey => curKlineData.key;

  /// 蜡烛总数
  @override
  int get totalCandleCount => curKlineData.list.length;

  /// 最大绘制宽度
  @override
  double get maxPaintWidth => totalCandleCount * candleActualWidth;

  /// 将offset转换为蜡烛数据
  @override
  CandleModel? offsetToCandle(Offset offset) {
    final index = offsetToIndex(offset);
    return curKlineData.getCandle(index);
  }

  /// 将offset指定的dx转换为当前绘制区域对应的蜡烛的下标.
  @override
  int offsetToIndex(Offset offset) => dxToIndex(offset.dx);

  @override
  int dxToIndex(double dx) {
    final dxPaintOffset = (mainChartRight - dx) + paintDxOffset;
    // final diff = dxPaintOffset % candleActualWidth;
    return (dxPaintOffset / candleActualWidth).floor();
  }

  /// 将index转换为当前绘制区域对应的X轴坐标. 如果超出范围, 则返回null.
  @override
  double? indexToDx(int index) {
    double dx = mainChartRight - (index * candleActualWidth - paintDxOffset);
    if (mainChartRect.inclueDx(dx)) return dx;
    return null;
  }

  /// 当前canvas绘制区域起始蜡烛右部dx值.
  @override
  double get startCandleDx {
    if (paintDxOffset == 0) {
      return 0;
    } else if (paintDxOffset > 0) {
      return mainChartRight + paintDxOffset % candleActualWidth;
    } else {
      return mainChartRight + paintDxOffset;
    }
  }

  /// 画布是否可以从右向左进行平移.
  @override
  bool get canPanRTL => paintDxOffset > minPaintDxOffset;

  /// 画布是否可以从左向右进行平移.
  @override
  bool get canPanLTR {
    return paintDxOffset < maxPaintDxOffset;
  }

  /// 代表当前绘制区域相对于startIndex右侧的偏移量.
  /// 1. 当为零时(默认) : 说明首根蜡烛在Canvas右边界展示.
  /// 2. 当为负数时     : 代表首根蜡烛到Canvas右边界的距离.
  /// 3. 当为正数时     : 说明首根蜡烛已向右移出Canvas.
  ///     移出右边界的蜡烛数量 = (paintDxOffset / candleActualWidth).floor()
  ///     绘制起始蜡烛的向右边界外的偏移 = paintDxOffset % candleActualWidth;
  double _paintDxOffset = 0;
  @override
  double get paintDxOffset => _paintDxOffset;
  set paintDxOffset(double val) {
    _paintDxOffset = clampPaintDxOffset(val);
  }

  /// PaintDxOffset的最小值
  double get minPaintDxOffset {
    return math.min(
      maxPaintWidth - mainChartWidth,
      -minPaintBlankWidth,
    );
  }

  /// PaintDxOffset的最大值
  double get maxPaintDxOffset {
    return maxPaintWidth - (mainChartWidth - minPaintBlankWidth);
  }

  /// 矫正PaintDxOffset的范围
  double clampPaintDxOffset(double dxOffset) {
    return dxOffset.clamp(minPaintDxOffset, maxPaintDxOffset);
  }

  void initPaintDxOffset() {
    paintDxOffset = math.min(
      maxPaintWidth - mainChartWidth, // 不足一屏, 首根蜡烛偏移量等于首根蜡烛右边长度.
      -settingConfig.firstCandleInitOffset, // 满足一屏时, 首根蜡烛相对于主绘制区域最小的偏移量
    );
  }

  /// 计算绘制蜡烛图的起始数组索引下标
  @override
  void calculateCandleDrawIndex() {
    if (paintDxOffset > 0) {
      final startIndex = (paintDxOffset / candleActualWidth).floor();
      final diff = paintDxOffset % candleActualWidth;
      final maxCount = ((mainChartWidth + diff) / candleActualWidth).round();
      curKlineData.ensureStartAndEndIndex(
        startIndex,
        maxCount,
      );
    } else {
      int maxCount;
      if (settingConfig.alwaysCalculateScreenOfCandlesIfEnough) {
        // 1: 当前[start, end]不足一屏蜡烛时, 向后取一屏蜡烛数据来计算最大最小
        maxCount = maxCandleCount;
      } else {
        // 2: 取当前可见蜡烛来计算最大最小. 四舍五入
        final offsetIndex = (paintDxOffset.abs() / candleActualWidth).round();
        maxCount = maxCandleCount - offsetIndex;
      }
      curKlineData.ensureStartAndEndIndex(
        0,
        maxCount,
      );
    }
  }

  /// 开始预计算Kline指标数据
  /// [data] 待计算的Kline蜡烛数据
  /// [newList] 待计算的蜡烛数据范围
  /// [reset] 是否重置[data],
  /// 1. true: 重新计算[data]的指标数据;
  /// 2. false: 仅计算[data]与[newList]合并后的部分.
  /// 数据合并更新结果的处理:
  /// 1. 对于历史数据追加, 像EMA这类依赖于历史数据会适时考虑从头计算.
  /// 2. 对于实时数据更新, 会仅计算[newList]部分.
  Future<KlineData> _startPrecomputeKlineData(
    KlineData data, {
    List<CandleModel> newList = const [],
    bool reset = false,
  }) async {
    if (newList.isEmpty || !reset) {
      // 无需计算; 直接返回
      return data;
    }

    // 确认当前数据的计算模式
    final computeMode = _computeMode;

    // 收集指标预计算参数.
    final calcParams = indicatorsConfig.getIndicatorCalcParams();

    final watchPrecompute = Stopwatch();

    try {
      logd('PrecomputeKlineData Begin:${DateTime.now()}');
      watchPrecompute.start();

      /// 使用scheduleTask + compute方式运行预计算
      // return await SchedulerBinding.instance.scheduleTask(
      //   () => precomputeKlineDataByCompute(
      //     data,
      //     newList: newList,
      //     computeMode: computeMode,
      //     calcParams: calcParams,
      //     reset: reset,
      //     debugLabel: 'Precompute-Compute',
      //     logger: loggerDelegate,
      //   ),
      //   Priority.animation,
      //   debugLabel: 'Precompute-Task',
      // );

      /// 使用scheduleTask方式运行预计算
      return await SchedulerBinding.instance.scheduleTask(
        () => KlineData.precomputeKlineData(
          data,
          newList: newList,
          computeMode: computeMode,
          calcParams: calcParams,
          reset: reset,
        ),
        Priority.animation,
        debugLabel: 'Precompute-Task',
      );

      /// 直接运行预计算
      // return await KlineData.precomputeKlineData(
      //   data,
      //   newList: newList,
      //   computeMode: computeMode,
      //   calcParams: calcParams,
      //   reset: reset,
      // );
    } catch (e, stack) {
      loge('PrecomputeKlineData exception!!!', error: e, stackTrace: stack);
      return data;
    } finally {
      watchPrecompute.stop();
      logd('PrecomputeKlineData End:${DateTime.now()}');
      logi('PrecomputeKlineData spent:${watchPrecompute.elapsedMicroseconds}');
    }
  }

  /// 开始加载[req]请求指定的蜡烛数据
  /// [req] 标记当前请求
  /// [useCacheFirst] 优先使用缓存. 注: 如果有缓存数据(说明之前加载过), loading不会展示.
  /// return
  ///   1. false:代表使用了缓存, 不会展示loading了
  ///   2. true: 代表已展示loading; 未使用缓存; 且当前KlineData数据被清空(如果有).
  @override
  bool startLoading(
    CandleReq req, {
    bool useCacheFirst = true,
  }) {
    KlineData? data = _klineDataCache[req.key];

    if (useCacheFirst && data != null && !data.isEmpty) {
      // 如果优先使用缓存且缓存数据不为空时, 设置缓存为当前KlineData, 同时结束loading状态.
      setCurKlineData(data);
      loadingListener.value = false;
      return false;
    }

    // 清理历史缓存数据.
    data?.dispose();

    // 重置当前KlineData为[req]请求指定的KlineData, 并更新到缓存中, 同时展示loading状态.
    loadingListener.value = true;
    data = KlineData(req.copyWith(), logger: loggerDelegate);
    _klineDataCache[req.key] = data;
    _curKlineData = data;
    timeBarListener.value = data.timeBar;
    return true;
  }

  /// 结束加载中状态
  /// [force] 使终结束加载
  /// [req] 如果指定, 且与当前正常加载的蜡烛请求一致, 才结束加载中状态
  @override
  void stopLoading(CandleReq request, {bool force = false}) {
    if (force || request.key == curDataKey) {
      loadingListener.value = false;
    }
  }

  /// 更新KlineData
  @override
  Future<void> updateKlineData(
    CandleReq request,
    List<CandleModel> list,
  ) async {
    // 数据为空, 无需要更新.
    if (list.isEmpty) return;

    final req = request.copyWith();

    KlineData? data = _klineDataCache[req.key];
    bool reset = data == null || data.isEmpty;
    final oldLen = data?.length ?? 0;

    data ??= KlineData(req, logger: loggerDelegate);

    data = await _startPrecomputeKlineData(
      data,
      newList: list,
      reset: reset,
    );

    _klineDataCache[req.key] = data;

    if (req.key == curDataKey) {
      if (reset) {
        setCurKlineData(data);
      } else {
        final newLen = data.length;
        if (paintDxOffset < 0 && newLen > oldLen) {
          /// 当数据合并后
          /// 1. 如果paintDxOffset > 0 说明满足一屏, 且最新蜡烛被用户移动到绘制区域外面, 无需调整偏移量paintDxOffset, 重绘时, 仍按此偏移量计算后, 当前首根蜡烛向左移动一个蜡烛.
          /// 2. 如果paintDxOffset == 0 说明当前最新蜡烛在屏幕第一位(最右边)展示. 无需调整偏移量paintDxOffset, 重绘时calculateCandleIndexAndOffset, 会计算startIndex = 0;
          /// 2. 如果paintDxOffset < 0 说明未满足一屏, 需要减小偏移量, 以保证新数据能够展示.
          ///    注: 如果调整后 paintDxOffset > 0 则要置为0, 以保证最新蜡烛在最右边展示.
          paintDxOffset = math.min(
            0,
            paintDxOffset + (newLen - oldLen) * candleActualWidth,
          );
        }

        markRepaintChart();
      }
    }
  }

  @override
  void handleMove(GestureData data) {
    super.handleMove(data);
    if (!data.moved) return;

    final newDxOffset = clampPaintDxOffset(paintDxOffset + data.dxDelta);
    if (newDxOffset != paintDxOffset) {
      paintDxOffset = newDxOffset;
      markRepaintChart();
    }
  }

  @override
  void handleScale(GestureData data) {
    super.handleScale(data);
    if (!data.scaled) return;

    final index = offsetToIndex(data.offset);
    final dxGrowth = data.scaleDelta * 10;
    final newWidth = (candleWidth + dxGrowth).clamp(1.0, candleMaxWidth);
    final newDxOffset = clampPaintDxOffset(
      paintDxOffset + dxGrowth * index,
    );
    logd(
      '>scale growth:$dxGrowth candleWidth:$candleWidth > newWidth:$newWidth, newDxOffset:$newDxOffset',
    );
    if (newWidth != candleWidth || newDxOffset != paintDxOffset) {
      candleWidth = newWidth;
      paintDxOffset = newDxOffset;
      markRepaintChart();
    }
  }

  @override
  void handleLongMove(GestureData data) {
    super.handleLongMove(data);
    if (!data.moved) return;
  }
}
