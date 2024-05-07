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
    for (var model in list) {
      model.maRets = null;
    }
  }

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (indicator is MAIndicator) {
      final startTime = DateTime.now();
      calcuAndCacheMa(indicator.calcParams, start: start, end: end);
      logd(
        'preprocess MA => total spent:${DateTime.now().difference(startTime).inMicroseconds} microseconds',
      );
    } else {
      super.preprocess(indicator, start: start, end: end, reset: reset);
    }
  }

  /// 计算 [index] 位置的 [count] 个数据的Ma指标.
  Decimal? calcuMa(
    int index,
    int count,
  ) {
    if (isEmpty) return null;
    int len = list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

    final m = list[index];

    Decimal sum = m.close;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].close;
    }

    return sum.div(count.d);
  }

  void calcuAndCacheMa(
    List<MaParam> calcParams, {
    int? start,
    int? end,
  }) {
    if (isEmpty || calcParams.isEmpty) return;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return;
    int? minCount;

    for (var param in calcParams) {
      minCount ??= param.count;
      minCount = param.count < minCount ? param.count : minCount;
    }

    end = math.min(end + minCount!, len);

    CandleModel m;
    final paramLen = calcParams.length;
    final closeSum = List.filled(paramLen, Decimal.zero, growable: false);
    for (int i = end - 1; i >= start; i--) {
      m = list[i];
      m.maRets = List.filled(calcParams.length, null, growable: false);
      for (int j = 0; j < calcParams.length; j++) {
        closeSum[j] += m.close;
        final count = calcParams[j].count;
        if (i <= end - count) {
          m.maRets![j] = closeSum[j].div(count.d);
          closeSum[j] -= list[i + (count - 1)].close;
        }
      }
    }
  }

  MinMax? calcuMaMinmax(
    List<MaParam> calcParams, {
    int? start,
    int? end,
  }) {
    if (isEmpty || calcParams.isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    if (list[start].isValidMaRets != true ||
        list[end - 1].isValidMaRets != true) {
      calcuAndCacheMa(calcParams, start: start, end: end);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end - 1; i >= start; i--) {
      m = list[i];
      minmax ??= m.maRetsMinmax;
      minmax?.updateMinMax(m.maRetsMinmax);
    }
    return minmax;
  }
}

mixin MAData2 on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init MA');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose MA');
    _maResultMap.clear();
  }

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (indicator is MAIndicator) {
      for (var param in indicator.calcParams) {
        final startTime = DateTime.now();
        calculateAndCacheMa(
          param.count,
          start: start,
          end: end,
          reset: reset,
        );
        logd(
          'preprocess MA => ${param.count} spent:${DateTime.now().difference(startTime).inMicroseconds} microseconds',
        );
      }
    } else {
      super.preprocess(indicator, start: start, end: end, reset: reset);
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
  void calculateAndCacheMa(
    int count, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (count <= 0 || isEmpty) return;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return;

    final maMap = getMaMap(count);
    if (reset) {
      maMap.clear();
    }

    // 计算从end到len之间count的偏移量
    int offset = math.max(end + count - len, 0);
    int index = end - offset;

    Decimal cD = Decimal.fromInt(count);
    CandleModel m = list[index];
    Decimal sum = m.close;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].close;
    }
    MaResult? ret = MaResult(count: count, ts: m.timestamp, val: sum.div(cD));
    maMap[m.timestamp] = ret;

    for (int i = index - 1; i >= start; i--) {
      m = list[i];
      sum = sum - list[i + count].close + m.close;
      ret = maMap[m.timestamp];
      if (ret == null || ret.dirty) {
        ret = MaResult(count: count, ts: m.timestamp, val: sum.div(cD));
      }
      maMap[m.timestamp] = ret;
    }
  }

  MinMax? calculateMaMinmax(
    int count, {
    int? start,
    int? end,
  }) {
    if (count <= 0 || isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    final maMap = getMaMap(count);

    int offset = math.max(end + count - len, 0);
    int index = end - offset;

    if (index < start) return null;
    if (maMap.isEmpty ||
        maMap[list[start].timestamp] == null ||
        maMap[list[index].timestamp] == null) {
      calculateAndCacheMa(count, start: start, end: end, reset: true);
    }

    MinMax? minmax;
    MaResult? ret;
    for (int i = index; i >= start; i--) {
      ret = maMap[list[i].timestamp];
      if (ret != null) {
        minmax ??= MinMax(max: ret.val, min: ret.val);
        minmax.updateMinMaxByVal(ret.val);
      }
    }
    return minmax;
  }
}
