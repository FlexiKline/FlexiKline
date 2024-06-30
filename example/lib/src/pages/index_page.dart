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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../constants/images.dart';
import '../theme/flexi_theme.dart';
import 'app_setting_page.dart';
import 'common/wide_screen_mixin.dart';

GlobalKey<ScaffoldState> mainNavScaffoldKey = GlobalKey();

class Destination {
  const Destination(this.icon, this.label);
  final IconData icon;
  final String label;
}

class IndexPage extends ConsumerStatefulWidget {
  const IndexPage({
    super.key = const ValueKey<String>('IndexPage'),
    required this.navigationShell,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _IndexPageState();
}

class _IndexPageState extends ConsumerState<IndexPage> with WideScreenMixin {
  List<Destination> get destinations => <Destination>[
        Destination(Icons.bar_chart_rounded, S.current.demo),
        Destination(Icons.view_comfy_alt_rounded, S.current.ok),
        Destination(Icons.pets_rounded, S.current.bit),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: mainNavScaffoldKey,
      drawer: const AppSettingDrawer(
        key: ValueKey("app_setting"),
      ),
      drawerEdgeDragWidth: 0.0, // 禁止通过滑动打开drawer
      body: Row(
        children: [
          buildLeftNavigationRail(context),
          Expanded(
            child: widget.navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }

  Widget? buildBottomNavigationBar(BuildContext context) {
    if (wideScreen) return null;
    final theme = ref.watch(themeProvider);
    // final s = S.of(context);
    return BottomNavigationBar(
      backgroundColor: theme.cardBg,
      selectedItemColor: theme.t1,
      unselectedItemColor: theme.t2,
      selectedLabelStyle: theme.t1s14w700,
      unselectedLabelStyle: theme.t2s14w400,
      items: destinations.map((d) {
        return BottomNavigationBarItem(
          icon: Icon(d.icon),
          label: d.label,
        );
      }).toList(),
      currentIndex: widget.navigationShell.currentIndex,
      onTap: widget.navigationShell.goBranch,
    );
  }

  Widget buildLeftNavigationRail(BuildContext context) {
    if (!wideScreen) return const SizedBox.shrink();
    final theme = ref.watch(themeProvider);
    return NavigationRail(
      backgroundColor: theme.cardBg,
      selectedIconTheme: theme.themeData.iconTheme.copyWith(color: theme.t1),
      unselectedIconTheme: theme.themeData.iconTheme.copyWith(color: theme.t2),
      selectedLabelTextStyle: theme.t1s14w700,
      unselectedLabelTextStyle: theme.t2s14w400,
      // leading: IconButton(
      //   onPressed: () {},
      //   icon: const Icon(Icons.menu),
      // ),
      leading: Container(
        padding: EdgeInsetsDirectional.all(8.r),
        margin: EdgeInsetsDirectional.only(bottom: 12.r),
        child: Image.asset(
          Images.logo,
          width: 30.r,
          height: 30.r,
        ),
      ),
      groupAlignment: -1.0,
      labelType: NavigationRailLabelType.all,
      selectedIndex: widget.navigationShell.currentIndex,
      onDestinationSelected: widget.navigationShell.goBranch,
      destinations: destinations.map((d) {
        return NavigationRailDestination(
          icon: Icon(d.icon),
          label: Text(d.label),
        );
      }).toList(),
    );
  }
}
