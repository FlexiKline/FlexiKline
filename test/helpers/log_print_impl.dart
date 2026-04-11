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

class LogPrintImpl implements IFlexiLogger {
  LogPrintImpl({
    required this.logTag,
    this.debugMode = kDebugMode,
  });

  final String logTag;

  @override
  final bool debugMode;

  @override
  void log(
    FlexiLogLevel level,
    String tag,
    String msg, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final levelStr = switch (level) {
      FlexiLogLevel.debug => 'Debug',
      FlexiLogLevel.info => 'Info',
      FlexiLogLevel.warn => 'Warn',
      FlexiLogLevel.error => 'Error',
    };
    debugPrint('[$levelStr] [$logTag] [$tag] $msg');
    if (error != null || stackTrace != null) {
      final errLabel = error != null ? ' error:${error.toString()}' : '';
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[$levelStr] [$logTag] [$tag]$errLabel',
      );
    }
  }
}
