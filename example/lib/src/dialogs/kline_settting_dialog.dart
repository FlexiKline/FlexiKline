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
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/kline_controller_state_provider.dart';
import '../widgets/flexi_kline_size_slider.dart';

class KlineSettingDialog extends ConsumerStatefulWidget {
  static const String dialogTag = "KlineSettingDialog";
  const KlineSettingDialog({
    super.key,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _KlineSettingDialogState();
}

class _KlineSettingDialogState extends ConsumerState<KlineSettingDialog> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingTab(context),
          _buildDisplaySetting(context),
          _buildKlineHeightSetting(context),
        ],
      ),
    );
  }

  Widget _buildSettingTab(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final s = S.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 16.r,
        vertical: 10.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.chartSettings,
            style: theme.t1s18w700,
          ),
          SizedBox(height: 20.r),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: theme.roundBtnStyle,
                onPressed: () {},
                child: Column(
                  children: [
                    Icon(Icons.screen_rotation_rounded, color: theme.t1),
                    Text(s.landscape, style: theme.t1s14w500),
                  ],
                ),
              ),
              TextButton(
                style: theme.roundBtnStyle,
                onPressed: () {},
                child: Column(
                  children: [
                    Icon(Icons.legend_toggle_rounded, color: theme.t1),
                    Text(s.indicators, style: theme.t1s14w500),
                  ],
                ),
              ),
              TextButton(
                style: theme.roundBtnStyle,
                onPressed: () {},
                child: Column(
                  children: [
                    Icon(Icons.draw_rounded, color: theme.t1),
                    Text(s.drawings, style: theme.t1s14w500),
                  ],
                ),
              ),
              TextButton(
                style: theme.roundBtnStyle,
                onPressed: () {},
                child: Column(
                  children: [
                    Icon(Icons.settings_rounded, color: theme.t1),
                    Text(s.more, style: theme.t1s14w500),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDisplaySetting(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final s = S.of(context);
    final klineState = ref.watch(klineStateProvider(widget.controller));
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 16.r,
        vertical: 10.r,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: true,
                  contentPadding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) {
                    setState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    s.lastPrice,
                    style: theme.t1s14w500,
                  ),
                  activeColor: theme.t1,
                  selected: true,
                  checkColor: theme.tlight,
                  // shape: theme.defaultShape,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: true,
                  contentPadding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) {
                    setState(() {});
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    s.priceScale,
                    style: theme.t1s14w500,
                  ),
                  activeColor: theme.t1,
                  selected: true,
                  checkColor: theme.tlight,
                  // shape: theme.defaultShape,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: klineState
                      .controller.indicatorsConfig.candle.showCountDown,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    ref.read(klineStateProvider(widget.controller).notifier);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    s.countdown,
                    style: theme.t1s14w500,
                  ),
                  activeColor: theme.t1,
                  selected: true,
                  checkColor: theme.tlight,
                ),
              ),
              Expanded(child: SizedBox.shrink())
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKlineHeightSetting(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final s = S.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 16.r,
        vertical: 10.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.chartWidth,
            style: theme.t1s14w400,
          ),
          FlexiKlineSizeSlider(
            controller: widget.controller,
            maxSize: Size(
              ScreenUtil().screenWidth,
              ScreenUtil().screenHeight * 2 / 3,
            ),
            axis: Axis.horizontal,
          ),
          Text(
            s.chartHeight,
            style: theme.t1s14w400,
          ),
          FlexiKlineSizeSlider(
            controller: widget.controller,
            maxSize: Size(
              ScreenUtil().screenWidth,
              ScreenUtil().screenHeight * 2 / 3,
            ),
            axis: Axis.vertical,
          ),
        ],
      ),
    );
  }
}