import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flexi_kline_demo/src/data/repositories/kline_repository.dart';
import 'package:flexi_kline_demo/src/data/service_locator.dart';
import 'package:flexi_kline_demo/src/presentation/kline/kline_landscape_page.dart';
import 'package:flexi_kline_demo/src/presentation/kline/kline_page.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/draw_menubar.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/title_with_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyRepository implements KlineRepository {
  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required KlineInterval interval,
    int? end,
    int limit = 500,
  }) async => [];

  @override
  Stream<List<CandleModel>> subscribeTicks({required String symbol, required KlineInterval interval}) =>
      const Stream.empty();
}

void main() {
  setUp(() => getIt.registerSingleton<KlineRepository>(_EmptyRepository()));
  tearDown(getIt.reset);

  testWidgets('K 线数据加载中展示加载指示器, 加载结束后隐藏', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KlinePage()));
    await tester.pump();
    final controller = tester.widget<FlexiKlineWidget>(find.byType(FlexiKlineWidget)).controller;

    // 空仓库立即返回, 先把当前规格切回空数据, 回到加载中。
    controller.switchKlineData(controller.klineData.spec);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.stopLoading(spec: controller.klineData.spec);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // 让头部按钮的节流定时器走完。
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击「绘图工具」显示绘图菜单栏, 点退出后收起', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KlinePage()));
    expect(find.byType(DrawMenubar), findsNothing);

    await tester.tap(find.byTooltip('绘图工具'));
    await tester.pump();
    expect(find.byType(DrawMenubar), findsOneWidget);

    await tester.tap(find.byTooltip('退出绘图'));
    await tester.pump();
    expect(find.byType(DrawMenubar), findsNothing);

    // 让头部按钮的节流定时器走完。
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('竖屏切到 1时 后打开横屏页，横屏页也在 1时', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KlinePage()));
    await tester.pump();

    await tester.tap(find.text('1时'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('横屏'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final landscapeBar = find.descendant(of: find.byType(KlineLandscapePage), matching: find.byType(TabBar));
    expect(
      tester.widget<TabBar>(landscapeBar).controller?.index,
      KlineInterval.values.indexOf(KlineInterval.hour1),
    );

    // 让头部按钮的节流定时器走完。
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  /// 竖屏切到 1时 → 打开横屏 → 横屏切到 1天，返回由 [exit] 完成。
  Future<void> openLandscapeAndPickDay(WidgetTester tester, Future<void> Function() exit) async {
    await tester.pumpWidget(const MaterialApp(home: KlinePage()));
    await tester.pump();
    await tester.tap(find.text('1时'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('横屏'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final landscape = find.byType(KlineLandscapePage);
    await tester.tap(find.descendant(of: landscape, matching: find.text('1天')));
    await tester.pump(const Duration(milliseconds: 500));

    await exit();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(landscape, findsNothing);
  }

  Future<void> expectPortraitInterval(WidgetTester tester, KlineInterval interval) async {
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.index, KlineInterval.values.indexOf(interval));

    // 让头部按钮的节流定时器走完。
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  }

  testWidgets('点 AppBar 返回退出横屏后，竖屏周期变为横屏所选', (tester) async {
    await openLandscapeAndPickDay(tester, () => tester.tap(find.byType(BackButton)));
    await expectPortraitInterval(tester, KlineInterval.day1);
  });

  testWidgets('系统返回键退出横屏后，竖屏周期变为横屏所选', (tester) async {
    await openLandscapeAndPickDay(tester, () => tester.binding.handlePopRoute());
    await expectPortraitInterval(tester, KlineInterval.day1);
  });

  testWidgets('竖屏 AppBar 标题是「标的 + 模拟」标签', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KlinePage()));
    await tester.pump();

    final appBar = find.descendant(of: find.byType(KlinePage), matching: find.byType(AppBar));
    expect(find.descendant(of: appBar, matching: find.byType(TitleWithTag)), findsOneWidget);
    expect(find.descendant(of: appBar, matching: find.text('BTC-USDT')), findsOneWidget);
    expect(find.descendant(of: appBar, matching: find.text('模拟')), findsOneWidget);

    // 让头部按钮的节流定时器走完。
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('横屏 AppBar 标题也是「标的 + 模拟」标签', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KlinePage()));
    await tester.pump();
    await tester.tap(find.byTooltip('横屏'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final appBar = find.descendant(of: find.byType(KlineLandscapePage), matching: find.byType(AppBar));
    expect(find.descendant(of: appBar, matching: find.byType(TitleWithTag)), findsOneWidget);
    expect(find.descendant(of: appBar, matching: find.text('BTC-USDT')), findsOneWidget);
    expect(find.descendant(of: appBar, matching: find.text('模拟')), findsOneWidget);

    // 让头部按钮的节流定时器走完。
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
