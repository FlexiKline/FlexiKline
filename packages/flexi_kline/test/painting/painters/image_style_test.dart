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
  const decoration = ShapeDecoration(color: Color(0xFF111111), shape: RoundedRectangleBorder());
  const colorFilter = ColorFilter.mode(Color(0xFF222222), BlendMode.srcIn);
  const base = ImageStyle(
    size: Size(16, 16),
    fit: BoxFit.contain,
    padding: EdgeInsets.all(2),
    decoration: decoration,
    clip: false,
    colorFilter: colorFilter,
    opacity: 0.8,
    filterQuality: FilterQuality.low,
  );

  test('默认值', () {
    const style = ImageStyle(size: Size(10, 10));
    expect(style.fit, BoxFit.fill);
    expect(style.padding, EdgeInsets.zero);
    expect(style.decoration, isNull);
    expect(style.clip, isTrue);
    expect(style.colorFilter, isNull);
    expect(style.opacity, 1);
    expect(style.filterQuality, FilterQuality.medium);
  });

  group('==', () {
    final variants = <String, ImageStyle>{
      'size': base.copyWith(size: const Size(16, 17)),
      'fit': base.copyWith(fit: BoxFit.cover),
      'padding': base.copyWith(padding: const EdgeInsets.all(3)),
      'decoration': base.copyWith(
        decoration: const ShapeDecoration(color: Color(0xFF333333), shape: RoundedRectangleBorder()),
      ),
      'clip': base.copyWith(clip: true),
      'colorFilter': base.copyWith(colorFilter: const ColorFilter.mode(Color(0xFF444444), BlendMode.srcIn)),
      'opacity': base.copyWith(opacity: 0.5),
      'filterQuality': base.copyWith(filterQuality: FilterQuality.high),
    };
    for (final MapEntry(:key, :value) in variants.entries) {
      test('$key 变化时不等', () => expect(base == value, isFalse));
    }

    test('等值的两个实例相等且哈希相同', () {
      // ignore: prefer_const_constructors
      final a = ImageStyle(size: const Size(16, 16), padding: const EdgeInsets.all(2), decoration: decoration);
      // ignore: prefer_const_constructors
      final b = ImageStyle(size: const Size(16, 16), padding: const EdgeInsets.all(2), decoration: decoration);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('copyWith', () {
    test('不传参: 新实例, 相等且哈希相同', () {
      final copy = base.copyWith();
      expect(identical(copy, base), isFalse);
      expect(copy, base);
      expect(copy.hashCode, base.hashCode);
    });

    test('只改传入的字段', () {
      final copy = base.copyWith(opacity: 0.5);
      expect(copy.opacity, 0.5);
      expect(copy.copyWith(opacity: base.opacity), base);
    });

    test('null 表示沿用原值, 不能借此清除 decoration / colorFilter', () {
      final copy = base.copyWith(decoration: null, colorFilter: null);
      expect(copy.decoration, decoration);
      expect(copy.colorFilter, colorFilter);
    });
  });
}
