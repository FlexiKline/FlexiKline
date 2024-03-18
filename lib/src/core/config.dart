import 'package:flutter/material.dart';

import 'binding_base.dart';

mixin ConfigBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd("config init");
  }

  Color background = Colors.red;

  void updateBackground() {
    logd("config updateBackground");
  }
}
