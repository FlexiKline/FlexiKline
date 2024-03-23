import 'package:decimal/decimal.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'candle.dart';
import 'price_order.dart';
import 'setting.dart';

abstract interface class IDataSource {
  void setCandleData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  });

  void appendCandleData(CandleReq req, List<CandleModel> list);
}

abstract interface class IDataScope {
  void moveCandle(int leftTs, int rightTs);
}

mixin DataSourceBinding
    on KlineBindingBase, SettingBinding
    implements IDataSource, IDataScope, IPriceOrder, ICandlePainter {
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
  CandleData get curCandleData => _curCandleData;
  set curCandleData(val) {
    /// TODO 预处理数据
    _curCandleData = val;
  }

  String get curDataKey => curCandleData.key;

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
  void moveCandle(int leftTs, int rightTs) {
    // 计算leftTs与rightTs在curCandleData的下标. 更新repaintCandle
  }
}
