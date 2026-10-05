import 'dart:async';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';

import '../../../config/my_kline_interval.dart';
import '../../../data/repositories/kline_repository.dart';
import 'my_kline_state_base.dart';

/// 公共 K 线数据接线 Mixin，负责 [KlineSpec]/数据源/HTTP 加载/WS 订阅接线。
mixin MyKlineDataCenterMixin<T extends StatefulWidget> on MyKlineStateBase<T> {
  /// 数据源，构造注入（由 `DemoKlinePage` 传入）。
  KlineRepository get repository;

  late KlineSpec _spec;

  StreamSubscription<List<CandleModel>>? _ticksSub;

  /// 当前生效周期（只读数据事实，供页面或调试读取）。
  ITimeInterval get timeInterval => _spec.interval;

  /// 新建 KlineSpec（接口，由页面基于入口参数构建）。
  KlineSpec createKlineSpec([KlineSpec? last]);

  @override
  void initState() {
    super.initState();
    _spec = createKlineSpec();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshKlineData(reset: true);
    });
  }

  @override
  void dispose() {
    _cancelTicks();
    super.dispose();
  }

  /// 周期切换。
  void didIntervalChanged(MyKlineInterval interval) {
    if (interval == _spec.interval) return;
    _cancelTicks();
    _spec = _spec.copyWith(interval: interval);
    refreshKlineData();
  }

  /// 加载 K 线数据（模拟 HTTP）并订阅推送。
  Future<void> refreshKlineData({bool reset = false}) async {
    final spec = _spec.initial();

    if (reset) _cancelTicks();

    klineController.requestCancelCross();
    klineController.switchKlineData(
      spec,
      useCacheFirst: !reset,
      useCachePaintDxOffset: true,
    );

    final candles = await repository.fetchCandles(
      symbol: spec.symbol,
      interval: spec.interval as MyKlineInterval,
      end: spec.to,
      limit: spec.limit,
    );
    if (!mounted) return;

    klineController.replaceKlineData(spec, candles);
    _subscribeTicks(spec);
  }

  /// 向前翻页加载历史 K 线数据。
  @override
  Future<void> loadMoreCandles(KlineSpec spec) async {
    final candles = await repository.fetchCandles(
      symbol: spec.symbol,
      interval: spec.interval as MyKlineInterval,
      end: spec.from,
      limit: spec.limit,
    );
    if (!mounted) return;
    klineController.appendHistoryKlineData(spec, candles);
  }

  void _subscribeTicks(KlineSpec spec) {
    _cancelTicks();
    _ticksSub = repository
        .subscribeTicks(
          symbol: spec.symbol,
          interval: spec.interval as MyKlineInterval,
        )
        .listen((batch) {
          if (!mounted) return;
          klineController.updateLatestKlineData(spec, batch);
        });
  }

  void _cancelTicks() {
    _ticksSub?.cancel();
    _ticksSub = null;
  }
}
