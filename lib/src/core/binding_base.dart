import 'package:flutter/foundation.dart';

import '../utils/log.dart';

abstract class KlineBindingBase with KlineLog {
  @override
  String get logTag => "BindingBase";

  KlineBindingBase() {
    logd("constrouct");
    initInstances();
  }

  @protected
  @mustCallSuper
  void initInstances() {
    logd("initInstances");
  }

  @protected
  static T checkInstance<T extends KlineBindingBase>(T? instance) {
    return instance!;
  }
}
