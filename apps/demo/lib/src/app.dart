import 'package:flutter/material.dart';

import 'pages/index/index_page.dart';
import 'route/route_observer.dart';
import 'theme/my_app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: myAppThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'FlexiKline Demo',
          debugShowCheckedModeBanner: false,
          navigatorObservers: [globalRouteObserver],
          themeMode: mode,
          theme: MyAppTheme.light,
          darkTheme: MyAppTheme.dark,
          home: const IndexPage(),
        );
      },
    );
  }
}
