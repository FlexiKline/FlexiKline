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

import 'package:flexi_kline/src/framework/logger.dart';
import 'package:flutter/foundation.dart';

class LogPrintImpl implements ILogger {
  final String? tag;
  bool debug;

  LogPrintImpl({
    this.tag,
    this.debug = false,
  });
  @override
  bool get isDebug => debug;

  @override
  String? get logTag => tag;

  @override
  void logd(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('zp:::Debug $logTag\t$msg');
  }

  @override
  void logi(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('zp:::Info $logTag\t$msg');
  }

  @override
  void logw(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('zp:::Warn $logTag\t$msg');
  }

  @override
  void loge(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('zp:::Error $logTag\t$msg');
  }
}
