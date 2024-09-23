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

import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rect = Rect.fromLTRB(0, 0, 14, 10);

  group('pointDistanceToLine', () {
    const offset = Offset(5, 5);
    Offset a;
    Offset b;
    double ret;
    test('test 点在线上', () {
      a = Offset(2, 2);
      b = Offset(8, 8);
      ret = distancePointToLine(offset, a, b);
      debugPrint('$a -> $b = $ret');
    });

    test('test 2', () {
      a = Offset(5, 2);
      b = Offset(8, 8);
      ret = offset.distanceToLine(a, b);
      debugPrint('$a -> $b = $ret');
    });

    test('test 3', () {
      a = Offset(5, 2);
      b = Offset(8, 8);
      ret = offset.distanceToLine(a, b);
      debugPrint('$a -> $b = $ret');
    });
  });

  group('reflectInRect', () {
    final offset = Offset(5, 5);
    test('reflectInRect', () {
      Offset other = Offset(10, 6);
      Offset ret = offset.reflectInRect(other, rect);
      debugPrint("1>" + ret.toString()); // 14, 6.8

      other = Offset(6, 8);
      ret = offset.reflectInRect(other, rect);
      debugPrint("2>" + ret.toString()); // 6.7, 10.0

      other = Offset(12, 2);
      ret = offset.reflectInRect(other, rect);
      debugPrint("3>" + ret.toString()); // 14.0, 1.1

      other = Offset(7, 1);
      ret = offset.reflectInRect(other, rect);
      debugPrint("4>" + ret.toString()); // 7.5, 0.0
    });

    test('reflectInRect2', () {
      Offset other = Offset(10, 6);
      Offset ret = other.reflectInRect(offset, rect);
      debugPrint("1>" + ret.toString()); // 0.0, 4.0

      other = Offset(6, 8);
      ret = other.reflectInRect(offset, rect);
      debugPrint("2>" + ret.toString()); // 3.3, 0.0

      other = Offset(12, 2);
      ret = other.reflectInRect(offset, rect);
      debugPrint("3>" + ret.toString()); // 0.0, 7.1

      other = Offset(7, 1);
      ret = other.reflectInRect(offset, rect);
      debugPrint("4>" + ret.toString()); // 2.5, 10.0
    });

    test('reflectInRect vertical horizontal', () {
      Offset other = Offset(2, 5);
      Offset ret = offset.reflectInRect(other, rect);
      debugPrint("1>" + ret.toString()); // 0.0, 5.0

      other = Offset(7, 5);
      ret = offset.reflectInRect(other, rect);
      debugPrint("2>" + ret.toString()); // 14.0, 5.0

      other = Offset(5, 2);
      ret = offset.reflectInRect(other, rect);
      debugPrint("3>" + ret.toString()); // 5.0, 0.0

      other = Offset(5, 7);
      ret = offset.reflectInRect(other, rect);
      debugPrint("4>" + ret.toString()); // 5.0, 10
    });

    test('reflectInRect outside', () {
      Offset other = Offset(2, 5);
      Offset ret = offset.reflectInRect(other, rect);
      debugPrint("1>" + ret.toString()); // 0.0, 5.0

      other = Offset(7, 5);
      ret = offset.reflectInRect(other, rect);
      debugPrint("2>" + ret.toString()); // 14.0, 5.0

      other = Offset(5, 2);
      ret = offset.reflectInRect(other, rect);
      debugPrint("3>" + ret.toString()); // 5.0, 0.0

      other = Offset(5, 7);
      ret = offset.reflectInRect(other, rect);
      debugPrint("4>" + ret.toString()); // 5.0, 10
    });
  });
}
