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
import 'package:flutter/scheduler.dart';

import '../framework/logger.dart';

extension StopwatchExt on Stopwatch {
  /// 同步运行[runable]任务, 并打印耗时.
  T run<T>(
    ValueGetter runable, {
    String debugLabel = 'runable',
    ILogger? logger,
  }) {
    reset();
    start();
    final result = runable();
    stop();
    debugPrint('WatchRun:::\t$debugLabel\tspent:$elapsedMicrosecondsμs');
    return result;
  }

  /// 异常运行[computation]任务, 并打印耗时.
  Future<T> runAsync<T>(
    TaskCallback<T> computation, {
    String debugLabel = 'compute',
  }) async {
    reset();
    start();
    final result = await Future(() => computation());
    stop();
    debugPrint('WatchRunAsync:::\t$debugLabel\tspent:$elapsedMicrosecondsμs');
    return result;
  }
}
