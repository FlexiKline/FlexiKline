import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/app_kline_config.dart';
import 'package:flexi_kline_demo/src/config/app_kline_indicator_config.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/draw_toolbar.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart' show trendLine;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('选中图形后打开颜色菜单不报错, 选色后生效并收起菜单', (tester) async {
    final indicators = AppKlineIndicatorConfig();
    final controller = FlexiKlineController(configuration: AppKlineConfig());
    const spec = KlineSpec(symbol: 'BTCUSDT', interval: KlineInterval.minute15, precision: 2);
    final step = KlineInterval.minute15.milliseconds;
    controller
      ..switchKlineData(spec)
      ..replaceKlineData(spec, [
        for (var i = 0; i < 100; i++)
          CandleModel(timestamp: i * step, open: 100, high: 101, low: 99, close: 100, volume: 1),
      ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 300,
                child: FlexiKlineWidget(controller: controller, candle: indicators.candle, time: indicators.time),
              ),
              DrawToolbar(controller: controller),
            ],
          ),
        ),
      ),
    );
    // 挂载前送入的数据在首帧结束后合并。
    await tester.pump();
    controller
      ..prepareDraw()
      ..startDraw(trendLine, isInitPointer: true);
    await tester.pump();

    await tester.tap(find.byTooltip('颜色'));
    // 图表有常驻的倒计时动画, pumpAndSettle 不会结束; 只等菜单动画走完。
    await tester.pump(const Duration(milliseconds: 500));
    final red = find.byWidgetPredicate((w) => w is ShapeIcon && w.color == Colors.redAccent);
    expect(red, findsOneWidget);

    await tester.tap(red);
    // 图表有常驻的倒计时动画, pumpAndSettle 不会结束; 只等菜单动画走完。
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.drawState.object!.line.paint.color, Colors.redAccent);
    expect(red, findsNothing, reason: '选色后菜单收起');

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    indicators.dispose();
  });
}
