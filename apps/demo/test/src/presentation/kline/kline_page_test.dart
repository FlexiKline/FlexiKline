import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/config/my_kline_interval.dart';
import 'package:flexi_kline_demo/src/data/repositories/kline_repository.dart';
import 'package:flexi_kline_demo/src/presentation/kline/kline_page.dart';
import 'package:flexi_kline_demo/src/presentation/kline/widgets/draw_menubar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyRepository implements KlineRepository {
  @override
  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required MyKlineInterval interval,
    int? end,
    int limit = 500,
  }) async => [];

  @override
  Stream<List<CandleModel>> subscribeTicks({required String symbol, required MyKlineInterval interval}) =>
      const Stream.empty();
}

class _TestPage extends KlinePage {
  const _TestPage();

  @override
  KlineRepository createRepository() => _EmptyRepository();
}

void main() {
  testWidgets('点击「绘图工具」显示绘图菜单栏, 点退出后收起', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _TestPage()));
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
}
