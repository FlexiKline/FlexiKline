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

import 'package:flexi_kline/src/extension/basic_type_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // toCamelCase
  // ---------------------------------------------------------------------------
  group('FlexiKlineStringExt.toCamelCase', () {
    test('下划线分隔 → camelCase', () {
      expect('hello_world'.toCamelCase(), 'helloWorld');
    });

    test('连字符分隔 → camelCase', () {
      expect('hello-world'.toCamelCase(), 'helloWorld');
    });

    test('空格分隔 → camelCase', () {
      expect('hello world'.toCamelCase(), 'helloWorld');
    });

    test('多词混合 → camelCase', () {
      expect('get_user_name'.toCamelCase(), 'getUserName');
    });

    test('首词大写被小写化', () {
      expect('Hello_World'.toCamelCase(), 'helloWorld');
    });

    test('空字符串返回空', () {
      expect(''.toCamelCase(), '');
    });

    test('单词不含分隔符', () {
      expect('hello'.toCamelCase(), 'hello');
    });
  });

  // ---------------------------------------------------------------------------
  // toSnakeCase
  // ---------------------------------------------------------------------------
  group('FlexiKlineStringExt.toSnakeCase', () {
    test('camelCase → snake_case', () {
      expect('helloWorld'.toSnakeCase(), 'hello_world');
    });

    test('多大写字母', () {
      expect('getUserName'.toSnakeCase(), 'get_user_name');
    });

    test('首字母大写会产生前导下划线', () {
      // 'HelloWorld' → '_hello_world'（实现行为，首字母大写被替换）
      expect('HelloWorld'.toSnakeCase(), '_hello_world');
    });

    test('空字符串返回空', () {
      expect(''.toSnakeCase(), '');
    });

    test('全小写单词不变', () {
      expect('hello'.toSnakeCase(), 'hello');
    });
  });

  // ---------------------------------------------------------------------------
  // truncate
  // ---------------------------------------------------------------------------
  group('FlexiKlineStringExt.truncate', () {
    test('长度未超出：原样返回', () {
      expect('hello'.truncate(10), 'hello');
    });

    test('长度刚好等于 maxLength：原样返回', () {
      expect('hello'.truncate(5), 'hello');
    });

    test('超出 maxLength：截断并添加省略号', () {
      expect('hello world'.truncate(5), 'hello...');
    });

    test('自定义省略号', () {
      expect('hello world'.truncate(5, ellipsis: '…'), 'hello…');
    });

    test('maxLength=0：只剩省略号', () {
      expect('hello'.truncate(0), '...');
    });
  });

  // ---------------------------------------------------------------------------
  // sensitive — 敏感信息脱敏
  // ---------------------------------------------------------------------------
  group('FlexiKlineStringExt.sensitive', () {
    test('空字符串返回空', () {
      expect(''.sensitive(), '');
    });

    test('长度小于 max(start, end)：原样返回（不脱敏）', () {
      // length=3, max(4,4)=4 → 不脱敏
      expect('123'.sensitive(), '123');
    });

    test('正常脱敏：默认 start=4, end=4', () {
      // '12345678': index = max(4, 8-4)=4 → '1234....5678'
      expect('12345678'.sensitive(), '1234....5678');
    });

    test('10 位字符串脱敏', () {
      // '1234567890': index = max(4, 10-4)=6 → '1234....7890'
      expect('1234567890'.sensitive(), '1234....7890');
    });

    test('自定义 start/end', () {
      // '12345678'.sensitive(start:2, end:2): index=max(2,8-2)=6 → '12....78'
      expect('12345678'.sensitive(start: 2, end: 2), '12....78');
    });

    test('自定义省略号', () {
      expect('12345678'.sensitive(ellipsis: '***'), '1234***5678');
    });
  });

  // ---------------------------------------------------------------------------
  // toBase64 / fromBase64 — 往返
  // ---------------------------------------------------------------------------
  group('FlexiKlineStringExt.toBase64 / fromBase64', () {
    test('ASCII 字符串往返', () {
      const original = 'Hello, World!';
      expect(original.toBase64().fromBase64(), original);
    });

    test('Unicode 字符串往返', () {
      const original = '你好，世界！';
      expect(original.toBase64().fromBase64(), original);
    });

    test('空字符串往返', () {
      expect(''.toBase64().fromBase64(), '');
    });

    test('toBase64 输出不含原始字符（除纯 ASCII 单字符外）', () {
      // Base64 编码后不应包含中文
      final encoded = '你好'.toBase64();
      expect(encoded.contains('你'), isFalse);
    });
  });
}
