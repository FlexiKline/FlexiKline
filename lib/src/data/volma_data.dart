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

import '../framework/indicator.dart';
import '../indicators/vol_ma.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'results.dart';

mixin VOLMAData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init VOLMA');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose VOLMA');
    for (var model in list) {
      model.volMaRets = null;
    }
  }

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (indicator is VolMaIndicator) {
      final startTime = DateTime.now();
      calcuAndCacheVolMa(indicator.calcParams, start: start, end: end);
      logd(
        'preprocess VOLMA => total spent:${DateTime.now().difference(startTime).inMicroseconds} microseconds',
      );
    } else {
      super.preprocess(indicator, start: start, end: end, reset: reset);
    }
  }

  /// 计算 [index] 位置的 [count] 个数据的Ma指标.
  BagNum? calcuVolMa(
    int index,
    int count,
  ) {
    if (isEmpty) return null;
    int len = list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

    final m = list[index];

    BagNum sum = m.vol;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].vol;
    }

    return sum.divNum(count);
  }

  void calcuAndCacheVolMa(
    List<MaParam> calcParams, {
    int? start,
    int? end,
  }) {
    if (isEmpty || calcParams.isEmpty) return;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return;

    int? maxCount = MaParam.getMaxCountByList(calcParams);
    end = math.min(end + maxCount!, len);

    CandleModel m;
    final paramLen = calcParams.length;
    final volSum = List.filled(paramLen, BagNum.zero, growable: false);
    for (int i = end - 1; i >= start; i--) {
      m = list[i];
      m.volMaRets = List.filled(calcParams.length, null, growable: false);
      for (int j = 0; j < calcParams.length; j++) {
        volSum[j] += m.vol;
        final count = calcParams[j].count;
        if (i <= end - count) {
          m.volMaRets![j] = volSum[j].divNum(count);
          volSum[j] -= list[i + (count - 1)].vol;
        }
      }
    }
  }

  MinMax? calcuVolMaMinmax(
    List<MaParam> calcParams, {
    int? start,
    int? end,
  }) {
    if (isEmpty || calcParams.isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    if (list[start].isValidVolMaRets != true ||
        list[end - 1].isValidVolMaRets != true) {
      calcuAndCacheVolMa(calcParams, start: start, end: end);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end - 1; i >= start; i--) {
      m = list[i];
      minmax ??= m.volMaRetsMinmax;
      minmax?.updateMinMax(m.volMaRetsMinmax);
    }
    return minmax;
  }
}

@Deprecated('废弃的')
mixin VOLMAData2 on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init VOLMA');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose VOLMA');
    // TODO: 是否要缓存
    _volmaResultMap.clear();
  }

  @override
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    if (indicator is VolMaIndicator) {
      for (var param in indicator.calcParams) {
        final startTime = DateTime.now();
        calculateAndCacheVolma(
          param.count,
          start: start,
          end: end,
          reset: reset,
        );
        logd(
          'preprocess VOLMA => ${param.count} spent:${DateTime.now().difference(startTime).inMicroseconds} microseconds',
        );
      }
    } else {
      super.preprocess(indicator, start: start, end: end, reset: reset);
    }
  }

  /// MAVOL数据缓存 <count, <timestamp, result>>
  final Map<int, Map<int, MaResult>> _volmaResultMap = {};

  Map<int, MaResult> getVolmaMap(int count) {
    _volmaResultMap[count] ??= {};
    return _volmaResultMap[count]!;
  }

  MaResult? getVolmaResult({int? count, int? ts}) {
    if (count != null && ts != null) {
      return _volmaResultMap[count]?[ts];
    }
    return null;
  }

  /// 计算从index开始的count个vol指标和
  /// 如果后续数据不够count个, 动态改变count. 最后平均. 所以最后的(count-1)个数据是不准确的.
  /// 注: 如果有旧数据加入, 需要重新计算最后的MA指标数据.
  MaResult? calculateVolma(
    int index,
    int count,
  ) {
    if (isEmpty) return null;
    int len = list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

    final m = list[index];

    final ret = getVolmaResult(count: count, ts: m.timestamp);
    if (ret != null && !ret.dirty) {
      return ret;
    }

    BagNum sum = m.vol;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].vol;
    }

    return MaResult(
      count: count,
      ts: m.timestamp,
      val: sum.divNum(count),
      dirty: index == 0, // 如果是第一根蜡烛的数据.下次需要重新计算.
    );
  }

  /// 计算并缓存MAVol数据.
  /// 如果start和end指定了, 只计算[start, end]区间内.
  /// 否则, 从当前绘制的[start, end]开始计算.
  void calculateAndCacheVolma(
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

    final maVolMap = getVolmaMap(count);
    if (reset) {
      maVolMap.clear();
    }

    // 计算从end到len之间count的偏移量
    int offset = math.max(end + count - len, 0);
    int index = end - offset;

    BagNum cD = BagNum.fromInt(count);
    CandleModel m = list[index];
    BagNum sum = m.vol;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].vol;
    }
    MaResult? ret = MaResult(count: count, ts: m.timestamp, val: sum.div(cD));
    maVolMap[m.timestamp] = ret;

    for (int i = index - 1; i >= start; i--) {
      m = list[i];
      sum = sum - list[i + count].vol + m.vol;
      ret = maVolMap[m.timestamp];
      if (ret == null || ret.dirty) {
        ret = MaResult(count: count, ts: m.timestamp, val: sum.div(cD));
      }
      maVolMap[m.timestamp] = ret;
    }
  }

  MinMax? calculateMavolMinmax(
    int count, {
    int? start,
    int? end,
  }) {
    if (count <= 0 || isEmpty) return null;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return null;

    final mavolMap = getVolmaMap(count);

    int offset = math.max(end + count - len, 0);
    int index = end - offset;

    if (index < start) return null;
    if (mavolMap.isEmpty ||
        mavolMap[list[start].timestamp] == null ||
        mavolMap[list[index].timestamp] == null) {
      calculateAndCacheVolma(count, start: start, end: end, reset: true);
    }

    MinMax? minmax;
    MaResult? ret;
    for (int i = index; i >= start; i--) {
      ret = mavolMap[list[i].timestamp];
      if (ret != null) {
        minmax ??= MinMax(max: ret.val, min: ret.val);
        minmax.updateMinMaxBy(ret.val);
      }
    }
    return minmax;
  }
}
