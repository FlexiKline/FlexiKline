import 'package:flexi_formatter/date_time.dart';

/// K 线时间周期接口
///
/// 定义 K 线数据的时间粒度，兼容币圈、股票等市场。
/// 各交易所特有的 API 参数映射由业务适配层实现，不在此接口中。
abstract interface class ITimeInterval {
  /// 单位倍数（如 15 表示 15 分钟）
  int get multiplier;

  /// 时间单位
  TimeUnit get unit;
}

extension ITimeIntervalExt on ITimeInterval {
  /// 单根 K 线的时间跨度（毫秒）
  ///
  /// 对于月等非固定时长周期，使用约定近似值（如 30 天）。
  /// 精确的时间对齐由业务层处理。
  int get milliseconds => unit.microseconds ~/ 1000 * multiplier;

  /// 是否是有效的时间周期
  bool get isValid => multiplier > 0 && unit != TimeUnit.microsecond;

  /// 比较两个时间周期是否语义相同
  bool isSameAs(ITimeInterval other) {
    return milliseconds == other.milliseconds;
  }

  /// 调试标签
  ///
  /// 采用 K 线行业惯例的时间单位缩写：
  /// `1s` / `1m`（分钟）/ `1H` / `1D` / `1W` / `1M`（月）/ `1Y`。
  /// 其中分钟用小写 `m` 与月份大写 `M` 区分，避免歧义。
  String get debugLabel {
    final suffix = switch (unit) {
      TimeUnit.year => 'Y',
      TimeUnit.month => 'M',
      TimeUnit.week => 'W',
      TimeUnit.day => 'D',
      TimeUnit.hour => 'H',
      TimeUnit.minute => 'm',
      TimeUnit.second => 's',
      TimeUnit.millisecond => 'ms',
      TimeUnit.microsecond => 'us',
    };
    return '$multiplier$suffix';
  }
}

/// 默认时间周期实现
final class FlexiTimeInterval implements ITimeInterval {
  const FlexiTimeInterval(this.multiplier, this.unit);

  @override
  final int multiplier;

  @override
  final TimeUnit unit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ITimeInterval && other.multiplier == multiplier && other.milliseconds == milliseconds;
  }

  @override
  int get hashCode => multiplier.hashCode ^ milliseconds.hashCode;

  @override
  String toString() => '$multiplier${unit.name}';
}
