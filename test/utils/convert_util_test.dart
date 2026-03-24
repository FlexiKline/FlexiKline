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

import 'package:decimal/decimal.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // parseInt
  // ---------------------------------------------------------------------------
  group('parseInt', () {
    test('null 输入返回 def（默认 null）', () {
      expect(parseInt(null), isNull);
      expect(parseInt(null, def: 0), 0);
    });

    test('int 输入直接返回', () {
      expect(parseInt(42), 42);
    });

    test('double 输入截断为 int', () {
      expect(parseInt(3.9), 3);
    });

    test('数字字符串解析', () {
      expect(parseInt('123'), 123);
    });

    test('非数字字符串返回 null', () {
      expect(parseInt('abc'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // parseDouble
  // ---------------------------------------------------------------------------
  group('parseDouble', () {
    test('null 输入返回 def（默认 null）', () {
      expect(parseDouble(null), isNull);
      expect(parseDouble(null, def: 0.0), 0.0);
    });

    test('int 输入转换为 double', () {
      expect(parseDouble(5), 5.0);
    });

    test('double 输入原样返回', () {
      expect(parseDouble(3.14), closeTo(3.14, 1e-12));
    });

    test('数字字符串解析', () {
      expect(parseDouble('2.718'), closeTo(2.718, 1e-9));
    });

    test('其他类型返回 def', () {
      expect(parseDouble(true, def: -1.0), -1.0);
    });
  });

  // ---------------------------------------------------------------------------
  // parseBool
  // ---------------------------------------------------------------------------
  group('parseBool', () {
    test('null 返回 def', () {
      expect(parseBool(null), isNull);
      expect(parseBool(null, def: true), isTrue);
    });

    test('"true" 返回 true', () {
      expect(parseBool('true'), isTrue);
      expect(parseBool('TRUE'), isTrue);
      expect(parseBool('True'), isTrue);
    });

    test('"false" 返回 false', () {
      expect(parseBool('false'), isFalse);
      expect(parseBool('FALSE'), isFalse);
    });

    test('无效字符串返回 null', () {
      expect(parseBool('yes'), isNull);
      expect(parseBool('1'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // parseDecimal
  // ---------------------------------------------------------------------------
  group('parseDecimal', () {
    test('null 返回 def', () {
      expect(parseDecimal(null), isNull);
      expect(parseDecimal(null, def: Decimal.zero), Decimal.zero);
    });

    test('int 输入转换为 Decimal', () {
      expect(parseDecimal(42), Decimal.fromInt(42));
    });

    test('字符串解析', () {
      expect(parseDecimal('3.14'), Decimal.parse('3.14'));
    });

    test('无效字符串返回 null', () {
      expect(parseDecimal('abc'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // parseDateTime / convertDateTime — 往返
  // ---------------------------------------------------------------------------
  group('parseDateTime / convertDateTime', () {
    test('null 输入返回 null', () {
      expect(parseDateTime(null), isNull);
    });

    test('int 毫秒时间戳解析', () {
      final ts = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      final dt = parseDateTime(ts);
      expect(dt?.millisecondsSinceEpoch, ts);
    });

    test('ISO 8601 字符串解析', () {
      final dt = parseDateTime('2024-01-01T00:00:00.000');
      expect(dt, isNotNull);
      expect(dt!.year, 2024);
    });

    test('convertDateTime：DateTime → int', () {
      final dt = DateTime(2024, 6, 15);
      final ts = convertDateTime(dt);
      expect(ts, dt.millisecondsSinceEpoch);
    });

    test('convertDateTime：int 原样返回', () {
      expect(convertDateTime(1234567890), 1234567890);
    });

    test('convertDateTime：null 返回 null', () {
      expect(convertDateTime(null), isNull);
    });

    test('往返一致性', () {
      final original = DateTime(2025, 3, 15, 12, 0, 0);
      final ts = convertDateTime(original)!;
      final restored = parseDateTime(ts)!;
      expect(restored.millisecondsSinceEpoch, original.millisecondsSinceEpoch);
    });
  });

  // ---------------------------------------------------------------------------
  // parseHexColor / convertHexColor — 颜色往返
  // ---------------------------------------------------------------------------
  group('parseHexColor / convertHexColor', () {
    test('null / 空字符串返回 def', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor(''), isNull);
      expect(parseHexColor(null, def: const Color(0xFFFFFFFF)), const Color(0xFFFFFFFF));
    });

    test('0x 格式（8 位 ARGB）', () {
      expect(parseHexColor('0xFFFF0000'), const Color(0xFFFF0000)); // 红
    });

    test('0x 格式无效字符串返回 def', () {
      expect(parseHexColor('0xInvalidHex'), isNull);
    });

    test('# + 6 位（RGB）：自动补 FF alpha', () {
      // #FF0000 → FFFF0000
      final color = parseHexColor('#FF0000');
      expect(color, const Color(0xFFFF0000));
    });

    test('# + 8 位（ARGB）', () {
      final color = parseHexColor('#80FF0000');
      expect(color, const Color(0x80FF0000));
    });

    test('大小写不敏感', () {
      expect(parseHexColor('#ff0000'), parseHexColor('#FF0000'));
    });

    test('convertHexColor：输出 0x 前缀小写十六进制', () {
      final hex = convertHexColor(const Color(0xFFABCDEF));
      expect(hex, '0xffabcdef');
    });

    test('convertHexColor：null 返回 def', () {
      expect(convertHexColor(null), isNull);
      expect(convertHexColor(null, def: '#000000'), '#000000');
    });

    test('往返一致性', () {
      const original = Color(0xFF123456);
      final hex = convertHexColor(original)!;
      final restored = parseHexColor(hex);
      expect(restored, original);
    });
  });

  // ---------------------------------------------------------------------------
  // parseRadius / convertRadius — 往返
  // ---------------------------------------------------------------------------
  group('parseRadius / convertRadius', () {
    test('null 返回 Radius.zero', () {
      expect(parseRadius(null), Radius.zero);
    });

    test('num 输入：circular', () {
      expect(parseRadius(10), const Radius.circular(10));
    });

    test('字符串单值：circular', () {
      expect(parseRadius('10'), const Radius.circular(10));
    });

    test('字符串双值：elliptical', () {
      expect(parseRadius('10:20'), const Radius.elliptical(10, 20));
    });

    test('convertRadius：Radius.zero 返回 null', () {
      expect(convertRadius(Radius.zero), isNull);
    });

    test('convertRadius：圆形 → 返回 double', () {
      expect(convertRadius(const Radius.circular(10)), 10.0);
    });

    test('convertRadius：椭圆 → 返回 "x:y" 字符串', () {
      expect(convertRadius(const Radius.elliptical(10, 20)), '10.0:20.0');
    });

    test('往返：circular', () {
      const r = Radius.circular(8);
      final converted = convertRadius(r);
      final restored = parseRadius(converted);
      expect(restored, r);
    });

    test('往返：elliptical', () {
      const r = Radius.elliptical(10, 20);
      final converted = convertRadius(r); // '10.0:20.0'
      final restored = parseRadius(converted);
      expect(restored, r);
    });
  });

  // ---------------------------------------------------------------------------
  // parseAlignment / convertAlignment — 往返
  // ---------------------------------------------------------------------------
  group('parseAlignment / convertAlignment', () {
    test('null / 空 Map 返回 null', () {
      expect(parseAlignment(null), isNull);
      expect(parseAlignment({}), isNull);
    });

    final presets = [
      (Alignment.topLeft, 'topLeft'),
      (Alignment.topCenter, 'topCenter'),
      (Alignment.topRight, 'topRight'),
      (Alignment.centerLeft, 'centerLeft'),
      (Alignment.center, 'center'),
      (Alignment.centerRight, 'centerRight'),
      (Alignment.bottomLeft, 'bottomLeft'),
      (Alignment.bottomCenter, 'bottomCenter'),
      (Alignment.bottomRight, 'bottomRight'),
    ];

    for (final (alignment, name) in presets) {
      test('预设 $name 往返', () {
        final json = convertAlignment(alignment);
        final restored = parseAlignment(json);
        expect(restored, alignment, reason: name);
      });
    }

    test('自定义 x/y 往返', () {
      const original = Alignment(0.3, -0.7);
      final json = convertAlignment(original);
      final restored = parseAlignment(json);
      expect(restored?.x, closeTo(0.3, 1e-9));
      expect(restored?.y, closeTo(-0.7, 1e-9));
    });
  });
}
