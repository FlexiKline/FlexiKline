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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/export.dart';
import '../providers/market_ticker_provider.dart';
import 'indicator_info_view.dart';

class MarketTickerView extends ConsumerWidget {
  const MarketTickerView({
    super.key,
    required this.instId,
    this.precision = 0,
    this.padding,
    this.backgroundColor,
  });

  final String instId;
  final int precision;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  String get base => instId.split('-').firstOrNull ?? instId;
  String get quote => instId.split('-').getItem(1) ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketTicker = ref.watch(marketTickerProvider(instId));

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 16.r,
            vertical: 12.r,
          ),
      color: backgroundColor,
      child: marketTicker.when(
        loading: () => _buildMarketTickerInfo(context, null),
        error: (error, stackTrace) => _buildMarketTickerInfo(context, null),
        data: (value) => _buildMarketTickerInfo(context, value),
      ),
    );
  }

  Widget _buildMarketTickerInfo(BuildContext context, MarketTicker? ticker) {
    final s = S.of(context);
    return Row(
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
                    ticker?.last.decimal,
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
                ticker?.changeRate,
              ))
            ],
          ),
        ),
        SizedBox(width: 16.r),
        Flexible(
          flex: 3,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IndicatorInfoView(
                title: s.h24_high,
                value: formatNumber(
                  ticker?.high24h.decimal,
                  precision: precision,
                  cutInvalidZero: true,
                ),
              ),
              IndicatorInfoView(
                title: s.h24_low,
                value: formatNumber(
                  ticker?.low24h.decimal,
                  precision: precision,
                  cutInvalidZero: true,
                ),
              ),
              IndicatorInfoView(
                title: s.h24_vol(base),
                value: formatNumber(
                  ticker?.vol24h.decimal,
                  precision: 2,
                  showCompact: true,
                  cutInvalidZero: true,
                ),
              ),
              IndicatorInfoView(
                title: s.h24_turnover(quote),
                value: formatNumber(
                  ticker?.volCcy24h.decimal,
                  precision: 2,
                  showCompact: true,
                  cutInvalidZero: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
