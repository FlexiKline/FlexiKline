import 'package:flexi_kline_demo/src/data/models/kline_interval.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/kline_interval_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KlineIntervalBar', () {
    testWidgets('渲染五档周期标签', (tester) async {
      final notifier = ValueNotifier(KlineInterval.minute15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KlineIntervalBar(
              selected: notifier,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      for (final label in const ['分时', '15分', '1时', '1天', '1周']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('点击周期只回调 onSelected，不改 selected', (tester) async {
      final notifier = ValueNotifier(KlineInterval.minute15);
      KlineInterval? changedTo;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KlineIntervalBar(
              selected: notifier,
              onSelected: (v) => changedTo = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('1时'));
      await tester.pumpAndSettle();

      expect(changedTo, KlineInterval.hour1);
      expect(notifier.value, KlineInterval.minute15);
    });

    testWidgets('外部改动 notifier 时 TabBar 同步选中态', (tester) async {
      final notifier = ValueNotifier(KlineInterval.minute15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KlineIntervalBar(
              selected: notifier,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // 初始选中 15分
      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller?.index,
        KlineInterval.values.indexOf(KlineInterval.minute15),
      );

      // 外部切到 1天
      notifier.value = KlineInterval.day1;
      await tester.pumpAndSettle();

      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller?.index,
        KlineInterval.values.indexOf(KlineInterval.day1),
      );
    });

    testWidgets('intervals 自定义子集', (tester) async {
      final notifier = ValueNotifier(KlineInterval.minute15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KlineIntervalBar(
              selected: notifier,
              onSelected: (_) {},
              intervals: const [KlineInterval.minute15, KlineInterval.hour1],
            ),
          ),
        ),
      );

      expect(find.text('15分'), findsOneWidget);
      expect(find.text('1时'), findsOneWidget);
      expect(find.text('1天'), findsNothing);
    });
  });
}
