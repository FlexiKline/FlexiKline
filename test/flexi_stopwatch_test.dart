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

import 'base/log_print_impl.dart';

void main() {
  test('test Stopwatch', () async {
    final stopwatch = Stopwatch();

    stopwatch.start();
    expect(stopwatch.isRunning, true);

    await Future.delayed(Duration(milliseconds: 100));
    debugPrint('elapsed:${stopwatch.elapsedMicroseconds}μs');

    await Future.delayed(Duration(milliseconds: 200));
    debugPrint('elapsed:${stopwatch.elapsedMicroseconds}μs');

    stopwatch.stop();
    debugPrint('elapsed:${stopwatch.elapsedMicroseconds}μs');
    expect(stopwatch.isRunning, false);
  });

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

    test("test FlexiStopwatch", () async {
      stopwatch.lap();
      await Future.delayed(Duration(milliseconds: 100));
      debugPrint('spnet:${stopwatch.spentMicroseconds}μs');

      expect(stopwatch.isRunning, true);

      stopwatch.lap();
      await Future.delayed(Duration(milliseconds: 200));
      debugPrint('spnet:${stopwatch.spentMicroseconds}μs');
    });

    test('test FlexiStopwatch run', () {
      stopwatch
        ..reset()
        ..start();

      stopwatch.run(
        () {
          for (int i = 0; i < 1000000; i++) {
            // do something
          }
        },
        label: 'sync',
        logger: defaultLogger.logd,
      );
      expect(stopwatch.isRunning, true);
      debugPrint('runSync end');
    });

    test('test FlexiStopwatch runAsync', () async {
      await stopwatch.exec(
        () => Future.delayed(Duration(milliseconds: 1000)),
        label: 'async',
        logger: defaultLogger.logd,
      );
      expect(stopwatch.isRunning, true);
      debugPrint('runAsync end');
    });
  });
}
