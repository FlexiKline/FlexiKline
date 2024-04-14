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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/ko_kliine_page.dart';
import 'pages/main_nav_page.dart';
import 'pages/my_demo_page.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'myApp',
);

extension GlobalKeyExt on GlobalKey<NavigatorState> {
  ProviderContainer get ref {
    final context = currentContext!;
    final ref = ProviderScope.containerOf(context);
    return ref;
  }
}

final List<RouteBase> routeList = <RouteBase>[
  StatefulShellRoute.indexedStack(
    restorationScopeId: 'index',
    pageBuilder: (
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    ) {
      return MaterialPage<void>(
        restorationId: 'nav',
        child: MainNavPage(navigationShell: navigationShell),
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
                restorationId: 'mydemo',
                child: MyDemoPage(),
              );
            },
            routes: <RouteBase>[],
          ),
        ],
      ),
      // The route branch for the second tab of the bottom navigation bar.
      StatefulShellBranch(
        restorationScopeId: 'kokline',
        routes: <RouteBase>[
          GoRoute(
            // The screen to display as the root in the second tab of the
            // bottom navigation bar.
            path: '/ko',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return const MaterialPage<void>(
                restorationId: 'kokline',
                child: KOKlinePage(),
              );
            },
            routes: <RouteBase>[],
          ),
        ],
      ),
    ],
  ),
];