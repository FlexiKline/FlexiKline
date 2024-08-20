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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

import 'pages/demo_accurate_kline_page.dart';
import 'pages/bit_kline_page.dart';
import 'pages/indicator_setting_page.dart';
import 'pages/kline_setting_page.dart';
import 'pages/landscape_kline_page.dart';
import 'pages/ok_kline_page.dart';
import 'pages/index_page.dart';
import 'pages/demo_kline_page.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'FlexiKlineApp',
);

extension StateExt on State {
  void exit<T extends Object?>([T? result]) {
    if (mounted) {
      context.pop(result);
    } else {
      GoRouter.of(globalNavigatorKey.currentContext!).pop(result);
    }
  }
}

extension GlobalKeyExt on GlobalKey<NavigatorState> {
  ProviderContainer get ref {
    final context = currentContext!;
    final ref = ProviderScope.containerOf(context);
    return ref;
  }
}

final routerProvider = Provider.autoDispose<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: globalNavigatorKey,
    observers: [
      FlutterSmartDialog.observer,
    ],
    initialLocation: '/ok',
    restorationScopeId: 'router',
    routes: routeList,
    debugLogDiagnostics: kDebugMode,
  );
  ref.onDispose(router.dispose);
  return router;
});

final List<RouteBase> routeList = <RouteBase>[
  StatefulShellRoute.indexedStack(
    restorationScopeId: 'index',
    pageBuilder: (
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    ) {
      return MaterialPage<void>(
        restorationId: 'indexPage',
        child: IndexPage(navigationShell: navigationShell),
      );
    },
    branches: <StatefulShellBranch>[
      // The route branch for the first tab of the bottom navigation bar.
      StatefulShellBranch(
        restorationScopeId: 'demo',
        routes: <RouteBase>[
          GoRoute(
            // The screen to display as the root in the first tab of the
            // bottom navigation bar.
            path: '/demo',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const MaterialPage<void>(
                restorationId: 'myDemo',
                child: MyKlineDemoPage(),
              );
            },
            routes: const <RouteBase>[],
          ),
        ],
      ),
      StatefulShellBranch(
        restorationScopeId: 'okKline',
        routes: <RouteBase>[
          GoRoute(
            path: '/ok',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const MaterialPage<void>(
                restorationId: 'okKline',
                child: OkKlinePage(),
              );
            },
            routes: const <RouteBase>[],
          ),
        ],
      ),
      StatefulShellBranch(
        restorationScopeId: 'bitKline',
        routes: <RouteBase>[
          GoRoute(
            path: '/bit',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const MaterialPage<void>(
                restorationId: 'bitKline',
                child: BitKlinePage(),
              );
            },
            routes: const <RouteBase>[],
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    name: 'landscapeKline',
    path: '/landscape_kline',
    pageBuilder: (context, state) {
      final param = state.extra as Map<String, dynamic>;
      return MaterialPage<void>(
        restorationId: 'bitKline',
        child: LandscapeKlinePage(
          configuration: param['configuration'],
          candleReq: param['candleReq'],
        ),
      );
    },
  ),
  GoRoute(
    name: 'accurateKline',
    path: '/accurate_kline',
    pageBuilder: (context, state) {
      return const MaterialPage<void>(
        restorationId: 'accurateKline',
        child: AccurateKlineDemoPage(),
      );
    },
  ),
  GoRoute(
    name: 'indicatorSetting',
    path: '/indicator_setting',
    pageBuilder: (context, state) {
      return const MaterialPage<void>(
        restorationId: 'indicatorSetting',
        child: IndicatorSettingPage(),
      );
    },
  ),
  GoRoute(
    name: 'klineSetting',
    path: '/kline_setting',
    pageBuilder: (context, state) {
      final controller = state.extra as FlexiKlineController;
      return MaterialPage<void>(
        restorationId: 'klineSetting',
        child: KlineSettingPage(
          controller: controller,
        ),
      );
    },
  ),
];
