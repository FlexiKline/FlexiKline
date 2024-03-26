import 'package:flutter/foundation.dart';

mixin KlineLog {
  String get logTag => 'Kline';
  bool get isDebug => false;
  

  void logd(String msg) {
    if (isDebug) debugPrint("zp::: DEBUG $logTag\t$msg");
  }

  void logi(String msg) {
    if (isDebug) debugPrint("zp::: INFO $logTag\t$msg");
  }

  void logw(String msg) {
    if (isDebug) debugPrint("zp::: WARN $logTag\t$msg");
  }

  void loge(String msg) {
    if (isDebug) debugPrint("zp::: ERROR $logTag\t$msg");
  }
}
