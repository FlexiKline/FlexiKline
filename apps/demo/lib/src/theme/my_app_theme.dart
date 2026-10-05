import 'package:flutter/material.dart';

/// 全局主题模式（Material 层与 K 线层共用），用 [ValueNotifier] 驱动。
/// 默认跟随系统，首次点击切换后脱离系统模式，此后在 light / dark 间切换。
final ValueNotifier<ThemeMode> myAppThemeMode = ValueNotifier(ThemeMode.system);

/// 切换到相反的显式主题模式。
///
/// 处于 [ThemeMode.system] 时，按当前平台亮度切到相反的显式模式；
/// 后续仅在 light / dark 间切换（不再回到 system）。
void toggleThemeMode() {
  final effective = switch (myAppThemeMode.value) {
    ThemeMode.dark => Brightness.dark,
    ThemeMode.light => Brightness.light,
    ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };
  myAppThemeMode.value = effective == Brightness.light ? ThemeMode.dark : ThemeMode.light;
}

/// Material 层主题，提供 light / dark 两套 [ThemeData]。
abstract final class MyAppTheme {
  static ThemeData get light => _base(Brightness.light);

  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        brightness: brightness,
      ),
    );
  }
}
