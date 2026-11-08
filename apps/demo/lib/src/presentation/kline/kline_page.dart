import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../config/app_kline_config.dart';
import '../../config/app_kline_indicator_config.dart';
import '../../config/app_kline_logger.dart';
import '../../config/my_kline_interval.dart';
import '../../data/repositories/kline_repository.dart';
import '../../utils/device_util.dart';
import '../../widgets/theme_toggle_button.dart';
import 'core/kline_data_center_mixin.dart';
import 'core/kline_state_base.dart';
import 'kline_landscape_page.dart';
import 'widgets/draw_menubar.dart';
import 'widgets/draw_toolbar.dart';
import 'widgets/kline_header_bar.dart';
import 'widgets/kline_interval_bar.dart';

/// 第一个形态：BTCUSDT 蜡烛 K 线（分时/15m/1h/1d/1w + 模拟实时推送）。
class KlinePage extends StatefulWidget {
  const KlinePage({
    super.key,
    this.symbol = 'BTCUSDT',
    this.label = 'BTC-USDT',
    this.precision = 2,
    this.limit = 500,
    this.interval,
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

  /// 仓库工厂（默认懒加载本地 JSON 的 [KlineRepositoryImpl]；测试可覆写注入假实现）。
  KlineRepository createRepository() => KlineRepositoryImpl();

  @override
  State<KlinePage> createState() => _KlinePageState();
}

class _KlinePageState extends KlineStateBase<KlinePage> with KlineDataCenterMixin<KlinePage>, AppKlineLoggerMixin {
  late final AppKlineIndicatorConfig _indicatorConfig;
  late final AppKlineConfig _klineConfig;
  late final KlineRepository _repository;

  /// 当前周期 UI 状态，由 intervalBar 回写。
  late final ValueNotifier<MyKlineInterval> _currentIntervalNotifier;

  /// 绘制工具条显隐。与 [FlexiKlineController.isDrawVisible] 正交：只联动状态机，不影响已画内容。
  final ValueNotifier<bool> _drawMenubarVisible = ValueNotifier(false);

  @override
  String get logTag => 'KlinePage';

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

  @override
  void initState() {
    // 先于 super.initState：基类创建 controller 时读取这些字段。
    _indicatorConfig = AppKlineIndicatorConfig();
    _klineConfig = AppKlineConfig();
    _currentIntervalNotifier = ValueNotifier(MyKlineInterval.parse(widget.interval));
    super.initState();
    _repository = widget.createRepository();
  }

  @override
  void dispose() {
    // 落盘须早于 dispose。
    klineController.storeFlexiKlineConfig();
    _indicatorConfig.dispose();
    _drawMenubarVisible.dispose();
    _currentIntervalNotifier.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    klineController.onThemeChanged();
    setState(() {});
  }

  void _toggleDraw() {
    _drawMenubarVisible.value = !_drawMenubarVisible.value;
    _drawMenubarVisible.value ? klineController.prepareDraw() : klineController.exitDraw();
  }

  /// 打开横屏页（复用本页配置，避免独立落盘覆盖）。
  Future<void> _openLandscapePage() async {
    if (!DeviceUtil.isMobile) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KlineLandscapePage(
          symbol: widget.symbol,
          label: widget.label,
          precision: widget.precision,
          limit: widget.limit,
          interval: _currentIntervalNotifier.value.name,
          indicatorConfig: _indicatorConfig,
          klineConfig: _klineConfig,
        ),
      ),
    );
    if (!mounted) return;
    klineController.syncFlexiKlineConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
        centerTitle: true,
        actions: [
          ThemeToggleButton(onChanged: _onThemeChanged),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              KlineHeaderBar(
                onToggleDraw: _toggleDraw.throttle(),
                onOpenLandscape: _openLandscapePage.throttle(),
                klineIntervalBar: KlineIntervalBar(
                  intervalNotifier: _currentIntervalNotifier,
                  onChanged: didIntervalChanged,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _drawMenubarVisible,
                builder: (context, isShow, child) => Visibility(
                  visible: isShow,
                  child: child!,
                ),
                child: DrawMenubar(controller: klineController, onExit: _toggleDraw),
              ),
              buildFlexiKlineWidget(
                key: const ValueKey('DemoKline'),
                drawToolbar: DrawToolbar(controller: klineController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
