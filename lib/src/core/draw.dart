import 'package:kline/src/model/gesture.dart';

import 'binding_base.dart';

///
/// 绘制工具
///
mixin DrawBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd('init draw');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
  }

  @override
  bool handleTap(GestureData data) {
    logd('handleTap draw');
    return super.handleTap(data);
  }
}
