import 'package:flutter/material.dart';

/// 全局主题模式（Material 层与 K 线层共用），用 [ValueNotifier] 驱动。
/// 默认跟随系统，首次点击切换后脱离系统模式，此后在 light / dark 间切换。
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

/// 切换到相反的显式主题模式。
///
/// 处于 [ThemeMode.system] 时，按当前平台亮度切到相反的显式模式；
/// 后续仅在 light / dark 间切换（不再回到 system）。
void toggleThemeMode() {
  final effective = switch (appThemeMode.value) {
    ThemeMode.dark => Brightness.dark,
    ThemeMode.light => Brightness.light,
    ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };
  appThemeMode.value = effective == Brightness.light ? ThemeMode.dark : ThemeMode.light;
}

/// Material 层主题，提供 light / dark 两套 [ThemeData]。
abstract final class AppTheme {
  static ThemeData get light => _base(Brightness.light);

  static ThemeData get dark => _base(Brightness.dark);

  /// 品牌蓝, 也是配色的种子色。
  static const brandBlue = Color(0xFF1565C0);

  /// 选中态用的品牌蓝: 种子派生的 primary 偏灰, 与未选中的灰色难以区分; 深色模式提亮, 保证在深色底上可辨。
  static Color selectedOf(Brightness brightness) =>
      brightness == Brightness.light ? brandBlue : const Color(0xFF5C9DFF);

  /// 品牌蓝派生的配色, 画布等拿不到 [BuildContext] 的地方也用它, 与 Material 层一致。
  static ColorScheme schemeOf(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: brandBlue, brightness: brightness);

  static ThemeData _base(Brightness brightness) {
    return ThemeData(useMaterial3: true, colorScheme: schemeOf(brightness));
  }
}
