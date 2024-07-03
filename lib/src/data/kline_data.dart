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

import '../constant.dart';
import '../extension/export.dart';
import '../framework/logger.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'boll_data.dart';
import 'candle_data.dart';
import 'ema_data.dart';
import 'kdj_data.dart';
import 'ma_data.dart';
import 'macd_data.dart';
import 'rsi_data.dart';
import 'sar_data.dart';
import 'volma_data.dart';

class KlineData extends BaseData
    with
        CandleData,
        MAData,
        VOLMAData,
        EMAData,
        MACDData,
        KDJData,
        BOLLData,
        SARData,
        RSIData {
  KlineData(
    super.req, {
    super.list,
    super.logger,
  });

  static final KlineData empty = KlineData(
    const CandleReq(instId: "", bar: ""),
    list: List.empty(growable: false),
  );

  /// 预计算Kline指标数据
  /// [data] 待计算的Kline蜡烛数据
  /// [newList] 新增的蜡烛数据
  /// [computeMode] 计算模式
  /// [calcParams] 指标计算参数
  /// [reset] 是否重置; 如果有, 忽略之前的计算结果.
  static Future<KlineData> precomputeKlineData(
    KlineData data, {
    required List<CandleModel> newList,
    required ComputeMode computeMode,
    required Map<ValueKey, dynamic> calcParams,
    bool reset = false,
  }) async {
    DateTime beginTime = DateTime.now();
    data.logd('WatchRun precomputeKlineData Begin:$beginTime');
    final stopwatch = Stopwatch();

    ///1. 合并[newList]到[data]中
    Range? range = await stopwatch.runAsync(
      () => data.mergeCandleList(newList),
      debugLabel: 'mergeCandleList\t${newList.length}|$reset',
    );
    data.updateReqRange(); // 更新当前data的[CandleReq]的请求边界[before, after]

    ///2. 确认要计算的范围.
    range ??= Range.empty;
    if (reset) range = Range(0, data.length);

    ///3. 根据计算模式初始化基础数据
    await stopwatch.runAsync(
      () => data.initBasicData(computeMode, reset: reset),
      debugLabel: 'initBasicData\t$range|$reset',
    );

    ///4. 预计算指标数据
    for (final param in calcParams.entries) {
      await stopwatch.runAsync(
        () => data.precompute(
          param.key,
          calcParam: param.value,
          range: range!,
          reset: reset,
        ),
        debugLabel: 'precompute${param.key}\t$range|$reset',
      );
    }

    final endTime = DateTime.now();
    final spent = endTime.difference(beginTime).inMicroseconds;
    data.logd('WatchRun precomputeKlineData End:$endTime, spent:$spentμs');
    return data;
  }
}

/// 通过compute方式预计算KlineData.
/// 实际执行参考[KlineData.precomputeKlineData]
/// [data]将在MainIsolate和subIsolate之间传递,
/// [data]的序列化反序列化耗时较大, 暂不使用此方式.
Future<KlineData> precomputeKlineDataByCompute(
  KlineData data, {
  required List<CandleModel> newList,
  required ComputeMode computeMode,
  required Map<ValueKey, dynamic> calcParams,
  bool reset = false,
  String? debugLabel,
  ILogger? logger,
}) async {
  if (newList.isEmpty) {
    return data;
  }

  try {
    logger ??= data.loggerDelegate;
    data.loggerDelegate = null;

    logger?.logd('compute Begin:${DateTime.now()}');
    data = await compute(
      (List<dynamic> params) async {
        final newData = await KlineData.precomputeKlineData(
          params[0],
          newList: params[1],
          computeMode: params[2],
          calcParams: params[3],
          reset: params[4],
        );
        return newData;
      },
      [data, newList, computeMode, calcParams, reset],
      debugLabel: debugLabel,
    );
    logger?.logd('compute End:${DateTime.now()}');
  } on Object catch (e, stack) {
    logger?.loge(
      'precomputeKlineDataByCompute exception!!!',
      error: e,
      stackTrace: stack,
    );
  } finally {
    data.loggerDelegate = logger;
  }
  return data;
}

extension KlineDataExt on KlineData {
  String get instId => req.instId;
  int get precision => req.precision;
  String get key => req.key;
  String get reqKey => req.reqKey;
  TimeBar? get timeBar => req.timeBar;

  bool get invalid => req.instId.isEmpty;

  CandleReq updateReqRange({RequestState state = RequestState.none}) {
    req = req.copyWith(
      after: list.lastOrNull?.ts,
      before: list.firstOrNull?.ts,
      state: state,
    );
    return req;
  }

  CandleReq getLoadMoreRequest() {
    return req.copyWith(
      after: list.lastOrNull?.ts,
      before: null,
    );
  }
}
