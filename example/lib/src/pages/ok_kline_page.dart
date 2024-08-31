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

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import '../indicators/avl_indicator.dart';
import '../providers/instruments_provider.dart';
import '../providers/default_kline_config.dart';
import '../theme/flexi_theme.dart';
import 'components/flexi_kline_draw_toolbar.dart';
import 'components/flexi_kline_indicator_bar.dart';
import 'components/flexi_kline_mark_view.dart';
import 'components/market_ticker_view.dart';
import 'components/flexi_kline_setting_bar.dart';
import 'components/trading_pair_select_title.dart';
import 'common/kline_page_data_update_mixin.dart';
import 'index_page.dart';

class OkKlinePage extends ConsumerStatefulWidget {
  const OkKlinePage({
    super.key,
    this.instId = 'BTC-USDT',
  });

  final String instId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _OkKlinePageState();
}

class _OkKlinePageState extends ConsumerState<OkKlinePage>
    with KlinePageDataUpdateMixin<OkKlinePage> {
  late final FlexiKlineController controller;
  late final DefaultFlexiKlineConfiguration configuration;
  bool isFullScreen = false;

  @override
  FlexiKlineController get flexiKlineController => controller;

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
    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: LoggerImpl(
        tag: "OkFlexiKline",
        debug: kDebugMode,
      ),
      klineDataCacheCapacity: 3,
    );

    final klineTheme = ref.read(defaultKlineThemeProvider);
    controller.addCustomMainIndicatorConfig(
      AVLIndicator(
        height: klineTheme.mainIndicatorHeight,
        padding: klineTheme.mainIndicatorPadding,
        line: LineConfig(
          width: 1.r,
          color: Colors.deepOrangeAccent,
          type: LineType.solid,
        ),
        tips: TipsConfig(
          label: 'AVL',
          style: TextStyle(
            color: Colors.orangeAccent,
            fontSize: klineTheme.normalTextSize,
            height: defaultTextHeight,
          ),
        ),
        tipsPadding: klineTheme.tipsPadding,
      ),
    );

    controller.onCrossI18nTooltipLables = tooltipLables;

    controller.onLoadMoreCandles = loadMoreCandles;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initKlineData(req);
    });
  }

  void setFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
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
        title: TradingPairSelectTitle(
          instId: req.instId,
          onChangeTradingPair: onChangeTradingSymbol,
        ),
        centerTitle: true,
      ),
      body: EasyRefresh(
        onRefresh: () async {
          req = req.copyWith(after: null, before: null);
          await initKlineData(req, reset: true);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isFullScreen) {
              controller.setFixedSize(
                Size(constraints.maxWidth, constraints.maxHeight - 30.r),
              );
            } else {
              controller.exitFixedSize();
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: !isFullScreen,
                    child: MarketTickerView(
                      instId: req.instId,
                      precision: req.precision,
                    ),
                  ),
                  Visibility(
                    visible: !isFullScreen,
                    child: FlexiKlineSettingBar(
                      controller: controller,
                      onTapTimeBar: onTapTimerBar,
                    ),
                  ),
                  FlexiKlineWidget(
                    controller: controller,
                    mainBackgroundView: FlexiKlineMarkView(
                      margin: EdgeInsetsDirectional.only(
                        bottom: 10.r,
                        start: 36.r,
                      ),
                    ),
                    mainForegroundViewBuilder: _buildKlineMainForgroundView,
                    onDoubleTap: setFullScreen,
                    drawToolbar: FlexiKlineDrawToolbar(
                      controller: controller,
                    ),
                  ),
                  FlexiKlineIndicatorBar(
                    height: 30.r,
                    controller: controller,
                  ),
                  Visibility(
                    visible: !isFullScreen,
                    child: Container(
                      height: 200,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('OkConfigStore'),
        heroTag: "Ok",
        backgroundColor: theme.cardBg,
        foregroundColor: theme.t1,
        mini: true,
        onPressed: () {
          // 模拟更新异常数据
          // final request = controller.curKlineData.req;
          // controller.updateKlineData(request, [
          //   CandleModel(
          //     ts: request.before! + request.timeBar!.milliseconds,
          //     o: Decimal.parse('67000'),
          //     h: Decimal.parse('70000'),
          //     l: Decimal.parse('62000'),
          //     c: Decimal.parse('63000'),
          //     v: Decimal.parse('10'),
          //   )
          // ]);
          controller.storeFlexiKlineConfig();
        },
        child: Text(
          'Store',
          style: theme.t1s14w400,
        ),
      ),
    );
  }

  /// 构建Kline前景View
  Widget _buildKlineMainForgroundView(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        /// 全屏快捷按钮
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
            icon: Icon(isFullScreen
                ? Icons.close_fullscreen_outlined
                : Icons.open_in_full_rounded),
            onPressed: setFullScreen,
          ),
        ),

        /// 回到初始位置
        Positioned(
          left: 80.r,
          right: 0,
          bottom: 8.r,
          child: ValueListenableBuilder(
            valueListenable: controller.isMoveOffScreenListener,
            builder: (context, value, child) => Offstage(
              offstage: !value,
              child: SizedBox(
                width: 28.r,
                height: 28.r,
                child: IconButton(
                  // constraints: BoxConstraints.tight(Size(28.r, 28.r)),
                  padding: EdgeInsets.zero,
                  style: theme.circleBtnStyle(
                    bg: theme.markBg.withOpacity(0.6),
                  ),
                  iconSize: 16.r,
                  icon: const Icon(Icons.keyboard_double_arrow_right_outlined),
                  onPressed: controller.moveToInitialPosition,
                ),
              ),
            ),
          ),
        ),

        /// Loading
        ValueListenableBuilder(
          valueListenable: controller.candleRequestListener,
          builder: (context, request, child) {
            return Offstage(
              offstage: !request.state.showLoading,
              child: Container(
                key: const ValueKey('loadingView'),
                alignment: request.state == RequestState.initLoading
                    ? AlignmentDirectional.center
                    : AlignmentDirectional.centerStart,
                padding: EdgeInsetsDirectional.all(32.r),
                child: SizedBox.square(
                  dimension: 28.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.r,
                    backgroundColor: theme.markBg,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.t1),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
