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
import '../time_bar.dart';

part 'kline_spec.g.dart';

/// K线加载状态
enum KlineLoadingState {
  none,
  initLoading,
  loadMore,
  loadingMore;

  bool get showLoading {
    return this == KlineLoadingState.initLoading || this == KlineLoadingState.loadingMore;
  }

  bool get isLoadMore {
    return this == KlineLoadingState.loadMore || this == KlineLoadingState.loadingMore;
  }
}

@CopyWith()
@FlexiModelSerializable
class KlineSpec {
  const KlineSpec({
    required this.symbol,
    this.timeBar = timeBar1m,
    this.limit = 100,
    this.precision = defaultPrecision,
    this.from,
    this.to,
    this.label,
  });

  /// 交易对标识，如 BTC-USDT、AAPL
  final String symbol;

  /// 时间粒度，默认 1m
  final ITimeBar timeBar;

  /// 分页条数，最大 300，默认 100
  final int limit;

  /// 分页游标起点（更旧一侧），毫秒时间戳；数据加载后自动同步为最旧蜡烛 ts
  final int? from;

  /// 分页游标终点（更新一侧），毫秒时间戳；数据加载后自动同步为最新蜡烛 ts
  final int? to;

  /// 价格精度（UI 渲染用，不参与序列化）
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int precision;

  /// 可选显示标签（不参与序列化）
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? label;

  @override
  String toString() => 'KlineSpec($symbol-$label, $timeBar, $limit, $precision, $from, $to)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is KlineSpec) {
      return other.runtimeType == runtimeType &&
          other.symbol == symbol &&
          other.timeBar == timeBar &&
          other.from == from &&
          other.to == to &&
          other.precision == precision;
    }
    return false;
  }

  @override
  int get hashCode => symbol.hashCode ^ timeBar.hashCode ^ precision.hashCode;

  factory KlineSpec.fromJson(Map<String, dynamic> json) => _$KlineSpecFromJson(json);
  Map<String, dynamic> toJson() => _$KlineSpecToJson(this);

  Map<String, dynamic> toRequestParams() {
    return toJson()
      ..remove('timeBar')
      ..['bar'] = timeBar.bar;
  }
}

extension KlineSpecExt on KlineSpec {
  String get key => '$symbol-$timeBar';
  String get rangeKey => '$symbol-$timeBar-$from-$to';

  /// 加载更多时使用的 HTTP 参数（不含 to，向旧方向无限翻页）
  Map<String, dynamic> toLoadMoreParams() => toRequestParams()..remove('to');

  /// 清除分页游标，返回初始规格（用于首次加载或重置）
  KlineSpec initial() => copyWith(from: null, to: null);

  /// 加密货币专用：base 货币（BTC-USDT 中的 BTC）
  String get base => symbol.split('-').firstOrNull ?? symbol;

  /// 加密货币专用：quote 货币（BTC-USDT 中的 USDT）
  String get quote => symbol.split('-').getItem(1) ?? '';
}
