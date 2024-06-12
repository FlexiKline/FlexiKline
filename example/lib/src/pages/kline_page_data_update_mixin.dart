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

import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../models/export.dart';
import '../providers/instruments_provider.dart';
import '../repo/api.dart' as api;

abstract interface class IKlinePage {
  FlexiKlineController get flexiKlineController;
}

mixin KlinePageDataUpdateMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> implements IKlinePage {
  late CandleReq req;

  CancelToken? cancelToken;

  final random = math.Random();
  Timer? _mockPushTimer;

  @override
  void dispose() {
    cancelToken?.cancel();
    _mockPushTimer?.cancel();
    super.dispose();
  }

  Future<void> initKlineData(
    CandleReq request, {
    bool reset = false,
  }) async {
    flexiKlineController.switchKlineData(request, useCacheFirst: !reset);

    cancelToken?.cancel();
    final resp = await api.getMarketCandles(
      request,
      cancelToken: cancelToken = CancelToken(),
    );
    cancelToken = null;
    if (resp.success && resp.data != null && resp.data!.isNotEmpty) {
      await flexiKlineController.updateKlineData(request, resp.data!);
      _startMockPushTimer(flexiKlineController.curKlineData.req); // 假装推送
    } else if (resp.msg.isNotEmpty) {
      SmartDialog.showToast(resp.msg);
    }
  }

  /// 更新历史行情的蜡烛数据
  /// [request] 请求[after]时间戳之前（更旧的数据）的分页内容
  Future<void> loadMoreCandles(CandleReq request) async {
    await Future.delayed(const Duration(milliseconds: 2000)); // 模拟延时, 展示loading
    final resp = await api.getHistoryCandles(
      request,
      cancelToken: cancelToken = CancelToken(),
    );
    cancelToken = null;
    if (resp.success && resp.data != null && resp.data!.isNotEmpty) {
      await flexiKlineController.updateKlineData(request, resp.data!);
    } else if (resp.msg.isNotEmpty) {
      SmartDialog.showToast(resp.msg);
    }
  }

  /// 启动模拟推送定时器
  void _startMockPushTimer(CandleReq request) {
    _mockPushTimer?.cancel();
    _mockPushTimer = Timer(
      Duration(milliseconds: random.nextInt(5000)),
      () async {
        await updateLatestCandles(request);
        _startMockPushTimer(request);
      },
    );
  }

  /// 更新最新行情的蜡烛数据
  Future<void> updateLatestCandles(CandleReq request) async {
    if (request.before == null || request.timeBar == null) return;
    request = request.copyWith(
      after: null,
      before: request.before! - request.timeBar!.milliseconds,
    );
    final resp = await api.getMarketCandles(
      request,
      cancelToken: cancelToken = CancelToken(),
    );
    if (resp.success && resp.data != null && resp.data!.isNotEmpty) {
      await flexiKlineController.updateKlineData(request, resp.data!);
    } else if (resp.msg.isNotEmpty) {
      SmartDialog.showToast(resp.msg);
    }
  }

  /// 交易对变更回调
  void onChangeTradingSymbol(MarketTicker ticker) {
    final p = ref.read(instrumentsMgrProvider.notifier).getPrecision(
          ticker.instId,
        );
    req = CandleReq(
      instId: ticker.instId,
      bar: req.bar,
      precision: p ?? ticker.precision,
    );
    initKlineData(req);
    setState(() {});
  }

  /// TimerBar变更回调
  void onTapTimerBar(TimeBar bar) {
    if (bar.bar != req.bar) {
      req = req.copyWith(bar: bar.bar);
      initKlineData(req);
      setState(() {});
    }
  }
}
