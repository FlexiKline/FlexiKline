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
import '../../framework/serializers.dart';
import '../../utils/convert_util.dart';
import '../bag_num.dart';
import 'candle_mixin.dart';

part 'candle_model.g.dart';

@FlexiModelSerializable
class CandleModel with MaMixin {
  CandleModel({
    required this.timestamp,
    required this.o,
    required this.h,
    required this.l,
    required this.c,
    required this.v,
    this.vc,
    this.vcq,
    this.confirm = '1',
  });

  /// 开始时间，Unix时间戳的毫秒数格式，如 1597026383085
  @JsonKey(fromJson: valueToInt, toJson: intToString)
  final int timestamp;
  // @JsonKey(fromJson: valueToDateTime, toJson: dateTimeToInt)
  // DateTime? datetime, // 从timestamp转换为dateTime;

  /// 开盘价格
  @JsonKey()
  final Decimal o;

  /// 最高价格
  @JsonKey()
  final Decimal h;

  ///最低价格
  @JsonKey()
  final Decimal l;

  /// 收盘价格
  @JsonKey()
  final Decimal c;

  /// 交易量，以张为单位: 如果是衍生品合约，数值为合约的张数。如果是币币/币币杠杆，数值为交易货币的数量。
  @JsonKey()
  final Decimal v;

  /// 交易量(成交额)，以币为单位: 如果是衍生品合约，数值为交易货币的数量。如果是币币/币币杠杆，数值为计价货币的数量。
  @JsonKey()
  Decimal? vc;

  ///交易量(成交额)，以计价货币为单位: 如 BTC-USDT和BTC-USDT-SWAP，单位均是USDT。BTC-USD-SWAP单位是USD。
  @JsonKey()
  Decimal? vcq;

  /// K线状态:  0：K线未完结  1：K线已完结
  @JsonKey()
  String confirm;

  factory CandleModel.fromJson(Map<String, dynamic> json) =>
      _$CandleModelFromJson(json);

  Map<String, dynamic> toJson() => _$CandleModelToJson(this);

  BagNum? _open;
  BagNum get open => _open ??= BagNum.fromDecimal(o);
  BagNum? _high;
  BagNum get high => _high ??= BagNum.fromDecimal(h);
  BagNum? _low;
  BagNum get low => _low ??= BagNum.fromDecimal(l);
  BagNum? _close;
  BagNum get close => _close ??= BagNum.fromDecimal(c);
  BagNum? _vol;
  BagNum get vol => _vol ??= BagNum.fromDecimal(v);
  BagNum? _volCcy;
  BagNum? get volCcy {
    if (vc != null) return _volCcy ??= BagNum.fromDecimal(vc!);
    return null;
  }

  BagNum? _volCcyQuote;
  BagNum? get volCcyQuote {
    if (vcq != null) return _volCcyQuote ??= BagNum.fromDecimal(vcq!);
    return null;
  }

  void initBasicData(ComputeMode mode, {bool reset = false}) {
    if (reset ||
        _open == null ||
        _high == null ||
        _low == null ||
        _close == null ||
        _vol == null ||
        _volCcy == null ||
        _volCcyQuote == null) {
      if (mode == ComputeMode.fast) {
        _open = BagNum.fromNum(o.toDouble());
        _high = BagNum.fromNum(h.toDouble());
        _low = BagNum.fromNum(l.toDouble());
        _close = BagNum.fromNum(c.toDouble());
        _vol = BagNum.fromNum(v.toDouble());
        _volCcy = vc != null ? BagNum.fromNum(vc!.toDouble()) : null;
        _volCcyQuote = vcq != null ? BagNum.fromNum(vcq!.toDouble()) : null;
      } else {
        _open = BagNum.fromDecimal(o);
        _high = BagNum.fromDecimal(h);
        _low = BagNum.fromDecimal(l);
        _close = BagNum.fromDecimal(c);
        _vol = BagNum.fromDecimal(v);
        _volCcy = vc != null ? BagNum.fromDecimal(vc!) : null;
        _volCcyQuote = vcq != null ? BagNum.fromDecimal(vcq!) : null;
      }
    }
    maRets = null;
  }

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
      o: open ?? this.o,
      h: high ?? this.h,
      l: low ?? this.l,
      c: close ?? this.c,
      v: vol ?? this.v,
      vc: volCcy == freezed
          ? this.vc
          : volCcy is Decimal
              ? volCcy
              : null,
      vcq: volCcyQuote == freezed
          ? this.vcq
          : volCcy is Decimal
              ? volCcy
              : null,
      confirm: confirm == '1' ? this.confirm : confirm,
    );
  }
}
