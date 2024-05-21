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

import '../config/export.dart';
import '../framework/indicator.dart';
import '../indicators/ma.dart';
import '../model/export.dart';
import 'base_data.dart';

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
      model.maList = null;
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
      calcuAndCacheMa(
        indicator.calcParams,
        start: start,
        end: end,
        reset: reset,
      );
    } else {
      super.preprocess(indicator, start: start, end: end, reset: reset);
    }
  }

  /// 计算 [index] 位置的 [count] 个数据的Ma指标.
  BagNum? calcuMa(
    int index,
    int count,
  ) {
    if (isEmpty) return null;
    int len = list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

    final m = list[index];

    BagNum sum = m.close;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].close;
    }

    return sum.divNum(count);
  }

  void _calculateMa(
    int count, {
    required int paramIndex,
    required int paramLen,
    int? start,
    int? end,
  }) {
    if (count <= 0 || isEmpty) return;
    int len = list.length;
    start ??= this.start;
    end ??= this.end;
    if (start < 0 || end > len) return;

    // 计算从end到len之间count的偏移量
    int offset = math.max(end + count - len, 0);
    int index = end - offset;

    /// 初始值化[index]位置的MA值
    CandleModel m = list[index];
    BagNum sum = m.close;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].close;
    }
    m.maList ??= List.filled(paramLen, null, growable: false);
    m.maList![paramIndex] = sum.divNum(count);

    for (int i = index - 1; i >= start; i--) {
      m = list[i];
      sum = sum - list[i + count].close + m.close;
      m.maList ??= List.filled(paramLen, null, growable: false);
      m.maList![paramIndex] = sum.divNum(count);
    }
  }

  void calcuAndCacheMa(
    List<MaParam> calcParams, {
    int? start,
    int? end,
    bool reset = false,
  }) {
    if (isEmpty || calcParams.isEmpty) return;
    final paramLen = calcParams.length;
    for (int i = 0; i < paramLen; i++) {
      _calculateMa(
        calcParams[i].count,
        paramIndex: i,
        paramLen: paramLen,
        start: start,
        end: end,
      );
    }
  }

  /// 计算并缓存MA数据.
  /// 如果[start]和[end]指定了, 只计算[start] ~ [end]区间内的MA值.
  /// 否则, 从当前可视区域的[start] ~ [end]开始计算.
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

    int minCount = MaParam.getMinCountByList(calcParams)!;
    end = math.min(len - minCount, end - 1);

    if (!list[end].isValidMaList) {
      calcuAndCacheMa(calcParams, start: 0, end: len);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end; i >= start; i--) {
      m = list[i];
      minmax ??= m.maListMinmax;
      minmax?.updateMinMax(m.maListMinmax);
    }
    return minmax;
  }
}
