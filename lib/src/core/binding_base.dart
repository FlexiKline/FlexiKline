import 'package:flutter/foundation.dart';

import '../utils/log.dart';

abstract class KlineBindingBase with KlineLog {
  @override
  String get logTag => "klineBinding";

  KlineBindingBase() {
    logd("constrouct");
    initBinding();
  }

  @protected
  @mustCallSuper
  void initBinding() {
    logd("base init");
  }

  @protected
  static T checkInstance<T extends KlineBindingBase>(T? instance) {
    return instance!;
  }
}
