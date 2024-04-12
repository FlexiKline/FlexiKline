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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'indicator_info_view.dart';

class LatestPriceView extends ConsumerWidget {
  const LatestPriceView({
    super.key,
    this.model,
    this.precision = 0,
    this.padding,
    this.backgroundColor,
  });

  final CandleModel? model;
  final int precision;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 16.r,
            vertical: 12.r,
          ),
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    formatNumber(
                      model?.close,
                      precision: precision,
                      showThousands: true,
                      cutInvalidZero: true,
                    ),
                    style: TextStyle(
                      fontSize: 38.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(formatPercentage(
                  model?.changeRate,
                ))
              ],
            ),
          ),
          SizedBox(width: 16.r),
          Flexible(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IndicatorInfoView(
                  title: '24小时最高',
                  value: formatNumber(
                    model?.high,
                    precision: precision,
                    cutInvalidZero: true,
                  ),
                ),
                IndicatorInfoView(
                  title: '24小时最低',
                  value: formatNumber(
                    model?.low,
                    precision: precision,
                    cutInvalidZero: true,
                  ),
                ),
                IndicatorInfoView(
                  title: '24小时量',
                  value: formatNumber(
                    model?.vol,
                    precision: 2,
                    showCompact: true,
                    cutInvalidZero: true,
                  ),
                ),
                IndicatorInfoView(
                  title: '24小时额',
                  value: formatNumber(
                    model?.volCcy,
                    precision: 2,
                    showCompact: true,
                    cutInvalidZero: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
