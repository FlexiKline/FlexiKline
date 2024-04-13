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

import 'package:example/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'setting_page.dart';

GlobalKey<ScaffoldState> mainNavScaffoldKey = GlobalKey();

class MainNavPage extends ConsumerWidget {
  const MainNavPage({
    super.key = const ValueKey<String>('MainNavPage'),
    required this.navigationShell,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Scaffold(
      key: mainNavScaffoldKey,
      drawer: const SettingDrawer(
        key: ValueKey("demo"),
      ),
      drawerEdgeDragWidth: 0.0, // 禁止通过滑动打开drawer
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.align_vertical_bottom),
            label: s.demo,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.view_comfy_alt),
            label: s.ko,
          ),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: (int tappedIndex) => navigationShell.goBranch(tappedIndex),
      ),
    );
  }
}
