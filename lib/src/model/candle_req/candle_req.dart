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
import 'package:json_annotation/json_annotation.dart';

import '../../constant.dart';
import '../../extension/export.dart';
import '../../framework/serializers.dart';

part 'candle_req.g.dart';

/// 请求状态
enum RequestState {
  // 正常
  none,
  // 初始加载中
  initLoading,
  // 加载更多
  loadMore,
  // 加载更多中(已到达当前最后一根蜡烛)
  loadingMore;

  bool get showLoading {
    return this == RequestState.initLoading || this == RequestState.loadingMore;
  }

  bool get isLoadMore {
    return this == RequestState.loadMore || this == RequestState.loadingMore;
  }
}

@CopyWith()
@FlexiModelSerializable
class CandleReq {
  const CandleReq({
    required this.instId,
    this.bar = '1m',
    this.limit = 100,
    this.precision = defaultPrecision,
    this.after,
    this.before,
    this.state = RequestState.none,
    this.displayName,
  });

  /// 产品ID，如 BTC-USDT
  @JsonKey()
  final String instId;

  /// 请求此时间戳之前（更旧的数据）的分页内容，传的值为对应接口的ts
  @JsonKey()
  final int? after;

  /// 请求此时间戳之后（更新的数据）的分页内容，传的值为对应接口的ts, 单独使用时，会返回最新的数据。
  @JsonKey()
  final int? before;

  /// 时间粒度，默认值1m
  /// 如 [1m/3m/5m/15m/30m/1H/2H/4H]
  /// 香港时间开盘价k线：[6H/12H/1D/2D/3D/1W/1M/3M]
  /// UTC时间开盘价k线：[/6Hutc/12Hutc/1Dutc/2Dutc/3Dutc/1Wutc/1Mutc/3Mutc]
  @JsonKey()
  final String bar;

  /// 分页返回的结果集数量，最大为300，不填默认返回100条
  @JsonKey()
  final int limit;

  /// 当前交易对精度
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int precision;

  /// 当前请求状态
  @JsonKey(includeFromJson: false, includeToJson: false)
  final RequestState state;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? displayName;

  @override
  String toString() {
    return 'CandleReq($instId-$displayName, $bar, $limit, $precision, $before, $after, $state)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is CandleReq) {
      return other.runtimeType == runtimeType &&
          other.instId == instId &&
          other.bar == bar &&
          other.after == after &&
          other.before == before &&
          other.precision == precision &&
          other.state == state;
    }
    return false;
  }

  @override
  int get hashCode {
    return instId.hashCode ^ bar.hashCode ^ precision.hashCode ^ state.hashCode;
  }

  factory CandleReq.fromJson(Map<String, dynamic> json) =>
      _$CandleReqFromJson(json);
  Map<String, dynamic> toJson() => _$CandleReqToJson(this);
}

extension CandleReqExt on CandleReq {
  String get key => "$instId-$bar";
  String get reqKey => "$instId-$bar-$before-$after";

  TimeBar? get timeBar => TimeBar.convert(bar);

  Map<String, dynamic> toLoadMoreJson() {
    return toJson()..remove('before');
  }

  CandleReq toInitReq() => copyWith(after: null, before: null);

  String get base => instId.split('-').firstOrNull ?? instId;
  String get quote => instId.split('-').getItem(1) ?? '';
}
