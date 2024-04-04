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
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/export.dart';

part 'candle_model.freezed.dart';
part 'candle_model.g.dart';

@freezed
class CandleModel with _$CandleModel {
  factory CandleModel({
    /// 开始时间，Unix时间戳的毫秒数格式，如 1597026383085
    // @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
    required int timestamp,
    // @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
    // DateTime? datetime, // 从timestamp转换为dateTime;

    /// 开盘价格
    @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
    required Decimal open,

    /// 最高价格
    @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
    required Decimal high,

    ///最低价格
    @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
    required Decimal low,

    /// 收盘价格
    @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
    required Decimal close,

    /// 交易量，以张为单位: 如果是衍生品合约，数值为合约的张数。如果是币币/币币杠杆，数值为交易货币的数量。
    @JsonKey(fromJson: stringToDecimal, toJson: decimalToString)
    required Decimal vol,

    /// 交易量(成交额)，以币为单位: 如果是衍生品合约，数值为交易货币的数量。如果是币币/币币杠杆，数值为计价货币的数量。
    @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
    Decimal? volCcy,

    ///交易量(成交额)，以计价货币为单位: 如 BTC-USDT和BTC-USDT-SWAP，单位均是USDT。BTC-USD-SWAP单位是USD。
    @JsonKey(fromJson: stringToDecimalOrNull, toJson: decimalToStringOrNull)
    Decimal? volCcyQuote,

    /// K线状态:  0：K线未完结  1：K线已完结
    @Default("1") String confirm,
  }) = _CandleModel;

  factory CandleModel.fromJson(Map<String, dynamic> json) =>
      _$CandleModelFromJson(json);
}
