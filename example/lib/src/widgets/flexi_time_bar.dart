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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/export.dart';

typedef TimeBarItemBuilder = Widget Function(BuildContext, TimeBar);

class FlexiTimeBar extends ConsumerStatefulWidget {
  const FlexiTimeBar({
    super.key,
    required this.controller,
    required this.onTapTimeBar,
    this.alignment,
    this.decoration,
  });

  final FlexiKlineController controller;
  final ValueChanged<TimeBar> onTapTimeBar;

  final AlignmentGeometry? alignment;
  final Decoration? decoration;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FlexiTimeBarState();
}

class _FlexiTimeBarState extends ConsumerState<FlexiTimeBar>
    with TickerProviderStateMixin {
  final List<TimeBar> timeBarList = [
    TimeBar.m15,
    TimeBar.H1,
    TimeBar.H4,
    TimeBar.D1,
  ];

  bool get isScrollTabBar => timeBarList.length > 4;

  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: timeBarList.length, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void onTapIndicatorSetting() {
    final preTimeBar = timeBarList.getItem(tabController.index);
    timeBarList.add(TimeBar.D2);
    tabController.dispose();
    int index = 0;
    if (preTimeBar != null) {
      final val = timeBarList.indexOf(preTimeBar);
      if (val >= 0) index = val;
    }
    tabController = TabController(
      initialIndex: index,
      length: timeBarList.length,
      vsync: this,
    );
    setState(() {});
  }

  void onTabKlineSetting() {}

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeProvider);
    return Container(
      alignment: widget.alignment ?? AlignmentDirectional.centerStart,
      padding: EdgeInsetsDirectional.only(start: 6.r, end: 16.r),
      decoration: widget.decoration,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: TabBar(
              controller: tabController,
              isScrollable: isScrollTabBar,
              tabAlignment: isScrollTabBar ? TabAlignment.start : null,
              physics: const BouncingScrollPhysics(),
              labelPadding: EdgeInsetsDirectional.symmetric(horizontal: 4.r),
              labelColor: theme.t1,
              unselectedLabelColor: theme.t2,
              labelStyle: theme.t1s14w700.copyWith(height: 2),
              unselectedLabelStyle: theme.t2s14w400.copyWith(height: 2),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(5.r),
                color: theme.markBg,
              ),
              splashBorderRadius: BorderRadius.circular(5.r),
              onTap: (index) {
                final timeBar = timeBarList.getItem(index);
                if (timeBar != null) widget.onTapTimeBar(timeBar);
              },
              tabs: timeBarList.map((bar) {
                return Tab(
                  height: 28.r,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 28.r),
                    alignment: AlignmentDirectional.center,
                    margin: EdgeInsetsDirectional.symmetric(horizontal: 8.r),
                    child: Text(bar.bar),
                  ),
                );
              }).toList(),
            ),
          ),
          TextButton(
            onPressed: onTapIndicatorSetting,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '指标',
                  style: theme.t1s14w500,
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.t1,
                )
              ],
            ),
          ),
          IconButton(
            onPressed: onTabKlineSetting,
            icon: Icon(
              Icons.settings_rounded,
              color: theme.t1,
              size: 18.r,
            ),
          )
        ],
      ),
    );
  }
}
