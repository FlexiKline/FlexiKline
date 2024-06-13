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
import 'package:example/generated/l10n.dart';
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/export.dart';
import '../providers/instruments_provider.dart';
import '../providers/market_ticker_provider.dart';
import '../widgets/flexi_text_field.dart';

class SelectTradingPairDialog extends HookConsumerWidget {
  static const String dialogTag = "SelectTradingPairDialog";
  const SelectTradingPairDialog({
    super.key,
    this.long,
    this.short,
    this.instId,
    this.instType = 'SPOT',
  });

  final String? instId;
  final Color? long;
  final Color? short;
  final String instType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = ref.watch(themeProvider);
    final mkListProvider = ref.watch(marketTickerListProvider(instType));
    final textController = useTextEditingController();
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
              s.selectTradingPair,
              style: theme.t1s20w700,
            ),
          ),
          SizedBox(height: 8.r),
          FlexiTextField(
            margin: EdgeInsetsDirectional.symmetric(horizontal: 16.r),
            contentPadding: EdgeInsetsDirectional.symmetric(
              horizontal: 12.r,
              vertical: 8.r,
            ),
            bgColor: Colors.transparent,
            defaultBorderRadius: 20.r,
            controller: textController,
            hintText: s.searchTradingPairHint,
            keyboardType: TextInputType.text,
            maxLines: 1,
            prefixIcon: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: 12.r,
                vertical: 4.r,
              ),
              child: const Icon(Icons.search_outlined),
            ),
            prefixIconConstraints: BoxConstraints(
              maxHeight: 32.r,
              maxWidth: 32.r,
            ),
            suffixIcon: GestureDetector(
              onTap: () {
                textController.clear();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 12.r,
                  vertical: 4.r,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                ),
              ),
            ),
            suffixIconConstraints: BoxConstraints(
              maxHeight: 32.r,
              maxWidth: 64.r,
            ),
          ),
          SizedBox(height: 8.r),
          Row(
            children: [
              SizedBox(width: 56.r),
              Text(
                s.labelNameVol,
                style: theme.t1s12w400,
              ),
              const Expanded(child: SizedBox.shrink()),
              Text(
                s.lastPrice,
                style: theme.t1s12w400,
              ),
              Container(
                width: 80.r,
                margin: EdgeInsetsDirectional.only(start: 12.r),
                alignment: AlignmentDirectional.center,
                child: Text(
                  s.label24HChange,
                  style: theme.t1s12w400,
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
                marketTickerListProvider(instType).future,
              ),
              child: mkListProvider.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.t1),
                  ),
                ),
                error: (error, stackTrace) => Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    s.loadFailed,
                    style: theme.t3s18w500,
                  ),
                ),
                data: (data) => ValueListenableBuilder(
                  valueListenable: textController,
                  builder: (context, value, child) {
                    final searchTxt = value.text.trim().toUpperCase();
                    List<MarketTicker> list = data;
                    if (searchTxt.isNotEmpty) {
                      list = data
                          .where((e) => e.instId.contains(searchTxt))
                          .toList();
                    }
                    return _buildTradingPairListView(ref, list);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingPairListView(WidgetRef ref, List<MarketTicker> list) {
    final theme = ref.watch(themeProvider);
    final instrumentsMgr = ref.watch(instrumentsMgrProvider);
    return ListView.separated(
      padding: EdgeInsetsDirectional.zero,
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return InkWell(
          onTap: () {
            SmartDialog.dismiss(
              tag: SelectTradingPairDialog.dialogTag,
              result: item.instId == instId ? null : item,
            );
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
      color: ticker.instId == instId ? theme.cardBg : null,
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
