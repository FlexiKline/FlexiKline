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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:example/src/models/export.dart';
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../providers/instruments_provider.dart';
import '../providers/market_ticker_provider.dart';

class SelectSymbolDialog extends ConsumerWidget {
  static const String dialogTag = "SelectSymbolDialog";
  const SelectSymbolDialog({
    super.key,
    this.long,
    this.short,
  });

  final Color? long;
  final Color? short;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final marketTickerList = ref.watch(marketTickerListProvider('SPOT'));
    final instrumentsMgr = ref.watch(instrumentsMgrProvider);
    return Container(
      width: ScreenUtil().screenWidth,
      height: ScreenUtil().screenHeight * 0.75,
      padding: EdgeInsetsDirectional.symmetric(vertical: 12.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: AlignmentDirectional.center,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 16.r,
              vertical: 8.r,
            ),
            child: Text(
              '币种选择',
              style: theme.t1s20w700,
            ),
          ),
          SizedBox(height: 8.r),
          Row(
            children: [
              SizedBox(width: 56.r),
              Text(
                '名称/成交量',
                style: theme.t1s14w500,
              ),
              const Expanded(child: SizedBox.shrink()),
              Text(
                '最新价',
                style: theme.t1s14w500,
              ),
              Container(
                width: 80.r,
                margin: EdgeInsetsDirectional.only(start: 12.r),
                alignment: AlignmentDirectional.center,
                child: Text(
                  '涨跌幅',
                  style: theme.t1s14w500,
                ),
              ),
              SizedBox(width: 16.r),
            ],
          ),
          SizedBox(height: 8.r),
          Container(height: theme.pixel, color: theme.dividerLine),
          Expanded(
            child: EasyRefresh(
              onRefresh: () => ref.refresh(
                marketTickerListProvider('SPOT').future,
              ),
              child: marketTickerList.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.t1),
                  ),
                ),
                error: (error, stackTrace) => Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    '加载失败!!!',
                    style: theme.t3s18w500,
                  ),
                ),
                data: (data) => ListView.separated(
                  padding: EdgeInsetsDirectional.zero,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return InkWell(
                      onTap: () {
                        SmartDialog.dismiss(tag: dialogTag, result: item);
                      },
                      child: _buildMarketTickerItemView(
                        context,
                        ref,
                        ticker: item,
                        instrument: instrumentsMgr[item.instId],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => Container(
                    key: ValueKey(index),
                    height: theme.pixel,
                    color: theme.dividerLine,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTickerItemView(
    BuildContext context,
    WidgetRef ref, {
    required MarketTicker ticker,
    Instrument? instrument,
  }) {
    final theme = ref.watch(themeProvider);
    return Container(
      key: ValueKey(ticker.instId),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 16.r,
        vertical: 10.r,
      ),
      child: Row(
        children: [
          CachedNetworkImage(
            width: 28.r,
            height: 28.r,
            cacheKey: ticker.instId,
            imageUrl: ticker.baseCcyIcon,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                color: theme.cardBg,
                shape: BoxShape.circle,
              ),
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.signal_wifi_bad_outlined,
              color: theme.t1,
            ),
          ),
          SizedBox(width: 12.r),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      ticker.baseCcy,
                      style: theme.t1s16w500,
                    ),
                    Text(
                      '/${ticker.quoteCcy}',
                      style: theme.t2s12w400,
                    ),
                  ],
                ),
                Text(
                  formatNumber(
                    ticker.volCcy24h.decimal,
                    precision: 2,
                    showCompact: true,
                  ),
                  style: theme.t2s10w400,
                ),
              ],
            ),
          ),
          Text(
            formatNumber(
              ticker.last.decimal,
              precision: instrument?.precision ?? ticker.precision,
              showThousands: true,
              prefix: '\$',
            ),
            style: theme.t1s14w500,
          ),
          Container(
            width: 80.r,
            height: 32.r,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: 12.r,
              vertical: 6.r,
            ),
            margin: EdgeInsetsDirectional.only(start: 12.r),
            decoration: BoxDecoration(
              color: ticker.changeRate >= 0
                  ? long ?? theme.long
                  : short ?? theme.short,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: FittedBox(
              child: Text(
                formatPercentage(ticker.changeRate),
                style: TextStyle(
                  color: theme.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
