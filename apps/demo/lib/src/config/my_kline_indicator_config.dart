import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';

import 'my_kline_interval.dart';
import 'my_kline_storage.dart';

/// 内置蜡烛 + 时间轴指标配置，不引入 flexi_kline_indicators。
class MyKlineIndicatorConfig extends MyKlineStorage with ChangeNotifier implements IIndicatorConfig {
  @override
  String cacheKey(String key) => key;

  final CandleIndicator _candle = CandleIndicator(
    intervalChartTypes: {MyKlineInterval.line: FlexiChartType.lineNormal},
  );

  final TimeIndicator _time = TimeIndicator(position: DrawPosition.bottom);

  @override
  CandleIndicator get candle => _candle;

  @override
  TimeIndicator get time => _time;

  @override
  List<Indicator> get mainIndicators => const [];

  @override
  List<Indicator> get subIndicators => const [];
}
