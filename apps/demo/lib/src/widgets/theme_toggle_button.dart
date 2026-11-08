import 'package:flexi_kline/flexi_kline.dart' show FlexiKlineFunctionExt;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 主题切换按钮：图标反映当前实际主题亮度（含跟随系统），点击切换到相反主题。
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: '切换主题',
      icon: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      ),
      onPressed: toggleThemeMode.throttle(),
    );
  }
}
