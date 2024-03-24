import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'setting.dart';
import '../model/export.dart';

mixin CrossBinding on KlineBindingBase, SettingBinding {
  @override
  void initBinding() {
    super.initBinding();
    logd('init priceOrder');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose priceOrder');
  }

  void paintCross(Canvas canvas, Size size) {
    logd('paintCross');
  }

  @override
  bool handleTap(GestureData data) {
    logd('handleTap cross');
    return super.handleTap(data);
  }
}
