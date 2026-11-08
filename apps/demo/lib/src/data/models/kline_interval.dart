import 'package:flexi_formatter/date_time.dart';
import 'package:flexi_kline/flexi_kline.dart';

/// 五档 K 线周期，每档对应一份独立 mock 数据，multiplier/unit 决定蜡烛时间跨度；展示文案由周期栏提供。
enum KlineInterval implements ITimeInterval {
  line(1, TimeUnit.minute),
  minute15(15, TimeUnit.minute),
  hour1(1, TimeUnit.hour),
  day1(1, TimeUnit.day),
  week1(1, TimeUnit.week);

  const KlineInterval(this.multiplier, this.unit);

  @override
  final int multiplier;

  @override
  final TimeUnit unit;

  /// 默认周期。
  static const KlineInterval initial = minute15;

  /// 按枚举名解析周期（忽略大小写与首尾空白）；未命中时回退到 [defaultValue]（供路由参数等字符串来源使用）。
  factory KlineInterval.parse(
    String? name, [
    KlineInterval defaultValue = initial,
  ]) {
    if (name == null) return defaultValue;
    name = name.trim().toLowerCase();
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => defaultValue,
    );
  }
}
