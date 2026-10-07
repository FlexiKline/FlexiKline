import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../config/my_kline_config.dart';
import '../../config/my_kline_indicator_config.dart';
import '../../config/my_kline_interval.dart';
import '../../config/my_kline_logger.dart';
import '../../data/repositories/kline_repository.dart';
import '../../utils/device.dart';
import '../../widgets/my_theme_toggle_button.dart';
import '../common/components/my_kline_interval_bar.dart';
import '../common/core/kline_state_base.dart';
import '../common/core/my_kline_data_center.dart';
import 'demo_kline_landscape_page.dart';
import 'widgets/demo_kline_header_bar.dart';

/// 第一个形态：BTCUSDT 蜡烛 K 线（分时/15m/1h/1d/1w + 模拟实时推送）。
class DemoKlinePage extends StatefulWidget {
  const DemoKlinePage({
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
  State<DemoKlinePage> createState() => _DemoKlinePageState();
}

class _DemoKlinePageState extends KlineStateBase<DemoKlinePage>
    with MyKlineDataCenterMixin<DemoKlinePage>, MyKlineLoggerMixin {
  late final MyKlineIndicatorConfig _indicatorConfig;
  late final MyKlineConfig _klineConfig;
  late final KlineRepository _repository;

  /// 当前周期 UI 状态，由 intervalBar 回写。
  late final ValueNotifier<MyKlineInterval> _currentIntervalNotifier;

  /// 绘制工具条显隐。与 [FlexiKlineController.isDrawVisible] 正交：只联动状态机，不影响已画内容。
  final ValueNotifier<bool> showDrawMenubar = ValueNotifier(false);

  @override
  String get logTag => 'DemoKlinePage';

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
    _indicatorConfig = MyKlineIndicatorConfig();
    _klineConfig = MyKlineConfig();
    _currentIntervalNotifier = ValueNotifier(MyKlineInterval.parse(widget.interval));
    super.initState();
    _repository = widget.createRepository();
  }

  @override
  void dispose() {
    // 落盘须早于 dispose。
    klineController.storeFlexiKlineConfig();
    _indicatorConfig.dispose();
    showDrawMenubar.dispose();
    _currentIntervalNotifier.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    klineController.onThemeChanged();
    setState(() {});
  }

  void _toggleDraw() {
    showDrawMenubar.value = !showDrawMenubar.value;
    showDrawMenubar.value ? klineController.prepareDraw() : klineController.exitDraw();
  }

  /// 打开横屏页（复用本页配置，避免独立落盘覆盖）。
  Future<void> openLandscapePage() async {
    if (!DeviceUtil.isMobile) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DemoKlineLandscapePage(
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
          MyThemeToggleButton(onChanged: _onThemeChanged),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              DemoKlineHeaderBar(
                onToggleDraw: _toggleDraw.throttle(),
                onOpenLandscape: openLandscapePage.throttle(),
                klineIntervalBar: MyKlineIntervalBar(
                  intervalNotifier: _currentIntervalNotifier,
                  onChanged: didIntervalChanged,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: showDrawMenubar,
                builder: (context, isShow, child) => Visibility(
                  visible: isShow,
                  child: child!,
                ),
                child: Container(
                  height: 20,
                  color: Colors.red,
                ),
              ),
              buildFlexiKlineWidget(
                key: const ValueKey('DemoKline'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
