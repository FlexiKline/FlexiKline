import 'core/export.dart';

class KlineController extends KlineBindingBase
    with
        SettingBinding,
        ConfigBinding,
        DataSourceBinding,
        GestureBinding,
        GridBgBinding,
        CandleBinding,
        PriceCrossBinding,
        DrawBinding {
  KlineController({
    super.debug,
  });
}
