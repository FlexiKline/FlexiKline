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
/// [spec] K线规格配置
/// [loadingState] K线加载状态
/// [list] 蜡烛数据列表
/// [start] 当前绘制区域起始下标
/// [end] 当前绘制区域结束下标
/// 注: 对于BaseData的指标计算mixin: 仅保留计算逻辑, 不持有状态, 计算结果统一整合在[CandleModel]中.
abstract class BaseData with FlexiLog {
  @override
  String get logTag => '${spec.label ?? spec.symbol}-${spec.timeBar}';

  BaseData(
    KlineSpec spec,
    this.indicatorCount, {
    KlineLoadingState loadingState = KlineLoadingState.none,
    List<FlexiCandleModel> list = const [],
    this.computeMode = ComputeMode.fast,
    IFlexiLogger? logger,
  })  : _spec = spec,
        _loadingState = loadingState,
        _list = List.of(list) {
    this.logger = logger;
    initData();
  }

  @protected
  void initData() {
    logd('initData BASE');
  }

  void dispose() {
    logd('dispose BASE');
    logger = null;
    list.clear();
    start = 0;
    end = 0;
  }

  final int indicatorCount;
  final ComputeMode computeMode;

  KlineSpec _spec;
  KlineSpec get spec => _spec;

  KlineLoadingState _loadingState;
  KlineLoadingState get loadingState => _loadingState;

  bool get invalid => spec.symbol.isEmpty;

  List<FlexiCandleModel> _list;
  List<FlexiCandleModel> get list => _list;
  int get length => _list.length;
  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  int _start = 0;

  /// 当前绘制区域起始下标 右
  int get start => _start;
  set start(int val) {
    _start = val.clamp(0, length);
  }

  int _end = 0;

  /// 当前绘制区域结束下标 左
  /// 注: 遍历时, 应 < end;
  int get end => _end;
  set end(int val) {
    _end = val.clamp(0, length);
  }

  bool checkStartAndEnd(int start, int end) {
    return isNotEmpty && start < end && start >= 0 && end <= length;
  }

  void updateState({KlineLoadingState state = KlineLoadingState.none});

  /// 未合并的数据
  final List<List<ICandleModel>> _waitingData = List.empty(growable: true);
}
