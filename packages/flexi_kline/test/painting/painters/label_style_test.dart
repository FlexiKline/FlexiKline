// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flexi_kline/src/painting/export.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = LabelStyle(
    text: TextStyle(fontSize: 10, color: Color(0xFF000000)),
    textAlign: TextAlign.left,
    strutStyle: StrutStyle(fontSize: 10),
    maxLines: 1,
    minWidth: 10,
    maxWidth: 200,
    padding: EdgeInsets.all(2),
    decoration: ShapeDecoration(color: Color(0xFF111111), shape: RoundedRectangleBorder()),
  );

  group('sameLayout', () {
    final layoutVariants = <String, LabelStyle>{
      'text': base.copyWith(text: const TextStyle(fontSize: 11, color: Color(0xFF000000))),
      'textAlign': base.copyWith(textAlign: TextAlign.right),
      'strutStyle': base.copyWith(strutStyle: const StrutStyle(fontSize: 12)),
      'maxLines': base.copyWith(maxLines: 2),
      'minWidth': base.copyWith(minWidth: 11),
      'maxWidth': base.copyWith(maxWidth: 201),
    };
    for (final MapEntry(:key, :value) in layoutVariants.entries) {
      test('对排版字段 $key 敏感', () {
        expect(base.sameLayout(value), isFalse);
        expect(base == value, isFalse);
      });
    }

    test('对 padding 不敏感, 但 == 敏感', () {
      final other = base.copyWith(padding: const EdgeInsets.all(4));
      expect(base.sameLayout(other), isTrue);
      expect(base == other, isFalse);
    });

    test('对 decoration 不敏感, 但 == 敏感', () {
      final other = base.copyWith(
        decoration: const ShapeDecoration(color: Color(0xFF222222), shape: RoundedRectangleBorder()),
      );
      expect(base.sameLayout(other), isTrue);
      expect(base == other, isFalse);
    });
  });

  group('== / hashCode', () {
    test('等值的不同实例相等且哈希一致', () {
      // 经参数构造, 保证两次不是同一个 const 实例。
      LabelStyle make(double fontSize) => LabelStyle(
        text: TextStyle(fontSize: fontSize),
        padding: const EdgeInsets.all(2),
      );
      final a = make(10);
      final b = make(10);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('copyWith', () {
    test('不传参时与原值相等', () {
      final copy = base.copyWith();
      expect(identical(copy, base), isFalse);
      expect(copy, base);
      expect(copy.hashCode, base.hashCode);
    });

    test('只覆盖 decoration', () {
      const decoration = ShapeDecoration(color: Color(0xFF333333), shape: CircleBorder());
      final copy = base.copyWith(decoration: decoration);
      expect(copy.decoration, decoration);
      expect(copy.sameLayout(base), isTrue);
      expect(copy.padding, base.padding);
    });

    test('null 表示沿用, 不能清除可空字段', () {
      final copy = base.copyWith(decoration: null, strutStyle: null, maxLines: null);
      expect(copy.decoration, base.decoration);
      expect(copy.strutStyle, base.strutStyle);
      expect(copy.maxLines, base.maxLines);
    });
  });
}
