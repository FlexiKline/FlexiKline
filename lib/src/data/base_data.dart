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

import 'package:flutter/foundation.dart';

import '../extension/export.dart';
import '../framework/indicator.dart';
import '../model/export.dart';
import '../utils/export.dart';

abstract class BaseData with KlineLog {
  @override
  String get logTag => '${super.logTag}\tDADA';

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

  @protected
  @mustCallSuper
  void dispose() {
    logd('dispose BASE');
    // TODO: 是否要缓存
    list.clear();
    start = 0;
    end = 0;
  }

  @protected
  @mustCallSuper
  void preprocess(
    Indicator indicator, {
    required int start,
    required int end,
    bool reset = false,
  }) {
    logd('preprocess BASE[$start, $end]$reset');
  }

  // /// 绘制前: 重置计算结果.
  // @protected
  // @mustCallSuper
  // void resetCalcuResult() {
  //   logd('resetCalcuResult BASE');
  // }

  final CandleReq req;
  List<CandleModel> _list = List.empty(growable: true);
  List<CandleModel> get list => _list;

  int get length => list.length;
  bool get isEmpty => list.isEmpty;

  bool get canPaintChart {
    return !isEmpty && list.checkIndex(start); // TODO && list.checkIndex(end);
  }

  CandleModel? get latest => list.firstOrNull;

  /// 获取index位置的蜡烛数据.
  CandleModel? getCandle(int? index) {
    if (index != null && index >= 0 && index < list.length) {
      return list[index];
    }
    return null;
  }

  /// 当前绘制区域起始下标 右
  int _start = 0;
  int get start => _start;
  set start(int val) {
    _start = val.clamp(0, list.length);
  }

  /// 当前绘制区域结束下标 左
  /// 注: 遍历时, 应 < end;
  int _end = 0;
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

  /// 合并newList到list
  void mergeCandleList(
    List<CandleModel> newList, {
    bool replace = false,
  }) {
    if (newList.isEmpty) {
      logw("mergeCandleList newList is empty!");
      return;
    }
    if (list.isEmpty || replace) {
      logw("mergeCandleList Use newList directly! $replace");
      _list = List.of(newList);
      return;
    }

    int curAfter = list.first.timestamp; // 此时间ts之前的数据
    int curBefore = list.last.timestamp; // 此时间ts之后的数据
    assert(
      curAfter >= curBefore,
      "curAfter($curAfter) should be greater than curBefore($curBefore)!",
    );

    int newAfter = newList.first.timestamp; // 此时间ts之前的数据
    int newBefore = newList.last.timestamp; // 此时间ts之后的数据
    assert(
      newAfter >= newBefore,
      "newAfter($newAfter) should be greater than newBefore($newBefore)!",
    );

    // 根据两个数组范围[after, before], 合并去重
    if (newBefore > curAfter) {
      // newList拼接到列表前面
      _list = [...newList, ...list];
    } else if (newAfter < curBefore) {
      // newList拼接到列表尾部
      _list = [...list, ...newList];
    } else {
      List<CandleModel> allList = [...list, ...newList];
      allList.sort((a, b) => b.timestamp - a.timestamp); // 排序
      allList = removeDuplicate(allList);
      _list = allList;
      // newList在list有重叠, 需要合并. // TODO: 后续算法优化
      // int newLen = newList.length;
      // int curLen = list.length;
      // int newIndex = 0;
      // int curIndex = 0;
      // CandleModel curData;
      // while (newIndex < newLen || curIndex < curLen) {
      //   if (newIndex == newLen) curData = newList[newIndex];
      //   if (curIndex == curLen) curData = list[curIndex];
      //   if (list[curIndex].timestamp < newList[newIndex].timestamp) {
      //     curData = list[curIndex++];
      //   } else {
      //     curData = newList[newIndex++];
      //   }
      //   // list[]
      // }
    }
  }

  static List<CandleModel> removeDuplicate(List<CandleModel> list) {
    int n = list.length;
    int fast = 1;
    int slow = 1;
    while (fast < n) {
      if (list[fast].timestamp != list[fast - 1].timestamp) {
        list[slow] = list[fast];
        ++slow;
      }
      ++fast;
    }
    return list.sublist(0, slow);
  }
}
