import 'package:flutter/widgets.dart';

import 'binding_base.dart';

mixin SettingBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd("setting init");
  }

  Rect _mainRect = Rect.zero;
  Rect get mainRect => _mainRect;
  double get mainRectWidth => mainRect.width;
  double get mainRectHeight => mainRect.height;

  void setMainSize(Size size) {
    _mainRect = Rect.fromLTRB(
      0,
      0,
      size.width,
      size.height,
    );
  }
}
