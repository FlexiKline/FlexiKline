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
import '../framework/indicator.dart';
import '../indicators/ma.dart';
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
    _maResultMap.clear();
  }

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    super.preprocess(indicator, start: start, end: end, reset: reset);
    if (indicator is MAIndicator) {
      for (var param in indicator.calcParams) {
        logd('preprocess MA => ${param.count}');
        calculateAndCacheMa(
          param.count,
          start: start,
          end: end,
          reset: reset,
        );
      }
    }
  }

  /// MA数据缓存 <count, <timestamp, Decimal>>
  final Map<int, Map<int, MaResult>> _maResultMap = {};

  Map<int, MaResult> getMaMap(int count) {
    _maResultMap[count] ??= {};
    return _maResultMap[count]!;
  }

  MaResult? getMaResult({int? count, int? ts}) {
    if (count != null && ts != null) {
      return _maResultMap[count]?[ts];
    }
    return null;
  }

  /// 计算从index(包含index)开始的count个收盘价的平均数
  /// 注: 如果index开始后不足count, 不矛计算, 返回空.
  MaResult? calculateMa(
    int index,
    int count,
  ) {
    if (isEmpty) return null;
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

    return MaResult(
      count: count,
      ts: m.timestamp,
      val: sum.div(count.d),
      dirty: index == 0, // 如果是第一根蜡烛的数据.下次需要重新计算.
    );
  }

  /// 计算并缓存MA数据.
  /// 如果start和end指定了, 只计算[start, end]区间内.
  /// 否则, 从当前绘制的[start, end]开始计算.
  MinMax? calculateAndCacheMa(
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (count <= 0 || isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    final maMap = getMaMap(count);
    if (reset) {
      maMap.clear();
    }

    // 计算从end到len之间count的偏移量
    int offset = math.max(end + count - len, 0);
    int index = end - offset;
    CandleModel m;
    MaResult? preRet = maMap.getItem(list.getItem(index + 1)?.timestamp);
    MaResult? curRet;
    MinMax? minmax;
    Decimal cD = Decimal.fromInt(count);
    for (int i = index; i >= start; i--) {
      m = list[i];
      curRet = maMap[m.timestamp];
      if (curRet == null || curRet.dirty) {
        // 没有缓存或无效, 计算MA
        if (preRet != null && !preRet.dirty && i + count < len) {
          // 用上一次结果进行换算当前结果
          curRet = MaResult(
            count: count,
            ts: m.timestamp,
            val: ((preRet.val * cD) - list[i + count].close + m.close).div(cD),
            dirty: i == 0,
          );
        } else {
          curRet = calculateMa(index, count);
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
  }
}
