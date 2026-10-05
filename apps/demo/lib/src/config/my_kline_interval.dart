import 'package:flexi_formatter/date_time.dart';
import 'package:flexi_kline/flexi_kline.dart';

/// 五档 K 线周期，每档对应一份独立 mock 数据，multiplier/unit 决定蜡烛时间跨度。
enum MyKlineInterval implements ITimeInterval {
  line(1, TimeUnit.minute, '分时'),
  minute15(15, TimeUnit.minute, '15分'),
  hour1(1, TimeUnit.hour, '1时'),
  day1(1, TimeUnit.day, '1天'),
  week1(1, TimeUnit.week, '1周');

  const MyKlineInterval(this.multiplier, this.unit, this.label);

  @override
  final int multiplier;

  @override
  final TimeUnit unit;

  /// 周期切换栏展示标签。
  final String label;

  /// 默认周期。
  static const MyKlineInterval initial = minute15;

  /// 按枚举名解析周期；未命中时回退到 [defaultValue]（供路由参数等字符串来源使用）。
  factory MyKlineInterval.parse(
    String? name, [
    MyKlineInterval defaultValue = initial,
  ]) {
    if (name == null) return defaultValue;
    name = name.trim().toUpperCase();
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => defaultValue,
    );
  }
}
