import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/app_kline_config.dart';
import 'package:flexi_kline_demo/src/config/app_kline_indicator_config.dart';
import 'package:flexi_kline_demo/src/config/app_kline_logger.dart';
import 'package:flexi_kline_demo/src/presentation/kline/core/kline_state_base.dart';
import 'package:flexi_kline_demo/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录 [onThemeChanged] 调用次数的控制器。
class _CountingController extends FlexiKlineController {
  _CountingController({required super.configuration, super.logger});

  int themeChanges = 0;

  @override
  void onThemeChanged([IFlexiKlineTheme? oldTheme]) {
    themeChanges++;
    super.onThemeChanged(oldTheme);
  }
}

class _TestPage extends StatefulWidget {
  const _TestPage();

  @override
  State<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends KlineStateBase<_TestPage> with AppKlineLoggerMixin {
  final AppKlineIndicatorConfig _indicatorConfig = AppKlineIndicatorConfig();
  final AppKlineConfig _klineConfig = AppKlineConfig();

  @override
  BaseIndicatorConfig get indicatorConfig => _indicatorConfig;

  @override
  IConfiguration get klineConfig => _klineConfig;

  @override
  FlexiKlineController createFlexiKlineController() => _CountingController(configuration: klineConfig, logger: this);

  @override
  KlineSpec createKlineSpec([KlineSpec? last]) => throw UnimplementedError();

  @override
  Future<void> refreshKlineData({bool reset = false}) async {}

  @override
  Future<void> loadMoreCandles(KlineSpec spec) async {}

  @override
  void dispose() {
    _indicatorConfig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  tearDown(() => appThemeMode.value = ThemeMode.system);

  group('KlineStateBase 主题刷新', () {
    testWidgets('应用主题切换时刷新 K 线配色', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestPage()));
      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      final controller = state.klineController as _CountingController;
      expect(controller.themeChanges, 0);

      appThemeMode.value = ThemeMode.dark;
      await tester.pump();
      expect(controller.themeChanges, 1);

      appThemeMode.value = ThemeMode.light;
      await tester.pump();
      expect(controller.themeChanges, 2);
    });

    testWidgets('页面销毁后不再监听', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestPage()));
      final controller = tester.state<_TestPageState>(find.byType(_TestPage)).klineController as _CountingController;

      await tester.pumpWidget(const SizedBox());
      appThemeMode.value = ThemeMode.dark;
      await tester.pump();

      expect(controller.themeChanges, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
