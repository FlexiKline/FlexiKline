import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';

/// 统一 [IFlexiLogger] 实现，供需要把日志传给 [FlexiKlineController] 的类混入。
mixin MyKlineLoggerMixin implements IFlexiLogger {
  @override
  bool get debugMode => kDebugMode;

  String get logTag => 'MyKline';

  @override
  void log(
    FlexiLogLevel level,
    String tag,
    String msg, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!debugMode) return;
    debugPrint('[${level.name.toUpperCase()}][$logTag][$tag] $msg');
    if (error != null) debugPrint('  error: $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }
}
