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
    CandleReq req,
    this.indicatorCount, {
    List<CandleModel> list = const [],
    this.computeMode = ComputeMode.fast,
    ILogger? logger,
  })  : _req = req,
        _list = List.of(list) {
    loggerDelegate = logger;
    initData();
  }

  @protected
  void initData() {
    logd("initData BASE");
  }

  void dispose() {
    logd('dispose BASE');
    loggerDelegate = null;
    list.clear();
    start = 0;
    end = 0;
  }

  final int indicatorCount;
  final ComputeMode computeMode;

  CandleReq _req;
  CandleReq get req => _req;

  List<CandleModel> _list;
  List<CandleModel> get list => _list;
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

  CandleReq updateState({RequestState state = RequestState.none});

  /// 未合并的数据
  final List<List<CandleModel>> _waitingData = List.empty(growable: true);
}
