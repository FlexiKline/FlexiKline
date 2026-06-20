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

/// 属性测试：自定义 Direct 指标 (D1)
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('v2.2.0/IndicatorPaintObjectManager/direct', () {
    test('D1: 自定义 Direct 进 registry、不占 slot、可激活', () {
      final ctx = FakePaintContext();
      final m = IndicatorPaintObjectManager(
        configuration: FakeFlexiKlineConfiguration(),
      );
      m.mountIndicators(
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: [TestDirectIndicator(key: directKey(1))],
        subIndicators: const [],
        context: ctx,
      );

      // 不占 computed slot
      expect(m.computedDataCount, 0);
      // 已注册
      expect(m.hasRegisteredInMain(directKey(1)), isTrue);
      // 激活后进入主区绘制队列
      m.addMainPaintObject(directKey(1), ctx);
      expect(directKey(1), isActivatedInMain(m));
    });
  });
}
