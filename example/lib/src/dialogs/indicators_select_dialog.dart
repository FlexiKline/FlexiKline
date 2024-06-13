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

class IndicatorSelectDialog extends ConsumerWidget {
  static const String dialogTag = "IndicatorSelectDialog";
  const IndicatorSelectDialog({
    super.key,
    required this.controller,
  });

  final FlexiKlineController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final s = S.of(context);
    return Container(
      width: ScreenUtil().screenWidth,
      padding: EdgeInsetsDirectional.all(16.r),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.r),
            Text(
              s.indicators,
              style: theme.t1s20w700,
            ),
            SizedBox(height: 20.r),
            Text(
              s.mainChartIndicators,
              style: theme.t1s16w500,
            ),
            SizedBox(height: 10.r),
            _buildMainIndicators(ref),
            SizedBox(height: 20.r),
            Text(
              s.subChartIndicators,
              style: theme.t1s16w500,
            ),
            SizedBox(height: 10.r),
            _buildSubIndicators(ref),
            SizedBox(height: 10.r),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                s.indicatorSetting,
                style: theme.t1s16w500,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: theme.t1,
                size: 16.r,
              ),
              onTap: () {
                // TODO:
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainIndicators(WidgetRef ref) {
    final theme = ref.read(themeProvider);
    final klineState = ref.watch(klineStateProvider(controller));
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 16.r,
      runSpacing: 8.r,
      children: klineState.supportMainIndicatorKeys.map((key) {
        final selected = klineState.mainIndicatorKeys.contains(key);
        return TextButton(
          key: key,
          style: theme.outlinedBtnStyle(showOutlined: selected),
          onPressed: () {
            ref
                .read(klineStateProvider(controller).notifier)
                .onTapMainIndicator(key);
          },
          child: Text(
            key.value.toString().toUpperCase(),
            style: theme.t2s12w400.copyWith(
              color: theme.t1,
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubIndicators(WidgetRef ref) {
    final theme = ref.read(themeProvider);
    final klineState = ref.watch(klineStateProvider(controller));
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 16.r,
      runSpacing: 8.r,
      children: klineState.supportSubIndicatorKeys.map((key) {
        final selected = klineState.subIndicatorKeys.contains(key);
        return TextButton(
          key: key,
          style: theme.outlinedBtnStyle(showOutlined: selected),
          onPressed: () {
            ref
                .read(klineStateProvider(controller).notifier)
                .onTapSubIndicator(key);
          },
          child: Text(
            key.value.toString().toUpperCase(),
            style: theme.t2s12w400.copyWith(
              color: theme.t1,
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
