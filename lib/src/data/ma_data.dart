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

import 'dart:math' as math;
import 'package:decimal/decimal.dart';

import '../extension/export.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'results.dart';

mixin MAData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init MA');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose MA');
    // TODO: 是否要缓存
    _count2ts2MaMap.clear();
  }

  /// MA数据缓存 <count, <timestamp, Decimal>>
  final Map<int, Map<int, MAResult>> _count2ts2MaMap = {};

  Map<int, MAResult> getCountMaMap(int count) {
    _count2ts2MaMap[count] ??= {};
    return _count2ts2MaMap[count]!;
  }

  MAResult? getMaResult(int? ts, int? count) {
    if (count != null && ts != null) {
      return _count2ts2MaMap[count]?[ts];
    }
    return null;
  }

  /// 计算从index开始的count个close指标和
  /// 如果后续数据不够count个, 动态改变count. 最后平均. 所以最后的(count-1)个数据是不准确的.
  /// 注: 如果有旧数据加入, 需要重新计算最后的MA指标数据.
  MAResult calculateMA(
    List<CandleModel> list,
    int index,
    int count,
  ) {
    final dataLen = list.length;
    assert(
      index >= 0 && index < dataLen,
      'calculateMa index is invalid',
    );
    count = math.min(count, dataLen - index);
    Decimal sum = Decimal.zero;
    CandleModel m = list[index];
    for (int i = index; i < index + count; i++) {
      sum += list[i].close;
    }
    return MAResult(
      count: count,
      ts: m.timestamp,
      val: sum.div(count.d),
    );
  }

  /// 计算并缓存MA数据.
  /// 如果start和end指定了, 只计算[start, end]区间内.
  MinMax? calculateAndCacheMA(
    List<CandleModel> list,
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (list.isEmpty) return null;
    int len = list.length;
    if (len < count) return null;

    bool needReturn = start != null && end != null && start >= 0 && end < len;
    start ??= 0;
    end ??= len;
    if (start < 0 || end > len) return null;

    Map<int, MAResult> maMap = getCountMaMap(count);

    if (maMap.isNotEmpty) {
      if (reset ||
          maMap.getItem(list.getItem(start)?.timestamp) == null ||
          maMap.getItem(list.getItem(end)?.timestamp) == null) {
        logd(
          'calculateAndCacheMA reset:$reset >>> maMapLen:${maMap.length}, listLen$len : [$start, $end]',
        );
        // countMaMap.clear(); // 清理旧数据. TODO: 如何清理dirty数据
      } else {
        logd('calculateAndCacheMA use cache!!! [$start, $end]');
        if (start == 0) {
          //如果start是0, 有可能更新了最新价, 重新计算
          maMap[list.first.timestamp] = calculateMA(list, 0, count);
        }
      }
    }

    int index = end; // 多算一个
    CandleModel m = list[index];
    MAResult pre = maMap[m.timestamp] ?? calculateMA(list, index, count);
    maMap[m.timestamp] = pre;
    final minmax = MinMax(max: pre.val, min: pre.val);
    for (int i = index - 1; i >= start; i--) {
      m = list[i];
      MAResult? data = maMap[m.timestamp];
      if (data == null) {
        // TODO: 优化: 利用pre去计算.
        // val = pre * math.
      }
      data ??= calculateMA(list, i, count);
      if (needReturn) minmax.updateMinMaxByVal(data.val);
      pre = data;
      maMap[m.timestamp] = data;
    }
    return needReturn ? minmax : null;
  }
}
