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

import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flexi_formatter/flexi_formatter.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart' hide Overlay;
import 'package:flutter_test/flutter_test.dart';

typedef Runable<T> = FutureOr<T> Function();

void main() {
  int val = 0;
  void microtask() {
    scheduleMicrotask(() {
      debugPrint('scheduleMicrotask:${val++}');
    });
  }

  test('sign rsi', () {
    Decimal hundred = Decimal.fromInt(100);
    Decimal sumUp = Decimal.fromJson('14.9');
    Decimal sumDown = Decimal.fromJson('15.4');
    Decimal ret = sumUp.div((sumUp + sumDown)) * hundred;

    debugPrint(ret.toString());

    Decimal ret2 = sumUp.divNum(9).div(sumUp.divNum(9) + sumDown.divNum(9)) * hundred;

    debugPrint(ret2.toString());
  });

  test('math ', () {
    debugPrint('math.log(0) ${math.log(0)}');
    debugPrint('math.log(0.1) ${math.log(0.1)}');
    debugPrint('math.log(0.9) ${math.log(0.9)}');
    debugPrint('math.log(1) ${math.log(1)}');
    debugPrint('math.log(1.1) ${math.log(1.1)}');
    debugPrint('math.log(2) ${math.log(2)}');
    debugPrint('math.log(2000) ${math.log(2000)}');
    debugPrint('math.log(-1) ${math.log(-1)}');
    debugPrint('math.log(-2) ${math.log(-2)}');
  });

  test('math log2', () {
    for (double i = 0.1; i < 2.5; i += 0.02) {
      final x = double.parse(i.toStringAsFixed(2));
      double scaleFactor = math.log(x); // 使用自然对数函数调整缩放速度
      debugPrint('math.log(${i.toStringAsFixed(2)}) \t $scaleFactor');
    }
  });

  test('test futureOr', () async {
    Future<T> logValue<T>(FutureOr<T> value) async {
      if (value is Future<T>) {
        microtask();
        var result = await value;
        debugPrint('$result');
        microtask();
        return result;
      } else {
        microtask();
        debugPrint('$value');
        microtask();
        return value;
      }
    }

    microtask();
    await logValue(Future(() => {}));
    microtask();
  });

  test('test  base', () {
    Future.microtask(() => debugPrint('在Microtask queue里运行的Future'));

    Future.delayed(
      const Duration(seconds: 1),
      () => debugPrint('1秒后在Event queue中运行的Future'),
    );

    Future(() => debugPrint('立刻在Event queue中运行的Future'));

    Future.sync(() => debugPrint('同步运行的Future'));

    scheduleMicrotask(() {
      debugPrint('scheduleMicrotask');
    });

    Timer.run(() {
      debugPrint('Timer.run');
    });
  });

  test('future dowhile', () async {
    var value = 0;
    await Future.doWhile(() async {
      value++;
      await Future.delayed(const Duration(seconds: 1));
      if (value == 3) {
        debugPrint('Finished with $value');
        return false;
      }
      return true;
    });
  });

  test('Test Overlay', () async {
    final overlay = Overlay.fromType(
      key: 'BTCUSDT',
      type: FlexiDrawType('aaa', 1),
      line: LineConfig(),
    );

    final str = jsonEncode(overlay);

    debugPrint(str);
  });

  group('test is vs case', () {
    final stopwatch = Stopwatch();
    dynamic value = 0;
    setUp(() {
      value = 0;
      stopwatch.reset();
    });

    test('test is', () {
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 10000000; i++) {
        if (value is int) {
          value = value + 1;
        }
      }
      stopwatch.stop();
      debugPrint('is:  ${stopwatch.elapsedMicroseconds} μs');
    });

    test('test case', () {
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 10000000; i++) {
        if (value case int val) {
          value = val + 1;
        }
      }
      stopwatch.stop();
      debugPrint('case:  ${stopwatch.elapsedMicroseconds} μs');
    });
  });
}
