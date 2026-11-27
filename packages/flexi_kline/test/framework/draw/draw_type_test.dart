import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FlexiDrawType.toString 列出 id、steps 与 groupId', () {
    const type = FlexiDrawType('line', 2, groupId: 'trend');

    expect(type.toString(), 'FlexiDrawType(id:line, steps:2, groupId:trend)');
  });
}
