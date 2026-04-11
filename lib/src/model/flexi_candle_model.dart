// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/flexi_formatter.dart';

import '../types.dart';
import '../utils/convert_util.dart' show parseDecimal, parseDouble;
import 'flexi_num.dart';
import 'time_interval.dart';

/// K 线蜡烛图数据接口
///
/// 定义 K 线数据的标准字段，兼容股票、加密货币、外汇等市场。
/// 价格和成交量字段支持 [String]、[num]、[Decimal] 类型，
/// 框架会根据计算模式自动转换为 [FlexiNum]。
abstract interface class ICandleModel {
  /// 时间戳（毫秒）
  ///
  /// K 线的开始时间，Unix 时间戳格式。
  int get timestamp;

  /// 开盘价
  Object get open;

  /// 最高价
  Object get high;

  /// 最低价
  Object get low;

  /// 收盘价
  Object get close;

  /// 成交量
  ///
  /// 以基础货币/股数计量的交易数量。
  Object get volume;

  /// 成交额 - 可选
  ///
  /// 以计价货币计量的交易金额。
  /// 股票市场称为"成交额"，加密货币称为 quoteVolume。
  Object? get turnover => null;

  /// 成交笔数 - 可选
  ///
  /// 该 K 线周期内的交易次数。
  int? get tradeCount => null;

  /// K 线是否已完结
  ///
  /// - true: K 线已完结（历史数据）
  /// - false: K 线未完结（实时更新中）
  bool get confirmed => true;
}

extension FlexiICandleModelExt on ICandleModel {
  int get ts => timestamp;

  Decimal get openDecimal => Decimal.parse(open.toString());

  Decimal get highDecimal => Decimal.parse(high.toString());

  Decimal get lowDecimal => Decimal.parse(low.toString());

  Decimal get closeDecimal => Decimal.parse(close.toString());

  Decimal get volumeDecimal => Decimal.parse(volume.toString());

  Decimal? get turnoverDecimal => parseDecimal(turnover);

  Decimal get changeDecimal => closeDecimal - openDecimal;

  Decimal get changeRateDecimal {
    final chg = changeDecimal;
    if (chg == Decimal.zero) return Decimal.zero;
    return (chg / openDecimal).toDecimal();
  }

  Decimal get rangeDecimal => highDecimal - lowDecimal;

  double get openDouble => double.parse(open.toString());

  double get highDouble => double.parse(high.toString());

  double get lowDouble => double.parse(low.toString());

  double get closeDouble => double.parse(close.toString());

  double get volumeDouble => double.parse(volume.toString());

  double? get turnoverDouble => parseDouble(turnover);

  double get changeDouble => closeDouble - openDouble;

  double get changeRateDouble {
    final chg = changeDouble;
    if (chg == 0) return 0;
    return (chg / openDouble).toDouble();
  }

  double get rangeDouble => highDouble - lowDouble;

  FlexiCandleModel toFlexiCandleModel(int count, ComputeMode mode) {
    return FlexiCandleModel.init(candle: this, count: count, mode: mode);
  }
}

/// 比较两个蜡烛数据模型，用于按时间戳降序排序。
///
/// 返回值 > 0 表示 a 应排在 b 之后。
int candleModelCompare(ICandleModel a, ICandleModel b) {
  return b.timestamp - a.timestamp;
}

/// 比较两个运行时计算模型，用于按时间戳降序排序。
///
/// 返回值 > 0 表示 a 应排在 b 之后。
int flexiCandleModelCompare(FlexiCandleModel a, FlexiCandleModel b) => b.ts - a.ts;

