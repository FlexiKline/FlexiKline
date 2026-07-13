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

/// 集成测试：isMounted 守卫
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  group('v2.2.0/FlexiKlineController/mounted_guard', () {
    test('mount 前调用受守卫 API 不抛异常', () {
      final c = FlexiKlineController(
        configuration: FakeFlexiKlineConfiguration(),
      );
      addTearDown(c.dispose);

      expect(c.isMounted, isFalse);

      // onThemeChanged 含 isMounted 守卫
      expect(() => c.onThemeChanged(), returnsNormally);

      // requestMoveToInitialPosition、moveToDateTime 含 isMounted 守卫
      expect(() => c.requestMoveToInitialPosition(), returnsNormally);
      expect(c.moveToDateTime(DateTime.utc(2026, 7, 10)), isFalse);
    });
  });
}
