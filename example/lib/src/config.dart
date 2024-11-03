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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// 是否启用实时更新Kline数据.
bool realTimeUpdateKlineData = false;

class AppProviderObserver extends ProviderObserver {
  AppProviderObserver();

  @override
  Future<void> didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) async {
    if (kDebugMode) {
      // 如果未指定名字, 或名字以下划线开头, 不打印日志.
      if (provider.name == null || provider.name!.startsWith('_')) return;
      debugPrint('PROVIDER    : ${provider.name ?? '<NO NAME>'}\n'
          '  Type      : ${provider.runtimeType}\n'
          '  Old value : $previousValue\n'
          '  New value : $newValue');
    }
  }
}

final defLogger = Logger(
  filter: null, // Use the default LogFilter (-> only log in debug mode)
  printer: PrettyPrinter(
    methodCount: 0, // number of method calls to be displayed
    errorMethodCount: 2, // number of method calls if stacktrace is provided
    lineLength: 120, // width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    dateTimeFormat: DateTimeFormat.onlyTime,
    // printTime: true, // Should each log print contain a timestamp
  ),
  output: null, // Use the default LogOutput (-> send everything to console)
);

class LoggerImpl implements ILogger {
  final String? tag;
  bool debug;
  final Logger logger;

  LoggerImpl({
    this.tag,
    this.debug = false,
    Logger? logger,
  }) : logger = logger ?? defLogger;

  @override
  String? get logTag => tag;

  @override
  bool get isDebug => debug;

  @override
  void logd(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.d(msg, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void logi(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.i(msg, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void logw(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.w(msg, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void loge(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.e(msg, time: time, error: error, stackTrace: stackTrace);
  }
}

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
    debugPrint("zp:::Debug $logTag\t$msg");
  }

  @override
  void logi(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint("zp:::Info $logTag\t$msg");
  }

  @override
  void logw(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint("zp:::Warn $logTag\t$msg");
  }

  @override
  void loge(
    String msg, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint("zp:::Error $logTag\t$msg");
  }
}
