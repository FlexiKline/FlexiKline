import 'package:flexi_kline_demo/src/config/my_kline_interval.dart';
import 'package:flexi_kline_demo/src/pages/common/components/my_kline_interval_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyKlineIntervalBar', () {
    testWidgets('渲染五档周期标签', (tester) async {
      final notifier = ValueNotifier(MyKlineInterval.minute15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyKlineIntervalBar(
              intervalNotifier: notifier,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      for (final interval in MyKlineInterval.values) {
        expect(find.text(interval.label), findsOneWidget);
      }
    });

    testWidgets('点击周期回写 notifier 并回调 onChanged', (tester) async {
      final notifier = ValueNotifier(MyKlineInterval.minute15);
      MyKlineInterval? changedTo;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyKlineIntervalBar(
              intervalNotifier: notifier,
              onChanged: (v) => changedTo = v,
            ),
          ),
        ),
      );

      await tester.tap(find.text('1时'));
      await tester.pumpAndSettle();

      expect(notifier.value, MyKlineInterval.hour1);
      expect(changedTo, MyKlineInterval.hour1);
    });

    testWidgets('外部改动 notifier 时 TabBar 同步选中态', (tester) async {
      final notifier = ValueNotifier(MyKlineInterval.minute15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyKlineIntervalBar(
              intervalNotifier: notifier,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // 初始选中 15分
      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller?.index,
        MyKlineInterval.values.indexOf(MyKlineInterval.minute15),
      );

      // 外部切到 1天
      notifier.value = MyKlineInterval.day1;
      await tester.pumpAndSettle();

      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller?.index,
        MyKlineInterval.values.indexOf(MyKlineInterval.day1),
      );
    });

    testWidgets('supportedIntervals 自定义子集', (tester) async {
      final notifier = ValueNotifier(MyKlineInterval.minute15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyKlineIntervalBar(
              intervalNotifier: notifier,
              onChanged: (_) {},
              supportedIntervals: const [MyKlineInterval.minute15, MyKlineInterval.hour1],
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
