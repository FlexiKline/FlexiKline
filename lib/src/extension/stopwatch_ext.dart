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

import 'package:flutter/foundation.dart';

typedef LogPrint = void Function(String message);

class FlexiStopwatch extends Stopwatch {
  FlexiStopwatch() : super();

  int? _spentTicks;

  @override
  void start() {
    if (!isRunning) _spentTicks = null;
    super.start();
  }

  @override
  void stop() {
    super.stop();
    _spentTicks = null;
  }

  void lap() {
    _spentTicks = elapsedTicks;
  }

  @override
  void reset() {
    super.reset();
    _spentTicks = null;
  }

  int get spentTicks => elapsedTicks - (_spentTicks ?? 0);

  int get spentMicroseconds => spentTicks * 1e6 ~/ frequency;

  int get spentMilliseconds => spentMicroseconds ~/ 1000;

  Duration get spent {
    return Duration(microseconds: spentMicroseconds);
  }

  /// 同步运行[computation]任务, 并打印耗时.
  T run<T>(
    T Function() computation, {
    String label = '',
    LogPrint? logger,
  }) {
    lap();
    final result = computation();
    (logger ?? debugPrint).call('Run:::\t$label\tspent:$spentMicrosecondsμs');
    return result;
  }

  /// 运行[task]任务, 并打印耗时.
  Future<T> exec<T>(
    FutureOr<T> Function() task, {
    String label = '',
    LogPrint? logger,
  }) async {
    lap();
    final result = await Future(() => task());
    (logger ?? debugPrint).call('Exec:::\t$label\tspent:$spentMicrosecondsμs');
    return result;
  }
}
