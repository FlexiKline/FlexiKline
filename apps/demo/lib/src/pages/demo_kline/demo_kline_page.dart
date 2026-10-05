import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../config/my_kline_interval.dart';
import '../../config/my_kline_logger.dart';
import '../../data/repositories/kline_repository.dart';
import '../../utils/device.dart';
import '../../widgets/my_theme_toggle_button.dart';
import '../common/components/my_kline_interval_bar.dart';
import '../common/core/my_kline_data_center.dart';
import '../common/core/my_kline_state_base.dart';
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

class _DemoKlinePageState extends MyKlineStateBase<DemoKlinePage>
    with MyKlineDataCenterMixin<DemoKlinePage>, MyKlineLoggerMixin {
  late final KlineRepository _repository;

  /// 当前周期 UI 状态（初始值来自页面入口参数），由 intervalBar 回写。
  late final ValueNotifier<MyKlineInterval> _currentIntervalNotifier;

  /// 绘制工具条显隐（页面本地状态，默认隐藏），与 example 同款模式。
  ///
  /// 与框架的 [FlexiKlineController.isDrawVisible]（绘制图层是否绘制）正交：
  /// 开关工具条只联动绘制状态机（prepareDraw/exitDraw），不影响已画内容是否显示。
  final ValueNotifier<bool> showDrawMenubar = ValueNotifier(false);

  @override
  void initState() {
    _currentIntervalNotifier = ValueNotifier(MyKlineInterval.parse(widget.interval));
    super.initState();
    _repository = widget.createRepository();
  }

  @override
  void dispose() {
    showDrawMenubar.dispose();
    _currentIntervalNotifier.dispose();
    super.dispose();
  }

  @override
  String get logTag => 'DemoKlinePage';

  @override
  KlineRepository get repository => _repository;

  /// 用「入口参数」构建 [KlineSpec]（覆写 mixin 的默认实现），周期取页面选中的周期。
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

  void _onThemeChanged() {
    // setState 让 FlexiKlineWidget 重建，背景/网格等颜色随新主题刷出。
    klineController.onThemeChanged();
    setState(() {});
  }

  void _toggleDraw() {
    showDrawMenubar.value = !showDrawMenubar.value;
    if (showDrawMenubar.value) {
      klineController.prepareDraw();
    } else {
      klineController.exitDraw();
    }
  }

  /// 以路由方式打开横屏页（横竖屏切换发生在 [DemoLandscapePage] 内）。
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
        ),
      ),
    );
    if (!mounted) return;
    // 刷新配置，确保横屏页的配置生效。
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
      body: SingleChildScrollView(
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
    );
  }
}
