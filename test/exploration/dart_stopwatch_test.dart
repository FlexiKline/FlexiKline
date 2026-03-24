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

/// Dart 标准库 Stopwatch 基础行为演示。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Stopwatch 基础行为', () async {
    final stopwatch = Stopwatch();

    stopwatch.start();
    expect(stopwatch.isRunning, isTrue);

    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('elapsed:${stopwatch.elapsedMicroseconds}μs');

    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('elapsed:${stopwatch.elapsedMicroseconds}μs');

    stopwatch.stop();
    expect(stopwatch.isRunning, isFalse);
    // 停止后累计时间应 >= 300ms
    expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(300));
  });
}
