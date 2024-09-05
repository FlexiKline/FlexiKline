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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../dialogs/indicators_select_dialog.dart';
import '../../dialogs/kline_settting_dialog.dart';
import '../../dialogs/timebar_select_dialog.dart';
import '../../theme/export.dart';
import '../../utils/dialog_manager.dart';
import '../../widgets/no_thumb_scroll_behavior.dart';
import '../../widgets/shrink_icon_button.dart';
import '../../widgets/text_arrow_button.dart';
import '../common/wide_screen_mixin.dart';
import 'flexi_kline_draw_menubar.dart';

class FlexiKlineSettingBar extends ConsumerStatefulWidget {
  const FlexiKlineSettingBar({
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
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FlexiKlineSettingBarState();
}

class _FlexiKlineSettingBarState extends ConsumerState<FlexiKlineSettingBar>
    with WideScreenMixin {
  bool _showDarwTool = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    timeBarSettingBtnStatus.dispose();
    indicatorSettingBtnStatus.dispose();
    super.dispose();
  }

  List<TimeBar> preferTimeBarList = [
    TimeBar.m15,
    TimeBar.H1,
    TimeBar.H4,
    TimeBar.D1,
    TimeBar.W1,
  ];

  bool isPreferTimeBar(TimeBar bar) => preferTimeBarList.contains(bar);

  List<TimeBar> get showTimeBarList {
    return wideScreen ? TimeBar.values : preferTimeBarList;
  }

  final timeBarSettingBtnStatus = ValueNotifier(false);
  Future<void> onTapTimeBarSetting() async {
    timeBarSettingBtnStatus.value = true;
    await DialogManager().showBottomDialog(
      dialogTag: TimerBarSelectDialog.dialogTag,
      builder: (context) => TimerBarSelectDialog(
        controller: widget.controller,
        onTapTimeBar: widget.onTapTimeBar,
        preferTimeBarList: preferTimeBarList,
      ),
    );
    timeBarSettingBtnStatus.value = false;
  }

  final indicatorSettingBtnStatus = ValueNotifier(false);
  Future<void> onTapIndicatorSetting() async {
    indicatorSettingBtnStatus.value = true;
    await DialogManager().showBottomDialog(
      dialogTag: IndicatorSelectDialog.dialogTag,
      builder: (context) => IndicatorSelectDialog(
        controller: widget.controller,
      ),
    );
    indicatorSettingBtnStatus.value = false;
  }

  void onTapKlineSetting() {
    SmartDialog.show(
      tag: KlineSettingDialog.dialogTag,
      alignment: Alignment.bottomCenter,
      builder: (context) => KlineSettingDialog(
        controller: widget.controller,
      ),
    );
  }

  void onTapDrawTool() {
    setState(() {
      _showDarwTool = !_showDarwTool;
      if (_showDarwTool) {
        widget.controller.onDrawPrepare();
      } else {
        widget.controller.onDrawExit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildSettingBar(context),
        Visibility(
          visible: _showDarwTool,
          child: FlexiKlineDrawMenubar(
            controller: widget.controller,
          ),
        )
      ],
    );
  }

  Widget buildSettingBar(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final s = S.of(context);

    return Container(
      alignment: widget.alignment ?? AlignmentDirectional.centerStart,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 6.r, vertical: 4.r),
      decoration: widget.decoration,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                // child: TimeBarTabBar(
                //   timerBarList: showTimeBarList,
                //   timeBarListener: widget.controller.timeBarListener,
                //   onTapTimeBar: widget.onTapTimeBar,
                // ),
                child: _buildTimeBarList(
                  context,
                  timerBarList: showTimeBarList,
                ),
              ),
            ),
          ),
          Container(
            color: theme.dividerLine,
            width: 1.r,
            height: 18.r,
            margin: EdgeInsets.symmetric(horizontal: 4.r),
          ),
          Offstage(
            offstage: wideScreen,
            child: ValueListenableBuilder(
              valueListenable: widget.controller.timeBarListener,
              builder: (context, value, child) {
                final showMore = value == null || isPreferTimeBar(value);
                return TextArrowButton(
                  onPressed: onTapTimeBarSetting,
                  text: showMore ? s.more : value.bar,
                  iconStatus: timeBarSettingBtnStatus,
                  background: showMore ? null : theme.markBg,
                );
              },
            ),
          ),
          TextArrowButton(
            onPressed: onTapIndicatorSetting,
            text: s.indicators,
            iconStatus: indicatorSettingBtnStatus,
          ),
          Container(
            color: theme.dividerLine,
            width: 1.r,
            height: 18.r,
            margin: EdgeInsets.symmetric(horizontal: 4.r),
          ),
          ShrinkIconButton(
            onPressed: onTapDrawTool,
            content: Icons.edit_rounded,
            padding: 6.r,
            color: theme.t1,
          ),
          ShrinkIconButton(
            onPressed: onTapKlineSetting,
            content: Icons.settings_rounded,
            padding: 6.r,
            color: theme.t1,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBarList(
    BuildContext context, {
    required List<TimeBar> timerBarList,
  }) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.timeBarListener,
      builder: (context, value, child) {
        final theme = ref.watch(themeProvider);
        return Row(
          children: timerBarList.map((bar) {
            final selected = value == bar;
            return GestureDetector(
              onTap: () => widget.onTapTimeBar(bar),
              child: Container(
                key: ValueKey(bar),
                constraints: BoxConstraints(minWidth: 38.r),
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                  color: selected ? theme.markBg : null,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 6.r,
                  vertical: 4.r,
                ),
                margin: EdgeInsetsDirectional.symmetric(horizontal: 2.r),
                child: Text(
                  bar.bar,
                  style: selected ? theme.t1s14w700 : theme.t1s14w400,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class TimeBarTabBar extends ConsumerStatefulWidget {
  const TimeBarTabBar({
    super.key,
    required this.timerBarList,
    required this.timeBarListener,
    this.onTapTimeBar,
  });

  final List<TimeBar> timerBarList;
  final ValueChanged<TimeBar>? onTapTimeBar;
  final ValueListenable<TimeBar?> timeBarListener;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TimeTabBarViewState();
}

class _TimeTabBarViewState extends ConsumerState<TimeBarTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<TimeBar> get timerBarList => widget.timerBarList;

  @override
  void initState() {
    super.initState();
    initTabController();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  void didUpdateWidget(covariant TimeBarTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timerBarList != widget.timerBarList) {
      _tabController.dispose();
      initTabController();
    }
  }

  void initTabController() {
    int index = 0;
    final bar = widget.timeBarListener.value;
    if (bar != null) index = timerBarList.indexOf(bar);
    index = index.clamp(0, timerBarList.length);
    _tabController = TabController(
      initialIndex: index,
      length: timerBarList.length,
      vsync: this,
    );
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return ValueListenableBuilder(
      valueListenable: widget.timeBarListener,
      builder: (context, value, child) {
        bool isInList = value != null;
        if (isInList) {
          final index = timerBarList.indexOf(value);
          isInList = index >= 0;
          if (isInList && index != _tabController.index) {
            _tabController.animateTo(index);
          }
        }
        return TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: EdgeInsetsDirectional.symmetric(horizontal: 6.r),
          labelStyle: theme.t1s14w700,
          unselectedLabelStyle: theme.t2s14w400,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: isInList ? theme.markBg : null,
            borderRadius: BorderRadius.circular(8.r),
          ),
          indicatorWeight: 0,
          tabAlignment: TabAlignment.start,
          onTap: (index) {
            final timeBar = timerBarList.getItem(index);
            if (timeBar != null) widget.onTapTimeBar?.call(timeBar);
          },
          tabs: timerBarList.map((bar) {
            return Tab(
              height: 28.r,
              child: Container(
                alignment: AlignmentDirectional.center,
                width: 40.r,
                child: FittedBox(
                  child: Text(bar.bar),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
