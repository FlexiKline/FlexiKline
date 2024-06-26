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

import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import '../providers/default_kline_config.dart';
import '../providers/market_candle_provider.dart';
import '../repo/mock.dart';
import '../test/canvas_demo.dart';
import 'components/flexi_kline_indicator_bar.dart';
import 'components/flexi_kline_mark_view.dart';
import 'components/flexi_kline_setting_bar.dart';
import 'components/market_tooltip_custom_view.dart';
import 'main_nav_page.dart';

class MyDemoPage extends ConsumerStatefulWidget {
  const MyDemoPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyDemoPageState();
}

class _MyDemoPageState extends ConsumerState<MyDemoPage> {
  late final FlexiKlineController controller;
  late final DefaultFlexiKlineConfiguration configuration;

  late CandleReq req;

  final logger = LogPrintImpl(
    debug: kDebugMode,
    tag: 'Demo',
  );

  @override
  void initState() {
    super.initState();
    req = CandleReq(
      instId: '000001',
      bar: TimeBar.D1.bar,
      precision: 2,
      displayName: '上证指数',
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

    logger.logd('genRandomCandleList Begin ${DateTime.now()}');
    final list = await genRandomCandleList(
      count: 500,
      bar: request.timeBar!,
    );
    logger.logd('genRandomCandleList End ${DateTime.now()}');

    await controller.updateKlineData(request, list);

    emitLatestMarketCandle();
  }

  Future<void> loadMoreCandles(CandleReq request) async {
    // TODO: 待实现
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
            ),
            FlexiKlineIndicatorBar(
              controller: controller,
            ),
            Container(
              height: 2,
              color: theme.dividerLine,
            ),
            // GestureTest(),
            const CanvasDemo(),
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
