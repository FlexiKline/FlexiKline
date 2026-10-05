import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

import '../../config/my_kline_interval.dart';
import '../../config/my_kline_logger.dart';
import '../../data/repositories/kline_repository.dart';
import '../../utils/screen_util.dart';
import '../../widgets/my_theme_toggle_button.dart';
import '../common/components/my_kline_interval_bar.dart';
import '../common/core/my_kline_data_center.dart';
import '../common/core/my_kline_state_base.dart';

/// 横屏 K 线形态：进入自动横屏，页内「横屏」开关仅移动端展示。
class DemoKlineLandscapePage extends StatefulWidget {
  const DemoKlineLandscapePage({
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
  State<DemoKlineLandscapePage> createState() => _DemoKlineLandscapePageState();
}

class _DemoKlineLandscapePageState extends MyKlineStateBase<DemoKlineLandscapePage>
    with
        MyKlineDataCenterMixin<DemoKlineLandscapePage>,
        ScreenLandscapeModeMixin<DemoKlineLandscapePage>,
        MyKlineLoggerMixin {
  late final KlineRepository _repository;

  /// 当前周期 UI 状态（初始值来自页面入口参数），由 intervalBar 回写。
  late final ValueNotifier<MyKlineInterval> _currentIntervalNotifier;

  @override
  void initState() {
    _currentIntervalNotifier = ValueNotifier(MyKlineInterval.parse(widget.interval));
    super.initState();
    _repository = widget.createRepository();
  }

  @override
  void dispose() {
    _currentIntervalNotifier.dispose();
    super.dispose();
  }

  @override
  String get logTag => 'DemoKlineLandscapePage';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
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
