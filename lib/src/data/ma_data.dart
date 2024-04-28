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

  MAResult? getMaResult({int? count, int? ts}) {
    if (count != null && ts != null) {
      return _count2ts2MaMap[count]?[ts];
    }
    return null;
  }

  /// 计算从index(包含index)开始的count个收盘价的平均数
  /// 注: 如果index开始后不足count, 不矛计算, 返回空.
  MAResult? calculateMA(
    int index,
    int count,
  ) {
    if (list.isEmpty) return null;
    int len = list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

    final m = list[index];

    final ret = getMaResult(count: count, ts: m.timestamp);
    if (ret != null && !ret.dirty) {
      return ret;
    }

    Decimal sum = m.close;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].close;
    }

    return MAResult(
      count: count,
      ts: m.timestamp,
      val: sum.div(count.d),
      dirty: index == 0, // 如果是第一根蜡烛的数据.下次需要重新计算.
    );
  }

  /// 计算并缓存MA数据.
  /// 如果start和end指定了, 只计算[start, end]区间内.
  /// 否则, 从当前绘制的[start, end]开始计算.
  MinMax? calculateAndCacheMA(
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (list.isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (len < count || start < 0 || end > len) return null;

    Map<int, MAResult> maMap = getCountMaMap(count);

    if (reset) {
      maMap.clear();
    }

    // 计算从end到len之间count的偏移量
    int offset = math.max(end + count - len, 0);
    int index = end - offset;
    CandleModel m;
    MAResult? preRet = maMap.getItem(list.getItem(index + 1)?.timestamp);
    MAResult? curRet;
    MinMax? minmax;
    Decimal cD = Decimal.fromInt(count);
    for (int i = index; i >= start; i--) {
      m = list[i];
      curRet = maMap[m.timestamp];
      if (curRet == null || curRet.dirty) {
        // 没有缓存或无效, 计算MA
        if (preRet != null && i + count < len) {
          // 用上一次结果进行换算当前结果
          curRet = MAResult(
            count: count,
            ts: m.timestamp,
            val: ((preRet.val * cD) - list[i + count].close + m.close).div(cD),
          );
        } else {
          curRet = calculateMA(index, count);
        }
      }

      if (curRet != null) {
        maMap[m.timestamp] = curRet;
        minmax ??= MinMax(max: curRet.val, min: curRet.val);
        minmax.updateMinMaxByVal(curRet.val);
      }
      preRet = curRet;
    }

    return minmax;

    // if (maMap.isNotEmpty) {
    //   if (reset ||
    //       maMap.getItem(list.getItem(start)?.timestamp) == null ||
    //       maMap.getItem(list.getItem(end)?.timestamp) == null) {
    //     logd(
    //       'calculateAndCacheMA reset:$reset >>> maMapLen:${maMap.length}, listLen$len : [$start, $end]',
    //     );
    //     // countMaMap.clear(); // 清理旧数据. TODO: 如何清理dirty数据
    //   } else {
    //     logd('calculateAndCacheMA use cache!!! [$start, $end]');
    //     if (start == 0) {
    //       //如果start是0, 有可能更新了最新价, 重新计算
    //       maMap[list.first.timestamp] = calculateMA(list, 0, count);
    //     }
    //   }
    // }

    // int index = end; // 多算一个
    // CandleModel m = list[index];
    // MAResult pre = maMap[m.timestamp] ?? calculateMA(list, index, count);
    // maMap[m.timestamp] = pre;
    // final minmax = MinMax(max: pre.val, min: pre.val);
    // for (int i = index - 1; i >= start; i--) {
    //   m = list[i];
    //   MAResult? data = maMap[m.timestamp];
    //   if (data == null) {
    //     // TODO: 优化: 利用pre去计算.
    //     // val = pre * math.
    //   }
    //   data ??= calculateMA(list, i, count);
    //   if (needReturn) minmax.updateMinMaxByVal(data.val);
    //   pre = data;
    //   maMap[m.timestamp] = data;
    // }
    // return needReturn ? minmax : null;
  }
}
