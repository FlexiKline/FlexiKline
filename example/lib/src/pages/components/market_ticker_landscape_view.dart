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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/export.dart';
import '../../providers/market_ticker_provider.dart';
import '../../widgets/basic_info_view.dart';

class MarketTickerLandscapeView extends ConsumerWidget {
  const MarketTickerLandscapeView({
    super.key,
    required this.instId,
    required this.precision,
    this.long,
    this.short,
    this.padding,
    this.backgroundColor,
  });

  final String instId;
  final int precision;
  final Color? long;
  final Color? short;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  String get base => instId.split('-').firstOrNull ?? instId;
  String get quote => instId.split('-').getItem(1) ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketTicker = ref.watch(marketTickerProvider(instId));

    return Container(
      alignment: AlignmentDirectional.centerStart,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 4.r,
            vertical: 2.r,
          ),
      color: backgroundColor,
      child: marketTicker.when(
        loading: () => _buildMarketTickerInfo(context, ref, null),
        error: (error, stack) => _buildMarketTickerInfo(context, ref, null),
        data: (value) => _buildMarketTickerInfo(context, ref, value),
      ),
    );
  }

  Widget _buildMarketTickerInfo(
    BuildContext context,
    WidgetRef ref,
    MarketTicker? ticker,
  ) {
    final theme = ref.watch(themeProvider);
    final s = S.of(context);
    final changeRate = ticker?.changeRate;
    Color rateColor;
    if (changeRate == null || changeRate == 0) {
      rateColor = theme.t1;
    } else if (changeRate > 0) {
      rateColor = long ?? theme.long;
    } else {
      rateColor = short ?? theme.short;
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$base/$quote', style: theme.t1s18w700),
        Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: 6.r,
            vertical: 2.r,
          ),
          margin: EdgeInsetsDirectional.symmetric(horizontal: 4.r),
          decoration: BoxDecoration(
            color: rateColor,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: FittedBox(
            child: Text(
              formatPercentage(ticker?.changeRate),
              style: TextStyle(
                color: theme.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Text(
          formatNumber(
            ticker?.last.decimal,
            precision: precision,
            showThousands: true,
            cutInvalidZero: true,
            prefix: '\$',
          ),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: rateColor,
          ),
        ),
        SizedBox(width: 8.r),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BasicInfoView(
                title: s.h24_high,
                value: formatNumber(
                  ticker?.high24h.decimal,
                  precision: precision,
                  cutInvalidZero: true,
                ),
                spacing: 4.r,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 6.r),
              ),
              BasicInfoView(
                title: s.h24_low,
                value: formatNumber(
                  ticker?.low24h.decimal,
                  precision: precision,
                  cutInvalidZero: true,
                ),
                spacing: 4.r,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 6.r),
              ),
              BasicInfoView(
                title: s.h24_vol(base),
                value: formatNumber(
                  ticker?.vol24h.decimal,
                  precision: 2,
                  showCompact: true,
                  cutInvalidZero: true,
                ),
                spacing: 4.r,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 6.r),
              ),
              BasicInfoView(
                title: s.h24_turnover(quote),
                value: formatNumber(
                  ticker?.volCcy24h.decimal,
                  precision: 2,
                  showCompact: true,
                  cutInvalidZero: true,
                ),
                spacing: 4.r,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 6.r),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
