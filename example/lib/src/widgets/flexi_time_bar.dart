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
import '../providers/kline_controller_state_provider.dart';
import '../theme/export.dart';
import '../utils/dialog_manager.dart';

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

class _FlexiTimeBarState extends ConsumerState<FlexiTimeBar> {
  @override
  void initState() {
    super.initState();
  }

  void onTapTimeBarSetting() {
    DialogManager().showBottomDialog(
      dialogTag: TimerBarSelectDialog.dialogTag,
      builder: (context) => TimerBarSelectDialog(
        controller: widget.controller,
      ),
    );
  }

  void onTapIndicatorSetting() {
    DialogManager().showBottomDialog(
      dialogTag: IndicatorSelectDialog.dialogTag,
      builder: (context) => IndicatorSelectDialog(
        controller: widget.controller,
      ),
    );
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
    final klineState = ref.watch(klineStateProvider(widget.controller));
    ref.listen(timeBarProvider(widget.controller), (prev, next) {
      if (prev != next && next != null) {
        widget.onTapTimeBar(next);
      }
    });
    return Container(
      alignment: widget.alignment ?? AlignmentDirectional.centerStart,
      padding: EdgeInsetsDirectional.only(start: 6.r, end: 6.r),
      decoration: widget.decoration,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: klineState.preferTimeBarList.map((bar) {
                  final selected = klineState.currentTimeBar == bar;
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(klineStateProvider(widget.controller).notifier)
                          .setTimeBar(bar);
                    },
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
              ),
            ),
          ),
          TextButton(
            onPressed: onTapTimeBarSetting,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  klineState.currentTimeBar == null ||
                          klineState.isPreferTimeBar
                      ? '更多'
                      : klineState.currentTimeBar!.bar,
                  style: theme.t1s14w500,
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: theme.t1,
                )
              ],
            ),
          ),
          TextButton(
            onPressed: onTapIndicatorSetting,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.indicators,
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