/// FlexiCandleModel 框架层蜡烛模型
/// 框架层蜡烛模型是框架层用于指标数据计算的蜡烛模型, 主要用于指标数据计算, 适配精确模式(Decimal)和快速模式(fast mode)
/// 支持时间戳(ts), 开盘价(o), 最高价(h), 最低价(l), 收盘价(c), 成交量(v), 成交额(tn), 成交笔数(tc), 是否已完结(cfm), 数据槽位(slots)
/// 时间戳(ts): 时间戳（毫秒）
/// 开盘价(o): 开盘价格
/// 最高价(h): 最高价格
/// 最低价(l): 最低价格
/// 收盘价(c): 收盘价格
/// 成交量(v): 成交量
/// 成交额(tn): 成交额（计价货币）
/// 成交笔数(tc): 成交笔数
/// 是否已完结(cfm): K 线是否已完结
/// 数据槽位(slots): 数据槽位
extension type FlexiCandleModel._(
    ({
      int ts,
      FlexiNum o,
      FlexiNum h,
      FlexiNum l,
      FlexiNum c,
      FlexiNum v,
      FlexiNum? tn,
      int? tc,
      bool cfm,
      List<Object?> slots,
    }) _m) {
  /// 从 ICandleModel 初始化 FlexiCandleModel
  ///
  /// [candle] 原始蜡烛数据（实现 ICandleModel 接口）
  /// [count] 指标数据槽位数量
  /// [mode] 计算模式：fast (double) 或 accurate (Decimal)
  factory FlexiCandleModel.init({
    required ICandleModel candle,
    required int count,
    ComputeMode mode = ComputeMode.fast,
  }) {
    return FlexiCandleModel._((
      ts: candle.timestamp,
      o: FlexiNum.fromAny(candle.open, mode),
      h: FlexiNum.fromAny(candle.high, mode),
      l: FlexiNum.fromAny(candle.low, mode),
      c: FlexiNum.fromAny(candle.close, mode),
      v: FlexiNum.fromAny(candle.volume, mode),
      tn: candle.turnover != null ? FlexiNum.fromAny(candle.turnover!, mode) : null,
      tc: candle.tradeCount,
      cfm: candle.confirmed,
      slots: List<Object?>.filled(count, null, growable: false),
    ));
  }

  /// 计算模式
  ComputeMode get mode => _m.o.mode;

  /// 时间戳（毫秒）
  int get ts => _m.ts;

  /// 开盘价格
  FlexiNum get open => _m.o;

  /// 最高价格
  FlexiNum get high => _m.h;

  /// 最低价格
  FlexiNum get low => _m.l;

  /// 收盘价格
  FlexiNum get close => _m.c;

  /// 成交量
  FlexiNum get vol => _m.v;

  /// 成交额（计价货币）
  FlexiNum? get turnover => _m.tn;

  /// 成交笔数
  int? get tradeCount => _m.tc;

  /// K 线是否已完结
  bool get confirmed => _m.cfm;

  /// 是否上涨（收盘价 >= 开盘价）
  bool get isLong => close >= open;

  /// 是否下跌（收盘价 < 开盘价）
  bool get isShort => close < open;

  /// 涨跌幅
  FlexiNum get change => close - open;

  /// 涨跌幅(百分比)
  double get changeRate {
    final chg = close - open;
    if (chg.isZero) return 0;
    return (chg / open).toDouble();
  }

  /// 振幅
  FlexiNum get range => high - low;

  /// 振幅率(百分比)
  double rangeRate(FlexiCandleModel pre) {
    final rng = high - low;
    if (rng.isZero) return 0;
    return (rng / pre.close).toDouble();
  }

  /// 检查指定槽位索引是否在有效范围内
  ///
  /// [index] 数据槽位索引
  /// 返回: 若槽位索引在有效范围内（未越界）则返回 true
  bool checkIndex(int index) => index >= 0 && index < _m.slots.length;

  /// 获取指定槽位的指标数据
  ///
  /// [index] 数据槽位索引
  /// 返回: 如果存在且类型匹配则返回数据，否则返回 null
  /// 注: 如果槽位索引越界, 则会抛出RangeError
  Object? operator [](int index) => _m.slots[index];

  /// 设置指定位置的指标数据
  ///
  /// [index] 数据槽位索引
  /// [value] 要存储的数据
  /// 注: 如果槽位索引越界, 则会抛出RangeError
  void operator []=(int index, Object? value) => _m.slots[index] = value;

  /// 检查指定槽位是否无数据
  ///
  /// [index] 数据槽位索引
  /// 返回: 该槽位无数据（为 null）或越界时为 true
  bool isEmpty(int index) {
    if (!checkIndex(index)) return true;
    return this[index] == null;
  }

  /// 检查指定槽位是否有数据
  ///
  /// [index] 数据槽位索引
  /// 返回: 该槽位存在非 null 数据时为 true
  bool isNotEmpty(int index) => !isEmpty(index);

  /// 是否有任意槽位存在有效数据
  ///
  /// 返回: 如果任意槽位存在非 null 数据则返回 true
  bool get hasValidData => _m.slots.any((e) => e != null);

  /// 检查指定槽位是否存在有效数据
  ///
  /// [index] 数据槽位索引
  /// 返回: 如果该槽位存在非 null 数据则返回 true
  bool hasValidDataAt<T>(int index) {
    if (!checkIndex(index)) return false;
    return switch (this[index]) {
      final T? data => data != null,
      final List<T?> list => list.any((e) => e != null),
      _ => false,
    };
  }

  /// 获取指定槽位的指标数据
  ///
  /// [index] 数据槽位索引
  /// 返回: 如果该槽位存在且类型匹配则返回数据，否则返回 null
  T? get<T>(int index) {
    if (!checkIndex(index)) return null;
    return this[index] is T ? this[index] as T : null;
  }

  /// 设置指定槽位的指标数据
  ///
  /// [index] 数据槽位索引
  /// [data] 要存储的数据
  /// 返回: 设置成功返回 true，槽位索引越界返回 false
  bool set<T>(int index, T data) {
    if (!checkIndex(index)) return false;
    this[index] = data;
    return true;
  }

  /// 获取指定槽位的指标数据列表
  ///
  /// [index] 数据槽位索引
  /// 返回: 如果该槽位存在且类型匹配则返回数据列表，否则返回 null
  List<T?>? getList<T>(int index) {
    if (!checkIndex(index)) return null;
    final list = this[index];
    return list is List<T?> ? list : null;
  }

  /// 设置指定槽位的指标数据列表
  ///
  /// [index] 数据槽位索引
  /// [data] 要存储的数据列表
  /// 返回: 设置成功返回 true，槽位索引越界返回 false
  bool setList<T>(int index, List<T?> data) {
    if (!checkIndex(index)) return false;
    this[index] = data;
    return true;
  }

  /// 获取指定槽位的指标数据列表, 如果列表不存在, 则初始化一个指定长度的列表
  ///
  /// [index] 数据槽位索引
  /// [count] 列表长度
  /// [growable] 是否可增长
  /// 注: 如果槽位索引越界, 则返回的是一个不在缓存中的空列表, 大部分情况下, 应该先检查槽位索引是否越界, 再使用此方法获取列表
  List<T?> getOrInitList<T>(int index, int count, {bool growable = false}) {
    final list = getList<T>(index);
    if (list != null) return list;
    final newList = List<T?>.filled(count, null, growable: growable);
    setList(index, newList);
    return newList;
  }

  /// 获取指定槽位的指标数据列表的第一个数据
  ///
  /// [index] 数据槽位索引
  /// [def] 列表为空或不存在时的默认值
  /// 返回: 列表的第一个数据，否则返回 [def]
  T firstOrDefault<T>(int index, T def) {
    return getList<T>(index)?.firstOrNull ?? def;
  }

  /// 清空指定槽位的指标数据
  ///
  /// [index] 数据槽位索引
  /// 返回: 清空成功返回 true，槽位索引越界返回 false
  bool clean(int index) {
    if (!checkIndex(index)) return false;
    this[index] = null;
    return true;
  }

  /// 清空所有槽位的指标数据
  void cleanAll() {
    for (int i = 0; i < _m.slots.length; i++) {
      this[i] = null;
    }
  }

  /// 开始时间，[DateTime] 格式
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(ts);

  /// 格式化时间，[DateTime] 格式
  ///
  /// [timeBar] 时间粒度
  /// 返回: 格式化后的时间字符串
  String formatDateTime(ITimeInterval timeBar) => dateTime.formatByUnit(timeBar.unit);

  /// 下一个更新时刻
  ///
  /// [timeBar] 时间粒度
  /// 返回: 下一更新时刻的 [DateTime]，[timeBar] 无效时返回 null
  DateTime? nextUpdateDateTime(ITimeInterval timeBar) {
    if (timeBar.isValid) {
      return DateTime.fromMillisecondsSinceEpoch(ts + timeBar.milliseconds);
    }
    return null;
  }

  /// 转换为指定蜡烛模型, 根据[converter]函数进行转换
  T toCandleModel<T extends ICandleModel>(T Function(FlexiCandleModel model) converter) {
    return converter(this);
  }

  /// 重置当前模型，根据[mode]和[count]重置指标数据槽位
  FlexiCandleModel reset(ComputeMode mode, int count) {
    return FlexiCandleModel._((
      ts: ts,
      o: open.reset(mode),
      h: high.reset(mode),
      l: low.reset(mode),
      c: close.reset(mode),
      v: vol.reset(mode),
      tn: turnover?.reset(mode),
      tc: tradeCount,
      cfm: confirmed,
      slots: List<Object?>.filled(count, null, growable: false),
    ));
  }

  /// 克隆当前模型，返回一个新的模型，新模型的指标数据槽位与原模型相同
  FlexiCandleModel clone() {
    return FlexiCandleModel._((
      ts: _m.ts,
      o: _m.o,
      h: _m.h,
      l: _m.l,
      c: _m.c,
      v: _m.v,
      tn: _m.tn,
      tc: _m.tc,
      cfm: _m.cfm,
      slots: List<Object?>.from(_m.slots, growable: false),
    ));
  }

  /// 创建当前模型的拷贝，仅对传入的非 null 参数进行替换，未传参数保留原值
  FlexiCandleModel copyWith({
    int? ts,
    Object? open,
    Object? high,
    Object? low,
    Object? close,
    Object? volume,
    Object? turnover,
    int? tradeCount,
    bool? confirmed,
    List<Object?>? slots,
  }) {
    final originalMode = mode;
    return FlexiCandleModel._((
      ts: ts ?? _m.ts,
      o: FlexiNum.fromAnyOrNull(open, originalMode) ?? _m.o,
      h: FlexiNum.fromAnyOrNull(high, originalMode) ?? _m.h,
      l: FlexiNum.fromAnyOrNull(low, originalMode) ?? _m.l,
      c: FlexiNum.fromAnyOrNull(close, originalMode) ?? _m.c,
      v: FlexiNum.fromAnyOrNull(volume, originalMode) ?? _m.v,
      tn: FlexiNum.fromAnyOrNull(turnover, originalMode),
      tc: tradeCount ?? _m.tc,
      cfm: confirmed ?? _m.cfm,
      slots: slots ?? _m.slots,
    ));
  }

  String valueString() {
    return '''{
      'ts': $ts   ,
      'o': ${open.valueString()},
      'h': ${high.valueString()},
      'l': ${low.valueString()},
      'c': ${close.valueString()},
      'v': ${vol.valueString()},
      'tn': ${turnover?.valueString()},
      'tc': $tradeCount,
      'cfm': $confirmed,
      'slots': ${_m.slots.map((e) => e?.toString()).join(',')},
    }''';
  }
}
