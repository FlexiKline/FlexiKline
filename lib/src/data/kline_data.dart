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

import '../extension/collections_ext.dart';
import '../framework/logger.dart';
import '../model/export.dart';
import '../types.dart';

part 'base_data.dart';
part 'kline_spec.dart';
part 'candle_list.dart';
part 'paint_draw.dart';

class KlineData extends BaseData with KlineSpecData, CandleListData, PaintDrawData {
  KlineData(
    super.spec, {
    super.loadingState,
    super.list,
    super.computeMode,
    super.logger,
  });

  /// 重建所有蜡烛的 slots 到新容量
  ///
  /// 遍历 [_list] 中每条蜡烛，调用 [FlexiCandleModel.rebuildSlots] 并写回
  /// （extension type 值语义要求必须写回）。
  /// 当 [computedDataCapacity] 增加导致需要扩容时，由 StateBinding 调用此方法。
  void rebuildSlots(int newCount) {
    for (int i = 0; i < _list.length; i++) {
      _list[i] = _list[i].rebuildSlots(newCount);
    }
  }

  static final KlineData empty = KlineData(
    const KlineSpec(symbol: '', interval: invalidInterval),
    list: List.empty(growable: false),
  );
}

// 通过 compute(isolate) 方式预计算 KlineData 的历史尝试（已废弃）。
// data 在 MainIsolate 与 subIsolate 间传递时序列化/反序列化耗时较大, 暂不使用此方式。
// Future<KlineData> precomputeKlineDataByCompute(
//   KlineData data, {
//   required int computedDataCount,
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
//           computedDataCount: params[1],
//           newList: params[2],
//           calcParams: params[3],
//           reset: params[4],
//         );
//         return newData;
//       },
//       [data, computedDataCount, newList, calcParams, reset],
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
    logger?.logw('combineCandleList newList is empty!');
    return (oldList, Range.empty);
  }
  if (oldList.isEmpty) {
    logger?.logw('combineCandleList Use newList directly!');
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
  final n = list.length;
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
