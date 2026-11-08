import 'dart:async';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../data/models/kline_interval.dart';
import '../../../data/repositories/kline_repository.dart';
import '../../../data/service_locator.dart';
import 'kline_state_base.dart';

/// K 线数据能力：拥有当前周期，负责加载、翻页与推送订阅。
///
/// 当前周期只由本 mixin 写：页面提供 [initialInterval]，周期栏读 [interval]、点击调 [selectInterval]。
mixin KlineDataCenterMixin<T extends StatefulWidget> on KlineStateBase<T> {
  /// 数据仓库，默认从依赖容器取；测试或需要特定实现的页面可覆写。
  KlineRepository get klineRepository => getIt<KlineRepository>();

  /// 进入页面时的周期；之后由 [selectInterval] 改变。
  KlineInterval get initialInterval;

  late final ValueNotifier<KlineInterval> _interval = ValueNotifier(initialInterval);

  late KlineSpec _spec;

  StreamSubscription<List<CandleModel>>? _ticksSub;

  /// 当前周期，周期栏据此显示选中态。
  ValueListenable<KlineInterval> get interval => _interval;

  /// 页面实现 [createKlineSpec] 时用它取周期，保证 spec 与 [interval] 一致。
  KlineInterval get currentInterval => _interval.value;

  @override
  void initState() {
    super.initState();
    _spec = createKlineSpec();
    klineController.onLoadMoreCandles = loadMoreCandles;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshKlineData(reset: true);
    });
  }

  @override
  void dispose() {
    _cancelTicks();
    _interval.dispose();
    super.dispose();
  }

  /// 下拉刷新：蜡烛是关键路径，全程 await（[RefreshIndicator.onRefresh] 等它完成）。
  @override
  Future<void> refresh() async {
    await super.refresh();
    await refreshKlineData(reset: true);
  }

  /// 切换周期；与当前周期相同时不做事。
  void selectInterval(KlineInterval value) {
    if (value == _interval.value) return;
    _interval.value = value;
    _cancelTicks();
    _spec = _spec.copyWith(interval: value);
    refreshKlineData();
  }

  /// 加载 K 线数据（模拟 HTTP）并订阅推送。
  @override
  Future<void> refreshKlineData({bool reset = false}) async {
    final spec = _spec.initial();

    if (reset) _cancelTicks();

    klineController.requestCancelCross();
    klineController.switchKlineData(
      spec,
      useCacheFirst: !reset,
      useCachePaintDxOffset: true,
    );

    final candles = await klineRepository.fetchCandles(
      symbol: spec.symbol,
      interval: _intervalOf(spec),
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
    final candles = await klineRepository.fetchCandles(
      symbol: spec.symbol,
      interval: _intervalOf(spec),
      end: spec.from,
      limit: spec.limit,
    );
    if (!mounted) return;
    klineController.prependHistoryKlineData(spec, candles);
  }

  /// spec 由本 mixin 用 [KlineInterval] 创建，这里是唯一的类型还原点。
  KlineInterval _intervalOf(KlineSpec spec) => spec.interval as KlineInterval;

  void _subscribeTicks(KlineSpec spec) {
    _cancelTicks();
    _ticksSub = klineRepository
        .subscribeTicks(
          symbol: spec.symbol,
          interval: _intervalOf(spec),
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
