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

  late final FlexiKlineController controller;
  late final BitFlexiKlineConfiguration configuration;
  CancelToken? cancelToken;

  @override
  void initState() {
    super.initState();
    configuration = BitFlexiKlineConfiguration();
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
      controller.startLoading(request, useCacheFirst: true);

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
    ref.listen(themeProvider, (previous, next) {
      if (previous != next) {
        final config = configuration.genFlexiKlineConfig(
          ref.read(bitFlexiKlineThemeProvider),
        );
        controller.updateFlexiKlineConfig(config);
      }
    });
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
              base: req.base,
              quote: req.quote,
              model: controller.curKlineData.latest,
              precision: req.precision,
            ),
            FlexiTimeBar(
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

  List<TooltipInfo> onCrossCustomTooltip(
    CandleModel model, {
    CandleModel? pre,
  }) {
    final s = S.of(context);
    final theme = ref.read(themeProvider);
    final lableStyle = theme.t1s10w400;
    final valueStyle = theme.t1s10w400;
    final valStyle = model.isLong ? theme.tls10w400 : theme.tss10w400;
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
