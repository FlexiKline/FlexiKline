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

import 'dart:math' as math;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  final stopwatch = Stopwatch();
  late List<CandleModel> list;
  late List<MaParam> calcParams;

  setUpAll(() {
    list = getCandleModelList();
    calcParams = const [
      MaParam(label: 'MA7', count: 7, color: Color(0xFF946F9A)),
      MaParam(label: 'MA30', count: 30, color: Color(0xFFF1BF32))
    ];
  });

  setUp(() {
    stopwatch.reset();
    stopwatch.start();
  });
  tearDown(() {
    stopwatch.stop();
    debugPrint('tearDown spent:${stopwatch.elapsedMicroseconds}');
  });
  test('test-use-double', () {
    debugPrint('test-use-double');
    calcuAndCacheMa(list, calcParams, 0, list.length);
    final maxmin = calcuMaMaxmin(list, calcParams, 50, 100);
    debugPrint('maxmin:$maxmin');
  });
}

void calcuAndCacheMa(
  List<CandleModel> list,
  List<MaParam> calcParams,
  int start,
  int end,
) {
  if (list.isEmpty || calcParams.isEmpty) return;
  int len = list.length;
  if (start < 0 || end > len) return;
  int? minCount;

  for (var param in calcParams) {
    minCount ??= param.count;
    minCount = param.count < minCount ? param.count : minCount;
  }

  end = math.min(end + minCount!, len);

  CandleModel m;
  final paramLen = calcParams.length;
  final closeSum = List.filled(paramLen, BagNum.zero, growable: false);
  for (int i = end - 1; i >= start; i--) {
    m = list[i];
    m.maRets = List.filled(calcParams.length, null, growable: false);
    for (int j = 0; j < calcParams.length; j++) {
      closeSum[j] += m.close;
      final count = calcParams[j].count;
      if (i <= end - count) {
        m.maRets![j] = closeSum[j].divNum(count);
        closeSum[j] -= list[i + (count - 1)].close;
      }
    }
  }
}

MinMax? calcuMaMaxmin(
  List<CandleModel> list,
  List<MaParam> calcParams,
  int start,
  int end,
) {
  if (list.isEmpty || calcParams.isEmpty) return null;
  int len = list.length;
  if (start < 0 || end > len) return null;

  if (list[start].isValidMaRets != true ||
      list[end - 1].isValidMaRets != true) {
    calcuAndCacheMa(list, calcParams, start, end);
  }

  MinMax? maxmin;
  CandleModel m;
  for (int i = end - 1; i >= start; i--) {
    m = list[i];
    maxmin ??= m.maRetsMinmax;
    maxmin?.updateMinMax(m.maRetsMinmax);
  }
  return maxmin;
}
