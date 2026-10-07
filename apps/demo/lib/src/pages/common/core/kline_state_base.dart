import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';

/// K 线页面 State 公共基类：负责控制器创建销毁与 K 线视图构建。
///
/// [klineController] 由本基类拥有；[indicatorConfig] / [klineConfig]
/// 由各 Page 持有与销毁，DataCenter mixin 不触碰配置生命周期。
abstract class KlineStateBase<T extends StatefulWidget> extends State<T>
    implements IFlexiKlineDataCenter, IFlexiLogger {
  late final FlexiKlineController _klineController;

  FlexiKlineController get klineController => _klineController;

  /// 指标配置（协变覆写为 Page 自身的具体类型）。
  BaseIndicatorConfig get indicatorConfig;

  /// 框架配置（协变覆写为 Page 自身的具体类型）。
  /// 须在 [super.initState] 前赋值，基类创建 controller 时读取。
  IConfiguration get klineConfig;

  /// 新建控制器。横屏页可覆写以注入 [FlexiLayoutMode.fixed] 等。
  @override
  FlexiKlineController createFlexiKlineController() {
    return FlexiKlineController(
      configuration: klineConfig,
      logger: this,
    );
  }

  @override
  void initState() {
    super.initState();
    _klineController = createFlexiKlineController();
    _klineController.onCrossCustomTooltip = customTooltips;
  }

  @override
  void dispose() {
    _klineController.dispose();
    super.dispose();
  }

  /// 下拉刷新统一入口。
  ///
  /// 关键路径 mixin：`await super.refresh(); await 自己的刷新();`（阻塞指示器）。
  /// 非关键 mixin：`自己的刷新(); await super.refresh();`（fire-and-forget）。
  @mustCallSuper
  Future<void> refresh() async {}

  /// 自定义十字线 Tooltip。子 mixin 用 `...?super.customTooltips(...)` 编排。
  @mustCallSuper
  List<TooltipInfo>? customTooltips(FlexiCandleModel? model, {FlexiCandleModel? prev}) => null;

  // ─── 指标扩展点（mixin 覆写时须先调 super）───

  @mustCallSuper
  CandleBaseIndicator buildCandleIndicator() => indicatorConfig.candle;

  @mustCallSuper
  TimeBaseIndicator buildTimeIndicator() => indicatorConfig.time;

  @mustCallSuper
  List<Indicator> buildExtraMainIndicators() => const [];

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
