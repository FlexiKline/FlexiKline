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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_ticker.freezed.dart';
part 'market_ticker.g.dart';

/// 参数名	类型	描述
/// instType	String	产品类型
/// instId	String	产品ID
/// last	String	最新成交价
/// lastSz	String	最新成交的数量
/// askPx	String	卖一价
/// askSz	String	卖一价对应的数量
/// bidPx	String	买一价
/// bidSz	String	买一价对应的数量
/// open24h	String	24小时开盘价
/// high24h	String	24小时最高价
/// low24h	String	24小时最低价
/// volCcy24h	String	24小时成交量，以币为单位
///   如果是衍生品合约，数值为交易货币的数量。
///   如果是币币/币币杠杆，数值为计价货币的数量。
/// vol24h	String	24小时成交量，以张为单位
///   如果是衍生品合约，数值为合约的张数。
///   如果是币币/币币杠杆，数值为交易货币的数量。
/// sodUtc0	String	UTC+0 时开盘价
/// sodUtc8	String	UTC+8 时开盘价
/// ts	String	ticker数据产生时间，Unix时间戳的毫秒数格式，如 1597026383085
///
/// 示例:
///  {
///  "instType": "SWAP",
///  "instId": "BTC-USD-SWAP",
///  "last": "56956.1",
///  "lastSz": "3",
///  "askPx": "56959.1",
///  "askSz": "10582",
///  "bidPx": "56959",
///  "bidSz": "4552",
///  "open24h": "55926",
///  "high24h": "57641.1",
///  "low24h": "54570.1",
///  "volCcy24h": "81137.755",
///  "vol24h": "46258703",
///  "ts": "1620289117764",
///  "sodUtc0": "55926",
///  "sodUtc8": "55926"
///  }
@freezed
class MarketTicker with _$MarketTicker {
  factory MarketTicker({
    required String instType,
    required String instId,
    required String last,
    required String lastSz,
    required String askPx,
    required String askSz,
    required String bidPx,
    required String bidSz,
    required String open24h,
    required String high24h,
    required String low24h,
    required String volCcy24h,
    required String vol24h,
    required String ts,
    required String sodUtc0,
    required String sodUtc8,
  }) = _MarketTicker;

  static MarketTicker fromJson2(dynamic json) => _$MarketTickerFromJson(json);

  factory MarketTicker.fromJson(Map<String, dynamic> json) =>
      _$MarketTickerFromJson(json);
}

extension MarketTickerExt on MarketTicker {
  double get changeRate {
    final open = open24h.d;
    final change = last.d - open;
    if (change == Decimal.zero) return 0;
    return (change / open).toDouble() * 100;
  }
}
