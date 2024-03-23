import 'binding_base.dart';

mixin GestureBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd('init gesture');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose gesture');
  }
}
