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
  // set curCandleData(val) {
  //   /// TODO 预处理数据
  //   _curCandleData = val;
  // }

  /// 数据缓存Key
  String get curDataKey => curCandleData.key;

  /// 最大绘制宽度
  double get maxPaintWidth => curCandleData.list.length * candleActualWidth;

  @override
  double get dyFactor {
    return canvasHeight / curCandleData.dataHeight.toDouble();
  }

  /// 当前start蜡烛X轴偏移量.
  double startDxOffset = 0;

  /// 当前画板绘制的X轴偏移量. 注: 滑动/缩放都主要通过调整其值.
  double paintDxOffset = 0;

  /// 计算startDx和endDx偏移. 根据dxOffset.
  void calculateStartDxByCanvasDxOffset() {
    if (maxPaintWidth <= canvasWidth) {
      logd('');
      return;
    }
  }

  /// 计算蜡烛数组的start和end下标.
  void calculateStartEndIndex() {
    if (maxPaintWidth <= canvasWidth) {
      logd('calculateStartEndIndex needless! $maxPaintWidth <= $canvasWidth');
      return;
    }
    final startIndex = (paintDxOffset / candleActualWidth).floor();
    final startDx = paintDxOffset % candleActualWidth;

    curCandleData.start += startIndex;
  }

  @override
  void setCandleData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  }) {
    final data = _candleDataCache[req.key] ?? CandleData(req, List.of(list));
    data.mergeCandleList(list, replace: replace);
    _candleDataCache[req.key] = data;
    if (curCandleData.invalid || req.key == curDataKey) {
      _curCandleData = data;
      markRepaintCandle();
      // _calculateCandleDataDrawParams(reset: true);
      startLastPriceCountDownTimer();
    }
  }

  @override
  void appendCandleData(CandleReq req, List<CandleModel> list) {
    final data = _candleDataCache[req.key] ?? CandleData(req, List.of(list));
    data.mergeCandleList(list);
    _candleDataCache[req.key] = data;
    if (req.key == curDataKey) {
      markRepaintCandle();
      // _calculateCandleDataDrawParams();
    }
  }

  /// 计算绘制所需要的参数.
  // void _calculateCandleDataDrawParams({
  //   bool reset = false, // 是否从头开始绘制.
  // }) {
  //   if (reset) curCandleData.reset();
  //   curCandleData.calculateDrawParams(
  //     maxCandleCount,
  //     candleActualWidth,
  //     canvasWidth, // 暂无用
  //   );

  //   markRepaintCandle();
  // }

  @override
  void handleMove(GestureData data) {
    super.handleScale(data);
    if (!data.moved) return;
    final dxDelta = data.dxDelta;
    final dyDelta = data.dyDelta;
    paintDxOffset += dxDelta;
    logd(
      '${DateTime.now()} move $paintDxOffset dxDelta:$dxDelta, dyDelta:$dyDelta',
    );

    // calculateStartEndIndex();
    // curCandleData.calculateIndex(
    //   paintDxOffset,
    //   candleActualWidth,
    // );
    // curCandleData.calculateMaxmin();
    // markRepaintCandle();

    /// 处理X轴移动
    // final distance = dxDelta * 3; // 放大3倍.
    // if (distance.abs().ceil() < candleWidth) {
    //   logd('move small offset!');
    //   return;
    // }
    // final count = (distance / candleActualWidth).ceil();
    // final ret = curCandleData.moveCandle(
    //   count,
    //   maxCandleCount: maxCandleCount,
    // );
    // if (ret) {
    //   markRepaintCandle();
    // }
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
