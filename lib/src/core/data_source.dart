import 'dart:math' as math;

import '../model/export.dart';
import 'binding_base.dart';
import 'candle_data.dart';
import 'interface.dart';
import 'setting.dart';

/// 负责数据的管理, 缓存, 切换, 计算
mixin DataSourceBinding
    on KlineBindingBase, SettingBinding
    implements IDataSource, ICandlePainter {
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

  /// 数据缓存Key
  String get curDataKey => curCandleData.key;

  /// 最大绘制宽度
  double get maxPaintWidth => curCandleData.list.length * candleActualWidth;

  /// 当前蜡烛数是否足够绘制一屏
  bool get isCanDrawAllCandlesInCanvas => maxPaintWidth <= canvasWidth;

  @override
  double get dyFactor {
    return canvasHeight / curCandleData.dataHeight.toDouble();
  }

  /// 代表当前绘制区域内部X轴的移到偏移量. 必须大于0
  /// 此变量仅限于当前蜡烛数小于一屏绘制时
  /// 注: 滑动/缩放都主要通过调整其值.
  /// maxPaintWidth - _paintDxOffset 就是X轴起始的绘制点.
  double _startDxOffset = 0;
  double get startDxOffset => _startDxOffset;
  set startDxOffset(double val) {
    _startDxOffset = math.max(val, 0.0);
  }

  /// 代表当前绘制区域外部X轴的移动偏移量. 必须大于0.
  /// 此变量仅限于当前蜡烛数大于一屏绘制时
  /// 注: 滑动/缩放都主要通过调整其值.
  /// maxPaintWidth - _paintDxOffset 就是X轴起始的绘制点.
  double _paintDxOffset = 0;
  @override
  double get paintDxOffset => _paintDxOffset;
  set paintDxOffset(double val) {
    _paintDxOffset = math.max(0.0, val);
  }

  /// 计算绘制蜡烛图的起始数组索引下标和绘制偏移量
  @override
  void calculateCandleIndexAndOffset() {
    logd(
      'calculateCandleIndexAndPaintOffset needless! $maxPaintWidth <= $canvasWidth',
    );
    if (isCanDrawAllCandlesInCanvas) {
      // 不足一屏
      final startIndex = (startDxOffset / candleActualWidth).floor();
      final dxOffset = startDxOffset % candleActualWidth;
      curCandleData.ensureIndexAndOffset(
        startIndex,
        dxOffset,
        maxCandleCount: maxCandleCount,
      );
      curCandleData.calculateMaxmin();
    } else {
      final startIndex = (paintDxOffset / candleActualWidth).floor();
      final dxOffset = paintDxOffset % candleActualWidth;
      curCandleData.ensureIndexAndOffset(
        startIndex,
        dxOffset,
        maxCandleCount: maxCandleCount,
      );
      curCandleData.calculateMaxmin();
    }
  }

  @override
  void setCandleData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  }) {
    CandleData? data = _candleDataCache[req.key];
    if (data == null) {
      data = CandleData(req, List.of(list));
    } else {
      data.mergeCandleList(list, replace: replace);
    }
    _candleDataCache[req.key] = data;
    if (curCandleData.invalid || req.key == curDataKey) {
      _curCandleData = data;
      markRepaintCandle();
    }
  }

  @override
  void appendCandleData(CandleReq req, List<CandleModel> list) {
    CandleData? data = _candleDataCache[req.key];
    if (data == null) {
      data = CandleData(req, List.of(list));
    } else {
      data.mergeCandleList(list);
    }
    _candleDataCache[req.key] = data;
    if (req.key == curDataKey) {
      markRepaintCandle();
    }
  }

  @override
  void handleMove(GestureData data) {
    super.handleScale(data);
    if (!data.moved) return;
    // logd('${DateTime.now()} move $paintDxOffset dxDelta:${data.dxDelta}');
    if (isCanDrawAllCandlesInCanvas) {
      paintDxOffset = 0;
      // 不足一屏, 调整绘制区域内部的偏移量:data.offset
      final newStartDxOffset = (startDxOffset + data.dxDelta).clamp(
        canvasWidth - minPaintWidthInCanvas,
        0.0,
      );
      if (newStartDxOffset != startDxOffset) {
        startDxOffset = newStartDxOffset;
        markRepaintCandle();
      }
    } else {
      startDxOffset = 0;
      // 满足一屏, 调整绘制区域外部的偏移量:paintDxOffset
      final newDxOffset = (paintDxOffset + data.dxDelta).clamp(
        0.0,
        maxPaintWidth - minPaintWidthInCanvas,
      );
      if (newDxOffset != paintDxOffset) {
        paintDxOffset = newDxOffset;
        markRepaintCandle();
      }
    }
  }

  @override
  void handleScale(GestureData data) {
    super.handleScale(data);
    if (!data.scaled) return;
  }

  @override
  void handleLongMove(GestureData data) {
    super.handleScale(data);
    if (!data.moved) return;
  }
}
