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

import 'package:flutter/foundation.dart';

abstract interface class ILogger {
  void logd(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  });
  void logi(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  });
  void logw(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  });
  void loge(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  });
}

mixin KlineLog implements ILogger {
  String get logTag => 'Kline';
  bool get isDebug => false;

  ILogger? logger;

  @override
  void logd(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (isDebug) {
      if (logger != null) {
        logger?.logd(msg, time: time, error: error, stackTrace: stackTrace);
      } else {
        debugPrint("zp::: DEBUG $logTag\t$msg");
      }
    }
  }

  @override
  void logi(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (isDebug) {
      if (logger != null) {
        logger?.logi(msg, time: time, error: error, stackTrace: stackTrace);
      } else {
        debugPrint("zp::: INFO $logTag\t$msg");
      }
    }
  }

  @override
  void logw(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (isDebug) {
      if (logger != null) {
        logger?.logw(msg, time: time, error: error, stackTrace: stackTrace);
      } else {
        debugPrint("zp::: WARN $logTag\t$msg");
      }
    }
  }

  @override
  void loge(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (isDebug) {
      if (logger != null) {
        logger?.loge(msg, time: time, error: error, stackTrace: stackTrace);
      } else {
        debugPrint("zp::: ERROR $logTag\t$msg");
      }
    }
  }
}
