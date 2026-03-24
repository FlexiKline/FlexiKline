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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 构造 / empty
  // ---------------------------------------------------------------------------
  group('Range 构造', () {
    test('基本构造：start / end 正确赋值', () {
      const r = Range(3, 10);
      expect(r.start, 3);
      expect(r.end, 10);
    });

    test('Range.empty：start=0, end=0', () {
      expect(Range.empty.start, 0);
      expect(Range.empty.end, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // length / isEmpty / isNotEmpty
  // ---------------------------------------------------------------------------
  group('Range getters', () {
    test('length = end - start', () {
      expect(const Range(3, 10).length, 7);
      expect(const Range(0, 0).length, 0);
    });

    test('isEmpty：length <= 0 时为 true', () {
      expect(Range.empty.isEmpty, isTrue);
      expect(const Range(5, 5).isEmpty, isTrue); // start == end
      expect(const Range(5, 3).isEmpty, isTrue); // end < start（异常构造）
    });

    test('isNotEmpty：length > 0 时为 true', () {
      expect(const Range(0, 1).isNotEmpty, isTrue);
      expect(const Range(3, 10).isNotEmpty, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // merge
  // ---------------------------------------------------------------------------
  group('Range.merge', () {
    test('两个相邻 Range：合并后覆盖整个区间', () {
      final r = const Range(0, 5).merge(const Range(5, 10));
      expect(r.start, 0);
      expect(r.end, 10);
    });

    test('两个重叠 Range：取外边界', () {
      final r = const Range(2, 8).merge(const Range(5, 12));
      expect(r.start, 2);
      expect(r.end, 12);
    });

    test('一个包含另一个：返回较大范围', () {
      final r = const Range(0, 10).merge(const Range(3, 7));
      expect(r.start, 0);
      expect(r.end, 10);
    });

    test('完全不相交：合并为两端外边界', () {
      final r = const Range(0, 3).merge(const Range(8, 12));
      expect(r.start, 0);
      expect(r.end, 12);
    });

    test('与 empty 合并：返回非 empty 的范围', () {
      final r = const Range(2, 7).merge(Range.empty);
      expect(r.start, 0);
      expect(r.end, 7);
    });

    test('两个相同 Range 合并：不变', () {
      final r = const Range(3, 9).merge(const Range(3, 9));
      expect(r.start, 3);
      expect(r.end, 9);
    });
  });

  // ---------------------------------------------------------------------------
  // 相等性 / hashCode
  // ---------------------------------------------------------------------------
  group('Range 相等性', () {
    test('相同 start/end 相等', () {
      expect(const Range(1, 5) == const Range(1, 5), isTrue);
    });

    test('不同 start 不相等', () {
      expect(const Range(1, 5) == const Range(2, 5), isFalse);
    });

    test('不同 end 不相等', () {
      expect(const Range(1, 5) == const Range(1, 6), isFalse);
    });

    test('相等的 Range hashCode 相同', () {
      expect(const Range(3, 7).hashCode, const Range(3, 7).hashCode);
    });

    test('Range.empty 相等性', () {
      expect(Range.empty == Range.empty, isTrue);
      expect(Range.empty == const Range(0, 0), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------
  group('Range.toString', () {
    test('格式为 Range[start, end]', () {
      expect(const Range(3, 7).toString(), 'Range[3, 7]');
    });
  });
}
