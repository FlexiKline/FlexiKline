import 'binding_base.dart';

mixin ConfigBinding on KlineBindingBase {
  @override
  void initBinding() {
    super.initBinding();
    logd("config init");
  }
}
