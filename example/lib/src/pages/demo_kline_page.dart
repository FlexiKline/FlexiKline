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
import '../providers/default_kline_config.dart';
import '../providers/market_candle_provider.dart';
import '../repo/mock.dart';
import '../repo/polygon_api.dart' as api;
// import '../test/canvas_demo.dart';
import '../theme/flexi_theme.dart';
import 'components/flexi_kline_draw_toolbar.dart';
import 'components/flexi_kline_indicator_bar.dart';
import 'components/flexi_kline_mark_view.dart';
import 'components/flexi_kline_setting_bar.dart';
import 'components/market_tooltip_custom_view.dart';
import 'index_page.dart';

class MyKlineDemoPage extends ConsumerStatefulWidget {
  const MyKlineDemoPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyDemoPageState();
}

class _MyDemoPageState extends ConsumerState<MyKlineDemoPage> {
  late final FlexiKlineController controller;
  late final DefaultFlexiKlineConfiguration configuration;

  late CandleReq req;
  CancelToken? cancelToken;
  bool isFullScreen = false;

  final logger = LogPrintImpl(
    debug: kDebugMode,
    tag: 'Demo',
  );

  @override
  void initState() {
    super.initState();
    const count = 500;
    const timeBar = TimeBar.D1;
    final now = DateTime.now().millisecondsSinceEpoch;
    final before = now - (now % timeBar.milliseconds);
    final after = before - count * timeBar.milliseconds;
    req = CandleReq(
      instId: 'AAPL',
      bar: timeBar.bar,
      precision: 2,
      displayName: 'Apple Inc.',
      after: after,
      before: before,
    );
    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: logger,
    );

    controller.onCrossCustomTooltip = onCrossCustomTooltip;

    controller.onLoadMoreCandles = loadMoreCandles;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initKlineData(req);
    });
  }

  /// 初始化加载K线蜡烛数据.
  Future<void> initKlineData(CandleReq request) async {
    controller.switchKlineData(request);
    List<CandleModel>? list;

    // list = await genRandomCandleList(
    //   count: 500,
    //   bar: request.timeBar!,
    // );

    // list = genETHUSDT1DLimit100List();

    final resp = await api.getHistoryKlineData(
      request,
      cancelToken: cancelToken = CancelToken(),
    );
    if (resp.success) {
      list = resp.data;
    } else {
      SmartDialog.showToast(resp.msg);
    }

    await controller.updateKlineData(request, list ?? const []);
    emitLatestMarketCandle();
  }

  Future<void> loadMoreCandles(CandleReq request) async {
    // // await Future.delayed(const Duration(milliseconds: 2000)); // 模拟延时, 展示loading
    // final resp = await api.getHistoryKlineData(
    //   request,
    //   cancelToken: cancelToken = CancelToken(),
    // );
    // cancelToken = null;
    // if (resp.success && resp.data != null && resp.data!.isNotEmpty) {
    //   await controller.updateKlineData(request, resp.data!);
    // } else if (resp.msg.isNotEmpty) {
    //   SmartDialog.showToast(resp.msg);
    // }
  }

  /// 当crossing时, 自定义Tooltip
  List<TooltipInfo>? onCrossCustomTooltip(
    CandleModel? current, {
    CandleModel? prev,
  }) {
    if (current == null) {
      ref.read(marketCandleProvider.notifier).emitOnCross(null);
      // Cross事件取消了, 更新行情为最新一根蜡烛数据.
      emitLatestMarketCandle();
      return [];
    }

    final candle = current.clone()..confirm = '';
    // 暂存振幅到candle的confirm中.
    if (prev != null) candle.confirm = candle.rangeRate(prev).toString();
    ref.read(marketCandleProvider.notifier).emitOnCross(candle);
    // 返回空数组, 自行定制.
    return [];
  }

  /// 更新最新的蜡烛数据到行情上.
  void emitLatestMarketCandle() {
    if (controller.curKlineData.latest != null) {
      ref.read(marketCandleProvider.notifier).emit(
            controller.curKlineData.latest!,
          );
    }
  }

  void onTapTimeBar(TimeBar bar) {
    if (bar.bar != req.bar) {
      req = req.copyWith(bar: bar.bar);
      setState(() {});
      initKlineData(req);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    ref.listen(defaultKlineThemeProvider, (previous, next) {
      if (previous != next) {
        final config = configuration.getFlexiKlineConfig(next);
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Offstage(
              offstage: req.displayName == null,
              child: Text(
                req.displayName ?? '',
                style: theme.t1s18w700,
              ),
            ),
            Text(
              req.instId,
              style: theme.t1s12w400,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarketTooltipCustomView(
              candleReq: req,
              data: controller.curKlineData.latest,
            ),
            FlexiKlineSettingBar(
              controller: controller,
              onTapTimeBar: onTapTimeBar,
            ),
            FlexiKlineWidget(
              key: const ValueKey('MyKlineDemo'),
              controller: controller,
              mainBackgroundView: FlexiKlineMarkView(
                margin: EdgeInsetsDirectional.only(bottom: 10.r, start: 10.r),
              ),
              drawToolbar: FlexiKlineDrawToolbar(
                controller: controller,
              ),
            ),
            FlexiKlineIndicatorBar(
              controller: controller,
            ),
            Container(
              height: 0.5.r,
              color: theme.dividerLine,
            ),
            // Container(
            //   height: 200.r,
            //   child: const CanvasDemo(),
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final latest = controller.curKlineData.latest;
          DateTime? dateTime;
          if (latest != null) {
            dateTime = DateTime.fromMillisecondsSinceEpoch(latest.ts);
          }
          dateTime ??= DateTime.now();

          /// 随机生成[count] 个以 [dateTime]为基准的新数据
          final newList = await genRandomCandleList(
            count: 3,
            dateTime: dateTime,
            bar: controller.curKlineData.req.timeBar!,
            isHistory: false,
          );

          controller.logd('Add $dateTime, ${req.key}, ${newList.length}');
          controller.updateKlineData(req, newList);

          emitLatestMarketCandle();
        },
        child: const Text('Add'),
      ),
    );
  }
}
