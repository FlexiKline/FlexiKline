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

import 'package:dio/dio.dart';
import 'package:example/generated/l10n.dart';
import 'package:example/src/constants/images.dart';
import 'package:example/src/models/export.dart';
import 'package:example/src/providers/instruments_provider.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../config.dart';
import '../providers/bit_kline_config.dart';
import '../repo/api.dart' as api;
import '../widgets/flexi_kline_indicator_bar.dart';
import '../widgets/market_ticker_view.dart';
import '../widgets/flexi_kline_setting_bar.dart';
import '../widgets/select_symbol_title_view.dart';
import 'main_nav_page.dart';

class BitKlinePage extends ConsumerStatefulWidget {
  const BitKlinePage({
    super.key,
    this.instId = 'BTC-USDT',
  });

  final String instId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BitKlinePageState();
}

class _BitKlinePageState extends ConsumerState<BitKlinePage> {
  late CandleReq req;

  late final FlexiKlineController controller;
  late final BitFlexiKlineConfiguration configuration;
  CancelToken? cancelToken;

  @override
  void initState() {
    super.initState();
    final p = ref.read(instrumentsMgrProvider.notifier).getPrecision(
          widget.instId,
        );
    req = CandleReq(
      instId: widget.instId,
      bar: TimeBar.m15.bar,
      precision: p ?? 2,
      limit: 300,
    );
    configuration = BitFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: LoggerImpl(
        tag: "BitFlexiKline",
        debug: kDebugMode,
      ),
    );

    controller.onCrossCustomTooltip = onCrossCustomTooltip;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadCandleData(req);
    });
  }

  Future<void> loadCandleData(CandleReq request) async {
    try {
      controller.startLoading(request);

      cancelToken?.cancel();
      final resp = await api.getMarketCandles(
        request,
        cancelToken: cancelToken = CancelToken(),
      );
      cancelToken = null;
      if (resp.success && resp.data != null) {
        await controller.updateKlineData(request, resp.data!);
      } else {
        SmartDialog.showToast(resp.msg);
      }
    } finally {
      controller.stopLoading(request);
    }
  }

  void onChangeKlineInstId(MarketTicker ticker) {
    final p = ref.read(instrumentsMgrProvider.notifier).getPrecision(
          ticker.instId,
        );
    req = req.copyWith(
      instId: ticker.instId,
      after: null,
      before: null,
      precision: p ?? ticker.precision,
    );
    loadCandleData(req);
    setState(() {});
  }

  void onTapTimerBar(TimeBar bar) {
    if (bar.bar != req.bar) {
      req.bar = bar.bar;
      setState(() {});
      loadCandleData(req);
    }
  }

  @override
  Widget build(BuildContext context) {
    final klineTheme = ref.watch(bitFlexiKlineThemeProvider);
    ref.listen(bitFlexiKlineThemeProvider, (previous, next) {
      if (previous != next) {
        final config = configuration.getFlexiKlineConfig(next);
        controller.updateFlexiKlineConfig(config);
      }
    });
    return Scaffold(
      backgroundColor: klineTheme.chartBg,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            mainNavScaffoldKey.currentState?.openDrawer();
          },
          child: const Icon(Icons.menu_outlined),
        ),
        title: SelectSymbolTitleView(
          instId: req.instId,
          onChangeTradingPair: onChangeKlineInstId,
          long: klineTheme.long,
          short: klineTheme.short,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            MarketTickerView(
              instId: req.instId,
              precision: req.precision,
              long: klineTheme.long,
              short: klineTheme.short,
            ),
            FlexiKlineSettingBar(
              controller: controller,
              onTapTimeBar: onTapTimerBar,
            ),
            FlexiKlineWidget(
              controller: controller,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.logo),
                  fit: BoxFit.scaleDown,
                  scale: 6,
                  opacity: 0.1,
                ),
              ),
            ),
            FlexiKlineIndicatorBar(
              controller: controller,
            ),
            Container(
              height: 200,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: klineTheme.tooltipBg,
        foregroundColor: klineTheme.textColor,
        mini: true,
        onPressed: () {
          controller.storeFlexiKlineConfig();
        },
        child: Text(
          'Store',
          style: TextStyle(
            fontSize: 14.sp,
            color: klineTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<TooltipInfo> onCrossCustomTooltip(
    CandleModel model, {
    CandleModel? pre,
  }) {
    final s = S.of(context);
    final klineTheme = ref.read(bitFlexiKlineThemeProvider);
    final lableStyle = TextStyle(color: klineTheme.textColor, fontSize: 10.sp);
    final valueStyle = TextStyle(color: klineTheme.textColor, fontSize: 10.sp);
    final valStyle = model.isLong
        ? TextStyle(color: klineTheme.long, fontSize: 10.sp)
        : TextStyle(color: klineTheme.short, fontSize: 10.sp);
    final p = req.precision;
    return <TooltipInfo>[
      TooltipInfo(
        label: s.tooltipTime,
        labelStyle: lableStyle,
        value: model.formatDateTimeByTimeBar(req.timeBar),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipOpen,
        labelStyle: lableStyle,
        value: formatPrice(model.o, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipHigh,
        labelStyle: lableStyle,
        value: formatPrice(model.h, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipLow,
        labelStyle: lableStyle,
        value: formatPrice(model.l, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipClose,
        labelStyle: lableStyle,
        value: formatPrice(model.c, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipAmount,
        labelStyle: lableStyle,
        value: formatPrice(model.c, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipChg,
        labelStyle: lableStyle,
        value: formatPrice(model.change, precision: p, showThousands: true),
        valueStyle: valStyle,
      ),
      TooltipInfo(
        label: s.tooltipChgRate,
        labelStyle: lableStyle,
        value: formatPercentage(model.changeRate),
        valueStyle: valStyle,
      ),
    ];
  }
}
