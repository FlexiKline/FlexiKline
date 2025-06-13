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

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'data/kline_data.dart';
import 'framework/configuration.dart';
import 'kline_controller.dart';
import 'model/candle_req/candle_req.dart';

abstract interface class IFlexiKlinePage {
  FlexiKlineController get klineController;

  /// 当前Kline页面是否可见获取焦点
  bool get isResume;

  /// 刷新K线数据
  /// @param [request] 刷新请求, 其中的 [before] 时间戳代表请求此时间戳之后（更新的数据）的数据.
  /// @param [reset] 是否重置当前KlineData所有数据
  Future<void> refreshKlineData(CandleReq request, {bool reset = false});

  /// 更新历史行情的蜡烛数据
  /// [request] 请求[after]时间戳之前（更旧的数据）的分页内容
  Future<void> loadMoreCandles(CandleReq request);

  /// 暂停K线数据推送
  Future<void> stopKlineDataPush() async {}
}

mixin FlexiKlinePageMixin<T extends StatefulWidget> on State<T> implements IFlexiKlinePage {
  IFlexiKlineTheme get flexiTheme => klineController.theme;

  late final AppLifecycleListener _listener;
  late AppLifecycleState? _state;
  AppLifecycleState? get appLifecycleState => _state;

  @override
  bool get isResume => _state == AppLifecycleState.resumed;

  /// 当前KlineData
  KlineData get curKlineData => klineController.curKlineData;

  /// 当前KlineData的刷新请求
  CandleReq get refreshRequest => curKlineData.getRefreshRequest(isResetKlineDataWhenResume);

  /// 当回到前台时，是否需要重置当前KlineData所有数据
  bool get isResetKlineDataWhenResume => false;

  @override
  void initState() {
    super.initState();
    _state = SchedulerBinding.instance.lifecycleState;
    _listener = AppLifecycleListener(
      onShow: onShow,
      onHide: onHide,
      onResume: onResume,
      onInactive: onInactive,
      // onPause: () => log('onPause'),
      // onDetach: () => log('onDetach'),
      // onRestart: () => log('onRestart'),
      onStateChange: (state) => _state = state,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    klineController.onLoadMoreCandles = loadMoreCandles;
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void log(String msg) {
    klineController.logd('FlexiKlinePageMixin >>> $msg');
  }

  /// 回到前台(可见)
  void onShow() {
    log('onShow');
    refreshKlineData(refreshRequest, reset: isResetKlineDataWhenResume);
  }

  /// 退出前台(完全不可见)
  void onHide() {
    log('onHide');
    stopKlineDataPush();
  }

  /// 可见且获得焦点
  void onResume() => log('onResume');

  /// 不可见或失去焦点
  void onInactive() => log('onInactive');
}
