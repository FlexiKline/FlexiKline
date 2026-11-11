import 'package:flexi_kline_demo/src/presentation/kline/widgets/title_with_tag.dart';
import 'package:flexi_kline_demo/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: TitleWithTag('BTC-USDT', tag: '模拟')),
        ),
      ),
    );
  }

  testWidgets('显示标题与标签', (tester) async {
    await pump(tester);
    expect(find.text('BTC-USDT'), findsOneWidget);
    expect(find.text('模拟'), findsOneWidget);
  });

  testWidgets('标签在标题右下角，且字号更小', (tester) async {
    await pump(tester);
    final title = tester.getRect(find.text('BTC-USDT'));
    final tag = tester.getRect(find.text('模拟'));

    expect(tag.left, greaterThanOrEqualTo(title.right));
    expect(tag.bottom, closeTo(title.bottom, 4));
    expect(tag.height, lessThan(title.height));
  });

  testWidgets('标签是品牌色底、白色文字', (tester) async {
    await pump(tester);
    final text = tester.widget<Text>(find.text('模拟'));
    expect(text.style?.color, Colors.white);

    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('模拟'), matching: find.byType(DecoratedBox)).first,
    );
    expect((box.decoration as BoxDecoration).color, AppTheme.brandBlue);
  });
}
