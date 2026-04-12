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

import '../../constant.dart';
import '../../extension/export.dart' show FlexiIterableExt;
import '../../utils/export.dart' show splitPair;
import '../time_interval.dart';

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
class KlineSpec {
  const KlineSpec({
    required this.symbol,
    this.interval = interval1D,
    this.limit = 100,
    this.precision = defaultPrecision,
    this.from,
    this.to,
    this.label,
  });

  /// 交易对标识，如 BTC-USDT、AAPL
  final String symbol;

  /// 时间粒度，默认 1D
  final ITimeInterval interval;

  /// 分页条数，最大 300，默认 100
  final int limit;

  /// 分页游标起点（更旧一侧），毫秒时间戳
  final int? from;

  /// 分页游标终点（更新一侧），毫秒时间戳
  final int? to;

  /// 价格精度（UI 渲染用）
  final int precision;

  /// 可选显示标签
  final String? label;

  @override
  String toString() => 'KlineSpec($symbol-$label, $interval, $limit, $precision, $from, $to)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is KlineSpec) {
      return other.runtimeType == runtimeType &&
          other.symbol == symbol &&
          other.interval == interval &&
          other.from == from &&
          other.to == to &&
          other.precision == precision;
    }
    return false;
  }

  @override
  int get hashCode => symbol.hashCode ^ interval.hashCode ^ precision.hashCode;
}

extension KlineSpecExt on KlineSpec {
  String get key => '$symbol-$interval';
  String get rangeKey => '$symbol-$interval-$from-$to';

  /// 清除分页游标，返回初始规格
  KlineSpec initial() => copyWith(from: null, to: null);

  /// 加密货币专用：base 货币（如 BTC-USDT、BTC_USDT、BTC/USDT → BTC）
  String get base => splitPair(symbol).firstOrNull ?? symbol;

  /// 加密货币专用：quote 货币（如 BTC-USDT → USDT）
  String get quote => splitPair(symbol).secondOrNull ?? '';
}
