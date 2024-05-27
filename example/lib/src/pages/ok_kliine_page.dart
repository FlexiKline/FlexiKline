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
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../config.dart';
import '../repo/api.dart' as api;
import '../providers/ok_kline_provider.dart';
import '../widgets/flexi_indicator_bar.dart';
import '../widgets/flexi_kline_mark_view.dart';
import '../widgets/latest_price_view.dart';
import '../widgets/flexi_time_bar.dart';
import 'main_nav_page.dart';

class OkKlinePage extends ConsumerStatefulWidget {
  const OkKlinePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _OkKlinePageState();
}

class _OkKlinePageState extends ConsumerState<OkKlinePage> {
  CandleReq req = CandleReq(
    instId: 'BTC-USDT',
    bar: TimeBar.m15.bar,
    precision: 2,
    limit: 300,
  );

  late final FlexiKlineController controller;
  late final OkFlexiKlineConfiguration configuration;
  CancelToken? cancelToken;

  @override
  void initState() {
    super.initState();
    configuration = OkFlexiKlineConfiguration();
    controller = FlexiKlineController(
      configuration: configuration,
      logger: LoggerImpl(
        tag: "OkFlexiKline",
        debug: kDebugMode,
      ),
    );

    controller.onCrossI18nTooltipLables = tooltipLables;

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
        final config = configuration.genFlexiKlineConfigObject(next);
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              mainBackgroundView: FlexiKlineMarkView(
                margin: EdgeInsetsDirectional.only(bottom: 10.r, start: 36.r),
              ),
              mainforegroundViewBuilder: _buildKlineMainForgroundView,
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

  Widget _buildKlineMainForgroundView(BuildContext context, bool isLoading) {
    final theme = ref.watch(themeProvider);
    return Stack(
      children: [
        Positioned(
          left: 8.r,
          bottom: 8.r,
          width: 28.r,
          height: 28.r,
          child: IconButton(
            // constraints: BoxConstraints.tight(Size(28.r, 28.r)),
            padding: EdgeInsets.zero,
            style: theme.circleBtnStyle(bg: theme.markBg.withOpacity(0.6)),
            iconSize: 16.r,
            icon: const Icon(Icons.open_in_full_rounded),
            onPressed: () {
              // TODO: 待实现
            },
          ),
        ),
        Positioned(
          child: Offstage(
            offstage: !isLoading,
            child: Center(
              key: const ValueKey('loadingView'),
              child: SizedBox.square(
                dimension: 28.r,
                child: CircularProgressIndicator(
                  strokeWidth: 3.r,
                  backgroundColor: theme.markBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.t1,
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
