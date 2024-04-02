import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../extension/export.dart';
import '../model/export.dart';
import 'binding_base.dart';
import 'data.dart';
import 'interface.dart';
import 'setting.dart';

/// 状态管理: 负责数据的管理, 缓存, 切换, 计算
mixin StateBinding
    on KlineBindingBase, SettingBinding
    implements IState, ICandle, ICross {
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

  final Map<String, KlineData> _klineDataCache = {};

  KlineData _curKlineData = KlineData.empty;
  @override
  KlineData get curKlineData => _curKlineData;

  /// 蜡烛总数
  @override
  int get totalCandleCount => curKlineData.list.length;

  /// 数据缓存Key
  String get curDataKey => curKlineData.key;

  /// 最大绘制宽度
  @override
  double get maxPaintWidth => curKlineData.list.length * candleActualWidth;

  /// 当前canvas绘制区域第一根蜡烛绘制的偏移量
  /// canvas绘制区右起始位置 - 当前第一根蜡烛在的起始偏移 - 半根蜡烛值
  /// 用于绘制蜡烛图计算的起始位置.
  @override
  double get startCandleDx {
    return mainDrawRight + curKlineData.offset - candleWidthHalf;
  }

  /// 将offset指定的dx转换为当前绘制区域对应的蜡烛的下标.
  @override
  int offsetToIndex(Offset offset) => dxToIndex(offset.dx);

  @override
  int dxToIndex(double dx) {
    // final rightOffset = mainDrawRight - dx;
    // return ((paintDxOffset + rightOffset) / candleActualWidth).floor();

    final index = ((startCandleDx - dx) / candleActualWidth).ceil();
    return curKlineData.start + index;
  }

  /// 将offset指定的dy转换为当前坐标Y轴中价钱.
  @override
  Decimal? offsetToPrice(Offset offset) => dyToPrice(offset.dy);

  @override
  Decimal? dyToPrice(double dy) {
    if (!mainDrawRect.inclueDy(dy)) return null;
    return curKlineData.max - ((dy - mainPadding.top) / dyFactor).d;
  }

  /// 将价钱转换为主图(蜡烛图)的Y轴坐标.
  @override
  double priceToDy(Decimal price) {
    price = price.clamp(curKlineData.min, curKlineData.max);
    return mainDrawBottom - (price - curKlineData.min).toDouble() * dyFactor;
  }

  /// 绘制区域高度 / 当前绘制的蜡烛数据高度.
  @override
  double get dyFactor {
    return mainDrawHeight / curKlineData.dataHeight.toDouble();
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
    return maxPaintWidth - paintDxOffset + minPaintBlankWidth > mainDrawWidth;
  }

  /// 矫正PaintDxOffset的范围
  double clampPaintDxOffset(double dxOffset) {
    if (minPaintBlankUseWidth) {
      if (maxPaintWidth < mainDrawWidth) {
        // 不足一屏: 按最少留白的宽度精确计算
        final min = math.min(minPaintBlankWidth, maxPaintWidth) - mainDrawWidth;
        // 如果为0时, 首根蜡烛可平移到MainRect绘制区域右边.
        final max = maxPaintWidth - minPaintBlankWidth;
        return math.min(math.max(min, dxOffset), max);
      } else {
        // 满足一屏: 按最少留白的宽度精确计算
        final min = -minPaintBlankWidth;
        final max = maxPaintWidth + minPaintBlankWidth - mainDrawWidth;
        return math.min(math.max(min, dxOffset), max);
      }
    } else {
      // TODO: 待优化.
      int dataLen = curKlineData.list.length;
      if (dataLen < maxCandleCount) {
        // 不足一屏: 按最少留白的蜡烛数来计算
        final min =
            math.min(minPaintBlankCandleCount, dataLen) * candleActualWidth -
                mainDrawWidth;
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
    paintDxOffset = math.min(
      maxPaintWidth - mainDrawWidth, // 不足一屏, 首根蜡烛偏移量等于首根蜡烛右边长度.
      -firstCandleInitOffset, // 满足一屏时, 首根蜡烛相对于主绘制区域最小的偏移量
    );
  }

  /// 计算绘制蜡烛图的起始数组索引下标和绘制偏移量
  @override
  void calculateCandleIndexAndOffset() {
    final dxOffsetIndex = (paintDxOffset / candleActualWidth).floor();
    if (paintDxOffset > 0) {
      final dxOffset = paintDxOffset % candleActualWidth;
      final maxCount = ((mainDrawWidth + dxOffset) / candleActualWidth).ceil();
      curKlineData.ensureIndexAndOffset(
        dxOffsetIndex,
        dxOffset,
        maxCandleCount: maxCount,
      );
    } else {
      // final maxCount = maxCandleCount; // 取一屏蜡烛数据来计算最大最小
      final maxCount = maxCandleCount - dxOffsetIndex.abs(); // 取当前可见蜡烛来计算最大最小
      curKlineData.ensureIndexAndOffset(
        0,
        paintDxOffset,
        maxCandleCount: maxCount,
      );
    }

    curKlineData.calculateMaxmin();
  }

  @override
  void setKlineData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  }) {
    KlineData? data = _klineDataCache[req.key];
    if (data != null) {
      paintDxOffset = 0;
      data.reset();
    }
    data = KlineData(req, List.of(list), debug: debug);
    _klineDataCache[req.key] = data;
    if (curKlineData.invalid || req.key == curDataKey) {
      _curKlineData = data;
      initPaintDxOffset();
      markRepaintCandle();
    }
  }

  @override
  void appendKlineData(CandleReq req, List<CandleModel> list) {
    KlineData? data = _klineDataCache[req.key];
    if (data == null || data.list.isEmpty) {
      logd('appendKlineData >setKlineData(${req.key}, ${data?.list.length})');
      setKlineData(req, list);
      return;
    }

    final oldLen = data.list.length;
    data.mergeCandleList(list);
    _klineDataCache[req.key] = data;
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
