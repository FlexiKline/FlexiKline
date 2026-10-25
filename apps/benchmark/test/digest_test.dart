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

import 'package:flexi_kline_benchmark/src/data/candles.dart';
import 'package:flexi_kline_benchmark/src/data/digest.dart';
import 'package:flutter_test/flutter_test.dart';

/// 跨数据方向对比时, 两侧的蜡烛顺序相反但内容相同, 指纹必须相等; 内容差一点就必须不等。
void main() {
  final candles = benchCandles(count: 50);

  test('digest ignores list direction', () {
    expect(dataDigest(candles.reversed.toList()), dataDigest(candles));
  });

  test('digest changes with any field or candle count', () {
    expect(dataDigest(benchCandles(count: 50, offset: 1)), isNot(dataDigest(candles)));
    expect(dataDigest(candles.sublist(1)), isNot(dataDigest(candles)));
  });

  test('digest is a 16-digit hex string', () {
    expect(dataDigest(candles), matches(RegExp(r'^[0-9a-f]{16}$')));
  });
}
