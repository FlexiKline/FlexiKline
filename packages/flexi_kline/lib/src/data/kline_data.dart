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
