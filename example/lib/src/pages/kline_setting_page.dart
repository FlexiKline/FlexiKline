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
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../dialogs/select_bottom_dialog.dart';
import '../providers/kline_controller_state_provider.dart';
import '../theme/flexi_theme.dart';
import '../utils/dialog_manager.dart';
import '../widgets/right_arrow.dart';

class KlineSettingPage extends ConsumerStatefulWidget {
  const KlineSettingPage({
    super.key,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _KlineSettingPageState();
}

class _KlineSettingPageState extends ConsumerState<KlineSettingPage> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final klineState = ref.watch(klineStateProvider(widget.controller));
    return Scaffold(
      backgroundColor: theme.pageBg,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'FlexiKline 设置',
          style: theme.t1s18w600,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpansionTile(
                title: Text(
                  '图表展示',
                  style: theme.t1s18w500,
                ),
                initiallyExpanded: true,
                children: [
                  ListTile(
                    onTap: () {},
                    title: Text(
                      'K线展示',
                      style: theme.t1s16w400,
                    ),
                    trailing: const RightArrow(),
                  ),
                  ListTile(
                    onTap: () {},
                    title: Text(
                      'K线阳线',
                      style: theme.t1s16w400,
                    ),
                    trailing: const RightArrow(),
                  ),
                ],
              ),
              Container(height: 0.5.r, color: theme.dividerLine),
              ExpansionTile(
                title: Text(
                  '图表交互',
                  style: theme.t1s18w500,
                ),
                initiallyExpanded: true,
                children: [
                  ListTile(
                    onTap: () {
                      SelectBottomDialog.show(
                        title: '缩放位置',
                        list: ScalePosition.values
                            .map((e) => e.name.toUpperCase())
                            .toList(),
                        current: klineState.scalePosition.name.toUpperCase(),
                      ).then((result) {
                        if (result != null) {
                          for (var e in ScalePosition.values) {
                            if (e.name.toUpperCase() == result.toUpperCase()) {
                              klineState.setScalePosition(e);
                              break;
                            }
                          }
                        }
                      });
                    },
                    title: Text(
                      '缩放位置',
                      style: theme.t1s16w400,
                    ),
                    trailing: RightArrow(
                      value: klineState.scalePosition.name.toUpperCase(),
                    ),
                  ),
                  // ListTile(
                  //   onTap: () {
                  //     SmartDialog.showToast('');
                  //   },
                  //   title: Text(
                  //     '缩放样式',
                  //     style: theme.t1s16w400,
                  //   ),
                  //   trailing: const RightArrow(),
                  // ),
                  SwitchListTile(
                    value: klineState.supportLongPress,
                    onChanged: (value) {
                      klineState.setSupportLongPress(
                        !klineState.supportLongPress,
                      );
                    },
                    title: Text(
                      '是否支持长按操作',
                      style: theme.t1s16w400,
                    ),
                    subtitle: Text(
                      '长按或展示Tooltips',
                      style: theme.t2s12w400,
                    ),
                  ),
                  ListTile(
                    onTap: () {
                      showInertialPanParamSettingDialog();
                    },
                    title: Text(
                      '惯性平移',
                      style: theme.t1s16w400,
                    ),
                    subtitle: Text(
                      '当平移结束后继续惯性平移',
                      style: theme.t2s12w400,
                    ),
                    trailing: RightArrow(
                      value: klineState.toleranceDesc,
                    ),
                  ),
                ],
              ),
              Container(height: 0.5.r, color: theme.dividerLine),
              SizedBox(height: 20.r)
            ],
          ),
        ),
      ),
    );
  }

  void showInertialPanParamSettingDialog() {
    DialogManager().showBottomDialog(
      builder: (context) {
        final theme = ref.watch(themeProvider);
        final klineState = ref.watch(klineStateProvider(widget.controller));
        return Container(
          width: ScreenUtil().screenWidth,
          margin: EdgeInsetsDirectional.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 16.r,
                  vertical: 12.r,
                ),
                child: Text(
                  '惯性平移设置',
                  style: theme.t1s20w700,
                ),
              ),
              SwitchListTile(
                value: klineState.isInertialPan,
                onChanged: (value) {
                  klineState.setInertialPan(
                    !klineState.isInertialPan,
                  );
                },
                title: Text(
                  '是否启用惯性平移',
                  style: theme.t1s16w400,
                ),
              ),
              ListTile(
                onTap: () {
                  showInertialPanParamSettingDialog();
                },
                title: Text(
                  '最大持续时间',
                  style: theme.t1s16w400,
                ),
                trailing: RightArrow(
                  value: '${klineState.tolerance.maxDuration}ms',
                ),
              ),
              ListTile(
                onTap: () {
                  showInertialPanParamSettingDialog();
                },
                title: Text(
                  '平移因子',
                  style: theme.t1s16w400,
                ),
                subtitle: Text(
                  '范围:[0~1]; 值越大, 惯性平移距离越长',
                  style: theme.t2s12w400,
                ),
                trailing: RightArrow(
                  value: '${klineState.tolerance.distanceFactor}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
