import 'package:flutter/foundation.dart';

import '../utils/log.dart';
import 'interface.dart';

abstract class KlineBindingBase with KlineLog, TapHanderImpl {
  @override
  String get logTag => "klineBinding";

  KlineBindingBase() {
    logd("constrouct");
    initBinding();
  }

  @protected
  @mustCallSuper
  void initBinding() {
    logd("init base");
  }

  @protected
  @mustCallSuper
  void dispose() {
    logd("dispose base");
  }

  @protected
  static T checkInstance<T extends KlineBindingBase>(T? instance) {
    return instance!;
  }
}
