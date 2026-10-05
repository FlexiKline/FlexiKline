import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';

import '../../../config/my_kline_config.dart';
import '../../../config/my_kline_indicator_config.dart';

/// K 线页面 State 的公共基类，负责控制器/配置/指标的创建销毁与 K 线视图构建。
abstract class MyKlineStateBase<T extends StatefulWidget> extends State<T> implements IFlexiLogger {
  late final FlexiKlineController _klineController;
  late final MyKlineIndicatorConfig _indicatorConfig;

  /// K 线控制器（[initState] 后可用）。
  FlexiKlineController get klineController => _klineController;

  /// 指标配置（[initState] 后可用）。
  MyKlineIndicatorConfig get indicatorConfig => _indicatorConfig;

  /// 框架配置工厂（默认 [MyKlineConfig]）。
  IConfiguration createFlexiKlineConfig() => MyKlineConfig();

  /// 指标配置工厂（默认 [MyKlineIndicatorConfig]）。
  MyKlineIndicatorConfig createIndicatorConfig() => MyKlineIndicatorConfig();

  /// 新建控制器，日志走本 State（[IFlexiLogger]）。
  FlexiKlineController createFlexiKlineController() {
    return FlexiKlineController(
      configuration: createFlexiKlineConfig(),
      logger: this,
    );
  }

  // ─── 生命周期 ───

  @override
  void initState() {
    super.initState();
    _indicatorConfig = createIndicatorConfig();
    _klineController = createFlexiKlineController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _klineController.onLoadMoreCandles = loadMoreCandles;
  }

  @override
  void dispose() {
    _indicatorConfig.dispose();
    storeAndDisposeKlineController();
    super.dispose();
  }

  /// 向前翻页加载历史 K 线数据，由 [MyKlineDataCenterMixin] 实现。
  Future<void> loadMoreCandles(KlineSpec spec);

  /// 落盘并释放 [klineController]（顺序不可换：落盘必须早于 dispose）。
  void storeAndDisposeKlineController() {
    klineController.storeFlexiKlineConfig();
    klineController.dispose();
  }

  // ─── 扩展点 ───

  /// 蜡烛指标扩展点。mixin 覆写时须 `return super.buildCandleIndicator().copyWith(...)`。
  @mustCallSuper
  CandleBaseIndicator buildCandleIndicator() => indicatorConfig.candle;

  /// 时间轴指标扩展点。mixin 覆写时须 `return super.buildTimeIndicator().copyWith(...)`。
  @mustCallSuper
  TimeBaseIndicator buildTimeIndicator() => indicatorConfig.time;

  /// 主区可选指标扩展点。mixin 覆写时须 `[...super.buildExtraMainIndicators(), ...]`。
  @mustCallSuper
  List<Indicator> buildExtraMainIndicators() => const [];

  /// 副区可选指标扩展点。mixin 覆写时须 `[...super.buildExtraSubIndicators(), ...]`。
  @mustCallSuper
  List<Indicator> buildExtraSubIndicators() => const [];

  // ─── 视图构建 ───

  /// 构建 K 线视图，监听 [indicatorConfig] 增量重建。
  Widget buildFlexiKlineWidget({
    Key? key,
    FlexiKlineWidgetBuilder? mainBackgroundBuilder,
    FlexiKlineWidgetBuilder? mainForegroundBuilder,
    FlexiKlineWidgetBuilder? loadingBuilder,
    FlexiKlineWidgetBuilder? exitZoomButtonBuilder,
    Widget? drawToolbar,
    VoidCallback? onDoubleTap,
    bool includeSubIndicators = true,
  }) {
    return ListenableBuilder(
      listenable: indicatorConfig,
      builder: (context, _) {
        return FlexiKlineWidget(
          key: key,
          controller: klineController,
          candle: buildCandleIndicator(),
          time: buildTimeIndicator(),
          mainIndicators: [
            ...indicatorConfig.mainIndicators,
            ...buildExtraMainIndicators(),
          ],
          subIndicators: includeSubIndicators
              ? [
                  ...indicatorConfig.subIndicators,
                  ...buildExtraSubIndicators(),
                ]
              : const [],
          mainBackgroundBuilder: mainBackgroundBuilder,
          mainForegroundBuilder: mainForegroundBuilder,
          loadingBuilder: loadingBuilder,
          exitZoomButtonBuilder: exitZoomButtonBuilder,
          drawToolbar: drawToolbar,
          onDoubleTap: onDoubleTap,
        );
      },
    );
  }
}
