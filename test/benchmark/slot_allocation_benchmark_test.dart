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

@Tags(['benchmark'])
library;

import 'dart:math';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  test('slot register/recycle 100k ops', () {
    final m = IndicatorPaintObjectManager(
      configuration: FakeFlexiKlineConfiguration(),
    );
    final rng = Random(0);
    final sw = Stopwatch()..start();
    for (int i = 0; i < 100000; i++) {
      final key = ComputedIndicatorKey('k_${rng.nextInt(50)}');
      if (rng.nextBool()) {
        m.allocateComputedDataIndexes([key]);
      } else {
        m.releaseComputedDataIndex(key);
      }
    }
    sw.stop();
    debugPrint('slot_allocation: 100k ops in ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(0));
  });
}
