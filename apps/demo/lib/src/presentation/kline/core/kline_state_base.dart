import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';

import '../../../config/app_kline_config.dart';
import '../../../theme/app_theme.dart';

/// K 线页面 State 公共基类：负责控制器创建销毁、应用主题切换时刷新配色与 K 线视图构建。
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

  /// 初始布局模式；横屏页覆写为 [FlexiLayoutMode.fixed]，避免横滑时主副图自适应抖动。
  FlexiLayoutMode get initialLayoutMode => FlexiLayoutMode.adapt;

  @override
  FlexiKlineController createFlexiKlineController() {
    return FlexiKlineController(
      configuration: klineConfig,
      initialLayoutMode: initialLayoutMode,
      logger: this,
    );
  }

  @override
  void initState() {
    super.initState();
    _klineController = createFlexiKlineController();
    _klineController.tooltipBuilder = customTooltips;
    appThemeMode.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    appThemeMode.removeListener(_onThemeChanged);
    _klineController.dispose();
    super.dispose();
  }

  /// 监听全局 [appThemeMode]：页面被盖住时也刷新，返回后配色已是新主题。
  void _onThemeChanged() {
    _klineController.onThemeChanged();
    // onThemeChanged 只重建主题派生资源, 不改配置; Tooltip 卡片的颜色在配置里, 须按新主题重新套用。
    _klineController.updateCrossConfig(
      (cross) => cross.copyWith(tooltipConfig: AppKlineConfig.styleTooltip(cross.tooltipConfig)),
    );
    setState(() {});
  }

  /// 下拉刷新统一入口。
  ///
  /// 关键路径 mixin：`await super.refresh(); await 自己的刷新();`（阻塞指示器）。
  /// 非关键 mixin：`自己的刷新(); await super.refresh();`（fire-and-forget）。
  @mustCallSuper
  Future<void> refresh() async {}

  /// 自定义十字线 Tooltip。子 mixin 用 `...?super.customTooltips(...)` 编排。
  @mustCallSuper
  List<TooltipInfo>? customTooltips(FlexiCandleModel model, {FlexiCandleModel? prev}) => null;

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
          loadingBuilder: loadingBuilder ?? buildLoading,
          exitZoomButtonBuilder: exitZoomButtonBuilder,
          drawToolbar: drawToolbar,
          onDoubleTap: onDoubleTap,
        );
      },
    );
  }

  /// 默认加载指示器；页面可通过 `buildFlexiKlineWidget(loadingBuilder:)` 替换。
  Widget buildLoading(BuildContext context, FlexiKlineController controller) {
    final theme = controller.theme;
    return FlexiLoading(
      controller: controller,
      child: SizedBox.square(
        dimension: 26,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          backgroundColor: theme.tooltipBg,
          valueColor: AlwaysStoppedAnimation<Color>(theme.textColor),
        ),
      ),
    );
  }

  /// 双击价格轴滑竿区退出缩放。
  void onDoubleTap(Offset position) {
    if (klineController.chartZoomSlideBarRect.include(position)) {
      klineController.exitChartZoom();
    }
  }
}
