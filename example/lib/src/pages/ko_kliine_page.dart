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
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../config.dart';
import '../repo/api.dart' as api;
import '../utils/flexi_kline_storage.dart';
import '../widgets/flexi_indicator_bar.dart';
import '../widgets/latest_price_view.dart';
import '../widgets/flexi_time_bar.dart';
import 'main_nav_page.dart';

class KOKlinePage extends ConsumerStatefulWidget {
  const KOKlinePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _KOKlinePageState();
}

class _KOKlinePageState extends ConsumerState<KOKlinePage> {
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

  @override
  void initState() {
    super.initState();

    controller = FlexiKlineController(
      logger: LoggerImpl(
        tag: "KOKline",
        debug: kDebugMode,
      ),
      storage: FlexiKlineStorage(),
    );
    controller.setMainSize(
      Size(ScreenUtil().screenWidth, 300.r),
    );

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
      final resp = await api.getHistoryCandles(
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
    return Scaffold(
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
              color: Colors.orangeAccent,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.storeState();
        },
        child: const Text('Store'),
      ),
    );
  }
}
