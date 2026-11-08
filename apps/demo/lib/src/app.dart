import 'package:flutter/material.dart';

import 'presentation/index/index_page.dart';
import 'theme/app_theme.dart';
import 'utils/app_navigator.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'FlexiKline Demo',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [globalRouteObserver],
          themeMode: mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const IndexPage(),
        );
      },
    );
  }
}
