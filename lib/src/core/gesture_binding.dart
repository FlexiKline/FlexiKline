import 'binding_base.dart';

mixin GestureBinding on KlineBindingBase {
  @override
  String get logTag => "GestureBinding";
  @override
  void initInstances() {
    super.initInstances();
    logd('initInstances');
  }
}
