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
import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/date_time.dart';

import '../../constant.dart';
import '../../extension/export.dart';
import '../../framework/serializers.dart';
import '../../utils/export.dart';
import '../bag_num.dart';

part 'candle_helper.dart';
part 'candle_model.g.dart';

@CopyWith()
@FlexiModelSerializable
class CandleModel implements Comparable<CandleModel> {
  CandleModel({
    required this.ts,
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
  final int ts;

  /// 开盘价格
  final Decimal o;

  /// 最高价格
  final Decimal h;

  ///最低价格
  final Decimal l;

  /// 收盘价格
  final Decimal c;

  /// 交易量，以张为单位: 如果是衍生品合约，数值为合约的张数。如果是币币/币币杠杆，数值为交易货币的数量。
  final Decimal v;

  /// 交易量(成交额)，以币为单位: 如果是衍生品合约，数值为交易货币的数量。如果是币币/币币杠杆，数值为计价货币的数量。
  Decimal? vc;

  ///交易量(成交额)，以计价货币为单位: 如 BTC-USDT和BTC-USDT-SWAP，单位均是USDT。BTC-USD-SWAP单位是USD。
  Decimal? vcq;

  /// K线状态:  0：K线未完结  1：K线已完结
  String confirm;

  CalculateData? _calcuData;

  CalculateData get calcuData => _calcuData!;

  @override
  int compareTo(CandleModel other) {
    return other.ts - ts;
  }

  static CandleModel? fromList(List<dynamic> data) {
    if (data.isEmpty || data.length < 6) return null;
    final ts = parseInt(data.getItem(0));
    if (ts == null) return null;
    final o = parseDecimal(data.getItem(1));
    if (o == null) return null;
    final h = parseDecimal(data.getItem(2));
    if (h == null) return null;
    final l = parseDecimal(data.getItem(3));
    if (l == null) return null;
    final c = parseDecimal(data.getItem(4));
    if (c == null) return null;
    final v = parseDecimal(data.getItem(5));
    if (v == null) return null;
    return CandleModel(
      ts: ts,
      o: o,
      h: h,
      l: l,
      c: c,
      v: v,
      vc: parseDecimal(data.getItem(6)),
      vcq: parseDecimal(data.getItem(7)),
      confirm: data.getItem(8).toString(),
    );
  }

  static List<CandleModel> fromDataList(List<dynamic>? dataList) {
    if (dataList == null || dataList.isEmpty) return [];
    return dataList.mapNonNullList((list) => fromList(list)).toList();
  }

  factory CandleModel.fromJson(Map<String, dynamic> json) => _$CandleModelFromJson(json);

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

  void initBasicData(
    ComputeMode mode,
    int indicatorCount, {
    bool reset = false,
  }) {
    if (reset || _open == null || _high == null || _low == null || _close == null || _vol == null) {
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
    _calcuData = CalculateData.init(indicatorCount);
  }
}
