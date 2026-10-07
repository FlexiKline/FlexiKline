import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../config/my_kline_config.dart';
import '../../config/my_kline_indicator_config.dart';
import '../../config/my_kline_interval.dart';
import '../../config/my_kline_logger.dart';
import '../../data/repositories/kline_repository.dart';
import '../../utils/screen_util.dart';
import '../../widgets/my_theme_toggle_button.dart';
import '../common/components/my_kline_interval_bar.dart';
import '../common/core/kline_state_base.dart';
import '../common/core/my_kline_data_center.dart';

/// 横屏 K 线形态：进入自动横屏，页内「横屏」开关仅移动端展示。
class DemoKlineLandscapePage extends StatefulWidget {
  const DemoKlineLandscapePage({
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

  /// 初始周期名（[MyKlineInterval] 枚举名，如 `minute15`）；为空或未命中时用默认周期。
  final String? interval;

  /// 指标配置注入（通常来自竖屏页复用）；为空时本页自建并在 dispose 时销毁。
  final BaseIndicatorConfig? indicatorConfig;

  /// 框架配置注入（通常来自竖屏页复用）；为空时本页自建并在 dispose 时落盘+销毁。
  final IConfiguration? klineConfig;

  /// 仓库工厂（默认懒加载本地 JSON 的 [KlineRepositoryImpl]；测试可覆写注入假实现）。
  KlineRepository createRepository() => KlineRepositoryImpl();

  @override
  State<DemoKlineLandscapePage> createState() => _DemoKlineLandscapePageState();
}

class _DemoKlineLandscapePageState extends KlineStateBase<DemoKlineLandscapePage>
    with
        MyKlineDataCenterMixin<DemoKlineLandscapePage>,
        ScreenLandscapeModeMixin<DemoKlineLandscapePage>,
        MyKlineLoggerMixin {
  late final KlineRepository _repository;
  late final ValueNotifier<MyKlineInterval> _currentIntervalNotifier;

  /// 注入则复用，否则自建。
  late final BaseIndicatorConfig _indicatorConfig;
  late final IConfiguration _klineConfig;

  @override
  String get logTag => 'DemoKlineLandscapePage';

  @override
  KlineRepository get repository => _repository;

  @override
  BaseIndicatorConfig get indicatorConfig => _indicatorConfig;

  @override
  IConfiguration get klineConfig => _klineConfig;

  @override
  KlineSpec createKlineSpec([KlineSpec? last]) {
    return KlineSpec(
      symbol: widget.symbol,
      interval: last?.interval ?? _currentIntervalNotifier.value,
      precision: widget.precision,
      limit: widget.limit,
      label: widget.label,
    );
  }

  /// 横屏固定布局，避免横滑时副图/主图自适应抖动。
  @override
  FlexiKlineController createFlexiKlineController() {
    return FlexiKlineController(
      configuration: klineConfig,
      initialLayoutMode: FlexiLayoutMode.fixed,
      logger: this,
    );
  }

  @override
  void initState() {
    // 先于 super.initState：基类创建 controller 时读取这些字段。
    _indicatorConfig = widget.indicatorConfig ?? MyKlineIndicatorConfig();
    _klineConfig = widget.klineConfig ?? MyKlineConfig();
    _currentIntervalNotifier = ValueNotifier(MyKlineInterval.parse(widget.interval));
    super.initState();
    _repository = widget.createRepository();
  }

  @override
  void dispose() {
    _currentIntervalNotifier.dispose();
    // 仅销毁自建实例；注入的由竖屏页销毁。落盘须早于 dispose。
    if (!identical(_klineConfig, widget.klineConfig)) {
      klineController.storeFlexiKlineConfig();
    }
    if (!identical(_indicatorConfig, widget.indicatorConfig)) {
      _indicatorConfig.dispose();
    }
    super.dispose();
  }

  void _onThemeChanged() {
    klineController.onThemeChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
        centerTitle: false,
        actions: [
          MyThemeToggleButton(onChanged: _onThemeChanged),
        ],
      ),
      body: Column(
        children: [
          MyKlineIntervalBar(
            intervalNotifier: _currentIntervalNotifier,
            onChanged: didIntervalChanged,
          ),
          Expanded(
            child: buildFlexiKlineWidget(
              key: const ValueKey('DemoLandscape'),
            ),
          ),
        ],
      ),
    );
  }
}
