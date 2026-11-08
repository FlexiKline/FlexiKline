import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../config/app_kline_config.dart';
import '../../config/app_kline_indicator_config.dart';
import '../../config/app_kline_logger.dart';
import '../../data/data_sources/mock/mock_kline_data_source.dart';
import '../../data/models/kline_interval.dart';
import '../../data/repositories/kline_repository.dart';
import '../../data/repositories/kline_repository_impl.dart';
import '../../utils/screen_orientation.dart';
import '../../widgets/theme_toggle_button.dart';
import 'core/kline_data_center_mixin.dart';
import 'core/kline_state_base.dart';
import 'widgets/kline_interval_bar.dart';

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

  /// 仓库工厂（默认 [KlineRepositoryImpl] 加 [MockKlineDataSource]；测试可覆写注入假实现）。
  KlineRepository createRepository() => KlineRepositoryImpl(MockKlineDataSource());

  @override
  State<KlineLandscapePage> createState() => _KlineLandscapePageState();
}

class _KlineLandscapePageState extends KlineStateBase<KlineLandscapePage>
    with KlineDataCenterMixin<KlineLandscapePage>, ScreenLandscapeModeMixin<KlineLandscapePage>, AppKlineLoggerMixin {
  late final KlineRepository _repository;
  late final ValueNotifier<KlineInterval> _currentIntervalNotifier;

  /// 注入则复用，否则自建。
  late final BaseIndicatorConfig _indicatorConfig;
  late final IConfiguration _klineConfig;

  @override
  String get logTag => 'KlineLandscapePage';

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
    _indicatorConfig = widget.indicatorConfig ?? AppKlineIndicatorConfig();
    _klineConfig = widget.klineConfig ?? AppKlineConfig();
    _currentIntervalNotifier = ValueNotifier(KlineInterval.parse(widget.interval));
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
          ThemeToggleButton(onChanged: _onThemeChanged),
        ],
      ),
      body: Column(
        children: [
          KlineIntervalBar(
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
