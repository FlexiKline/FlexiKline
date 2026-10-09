import 'package:flexi_kline_demo/src/pages/painting/painting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('每节都能画出来, 返回时释放资源不抛异常', (tester) async {
    // 足够高, 让 ListView 一次构建全部节。
    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PaintingPage()));
    expect(find.byType(Card), findsNWidgets(9));

    await tester.tap(find.text('换值'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
