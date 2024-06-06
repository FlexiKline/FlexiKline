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

import 'dart:async';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Runable<T> = FutureOr<T> Function();

void main() {
  int val = 0;
  void microtask() {
    scheduleMicrotask(() {
      print('scheduleMicrotask:${val++}');
    });
  }

  test('test future', () async {
    final stopwatch = Stopwatch();
    for (var element in [1, 2, 3, 4]) {
      microtask();
      await stopwatch.runAsync(
        () => debugPrint('$element'),
      );
      microtask();
    }
  });

  test('test futureOr', () async {
    Future<T> logValue<T>(FutureOr<T> value) async {
      if (value is Future<T>) {
        microtask();
        var result = await value;
        print(result);
        microtask();
        return result;
      } else {
        microtask();
        print(value);
        microtask();
        return value;
      }
    }

    microtask();
    await logValue(Future(()=>{}));
    microtask();
  });

  test('test  base', () {
    Future.microtask(() => print('在Microtask queue里运行的Future'));

    Future.delayed(
      const Duration(seconds: 1),
      () => print('1秒后在Event queue中运行的Future'),
    );

    Future(() => print('立刻在Event queue中运行的Future'));

    Future.sync(() => print('同步运行的Future'));

    scheduleMicrotask(() {
      print('scheduleMicrotask');
    });

    Timer.run(() {
      print('Timer.run');
    });
  });

  test('future dowhile', () async {
    var value = 0;
    await Future.doWhile(() async {
      value++;
      await Future.delayed(const Duration(seconds: 1));
      if (value == 3) {
        print('Finished with $value');
        return false;
      }
      return true;
    });
  });
}
