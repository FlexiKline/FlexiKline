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

// ignore_for_file: prefer_final_locals

/// Dart 异步机制探索演示：Future / scheduleMicrotask / Timer / FutureOr
///
/// 属于探索性测试，无业务断言，CI 可选择性跳过此目录。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Future 队列执行顺序演示', () {
    int val = 0;
    void microtask() {
      scheduleMicrotask(() {
        debugPrint('scheduleMicrotask:${val++}');
      });
    }

    Future.microtask(() => debugPrint('在 Microtask queue 里运行的 Future'));

    Future.delayed(
      const Duration(milliseconds: 100),
      () => debugPrint('延迟后在 Event queue 中运行的 Future'),
    );

    Future(() => debugPrint('立刻在 Event queue 中运行的 Future'));
    Future.sync(() => debugPrint('同步运行的 Future'));
    microtask();
    Timer.run(() => debugPrint('Timer.run'));
  });

  test('Future.doWhile 循环演示', () async {
    var value = 0;
    await Future.doWhile(() async {
      value++;
      await Future.delayed(const Duration(milliseconds: 10));
      if (value == 3) {
        debugPrint('Finished with $value');
        return false;
      }
      return true;
    });
    expect(value, 3);
  });

  test('Overlay JSON 序列化演示', () {
    final overlay = Overlay.fromType(
      key: 'BTCUSDT',
      type: const FlexiDrawType('aaa', 1),
      line: const LineConfig(),
    );
    final str = jsonEncode(overlay);
    debugPrint(str);
    expect(str, isNotEmpty);
  });

  group('is vs case 性能对比', () {
    test('is 模式', () {
      dynamic value = 0;
      final sw = Stopwatch()..start();
      for (var i = 0; i < 1000000; i++) {
        if (value is int) {
          value = value + 1;
        }
      }
      sw.stop();
      debugPrint('is: ${sw.elapsedMicroseconds} μs');
    });

    test('case 模式', () {
      dynamic value = 0;
      final sw = Stopwatch()..start();
      for (var i = 0; i < 1000000; i++) {
        if (value case int val) {
          value = val + 1;
        }
      }
      sw.stop();
      debugPrint('case: ${sw.elapsedMicroseconds} μs');
    });
  });
}
