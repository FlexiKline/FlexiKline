import 'package:flexi_kline_demo/src/presentation/painting/painting_page.dart';
import 'package:flexi_kline_demo/src/presentation/painting/widgets/painting/icon_shapes_section.dart';
import 'package:flexi_painting/flexi_painting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('两个标签页的每节都能画出来, 切换与返回时释放资源不抛异常', (tester) async {
    // 足够高, 让 ListView 一次构建全部节。
    tester.view.physicalSize = const Size(400, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PaintingPage()));
    expect(find.byType(Card), findsNWidgets(10));
    // 内置图形的全部变体, 加上「三处用」一节底部的 3 个。
    expect(find.byType(ShapeIcon), findsNWidgets(IconShapesSection.variantCount + 3));
    expect(find.byWidgetPredicate((w) => w is Image && w.image is ShapeImageProvider), findsNWidgets(3));

    await tester.tap(find.text('换值'));
    await tester.pump();

    await tester.tap(find.text('K 线场景'));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNWidgets(6));

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
