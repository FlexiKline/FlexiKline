import '../model/export.dart';
import 'binding_base.dart';
import 'candle_data.dart';
import 'interface.dart';
import 'setting.dart';

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
  set curCandleData(val) {
    /// TODO 预处理数据
    _curCandleData = val;
  }

  /// 数据缓存Key
  String get curDataKey => curCandleData.key;

  /// 画板的最大宽度
  double get maxCanvasWidth => curCandleData.list.length * candleActualWidth;

  /// 当前画板绘制的X轴偏移量. 注: 滑动/缩放都主要通过调整其值.
  double dxOffset = 0;

  @override
  double get dyFactor {
    return canvasHeight / curCandleData.dataHeight.toDouble();
  }

  /// 计算startDx和endDx偏移. 根据dxOffset.
  void calculateStartEndDx() {}

  /// 计算蜡烛数组的start和end下标.
  void calculateStartEndIndex() {}

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
      curCandleData = data;
      _calculateCandleDataDrawParams(reset: true);
      startLastPriceCountDownTimer();
    }
  }

  @override
  void appendCandleData(CandleReq req, List<CandleModel> list) {
    final data = _candleDataCache[req.key] ?? CandleData(req, List.of(list));
    data.mergeCandleList(list);
    _candleDataCache[req.key] = data;
    if (req.key == curDataKey) {
      _calculateCandleDataDrawParams();
      checkAndRestartLastPriceCountDownTimer();
    }
  }

  /// 计算绘制所需要的参数.
  void _calculateCandleDataDrawParams({
    bool reset = false, // 是否从头开始绘制.
  }) {
    if (reset) curCandleData.reset();
    curCandleData.calculateDrawParams(
      maxCandleCount,
      candleActualWidth,
      canvasWidth, // 暂无用
    );

    markRepaintCandle();
  }

  @override
  void handleMove(GestureData data) {
    super.handleScale(data);
    if (!data.moved) return;
    final dxDelta = data.dxDelta;
    final dyDelta = data.dyDelta;
    logd('move dxDelta:$dxDelta, dyDelta:$dyDelta');

    /// 处理X轴移动
    final distance = dxDelta * 3; // 放大3倍.
    if (distance.abs().ceil() < candleWidth) {
      logd('move small offset!');
      return;
    }
    final count = (distance / candleActualWidth).ceil();
    final ret = curCandleData.moveCandle(
      count,
      maxCandleCount: maxCandleCount,
    );
    if (ret) {
      markRepaintCandle();
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
