// Minimal flexi_kline setup: an in-memory configuration, a candle chart and generated data.
// The full multi-platform demo lives in apps/demo of the repository:
// https://github.com/FlexiKline/FlexiKline/tree/main/apps/demo

import 'dart:math' as math;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: KlinePage()));

class KlinePage extends StatefulWidget {
  const KlinePage({super.key});

  @override
  State<KlinePage> createState() => _KlinePageState();
}

class _KlinePageState extends State<KlinePage> {
  static const spec = KlineSpec(
    symbol: 'BTC-USDT',
    interval: FlexiTimeInterval(1, TimeUnit.hour),
  );

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
    return Scaffold(
      appBar: AppBar(title: const Text('FlexiKline')),
      body: FlexiKlineWidget(
        controller: controller,
        candle: candle,
        time: time,
      ),
    );
  }
}

/// Keeps the configuration in memory; persist it in a real app (e.g. shared_preferences).
class ExampleConfiguration with FlexiKlineConfigurationMixin {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  IFlexiKlineTheme get theme => const ExampleTheme();

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

/// Random-walk candles, newest first (the order flexi_kline expects).
List<CandleModel> generateCandles(int count) {
  final random = math.Random(7);
  final hour = const Duration(hours: 1).inMilliseconds;
  final now = DateTime.now().millisecondsSinceEpoch ~/ hour * hour;
  var close = 60000.0;
  return List.generate(count, (i) {
    final open = close + (random.nextDouble() - 0.5) * 400;
    final high = math.max(open, close) + random.nextDouble() * 200;
    final low = math.min(open, close) - random.nextDouble() * 200;
    final candle = CandleModel(
      timestamp: now - i * hour,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: random.nextDouble() * 100,
    );
    close = open;
    return candle;
  });
}
