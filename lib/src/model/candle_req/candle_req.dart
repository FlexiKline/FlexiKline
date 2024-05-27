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

import 'package:flexi_kline/src/extension/export.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../constant.dart';
import '../../framework/serializers.dart';

part 'candle_req.g.dart';

@FlexiModelSerializable
class CandleReq {
  CandleReq({
    required this.instId,
    this.bar = '1m',
    this.limit = 100,
    this.precision = defaultPrecision,
    this.after,
    this.before,
  });

  /// 产品ID，如 BTC-USDT
  @JsonKey()
  final String instId;

  /// 请求此时间戳之前（更旧的数据）的分页内容，传的值为对应接口的ts
  @JsonKey()
  int? after;

  /// 请求此时间戳之后（更新的数据）的分页内容，传的值为对应接口的ts, 单独使用时，会返回最新的数据。
  @JsonKey()
  int? before;

  /// 时间粒度，默认值1m
  /// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
  /// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
  /// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
  @JsonKey()
  String bar;

  /// 分页返回的结果集数量，最大为300，不填默认返回100条
  @JsonKey()
  int limit;

  /// 当前交易对精度
  @JsonKey()
  int precision;

  factory CandleReq.fromJson(Map<String, dynamic> json) =>
      _$CandleReqFromJson(json);
  Map<String, dynamic> toJson() => _$CandleReqToJson(this);

  CandleReq copyWith({
    String? instId,
    Object? after = freezed,
    Object? before = freezed,
    String? bar,
    int? limit,
    int? precision,
  }) {
    return CandleReq(
      instId: instId ?? this.instId,
      after: after == freezed
          ? this.after
          : after is int
              ? after
              : null,
      before: before == freezed
          ? this.before
          : before is int
              ? before
              : null,
      bar: bar ?? this.bar,
      limit: limit ?? this.limit,
      precision: precision ?? this.precision,
    );
  }
}

extension CandleReqExt on CandleReq {
  String get key => "$instId-$bar";
  String get reqKey => "$instId-$bar-$before-$after";

  TimeBar? get timeBar => TimeBar.convert(bar);

  void update(CandleReq req) {
    if (instId == req.instId) {
      // instId = req.instId;
      after = req.after;
      before = req.before;
      bar = req.bar;
      limit = req.limit;
      precision = req.precision;
    }
  }

  String get base => instId.split('-').firstOrNull ?? instId;
  String get quote => instId.split('-').getItem(1) ?? '';
}
