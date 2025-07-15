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

library;

import 'package:flutter/foundation.dart';

import '../constant.dart';
import '../extension/export.dart';
import '../framework/chart/indicator.dart';
import '../framework/logger.dart';
import '../model/export.dart';

part 'base_data.dart';
part 'candle_req.dart';
part 'candle_list.dart';
part 'paint_draw.dart';
part 'indicator.dart';

class KlineData extends BaseData with CandleReqData, CandleListData, PaintDrawData, IndicatorData {
  KlineData(
    super.req,
    super.indicatorCount, {
    super.list,
    super.computeMode,
    super.logger,
  });

  final FlexiStopwatch stopwatch = FlexiStopwatch();

  static final KlineData empty = KlineData(
    const CandleReq(instId: "", bar: ""),
    0,
    list: List.empty(growable: false),
  );

  /// 预计算Kline指标数据
  /// [indicatorCount]指标图个数
  /// [newList] 新增的蜡烛数据
  /// [subPaintObjects] 待计算的指标集合
  /// [reset] 是否重置; 如果有, 忽略之前的计算结果.
  Future<void> precomputeKlineData({
    required List<CandleModel> newList,
    required Iterable<PaintObject> mainPaintObjects,
    required Iterable<PaintObject> subPaintObjects,
    bool reset = false,
  }) async {
    if (stopwatch.isRunning) {
      logd('precomputeKlineData is running, waitingData.size:${_waitingData.length}');
      _waitingData.add(newList);
      return;
    }

    try {
      stopwatch
        ..reset()
        ..start();

      /// 1. 合并数据
      final data = newList.isEmpty ? _waitingData : [newList, ..._waitingData];
      Range? range = stopwatch.run(
        () => mergeCandleData(data),
        label: '$logTag-mergeCandleData-${data.length}',
      );
      _waitingData.clear();

      /// 2. 确认要计算的范围.
      if (reset) range = allRange;
      if (range == null || range.isEmpty) {
        // 没有合并新的数据, 且不是重置, 则不计算
        logd('precomputeKlineData There is no data($range) to be calculated!');
        return;
      } else if (range.start < 0 || range.end >= length || range.length == length) {
        // 如果不是首根更新, 或者是加载更多(尾部)数据, 指标计算结果需要重置.
        range = allRange;
        reset = true;
      }

      /// 3. 计算指标数据
      logd('precomputeKlineData Start Main $reset-$range');
      for (final object in mainPaintObjects) {
        await stopwatch.exec(
          () => object.precompute(
            range!,
            reset: reset,
          ),
          label: '$logTag-Main-precompute:${object.key}-$range',
        );
      }

      logd('precomputeKlineData Start Sub $reset-$range');
      for (final object in subPaintObjects) {
        await stopwatch.exec(
          () => object.precompute(
            range!,
            reset: reset,
          ),
          label: '$logTag-Sub-precompute:${object.key}-$range',
        );
      }
      logd('precomputeKlineData End $reset-$range');
    } catch (e, stack) {
      loge('precomputeKlineData catch an exception!!!', error: e, stackTrace: stack);
    } finally {
      stopwatch.stop();
      if (_waitingData.isNotEmpty) {
        precomputeKlineData(
          newList: [],
          mainPaintObjects: mainPaintObjects,
          subPaintObjects: subPaintObjects,
        );
      }
    }
  }
}

/// 通过compute方式预计算KlineData.
/// 实际执行参考[KlineData.precomputeKlineData]
/// [data]将在MainIsolate和subIsolate之间传递,
/// [data]的序列化反序列化耗时较大, 暂不使用此方式.
// Future<KlineData> precomputeKlineDataByCompute(
//   KlineData data, {
//   required int indicatorCount,
//   required List<CandleModel> newList,
//   required Map<IIndicatorKey, dynamic> calcParams,
//   bool reset = false,
//   String? debugLabel,
//   ILogger? logger,
// }) async {
//   if (newList.isEmpty) {
//     return data;
//   }

//   try {
//     logger ??= data.loggerDelegate;
//     data.loggerDelegate = null;

//     logger?.logd('compute Begin:${DateTime.now()}');
//     data = await compute(
//       (List<dynamic> params) async {
//         final newData = await KlineData.precomputeKlineData(
//           params[0],
//           indicatorCount: params[1],
//           newList: params[2],
//           calcParams: params[3],
//           reset: params[4],
//         );
//         return newData;
//       },
//       [data, indicatorCount, newList, calcParams, reset],
//       debugLabel: debugLabel,
//     );
//     logger?.logd('compute End:${DateTime.now()}');
//   } on Object catch (e, stack) {
//     logger?.loge(
//       'precomputeKlineDataByCompute exception!!!',
//       error: e,
//       stackTrace: stack,
//     );
//   } finally {
//     data.loggerDelegate = logger;
//   }
//   return data;
// }

/// 合并[oldList]和[newList]为一个新数组
/// 约定: [newList]和[oldList]都是按时间倒序排好的, 即最近/新的蜡烛数据以数组0开始依次存放.
/// 去重: 如两个数组拼接过程中发现重复的, 要去掉[oldList]中重复的元素.
(List<CandleModel>, Range) combineCandleList(
  List<CandleModel> oldList,
  List<CandleModel> newList, {
  ILogger? logger,
}) {
  if (newList.isEmpty) {
    logger?.logw("combineCandleList newList is empty!");
    return (oldList, Range.empty);
  }
  if (oldList.isEmpty) {
    logger?.logw("combineCandleList Use newList directly!");
    return (List.of(newList), Range(0, newList.length));
  }

  if (oldList.first.ts <= newList.first.ts) {
    int start = 0;
    while (start < oldList.length && oldList[start].ts >= newList.last.ts) {
      start++;
    }
    final curIterable = oldList.getRange(start, oldList.length);
    final mergedList = List.of(newList, growable: true)..addAll(curIterable);
    return (
      mergedList,
      Range(0, newList.length),
    );
  } else if (oldList.last.ts >= newList.last.ts) {
    int end = oldList.length - 1;
    while (end >= 0 && oldList[end].ts <= newList.first.ts) {
      end--;
    }
    final curIterable = oldList.getRange(0, end + 1);
    final mergedlist = List.of(curIterable, growable: true)..addAll(newList);
    return (
      mergedlist,
      Range(end + 1, mergedlist.length),
    );
  }
  return (oldList, Range.empty);
}

/// 去重
List<CandleModel> removeDuplicate(List<CandleModel> list) {
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
