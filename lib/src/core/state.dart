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

import '../data/export.dart';
import '../extension/export.dart';
import '../framework/indicator.dart';
import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 状态管理: 负责数据的管理, 缓存, 切换, 计算
mixin StateBinding
    on KlineBindingBase, SettingBinding
    implements IState, IChart, ICross, IConfig {
  @override
  void initState() {
    super.initState();
    logd('initState state');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose state');
    _klineDataCache.forEach((key, data) {
      data.dispose();
    });
    _klineDataCache.clear();
  }

  final Map<String, KlineData> _klineDataCache = {};
  KlineData _curKlineData = KlineData.empty;
  @override
  KlineData get curKlineData => _curKlineData;
  set curKlineData(data) {
    _curKlineData = data;
    initPaintDxOffset();
    markRepaintChart();
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
    final dxPaintOffset = (mainDrawRight - dx) + paintDxOffset;
    // final diff = dxPaintOffset % candleActualWidth;
    return (dxPaintOffset / candleActualWidth).floor();
  }

  /// 将index转换为当前绘制区域对应的X轴坐标. 如果超出范围, 则返回null.
  @override
  double? indexToDx(int index) {
    double dx = mainDrawRight - (index * candleActualWidth - paintDxOffset);
    if (mainDrawRect.inclueDx(dx)) return dx;
    return null;
  }

  /// 当前canvas绘制区域起始蜡烛右部dx值.
  @override
  double get startCandleDx {
    if (paintDxOffset == 0) {
      return 0;
    } else if (paintDxOffset > 0) {
      return mainDrawRight + paintDxOffset % candleActualWidth;
    } else {
      return mainDrawRight + paintDxOffset;
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
      maxPaintWidth - mainDrawWidth,
      -minPaintBlankWidth,
    );
  }

  /// PaintDxOffset的最大值
  double get maxPaintDxOffset {
    return maxPaintWidth - (mainDrawWidth - minPaintBlankWidth);
  }

  /// 矫正PaintDxOffset的范围
  double clampPaintDxOffset(double dxOffset) {
    return dxOffset.clamp(minPaintDxOffset, maxPaintDxOffset);
  }

  void initPaintDxOffset() {
    paintDxOffset = math.min(
      maxPaintWidth - mainDrawWidth, // 不足一屏, 首根蜡烛偏移量等于首根蜡烛右边长度.
      -firstCandleInitOffset, // 满足一屏时, 首根蜡烛相对于主绘制区域最小的偏移量
    );
  }

  /// 计算绘制蜡烛图的起始数组索引下标
  @override
  void calculateCandleDrawIndex() {
    if (paintDxOffset > 0) {
      final startIndex = (paintDxOffset / candleActualWidth).floor();
      final diff = paintDxOffset % candleActualWidth;
      final maxCount = ((mainDrawWidth + diff) / candleActualWidth).round();
      curKlineData.ensureStartAndEndIndex(
        startIndex,
        maxCount,
      );
    } else {
      int maxCount;
      if (alwaysCalculateScreenOfCandlesIfEnough) {
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

  void preprocessIndicatorData(KlineData data, {bool reset = false}) {
    if (data.isEmpty) return;

    const start = 0;
    final end = data.length;

    final startTime = DateTime.now();
    logd('preprocessIndicatorData start at $startTime');

    for (var child in mainIndicator.children) {
      data.preprocess(child, start: start, end: end, reset: reset);
    }

    for (var indicator in subIndicators) {
      if (indicator is MultiPaintObjectIndicator) {
        for (var child in indicator.children) {
          data.preprocess(child, start: start, end: end, reset: reset);
        }
      } else {
        data.preprocess(indicator, start: start, end: end, reset: reset);
      }
    }
    logd(
      'preprocessIndicatorData completed!!! Total time spent ${DateTime.now().difference(startTime).inMicroseconds} milliseconds',
    );
  }

  /// 起动loading
  /// req: 标记当前请求
  /// return: 返回false代表使用了缓存, 不展示loading了
  bool startLoading(
    CandleReq req, {
    bool useCacheFirst = false,
  }) {
    KlineData? data = _klineDataCache[req.key];
    if (useCacheFirst && data != null && !data.isEmpty) {
      curKlineData = data;
      onLoading?.call(false);
      return false;
    }
    curKlineData = KlineData(req);
    onLoading?.call(true);
    return true;
  }

  void stopLoading() => onLoading?.call(false);

  @override
  void setKlineData(CandleReq req, List<CandleModel> list) {
    // TODO: 校验数据合法性.
    req = req.copyWith();
    KlineData? data = _klineDataCache[req.key];
    if (data != null && !data.isEmpty) {
      data.dispose();
    }
    data = KlineData(req, list: List.of(list), logger: loggerDelegate);
    _klineDataCache[req.key] = data;
    preprocessIndicatorData(data, reset: true);
    if (curKlineData.invalid || req.key == curDataKey) {
      curKlineData = data;
    }
  }

  @override
  void appendKlineData(CandleReq req, List<CandleModel> list) {
    KlineData? data = _klineDataCache[req.key];
    if (data == null || data.list.isEmpty) {
      logd('appendKlineData > setKlineData(${req.key}, ${data?.list.length})');
      setKlineData(req, list);
      return;
    }

    final oldLen = data.list.length;
    data.mergeCandleList(list);
    _klineDataCache[req.key] = data;
    preprocessIndicatorData(data, reset: false);
    if (req.key == curDataKey) {
      final newLen = data.list.length;
      if (paintDxOffset < 0 && newLen > oldLen) {
        /// 当数据合并后
        /// 1. 如果paintDxOffset > 0 说明满足一屏, 且最蜡烛被用户移动到绘制区域外面, 无需调整偏移量paintDxOffset, 重绘时, 仍按此偏移量计算后, 当前首根蜡烛向左移动一个蜡烛.
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
