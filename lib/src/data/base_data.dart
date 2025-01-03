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

part of 'kline_data.dart';

/// KlineData基类
///
/// [req] 蜡烛数据请求
/// [list] 蜡烛数据列表
/// [start] 当前绘制区域起始下标
/// [end] 当前绘制区域结束下标
/// 注: 对于BaseData的指标计算mixin: 仅保留计算逻辑, 不持有状态, 计算结果统一整合在[CandleModel]中.
abstract class BaseData with KlineLog {
  @override
  String get logTag => req.key;

  BaseData(
    this.req, {
    List<CandleModel> list = const [],
    ILogger? logger,
  }) : _list = List.of(list) {
    loggerDelegate = logger;
    initData();
  }

  @protected
  @mustCallSuper
  void initData() {
    logd("init BASE");
  }

  @mustCallSuper
  void dispose() {
    logd('dispose BASE');
    loggerDelegate = null;
    list.clear();
    start = 0;
    end = 0;
  }

  /// 预计算指标数据
  /// [key] 对应指标图的key
  /// [calcParam] 对应指标图的计算参数
  /// [range] 预计算的范围
  /// [reset] 是否重置; 如果有, 忽略之前的计算结果.
  @protected
  @mustCallSuper
  void precompute(
    IIndicatorKey key, {
    dynamic calcParam,
    required Range range,
    bool reset = false,
  }) {
    logd('precompute BASE(key:$key, $range, $reset, $calcParam)');
  }

  CandleReq req;

  List<CandleModel> _list;
  List<CandleModel> get list => _list;

  int get length => list.length;
  bool get isEmpty => list.isEmpty;

  bool get canPaintChart {
    return !isEmpty && list.checkIndex(start); // TODO && list.checkIndex(end);
  }

  CandleModel? get latest => list.firstOrNull;

  bool checkStartAndEnd(int start, int end) {
    return list.isNotEmpty && start < end && start >= 0 && end <= list.length;
  }

  bool checkIndex(int index) => index >= 0 && index < length;

  /// 初始化基础数据
  void initBasicData(
    ComputeMode mode,
    Range range,
    int indicatorCount, {
    bool reset = false,
  }) {
    for (int i = range.start; i < range.end; i++) {
      // for (var m in _list) {
      _list[i].initBasicData(mode, indicatorCount, reset: reset);
    }
  }

  /// 根据[start, end]下标计算最大最小值
  MinMax? calculateMinmax(int start, int end) {
    if (!checkStartAndEnd(start, end)) return null;

    CandleModel m = list[end - 1];
    BagNum maxHigh = m.high;
    BagNum minLow = m.low;
    for (int i = end - 2; i >= start; i--) {
      m = list[i];
      maxHigh = m.high > maxHigh ? m.high : maxHigh;
      minLow = m.low < minLow ? m.low : minLow;
    }
    return MinMax(max: maxHigh, min: minLow);
  }

  /// 获取index位置的蜡烛数据.
  CandleModel? getCandle(int? index) {
    if (index != null && index >= 0 && index < list.length) {
      return list[index];
    }
    return null;
  }

  int _start = 0;

  /// 当前绘制区域起始下标 右
  int get start => _start;
  set start(int val) {
    _start = val.clamp(0, list.length);
  }

  int _end = 0;

  /// 当前绘制区域结束下标 左
  /// 注: 遍历时, 应 < end;
  int get end => _end;
  set end(int val) {
    _end = val.clamp(0, list.length);
  }

  void ensureStartAndEndIndex(
    int startIndex,
    int maxCandleCount,
  ) {
    start = startIndex;
    end = startIndex + maxCandleCount;
  }

  Range get computableRange => Range(0, length);

  Range? get drawTimeRange {
    if (checkStartAndEnd(start, end)) {
      return Range(list[start].ts, list[end].ts);
    }
    return null;
  }

  /// 将[ts]转换为当前KlineData数据列表的下标和剩余偏移率
  /// 如果ts > 最新价, 将为负
  double? timestampToIndex(int ts) {
    if (list.isEmpty || req.timeBar == null) return null;
    int latestIndex = 0; // TODO: 后续性能优化考虑数据方向
    final timespans = req.timeBar!.milliseconds;
    final first = list.first;
    final last = list.last;
    if (ts > first.ts) {
      // 超出蜡烛数据时间范围, 不予考虑交易时间问题
      final distance = first.ts - ts;
      final value = distance / timespans;
      return latestIndex + value;
    } else if (ts <= last.ts) {
      // 超出蜡烛数据时间范围, 不予考虑交易时间问题
      final distance = last.ts - ts;
      final value = distance / timespans;
      return list.length - 1 + value;
    } else {
      int i = latestIndex;
      final distance = first.ts - ts;
      final indexValue = distance / timespans;
      final index = indexValue.truncate();
      final patch = indexValue - index;
      for (; i < list.length; i++) {
        if (ts == list[i].ts) break;
        if (ts > list[i].ts) {
          i--;
          break;
        }
      }
      return i + patch;
    }
  }

  /// 将[indexValue]转换为以当前KlineData数据范围为基础的timestamp
  int? indexToTimestamp(double indexValue) {
    if (list.isEmpty || req.timeBar == null) return null;
    final timespans = req.timeBar!.milliseconds;
    final index = indexValue.toInt();
    final patchTs = ((indexValue - index) * timespans).truncate();
    if (index < 0) {
      return list.first.ts - index * timespans - patchTs;
    } else if (index >= list.length - 1) {
      return list.last.ts - (index + 1 - list.length) * timespans - patchTs;
    } else {
      return list[index].ts - patchTs;
    }
  }

  /// 合并[list]和[newList]为一个新数组
  /// 约定: [newList]和[list]都是按时间倒序排好的, 即最近/新的蜡烛数据以数组0开始依次存放.
  /// 去重: 如两个数组拼接过程中发现重复的, 要去掉[list]中重复的元素.
  /// return: 返回新列表中被更新的范围[start] ~ [end]
  Range? mergeCandleList(List<CandleModel> newList) {
    if (newList.isEmpty) {
      logw("mergeCandleList newList is empty!");
      return null;
    }
    if (list.isEmpty) {
      logw("mergeCandleList Use newList directly!");
      _list = List.of(newList);
      return Range(0, newList.length);
    }

    if (list.first.ts <= newList.first.ts) {
      int start = 0;
      while (start < list.length && list[start].ts >= newList.last.ts) {
        start++;
      }
      final curIterable = list.getRange(start, list.length);
      _list = List.of(newList, growable: true)..addAll(curIterable);
      // _list = List.of([...newList, ...curIterable]);
      return Range(0, newList.length);
    } else if (list.last.ts >= newList.last.ts) {
      int end = list.length - 1;
      while (end >= 0 && list[end].ts <= newList.first.ts) {
        end--;
      }
      final curIterable = list.getRange(0, end + 1);
      _list = List.of(curIterable, growable: true)..addAll(newList);
      // _list =  List.of([...curIterable, ...newList]);
      return Range(end + 1, _list.length);
    }
    return null;
  }

  static List<CandleModel> removeDuplicate(List<CandleModel> list) {
    int n = list.length;
    int fast = 1;
    int slow = 1;
    while (fast < n) {
      if (list[fast].ts != list[fast - 1].ts) {
        list[slow] = list[fast];
        ++slow;
      }
      ++fast;
    }
    return list.sublist(0, slow);
  }
}
