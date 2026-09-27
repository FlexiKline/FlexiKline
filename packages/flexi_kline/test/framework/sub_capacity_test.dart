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

/// 属性测试：副区满容量 FIFO 驱逐 (M10)
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('v2.2.0/IndicatorPaintObjectManager/sub_capacity', () {
    test('M10: 副区满容量时 FIFO 驱逐队首', () {
      final ctx = FakePaintContext();
      final m = IndicatorPaintObjectManager(
        configuration: FakeFlexiKlineConfiguration(),
        subIndicatorMaxCount: 2,
      );
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [
          TestComputedIndicator(key: computedKey(1)),
          TestComputedIndicator(key: computedKey(2)),
          TestComputedIndicator(key: computedKey(3)),
        ],
        context: ctx,
      );

      m.addSubPaintObject(computedKey(1), ctx);
      m.addSubPaintObject(computedKey(2), ctx);
      m.addSubPaintObject(computedKey(3), ctx); // 容量2 → 驱逐队首 key1

      final activeSub = m.subIndicatorKeys.toSet();
      expect(activeSub.contains(computedKey(2)), isTrue);
      expect(activeSub.contains(computedKey(3)), isTrue);
      expect(activeSub.contains(computedKey(1)), isFalse);
    });
  });
}
