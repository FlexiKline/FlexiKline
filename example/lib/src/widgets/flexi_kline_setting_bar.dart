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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../dialogs/indicators_select_dialog.dart';
import '../dialogs/kline_settting_dialog.dart';
import '../dialogs/timebar_select_dialog.dart';
import '../theme/export.dart';
import '../utils/dialog_manager.dart';
import 'text_arrow_button.dart';

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

class _FlexiKlineSettingBarState extends ConsumerState<FlexiKlineSettingBar> {
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
  ];

  bool isPreferTimeBar(TimeBar bar) => preferTimeBarList.contains(bar);

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

  void onTabKlineSetting() {
    DialogManager().showBottomDialog(
      dialogTag: KlineSettingDialog.dialogTag,
      builder: (context) => KlineSettingDialog(
        controller: widget.controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final s = S.of(context);

    return Container(
      alignment: widget.alignment ?? AlignmentDirectional.centerStart,
      padding: EdgeInsetsDirectional.only(start: 6.r, end: 6.r),
      decoration: widget.decoration,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildPreferTimeBarList(context),
            ),
          ),
          ValueListenableBuilder(
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
          TextArrowButton(
            onPressed: onTapIndicatorSetting,
            text: s.indicators,
            iconStatus: indicatorSettingBtnStatus,
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

  Widget _buildPreferTimeBarList(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.timeBarListener,
      builder: (context, value, child) {
        final theme = ref.watch(themeProvider);
        return Row(
          children: preferTimeBarList.map((bar) {
            final selected = value == bar;
            return GestureDetector(
              onTap: () => widget.onTapTimeBar(bar),
              child: Container(
                key: ValueKey(bar),
                constraints: BoxConstraints(minWidth: 28.r),
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                  color: selected ? theme.markBg : null,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 6.r,
                  vertical: 4.r,
                ),
                margin: EdgeInsetsDirectional.symmetric(horizontal: 6.r),
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
