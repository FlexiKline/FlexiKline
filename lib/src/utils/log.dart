import 'package:flutter/foundation.dart';

mixin KlineLog {
  String get logTag => 'Kline';

  void logd(String msg) {
    debugPrint("zp::: DEBUG $logTag\t>>>$msg");
  }

  void logi(String msg) {
    debugPrint("zp::: INFO $logTag\t>>>$msg");
  }

  void logw(String msg) {
    debugPrint("zp::: WARN $logTag\t>>>$msg");
  }

  void loge(String msg) {
    debugPrint("zp::: ERROR $logTag\t>>>$msg");
  }
}
