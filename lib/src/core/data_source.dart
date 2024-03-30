import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'candle_data.dart';
import 'interface.dart';
import 'setting.dart';

/// 负责数据的管理, 缓存, 切换, 计算
mixin DataSourceBinding
    on KlineBindingBase, SettingBinding
    implements IDataSource, ICandlePainter, IPriceCrossPainter {
  @override
  void initBinding() {
    super.initBinding();
    logd('init dataSource');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose dataSource');
  }

  final Map<String, CandleData> _candleDataCache = {};

  CandleData _curCandleData = CandleData.empty;
  @override
  CandleData get curCandleData => _curCandleData;

  /// 蜡烛总数
  @override
  int get totalCandleCount => curCandleData.list.length;

  /// 数据缓存Key
  String get curDataKey => curCandleData.key;

  /// 最大绘制宽度
  @override
  double get maxPaintWidth => curCandleData.list.length * candleActualWidth;

  /// 当前canvas绘制区域第一根蜡烛绘制的偏移量
  /// canvas绘制区右起始位置 - 当前第一根蜡烛在的起始偏移 - 半根蜡烛值
  /// 用于绘制蜡烛图计算的起始位置.
  @override
  double get startCandleDx {
    return canvasRight + curCandleData.offset + candleWidthHalf;
  }

  /// 将offset指定的dx转换为蜡烛index.
  @override
  int offsetToIndex(Offset offset) {
    final rightOffset = canvasRight - offset.dx;
    // logd('dxToIndex paintDxOffset:$paintDxOffset, rightOffset:$rightOffset');
    return ((paintDxOffset + rightOffset) / candleActualWidth).round();
  }

  /// 绘制区域高度 / 当前绘制的蜡烛数据高度.
  @override
  double get dyFactor {
    return canvasHeight / curCandleData.dataHeight.toDouble();
  }

  /// 代表当前绘制区域相对于startIndex的偏移量.
  /// 取值范围 [-canvasWidth, maxPaintWidth - minPaintWidthInCanvas]
  /// 1. 当为零时(默认) : 说明首根蜡烛在Canvas最右边展示.
  /// 2. 当为负数时     : 代表首根蜡烛到Canvas右部的距离
  /// 3. 当为正数时     : 说明有部分蜡烛已向右移出Canvas.
  ///     移出数量 = (paintDxOffset / candleActualWidth).floor()
  ///     移出Offset = paintDxOffset % candleActualWidth;
  double _paintDxOffset = 0;
  @override
  double get paintDxOffset => _paintDxOffset;
  set paintDxOffset(double val) {
    _paintDxOffset = clampPaintDxOffset(val);
  }

  /// 画布是否可以从右向左进行平移.
  @override
  bool get canPanRTL => paintDxOffset > 0;

  /// 画布是否可以从左向右进行平移.
  @override
  bool get canPanLTR {
    // 蜡烛数据最大可绘制长度 - 移动画面的长度 + 最小留白区域长度 = 剩余可以移动的区域长度.
    // 如果大于当前画布宽度, 即是可以从左向右平移的.
    return maxPaintWidth - paintDxOffset + minPaintBlankWidth > canvasWidth;
  }

  /// 矫正PaintDxOffset的范围
  double clampPaintDxOffset(double dxOffset) {
    if (minPaintBlandUseWidth) {
      if (maxPaintWidth < canvasWidth) {
        // 不足一屏: 按最少留白的宽度精确计算
        final min = math.min(minPaintBlankWidth, maxPaintWidth) - canvasWidth;
        final max = maxPaintWidth - minPaintBlankWidth;
        return math.min(math.max(min, dxOffset), max);
      } else {
        // 满足一屏: 按最少留白的宽度精确计算
        final min = -minPaintBlankWidth;
        final max = maxPaintWidth + minPaintBlankWidth - canvasWidth;
        return math.min(math.max(min, dxOffset), max);
      }
    } else {
      int dataLen = curCandleData.list.length;
      if (dataLen < maxCandleCount) {
        // 不足一屏: 按最少留白的蜡烛数来计算
        final min =
            math.min(minPaintBlankCandleCount, dataLen) * candleActualWidth -
                canvasWidth;
        final max = (dataLen - minPaintBlankCandleCount) * candleActualWidth;

        return math.min(math.max(min, dxOffset), max);
      } else {
        // 满足一屏: 按最少留白的蜡烛数来计算
        final min = -minPaintBlankCandleCount * candleActualWidth;
        final max = (dataLen + minPaintBlankCandleCount - maxCandleCount) *
            candleActualWidth;
        // maxPaintWidth - minPaintBlankCandleCount  * candleActualWidth;
        return math.min(math.max(min, dxOffset), max);
      }
    }
  }

  void initPaintDxOffset() {
    if (maxPaintWidth >= canvasWidth) {
      // 当前蜡烛数足够绘制一屏
      paintDxOffset = 0;
    } else {
      // 不足一屏
      paintDxOffset = maxPaintWidth - canvasWidth;
    }
  }

  /// 计算绘制蜡烛图的起始数组索引下标和绘制偏移量
  @override
  void calculateCandleIndexAndOffset() {
    // logd(
    //   'calculateCandleIndexAndOffset begin paintDxOffset:$paintDxOffset in [${-canvasWidth}, ${maxPaintWidth - minPaintBlankWidth}]',
    // );

    if (paintDxOffset > 0) {
      final startIndex = (paintDxOffset / candleActualWidth).floor();
      final dxOffset = paintDxOffset % candleActualWidth;
      curCandleData.ensureIndexAndOffset(
        startIndex,
        dxOffset,
        maxCandleCount: maxCandleCount,
      );
    } else {
      curCandleData.ensureIndexAndOffset(
        0,
        paintDxOffset,
        maxCandleCount: maxCandleCount,
      );
    }

    // logd(
    //   'calculateCandleIndexAndOffset end paintDxOffset:$paintDxOffset in [${-canvasWidth}, ${maxPaintWidth - minPaintBlankWidth}]',
    // );
    curCandleData.calculateMaxmin();
  }

  @override
  void setCandleData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  }) {
    CandleData? data = _candleDataCache[req.key];
    if (data != null) {
      paintDxOffset = 0;
      data.reset();
    }
    data = CandleData(req, List.of(list));
    _candleDataCache[req.key] = data;
    if (curCandleData.invalid || req.key == curDataKey) {
      _curCandleData = data;
      initPaintDxOffset();
      markRepaintCandle();
    }
  }

  @override
  void appendCandleData(CandleReq req, List<CandleModel> list) {
    CandleData? data = _candleDataCache[req.key];
    if (data == null || data.list.isEmpty) {
      logd('appendCandleData >setCandleData(${req.key}, ${data?.list.length})');
      setCandleData(req, list);
      return;
    }

    int oldLen = data.list.length;
    data.mergeCandleList(list);
    _candleDataCache[req.key] = data;
    if (req.key == curDataKey) {
      if (paintDxOffset <= 0) {
        /// 当数据合并后
        /// 1. 如果paintDxOffset > 0 说明满足一屏, 且最蜡烛被用户移动到绘制区域外面, 无需要更新绘制偏移量paintDxOffset
        /// 2. 如果paintDxOffset <= 0 说明未满足一屏, 或当前最新蜡烛在屏幕第一位(最右边)展示, 需要减小偏移量, 以保证新数据能够展示.
        ///    注: 如果调整后 paintDxOffset > 0 则要置为0, 以保证最新蜡烛在最右边展示.
        paintDxOffset = math.min(
          0,
          paintDxOffset + (data.list.length - oldLen) * candleActualWidth,
        );
      }

      markRepaintCandle();
    }
  }

  @override
  void handleMove(GestureData data) {
    super.handleMove(data);
    if (!data.moved) return;

    final newDxOffset = clampPaintDxOffset(paintDxOffset + data.dxDelta);
    if (newDxOffset != paintDxOffset) {
      paintDxOffset = newDxOffset;
      markRepaintCandle();

      // TODO: 是否要将最新价移回 Candle 模块中绘制 ???
      markRepaintLastPrice();
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
      markRepaintCandle();
    }
  }

  @override
  void handleLongMove(GestureData data) {
    super.handleLongMove(data);
    if (!data.moved) return;
  }
}
