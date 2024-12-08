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

part of 'vol_ma.dart';

@visibleForTesting
extension on CandleModel {
  List<BagNum?>? getVolMaList(int dataIndex, [int? paramLen]) {
    List<BagNum?>? list = calcuData.getData(dataIndex);
    if (list == null && paramLen != null && paramLen > 0) {
      calcuData.setData(
        dataIndex,
        list = List.filled(paramLen, null, growable: false),
      );
    }
    return list;
  }

  bool isValidVolMaList(int dataIndex) {
    return getVolMaList(dataIndex)?.hasValidData ?? false;
  }

  MinMax? getVolMaListMinmax(int dataIndex) {
    return MinMax.getMinMaxByList(getVolMaList(dataIndex));
  }

  void cleanVolMaData(int dataIndex) {
    calcuData.setData(dataIndex, null);
  }
}

mixin VolmaDataMixin<T extends VolMaIndicator> on SinglePaintObjectBox<T> {
  List<MaParam> get calcParam => indicator.calcParams;

  @override
  void precompute(Range range, {bool reset = false}) {
    calcuAndCacheVolMa(
      calcParam,
      start: range.start,
      end: range.end,
      // reset: reset,
    );
  }

  /// 计算 [index] 位置的 [count] 个数据的Ma指标.
  BagNum? calcuVolMa(
    int index,
    int count,
  ) {
    if (klineData.isEmpty) return null;
    int len = klineData.list.length;
    if (count <= 0 || index < 0 || index + count > len) return null;

    final m = klineData.list[index];

    BagNum sum = m.vol;
    for (int i = index + 1; i < index + count; i++) {
      sum += klineData.list[i].vol;
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
    final len = klineData.list.length;
    start ??= klineData.start;
    end ??= klineData.end;
    if (count > len || !klineData.checkStartAndEnd(start, end)) return;
    logd('calculateVolMa [end:$end ~ start:$start] count:$count');

    end = math.min(len - count, end - 1);

    /// 初始值化[index]位置的MA值
    CandleModel m = klineData.list[end];
    BagNum sum = m.vol;
    for (int i = end + 1; i < end + count; i++) {
      sum += klineData.list[i].vol;
    }

    m.getVolMaList(dataIndex, paramLen)?[paramIndex] = sum.divNum(count);

    for (int i = end - 1; i >= start; i--) {
      m = klineData.list[i];
      sum = sum - klineData.list[i + count].vol + m.vol;
      m.getVolMaList(dataIndex, paramLen)?[paramIndex] = sum.divNum(count);
    }
  }

  void calcuAndCacheVolMa(
    List<MaParam> calcParams, {
    required int start,
    required int end,
  }) {
    if (klineData.isEmpty || calcParams.isEmpty) return;
    final paramLen = calcParams.length;
    for (int i = 0; i < paramLen; i++) {
      _calculateVolMa(
        calcParams[i].count,
        paramIndex: i,
        paramLen: paramLen,
        start: math.max(0, start - calcParams[i].count), // 补起上一次未算数据
        end: end,
      );
    }
  }

  MinMax? calcuVolMaMinmax(
    List<MaParam> calcParams, {
    int? start,
    int? end,
  }) {
    start ??= klineData.start;
    end ??= klineData.end;
    if (calcParams.isEmpty || !klineData.checkStartAndEnd(start, end)) {
      return null;
    }
    final len = klineData.list.length;

    int minCount = MaParam.getMinCountByList(calcParams)!;
    end = math.min(len - minCount, end - 1);

    if (end < start) return null;
    if (!klineData.list[end].isValidVolMaList(dataIndex)) {
      calcuAndCacheVolMa(calcParams, start: 0, end: len);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = end; i >= start; i--) {
      m = klineData.list[i];
      minmax ??= m.getVolMaListMinmax(dataIndex);
      minmax?.updateMinMax(m.getVolMaListMinmax(dataIndex));
    }
    return minmax;
  }

  MinMax? calculateVolMinmax({
    int? start,
    int? end,
  }) {
    start ??= klineData.start;
    end ??= klineData.end;
    if (!klineData.checkStartAndEnd(start, end)) return null;

    CandleModel m = klineData.list[end - 1];
    BagNum minVol = m.vol;
    BagNum maxVol = m.vol;
    for (int i = end - 2; i >= start; i--) {
      m = klineData.list[i];
      maxVol = m.vol > maxVol ? m.vol : maxVol;
      minVol = m.vol < minVol ? m.vol : minVol;
    }
    return MinMax(max: maxVol, min: minVol);
  }
}
