import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../config/app_kline_config.dart';
import '../../config/app_kline_indicator_config.dart';
import '../../config/app_kline_logger.dart';
import '../../data/models/kline_interval.dart';
import '../../utils/screen_orientation.dart';
import '../../widgets/theme_toggle_button.dart';
import 'core/kline_data_center_mixin.dart';
import 'core/kline_state_base.dart';
import 'widgets/kline_interval_bar.dart';
import 'widgets/title_with_tag.dart';

/// 横屏页退出时交回竖屏页的结果；需要回传更多数据时在这里加命名字段。
typedef KlineLandscapeResult = ({KlineInterval interval});

/// 横屏 K 线形态：进入自动横屏，页内「横屏」开关仅移动端展示。
class KlineLandscapePage extends StatefulWidget {
  const KlineLandscapePage({
    super.key,
    this.symbol = 'BTCUSDT',
    this.label = 'BTC-USDT',
    this.precision = 2,
    this.limit = 500,
    this.interval,
    this.indicatorConfig,
    this.klineConfig,
  });

  /// 交易对标识（如 `BTCUSDT`）。
  final String symbol;

  /// 显示标签（如 `BTC-USDT`）。
  final String label;

  /// 价格精度。
  final int precision;

  /// 单次分页条数。
  final int limit;

  /// 初始周期名（[KlineInterval] 枚举名，如 `minute15`）；为空或未命中时用默认周期。
  final String? interval;

  /// 指标配置注入（通常来自竖屏页复用）；为空时本页自建并在 dispose 时销毁。
  final BaseIndicatorConfig? indicatorConfig;

  /// 框架配置注入（通常来自竖屏页复用）；为空时本页自建并在 dispose 时落盘+销毁。
  final IConfiguration? klineConfig;

  @override
  State<KlineLandscapePage> createState() => _KlineLandscapePageState();
}

class _KlineLandscapePageState extends KlineStateBase<KlineLandscapePage>
    with KlineDataCenterMixin<KlineLandscapePage>, ScreenLandscapeModeMixin<KlineLandscapePage>, AppKlineLoggerMixin {
  /// 注入则复用，否则自建。
  late final BaseIndicatorConfig _indicatorConfig;
  late final IConfiguration _klineConfig;

  @override
  String get logTag => 'KlineLandscapePage';

  @override
  KlineInterval get initialInterval => KlineInterval.parse(widget.interval);

  @override
  BaseIndicatorConfig get indicatorConfig => _indicatorConfig;

  @override
  IConfiguration get klineConfig => _klineConfig;

  @override
  KlineSpec createKlineSpec([KlineSpec? last]) {
    return KlineSpec(
      symbol: widget.symbol,
      interval: last?.interval ?? currentInterval,
      precision: widget.precision,
      limit: widget.limit,
      label: widget.label,
    );
  }

  @override
  FlexiLayoutMode get initialLayoutMode => FlexiLayoutMode.fixed;

  @override
  void initState() {
    // 先于 super.initState：基类创建 controller 时读取这些字段。
    _indicatorConfig = widget.indicatorConfig ?? AppKlineIndicatorConfig();
    _klineConfig = widget.klineConfig ?? AppKlineConfig();
    super.initState();
  }

  @override
  void dispose() {
    // 仅销毁自建实例；注入的由竖屏页销毁。落盘须早于 dispose。
    if (!identical(_klineConfig, widget.klineConfig)) {
      klineController.storeFlexiKlineConfig();
    }
    if (!identical(_indicatorConfig, widget.indicatorConfig)) {
      _indicatorConfig.dispose();
    }
    super.dispose();
  }

  /// 退出时把 [KlineLandscapeResult] 作为路由结果交回竖屏页；AppBar 返回与系统返回都经过这里。
  void _onPopInvoked(bool didPop, KlineLandscapeResult? result) {
    if (didPop) return;
    Navigator.of(context).pop<KlineLandscapeResult>((interval: currentInterval));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<KlineLandscapeResult>(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: TitleWithTag(widget.label, tag: '模拟'),
          centerTitle: false,
          actions: [
            const ThemeToggleButton(),
          ],
        ),
        body: Column(
          children: [
            KlineIntervalBar(selected: interval, onSelected: selectInterval),
            Expanded(
              child: buildFlexiKlineWidget(
                key: const ValueKey('DemoLandscape'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
