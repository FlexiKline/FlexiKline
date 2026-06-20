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

/// 集成测试：FlexiKlineLifecycle 三态切换
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('v2.2.0/FlexiKlineController/lifecycle', () {
    test('initial → mounted → disposed 三态切换', () {
      final c = FlexiKlineController(
        configuration: FakeFlexiKlineConfiguration(),
      );

      // 1. 构造后处于 initial 状态
      expect(c.lifecycleListenable.value, FlexiKlineLifecycle.initial);
      expect(c.isMounted, isFalse);

      // 2. mountIndicators 后进入 mounted 状态
      c.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: const [],
      );

      expect(c.lifecycleListenable.value, FlexiKlineLifecycle.mounted);
      expect(c.isMounted, isTrue);

      // 3. dispose 后进入 disposed 状态
      c.dispose();
      expect(c.lifecycleListenable.value, FlexiKlineLifecycle.disposed);
    });
  });
}
