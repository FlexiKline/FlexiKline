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

/// 日志级别
enum FlexiLogLevel { debug, info, warn, error }

/// 外部日志适配接口
///
/// 用户实现此接口，将 FlexiKline 日志接入自己的日志库（如 logger、talker 等）。
/// 无需关心 tag 的来源，tag 由内部 [FlexiLog] 自动提供。
abstract interface class IFlexiLogger {
  /// 是否是调试模式
  bool get debugMode;

  /// 输出一条日志
  void log(
    FlexiLogLevel level,
    String tag,
    String msg, {
    Object? error,
    StackTrace? stackTrace,
  });
}

/// 外部日志适配器扩展方法
/// 提供日志输出能力，用于外部日志方便调用。
extension FlexiLoggerExt on IFlexiLogger {
  void logd(String tag, String msg, {Object? error, StackTrace? stackTrace}) {
    log(FlexiLogLevel.debug, tag, msg, error: error, stackTrace: stackTrace);
  }

  void logi(String tag, String msg, {Object? error, StackTrace? stackTrace}) {
    log(FlexiLogLevel.info, tag, msg, error: error, stackTrace: stackTrace);
  }

  void logw(String tag, String msg, {Object? error, StackTrace? stackTrace}) {
    log(FlexiLogLevel.warn, tag, msg, error: error, stackTrace: stackTrace);
  }

  void loge(String tag, String msg, {Object? error, StackTrace? stackTrace}) {
    log(FlexiLogLevel.error, tag, msg, error: error, stackTrace: stackTrace);
  }
}

/// 内部日志能力接口
/// 提供日志输出能力，用于在内部打印日志。
abstract interface class ILogger {
  bool get isDebug;

  void logd(String msg, {Object? error, StackTrace? stackTrace});
  void logi(String msg, {Object? error, StackTrace? stackTrace});
  void logw(String msg, {Object? error, StackTrace? stackTrace});
  void loge(String msg, {Object? error, StackTrace? stackTrace});
}

/// 内部日志 mixin
/// 内部类通过 `with FlexiLog` 获得日志能力。
/// - [logTag]：子类覆盖以提供类名标签，默认 `'FlexiKline'`。
/// - [logger]：外部日志适配器，由上层构造时注入，为 null 时退化为 [debugPrint]。
mixin FlexiLog implements ILogger {
  /// 日志标签，子类可覆盖
  String get logTag => 'FlexiKline';

  /// 外部日志适配器，由上层构造时注入
  IFlexiLogger? logger;

  @override
  bool get isDebug => logger?.debugMode ?? kDebugMode;

  @override
  void logd(String msg, {Object? error, StackTrace? stackTrace}) {
    _klineLogOutput(FlexiLogLevel.debug, msg, error: error, stackTrace: stackTrace);
  }

  @override
  void logi(String msg, {Object? error, StackTrace? stackTrace}) {
    _klineLogOutput(FlexiLogLevel.info, msg, error: error, stackTrace: stackTrace);
  }

  @override
  void logw(String msg, {Object? error, StackTrace? stackTrace}) {
    _klineLogOutput(FlexiLogLevel.warn, msg, error: error, stackTrace: stackTrace);
  }

  @override
  void loge(String msg, {Object? error, StackTrace? stackTrace}) {
    _klineLogOutput(FlexiLogLevel.error, msg, error: error, stackTrace: stackTrace);
  }

  void _klineLogOutput(
    FlexiLogLevel level,
    String msg, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!isDebug) return;
    if (logger != null) {
      logger!.log(level, logTag, msg, error: error, stackTrace: stackTrace);
    } else {
      final levelName = level.name.toUpperCase();
      debugPrint('[$levelName][$logTag] $msg');
      if (error != null || stackTrace != null) {
        final errLabel = error != null ? ' error:${error.toString()}' : '';
        debugPrintStack(
          stackTrace: stackTrace,
          label: '[$levelName] [$logTag]$errLabel',
        );
      }
    }
  }
}
