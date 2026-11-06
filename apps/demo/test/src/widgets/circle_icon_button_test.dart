import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_demo/src/theme/my_app_theme.dart';
import 'package:flexi_kline_demo/src/widgets/circle_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, ThemeData theme, {required bool selected}) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Center(
        child: CircleIconButton(selected: selected, onPressed: () {}, icon: const ShapeIcon(CircleShape())),
      ),
    ),
  );

  Color iconColor(WidgetTester tester) => IconTheme.of(tester.element(find.byType(ShapeIcon))).color!;

  for (final (name, theme) in [('浅色', MyAppTheme.light), ('深色', MyAppTheme.dark)]) {
    testWidgets('$name: 选中用品牌蓝, 未选中用次要文字色, 都不加背景', (tester) async {
      await pump(tester, theme, selected: true);
      expect(iconColor(tester), MyAppTheme.selectedOf(theme.brightness));
      final style = tester.widget<IconButton>(find.byType(IconButton)).style!;
      expect(style.backgroundColor, isNull);

      await pump(tester, theme, selected: false);
      // 选中态切换时图标色经 AnimatedTheme 过渡。
      await tester.pumpAndSettle();
      expect(iconColor(tester), theme.colorScheme.onSurfaceVariant);
    });
  }

  testWidgets('按钮为给定直径的正方形', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CircleIconButton(size: 28, onPressed: () {}, icon: const Icon(Icons.edit)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(IconButton)), const Size(28, 28));
  });
}
