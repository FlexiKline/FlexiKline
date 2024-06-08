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

import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:example/src/providers/instruments_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_ume_kit_dio_plus/flutter_ume_kit_dio_plus.dart';
import 'package:flutter_ume_kit_perf_plus/flutter_ume_kit_perf_plus.dart';
import 'package:flutter_ume_kit_ui_plus/flutter_ume_kit_ui_plus.dart';
import 'package:flutter_ume_plus/flutter_ume_plus.dart';

import 'i18n.dart';
import 'repo/http_client.dart';
import 'router.dart';
import 'theme/export.dart';

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
        ..register(DioInspector(dio: httpClient.dio))
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
        );
      },
    );
  }

  void configDefaultRefresher() {
    final theme = ref.read(themeProvider);
    Header header;
    if (Platform.isIOS) {
      header = CupertinoHeader(
        foregroundColor: theme.brand,
        backgroundColor: theme.cardBg,
      );
    } else {
      header = MaterialHeader(
        color: theme.brand,
        backgroundColor: theme.cardBg,
      );
    }
    EasyRefresh.defaultHeaderBuilder = () => header;
    EasyRefresh.defaultFooterBuilder = () => CupertinoFooter(
          emptyWidget: Text(
            'Protected By FlexiKline',
            style: theme.t2s12w400,
          ),
        );
  }
}
