import 'core/export.dart';

class KlineController extends KlineBindingBase
    with
        SettingBinding,
        ConfigBinding,
        StateBinding,
        GestureBinding,
        GridBinding,
        CandleBinding,
        CrossBinding,
        DrawBinding {
  KlineController({
    super.debug,
  });
}
