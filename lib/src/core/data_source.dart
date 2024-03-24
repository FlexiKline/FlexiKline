import 'package:decimal/decimal.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'candle.dart';
import 'candle_data.dart';
import 'interface.dart';
import 'setting.dart';

mixin DataSourceBinding
    on KlineBindingBase, SettingBinding
    implements
        IDataSource,
        IPriceOrder,
        ICandlePainter,
        IGestureData,
        IDataConvert {
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

  String get curDataKey => curCandleData.key;

  /// 画板的最大宽度
  double get maxCanvasWidth => curCandleData.list.length * candleActualWidth;


  @override
  double get dyFactor {
    return canvasHeight / curCandleData.dataHeight.toDouble();
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

  /// 价钱格式化函数
  /// TODO: 待数据格式化.
  @override
  String formatPrice(Decimal val, {int? precision}) {
    int p = precision ?? 6; // TODO: 待优化
    if (priceFormat != null) {
      return priceFormat!.call(
        curCandleData.req.instId,
        val,
        precision: p,
      );
    }
    return val.toStringAsFixed(p);
  }

  /// 计算时间差, 并格式化展示
  /// 1. 超过1天展示 "md nh"
  /// 2. 小于一天展示 "hh:MM:ss"
  /// 3. 小天一小时展示 "MM:ss"
  @override
  String? calculateTimeDiff(DateTime nextUpdateDateTime) {
    final timeLag = nextUpdateDateTime.difference(DateTime.now());
    if (timeLag.isNegative) {
      logd(
        'calculateTimeDiff > next:$nextUpdateDateTime - now:${DateTime.now()} = $timeLag',
      );
      return null;
    }

    final dayLag = timeLag.inDays;
    if (dayLag >= 1) {
      final hoursLag = (timeLag.inHours - dayLag * 24).clamp(0, 23);
      return '${dayLag}h ${hoursLag}h';
    } else {
      return timeLag.toString().substring(0, 8);
    }
  }

  @override
  void move(GestureData data) {
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
  void scale(GestureData data) {
    if (!data.scaled) return;
  }

  @override
  void longMove(GestureData data) {
    if (!data.moved) return;
  }
}
