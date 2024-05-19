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
      model.cleanVolMa();
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
      calcuAndCacheVolMa(indicator.calcParams, start: start, end: end);
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

  void _calculateVolMa(
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
    BagNum sum = m.vol;
    for (int i = index + 1; i < index + count; i++) {
      sum += list[i].vol;
    }
    m.volMaList ??= List.filled(paramLen, null, growable: false);
    m.volMaList![paramIndex] = sum.divNum(count);

    for (int i = index - 1; i >= start; i--) {
      m = list[i];
      sum = sum - list[i + count].vol + m.vol;
      m.volMaList ??= List.filled(paramLen, null, growable: false);
      m.volMaList![paramIndex] = sum.divNum(count);
    }
  }

  void calcuAndCacheVolMa(
    List<MaParam> calcParams, {
    int? start,
    int? end,
  }) {
    if (isEmpty || calcParams.isEmpty) return;
    final paramLen = calcParams.length;
    for (int i = 0; i < paramLen; i++) {
      _calculateVolMa(
        calcParams[i].count,
        paramIndex: i,
        paramLen: paramLen,
        start: start,
        end: end,
      );
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

    int minCount = MaParam.getMinCountByList(calcParams)!;
    end = math.min(len - minCount, end - 1);

    if (end < start) return null;
    if (!list[end].isValidVolMaList) {
      calcuAndCacheVolMa(calcParams, start: 0, end: len);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end; i >= start; i--) {
      m = list[i];
      minmax ??= m.volMaListMinmax;
      minmax?.updateMinMax(m.volMaListMinmax);
    }
    return minmax;
  }
}
