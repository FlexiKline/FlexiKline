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

import 'package:copy_with_extension/copy_with_extension.dart';

import '../../extension/collections_ext.dart' show FlexiIterableExt, FlexiKlineListExt;
import '../../utils/convert_util.dart' show parseInt;
import '../../utils/export.dart' show parseBool;
import '../flexi_candle_model.dart' show ICandleModel, FlexiCandleModel;

part 'candle_model.g.dart';

/// FlexiKline 提供的 K 线参考模型。
///
/// 本类仅为参考实现，并非必须使用。你可以在自己的业务模型上实现 [ICandleModel]，
/// 达到与 [CandleModel] 相同的效果，从而减少在 FlexiKline 内部的转换操作，
/// 直接使用自有模型参与计算与渲染。
@CopyWith()
class CandleModel implements ICandleModel, Comparable<ICandleModel> {
  CandleModel({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.turnover,
    this.tradeCount,
    this.confirmed = true,
  });

  /// 时间戳（毫秒）
  ///
  /// K 线的开始时间，Unix 时间戳格式。
  @override
  final int timestamp;

  /// 开盘价
  @override
  final Object open;

  /// 最高价
  @override
  final Object high;

  /// 最低价
  @override
  final Object low;

  /// 收盘价
  @override
  final Object close;

  /// 成交量
  ///
  /// 以基础货币/股数计量的交易数量。
  @override
  final Object volume;

  /// 成交额 - 可选
  ///
  /// 以计价货币计量的交易金额。
  /// 股票市场称为"成交额"，加密货币称为 quoteVolume。
  @override
  final Object? turnover;

  /// 成交笔数 - 可选
  ///
  /// 该 K 线周期内的交易次数。
  @override
  final int? tradeCount;

  /// K 线是否已完结
  ///
  /// - true: K 线已完结（历史数据）
  /// - false: K 线未完结（实时更新中）
  @override
  final bool confirmed;

  @override
  int compareTo(ICandleModel other) {
    return other.timestamp - timestamp;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      if (turnover != null) 'turnover': turnover,
      if (tradeCount != null) 'tradeCount': tradeCount,
      'confirmed': confirmed,
    };
  }

  factory CandleModel.fromJson(Map<String, dynamic> json) {
    return CandleModel(
      timestamp: json['timestamp'],
      open: json['open'],
      high: json['high'],
      low: json['low'],
      close: json['close'],
      volume: json['volume'],
      turnover: json['turnover'],
      tradeCount: json['tradeCount'],
      confirmed: json['confirmed'],
    );
  }

  factory CandleModel.fromFlexiCandleModel(FlexiCandleModel model) {
    return CandleModel(
      timestamp: model.ts,
      open: model.open.toDecimal(),
      high: model.high.toDecimal(),
      low: model.low.toDecimal(),
      close: model.close.toDecimal(),
      volume: model.vol.toDecimal(),
      turnover: model.turnover?.toDecimal(),
      tradeCount: model.tradeCount,
      confirmed: model.confirmed,
    );
  }

  factory CandleModel.fromList(List<dynamic> data) {
    assert(data.length >= 6, 'data length must be greater than 6');
    final cfd = data.getItem(8);
    return CandleModel(
      timestamp: int.parse(data[0]),
      open: data[1],
      high: data[2],
      low: data[3],
      close: data[4],
      volume: data[5],
      turnover: data.getItem(6),
      tradeCount: parseInt(data.getItem(7)),
      confirmed: parseBool(cfd) ?? cfd == '1',
    );
  }

  static List<CandleModel> fromDataList(List<dynamic>? dataList) {
    if (dataList == null || dataList.isEmpty) return [];
    return dataList.mapNonNullList((list) => CandleModel.fromList(list)).toList();
  }
}
