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
import 'package:json_annotation/json_annotation.dart';

import '../../constant.dart';
import '../../framework/serializable.dart';
import '../../utils/convert_util.dart';

part 'candle_model.g.dart';

@FlexiModelSerializable
class CandleModel {
  CandleModel({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.vol,
    this.volCcy,
    this.volCcyQuote,
    this.confirm = '1',
  });

  /// 开始时间，Unix时间戳的毫秒数格式，如 1597026383085
  @JsonKey(fromJson: valueToInt, toJson: intToString)
  final int timestamp;
  // @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
  // DateTime? datetime, // 从timestamp转换为dateTime;

  /// 开盘价格
  @JsonKey()
  final Decimal open;

  /// 最高价格
  @JsonKey()
  final Decimal high;

  ///最低价格
  @JsonKey()
  final Decimal low;

  /// 收盘价格
  @JsonKey()
  final Decimal close;

  /// 交易量，以张为单位: 如果是衍生品合约，数值为合约的张数。如果是币币/币币杠杆，数值为交易货币的数量。
  @JsonKey()
  final Decimal vol;

  /// 交易量(成交额)，以币为单位: 如果是衍生品合约，数值为交易货币的数量。如果是币币/币币杠杆，数值为计价货币的数量。
  @JsonKey()
  Decimal? volCcy;

  ///交易量(成交额)，以计价货币为单位: 如 BTC-USDT和BTC-USDT-SWAP，单位均是USDT。BTC-USD-SWAP单位是USD。
  @JsonKey()
  Decimal? volCcyQuote;

  /// K线状态:  0：K线未完结  1：K线已完结
  @JsonKey()
  String confirm;

  factory CandleModel.fromJson(Map<String, dynamic> json) =>
      _$CandleModelFromJson(json);

  Map<String, dynamic> toJson() => _$CandleModelToJson(this);

  CandleModel copyWith({
    int? timestamp,
    Decimal? open,
    Decimal? high,
    Decimal? low,
    Decimal? close,
    Decimal? vol,
    Object? volCcy = freezed,
    Object? volCcyQuote = freezed,
    String confirm = '1',
  }) {
    return CandleModel(
      timestamp: timestamp ?? this.timestamp,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      vol: vol ?? this.vol,
      volCcy: volCcy == freezed ? this.volCcy : volCcy as Decimal?,
      volCcyQuote:
          volCcyQuote == freezed ? this.volCcyQuote : volCcy as Decimal?,
      confirm: confirm == '1' ? this.confirm : confirm,
    );
  }
}
