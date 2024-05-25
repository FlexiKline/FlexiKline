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
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../config.dart';
import '../providers/bit_kline_provider.dart';
import '../repo/api.dart' as api;
import '../widgets/flexi_indicator_bar.dart';
import '../widgets/latest_price_view.dart';
import '../widgets/flexi_time_bar.dart';
import 'main_nav_page.dart';

class BitKlinePage extends ConsumerStatefulWidget {
  const BitKlinePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BitKlinePageState();
}

class _BitKlinePageState extends ConsumerState<BitKlinePage> {
  CandleReq req = CandleReq(
    instId: 'BTC-USDT',
    bar: TimeBar.m15.bar,
    precision: 2,
    limit: 300,
  );

  final List<TimeBar> timBarList = const [
    TimeBar.m15,
    TimeBar.H1,
    TimeBar.H4,
    TimeBar.D1
  ];

  late final FlexiKlineController controller;
  CandleModel? latest;
  CancelToken? cancelToken;
  Map<TooltipLabel, String> tooltipLables() {
    return {
      TooltipLabel.time: S.current.tooltipTime,
      TooltipLabel.open: S.current.tooltipOpen,
      TooltipLabel.high: S.current.tooltipHigh,
      TooltipLabel.low: S.current.tooltipLow,
      TooltipLabel.close: S.current.tooltipClose,
      TooltipLabel.chg: S.current.tooltipChg,
      TooltipLabel.chgRate: S.current.tooltipChgRate,
      TooltipLabel.range: S.current.tooltipRange,
      TooltipLabel.amount: S.current.tooltipAmount,
      TooltipLabel.turnover: S.current.tooltipTurnover,
    };
  }

  @override
  void initState() {
    super.initState();

    controller = FlexiKlineController(
      configuration: BitFlexiKlineConfiguration(),
      logger: LoggerImpl(
        tag: "BitFlexiKline",
        debug: kDebugMode,
      ),
    );
    // controller.setMainSize(
    //   Size(ScreenUtil().screenWidth, 300.r),
    // );

    controller.onCrossI18nTooltipLables = tooltipLables;

    // controller.candleMainIndicator = CustomCandleIndicator(
    //   height: 300.r,
    //   latestPriceRectBackgroundColor: Colors.grey,
    //   // latestPriceTextStyle: const TextStyle(
    //   //   color: Colors.red,
    //   //   fontSize: 12,
    //   //   fontWeight: FontWeight.bold,
    //   // ),
    // );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadCandleData(req);
    });
  }

  Future<void> loadCandleData(CandleReq request) async {
    try {
      controller.startLoading(request, useCacheFirst: true);

      await Future.delayed(const Duration(seconds: 2));

      cancelToken?.cancel();
      final resp = await api.getMarketCandles(
        request,
        cancelToken: cancelToken = CancelToken(),
      );
      cancelToken = null;
      if (resp.success && resp.data != null) {
        controller.setKlineData(request, resp.data!);
        setState(() {});
      } else {
        SmartDialog.showToast(resp.msg);
      }
    } finally {
      controller.stopLoading();
    }
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
    final theme = ref.watch(themeProvider);
    return Scaffold(
      backgroundColor: theme.pageBg,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            mainNavScaffoldKey.currentState?.openDrawer();
          },
          child: const Icon(Icons.menu_outlined),
        ),
        title: Text(req.instId),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            LatestPriceView(
              model: controller.curKlineData.latest,
              precision: req.precision,
            ),
            FlexiTimeBar(
              controller: controller,
              onTapTimeBar: onTapTimerBar,
            ),
            FlexiKlineWidget(
              controller: controller,
            ),
            FlexiIndicatorBar(
              controller: controller,
            ),
            Container(
              height: 200,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.cardBg,
        foregroundColor: theme.t1,
        mini: true,
        onPressed: () {
          controller.storeFlexiKlineConfig();
        },
        child: Text(
          'Store',
          style: theme.t1s14w400,
        ),
      ),
    );
  }
}
