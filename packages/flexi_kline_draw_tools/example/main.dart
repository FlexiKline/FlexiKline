// Minimal flexi_kline_draw_tools setup: register the built-in tools and start drawing from buttons.
// The full multi-platform demo lives in apps/demo of the repository:
// https://github.com/FlexiKline/FlexiKline/tree/main/apps/demo

import 'dart:math' as math;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      textStyle: const TextStyle(color: Color(0xFF111111), fontSize: 14),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      ),
      home: const ColoredBox(color: Color(0xFFFFFFFF), child: DrawToolsPage()),
    ),
  );
}

class DrawToolsPage extends StatefulWidget {
  const DrawToolsPage({super.key});

  @override
  State<DrawToolsPage> createState() => _DrawToolsPageState();
}

class _DrawToolsPageState extends State<DrawToolsPage> {
  static const spec = KlineSpec(symbol: 'BTC-USDT', interval: FlexiTimeInterval(1, TimeUnit.hour));

  late final FlexiKlineController controller;
  final candle = CandleIndicator();
  final time = TimeIndicator(position: DrawPosition.bottom);

  @override
  void initState() {
    super.initState();
    controller = FlexiKlineController(configuration: ExampleConfiguration());
    controller.switchKlineData(spec);
    controller.replaceKlineData(spec, generateCandles(300));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in [trendLine, horizontalLine, rectangle, fibRetracement])
                _ToolButton(label: type.id, onTap: () => controller.startDraw(type)),
              _ToolButton(label: 'exit', onTap: controller.exitDraw),
            ],
          ),
          Expanded(
            child: FlexiKlineWidget(
              controller: controller,
              candle: candle,
              time: time,
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain bordered button; the example does not depend on Material.
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF448AFF)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label, style: const TextStyle(color: Color(0xFF448AFF))),
        ),
      ),
    );
  }
}

/// `DrawObjectBuildersConfigMixin` provides every built-in tool; drawing must also be enabled.
class ExampleConfiguration with FlexiKlineConfigurationMixin, DrawObjectBuildersConfigMixin {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  IFlexiKlineTheme get theme => const ExampleTheme();

  @override
  DrawConfig genDrawConfig([DrawConfig? draw]) => super
      .genDrawConfig(draw)
      .copyWith(
        enable: true,
      );

  @override
  Map<String, dynamic>? getConfig(String key) => _store[key];

  @override
  Future<bool> setConfig(String key, Map<String, dynamic> value) async {
    _store[key] = value;
    return true;
  }
}

class ExampleTheme implements IFlexiKlineTheme {
  const ExampleTheme();

  @override
  Color get longColor => const Color(0xFF21B26D);
  @override
  Color get shortColor => const Color(0xFFEE4549);
  @override
  Color get chartBg => const Color(0xFFFFFFFF);
  @override
  Color get tooltipBg => const Color(0xCCFFFFFF);
  @override
  Color get crossTextBg => const Color(0xFF444444);
  @override
  Color get latestPriceBg => const Color(0xFFFFFFFF);
  @override
  Color get lastPriceBg => const Color(0x8A000000);
  @override
  Color get countdownBg => const Color(0xFFF5F5F5);
  @override
  Color get dragBg => const Color(0xFF111111);
  @override
  Color get gridLineColor => const Color(0xFFE9E9E9);
  @override
  Color get crosshairColor => const Color(0xFFF6A701);
  @override
  Color get drawToolColor => const Color(0xFF448AFF);
  @override
  Color get markLineColor => const Color(0xFF111111);
  @override
  Color get lineChartColor => const Color(0xFF03A9F4);
  @override
  Color get textColor => const Color(0xFF111111);
  @override
  Color get ticksTextColor => const Color(0xFF949494);
  @override
  Color get lastPriceColor => const Color(0xFFF9F8F8);
  @override
  Color get crossTextColor => const Color(0xFFF9F8F8);
  @override
  Color get tooltipTextColor => const Color(0xFF111111);
}

/// Random-walk candles in ascending time order (oldest first, newest last — the order flexi_kline expects).
List<CandleModel> generateCandles(int count) {
  final random = math.Random(7);
  final hour = const Duration(hours: 1).inMilliseconds;
  final now = DateTime.now().millisecondsSinceEpoch ~/ hour * hour;
  final candles = <CandleModel>[];
  var close = 60000.0;
  for (var i = 0; i < count; i++) {
    final open = close + (random.nextDouble() - 0.5) * 400;
    final high = math.max(open, close) + random.nextDouble() * 200;
    final low = math.min(open, close) - random.nextDouble() * 200;
    candles.add(
      CandleModel(
        timestamp: now - (count - 1 - i) * hour,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: random.nextDouble() * 100,
      ),
    );
    close = open;
  }
  return candles;
}
