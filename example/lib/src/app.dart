// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:easy_refresh/easy_refresh.dart';
import 'package:example/src/repo/polygon_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_ume_kit_perf_plus/flutter_ume_kit_perf_plus.dart';
import 'package:flutter_ume_kit_ui_plus/flutter_ume_kit_ui_plus.dart';
import 'package:flutter_ume_plus/flutter_ume_plus.dart';

import 'i18n.dart';
import 'providers/instruments_provider.dart';
import 'repo/okx_api.dart';
import 'router.dart';
import 'test/app_dio_inspector.dart';
import 'theme/export.dart';
import 'utils/device_util.dart';
// import 'widgets/no_thumb_scroll_behavior.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    configDefaultRefresher();
    if (kDebugMode) {
      PluginManager.instance
        ..register(AppDioInspector(
          key: const ValueKey('OKX'),
          dio: okxHttpClient.dio,
          showName: 'OKX',
        ))
        ..register(AppDioInspector(
          key: const ValueKey('Polygon'),
          dio: polygonHttpClient.dio,
          showName: 'Polygon',
        ))
        ..register(Performance())
        ..register(const MemoryInfoPage())
        ..register(const WidgetInfoInspector())
        ..register(const WidgetDetailInspector())
        ..register(const ColorSucker())
        ..register(AlignRuler())
        ..register(const ColorPicker()) // New feature
        ..register(const TouchIndicator());
    }
    ref.read(instrumentsMgrProvider.notifier).loadInstruments();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return UMEWidget(child: buildApp(context));
    } else {
      return buildApp(context);
    }
  }

  Widget buildApp(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, child) {
        return MaterialApp.router(
          restorationScopeId: 'flexiKlineApp',
          routerConfig: ref.watch(routerProvider),
          builder: FlutterSmartDialog.init(),
          debugShowCheckedModeBanner: false,
          locale: ref.watch(localProvider),
          localizationsDelegates: I18nManager().localizationsDelegates,
          supportedLocales: I18nManager().supportedLocales,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ref.watch(themeModeProvider),
          themeAnimationCurve: Curves.linear,
          themeAnimationDuration: const Duration(milliseconds: 500),
          // themeAnimationStyle: ActionDispatcher,
          // scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
        );
      },
    );
  }

  void configDefaultRefresher() {
    EasyRefresh.defaultHeaderBuilder = () {
      final theme = ref.watch(themeProvider);
      if (DeviceUtil.isTargetMobile) {
        return CupertinoHeader(
          foregroundColor: theme.t1,
          backgroundColor: theme.markBg,
        );
        // } else if (DeviceUtil.isIOS) {
        //   return MaterialHeader(
        //     color: theme.t1,
        //     backgroundColor: theme.markBg,
        //   );
      } else {
        return const ClassicHeader();
      }
    };
    EasyRefresh.defaultFooterBuilder = () {
      final theme = ref.watch(themeProvider);
      if (DeviceUtil.isTargetMobile) {
        return CupertinoFooter(
          emptyWidget: Text(
            'Protected By FlexiKline',
            style: theme.t2s12w400,
          ),
        );
        // } else if (DeviceUtil.isIOS) {
        //   return MaterialFooter(
        //     color: theme.t1,
        //     backgroundColor: theme.markBg,
        //   );
      } else {
        return const ClassicFooter();
      }
    };
  }
}
