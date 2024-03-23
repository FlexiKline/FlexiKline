import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'setting.dart';

mixin ConfigBinding on KlineBindingBase, SettingBinding {
  @override
  void initBinding() {
    super.initBinding();
    logd("init config");
  }

  @override
  void dispose() {
    super.dispose();
    logd("dispose config");
  }
}
