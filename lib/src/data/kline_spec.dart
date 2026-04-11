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

mixin KlineSpecData on BaseData {
  String get symbol => spec.symbol;
  int get precision => spec.precision;
  String get key => spec.key;
  String get rangeKey => spec.rangeKey;
  ITimeInterval get timeBar => spec.timeBar;

  @override
  void updateState({KlineLoadingState state = KlineLoadingState.none}) {
    _loadingState = state;
    _spec = spec.copyWith(
      from: list.lastOrNull?.ts,
      to: list.firstOrNull?.ts,
    );
    // from/to 仅更新 spec，是否通知由 StateBinding 按 key 决定
  }

  /// 返回用于加载更多历史数据的规格（to 置空，向旧方向无限翻页）
  KlineSpec getLoadMoreSpec() {
    return spec.copyWith(
      from: null,
      to: list.lastOrNull?.ts,
    );
  }

  /// 返回用于刷新最新数据的规格
  KlineSpec getRefreshSpec([bool reset = false]) {
    if (isEmpty || reset) {
      return spec.copyWith(from: null, to: null);
    }
    final model = list.secondWhereOrNull((m) => m.hasValidData);
    return spec.copyWith(
      from: null,
      to: model?.ts,
    );
  }
}
