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
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/log_print_impl.dart';

void main() {
  group('FlexiStopwatch', () {
    final ILogger defaultLogger = LogPrintImpl(tag: 'FlexiStopwatch');
    final FlexiStopwatch stopwatch = FlexiStopwatch();

    setUp(() {
      stopwatch
        ..reset()
        ..start();
    });
    tearDown(() {
      stopwatch.stop();
    });

    test('lap / spentMicroseconds', () async {
      stopwatch.lap();
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('spent:${stopwatch.spentMicroseconds}μs');

      expect(stopwatch.isRunning, isTrue);

      stopwatch.lap();
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('spent:${stopwatch.spentMicroseconds}μs');
    });

    test('run 同步：运行后秒表仍在计时', () {
      stopwatch.run(
        () {
          for (int i = 0; i < 100000; i++) {}
        },
        label: 'sync',
        logger: defaultLogger.logd,
      );
      expect(stopwatch.isRunning, isTrue);
    });

    test('exec 异步：执行后秒表仍在计时', () async {
      await stopwatch.exec(
        () => Future.delayed(const Duration(milliseconds: 50)),
        label: 'async',
        logger: defaultLogger.logd,
      );
      expect(stopwatch.isRunning, isTrue);
    });
  });
}
