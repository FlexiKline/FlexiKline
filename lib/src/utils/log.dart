import 'package:flutter/foundation.dart';

mixin KlineLog {
  String get logTag => 'Kline';

  void logd(String msg) {
    debugPrint("zp::: $logTag\t>>>$msg");
  }
}
