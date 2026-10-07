import 'package:flexi_kline/flexi_kline.dart';

import 'my_kline_interval.dart';
import 'my_kline_storage.dart';

/// 内置蜡烛 + 时间轴指标配置，不引入 flexi_kline_indicators。
///
/// 继承框架 [BaseIndicatorConfig]（提供可监听 + 可释放 + 指标契约），
/// 混入 [MyKlineStorageMixin]（提供进程内存储）。
class MyKlineIndicatorConfig extends BaseIndicatorConfig with MyKlineStorageMixin {
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
