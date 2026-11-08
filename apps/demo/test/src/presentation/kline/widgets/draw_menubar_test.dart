import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/app_kline_config.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/draw_menubar.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/draw_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlexiKlineController controller;

  setUp(() => controller = FlexiKlineController(configuration: AppKlineConfig()));
  tearDown(() => controller.dispose());

  Future<void> pumpMenubar(WidgetTester tester, {VoidCallback? onExit}) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DrawMenubar(controller: controller, onExit: onExit),
      ),
    ),
  );

  testWidgets('每个支持的绘图工具一个图标按钮, 另有磁吸图标', (tester) async {
    // 足够宽, 让横向列表一次构建全部按钮。
    tester.view.physicalSize = const Size(2400, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpMenubar(tester);

    expect(controller.supportDrawTypes, hasLength(19));
    expect(find.byType(ShapeIcon), findsNWidgets(19 + 1));
    expect(find.byTooltip('trendLine'), findsOneWidget);
  });

  testWidgets('磁吸按钮依次切换模式, 连续绘制按钮切换开关, 退出按钮回调', (tester) async {
    var exited = false;
    await pumpMenubar(tester, onExit: () => exited = true);

    expect(controller.drawMagnet, MagnetMode.normal);
    await tester.tap(find.byTooltip('磁吸: normal'));
    await tester.pump();
    expect(controller.drawMagnet, MagnetMode.weak);

    final continuous = controller.drawContinuousListenable.value;
    await tester.tap(find.byTooltip('连续绘制'));
    await tester.pump();
    expect(controller.drawContinuousListenable.value, !continuous);

    await tester.tap(find.byTooltip('退出绘图'));
    expect(exited, isTrue);
  });

  testWidgets('没有选中图形时样式工具条不显示内容', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DrawToolbar(controller: controller)),
      ),
    );
    expect(find.byType(IconButton), findsNothing);
  });
}
