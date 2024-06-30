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
import 'package:example/generated/l10n.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../config.dart';
import '../constants/images.dart';
import '../providers/bit_kline_config.dart';
import '../providers/instruments_provider.dart';
import '../theme/flexi_theme.dart';
import 'components/flexi_kline_indicator_bar.dart';
import 'components/flexi_kline_mark_view.dart';
import 'components/market_ticker_view.dart';
import 'components/flexi_kline_setting_bar.dart';
import 'components/trading_pair_select_title.dart';
import 'common/kline_page_data_update_mixin.dart';
import 'index_page.dart';

class BitKlinePage extends ConsumerStatefulWidget {
  const BitKlinePage({
    super.key,
    this.instId = 'BTC-USDT',
  });

  final String instId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BitKlinePageState();
}

class _BitKlinePageState extends ConsumerState<BitKlinePage>
    with KlinePageDataUpdateMixin<BitKlinePage> {
  late final FlexiKlineController controller;
  late final BitFlexiKlineConfiguration configuration;

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
    configuration = BitFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: LoggerImpl(
        tag: "BitFlexiKline",
        debug: kDebugMode,
      ),
    );

    controller.onCrossCustomTooltip = onCrossCustomTooltip;

    controller.onLoadMoreCandles = loadMoreCandles;

    controller.onDoubleTap = openLandscapePage;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initKlineData(req);
    });
  }

  Future<void> openLandscapePage() async {
    controller.storeFlexiKlineConfig();
    final isUpdate = await context.pushNamed(
      'landscapeKline',
      extra: {
        "candleReq": controller.curKlineData.req.toInitReq(),
        "configuration": controller.configuration,
      },
    );
    if (mounted && isUpdate == true) {
      controller.logd('openLandscapePage return isUpdate> $isUpdate');
      final landConfig = controller.configuration.getFlexiKlineConfig();
      controller.updateFlexiKlineConfig(landConfig);
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
        title: TradingPairSelectTitle(
          instId: req.instId,
          onChangeTradingPair: onChangeTradingSymbol,
          long: klineTheme.long,
          short: klineTheme.short,
        ),
        centerTitle: true,
      ),
      body: EasyRefresh(
        onRefresh: () async {
          req = req.copyWith(after: null, before: null);
          // reset = false: 下拉刷新不清理当前数据, 等新数据回来后再更新.
          await initKlineData(req, reset: false);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                mainBackgroundView: const FlexiKlineMarkView(
                  alignment: AlignmentDirectional.center,
                  showLogo: false,
                ),
                mainforegroundViewBuilder: _buildKlineMainForgroundView,
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
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('BitConfigStore'),
        heroTag: "Bit",
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

  /// Custom Kline Forground UI
  Widget _buildKlineMainForgroundView(BuildContext context) {
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
            iconSize: 20.r,
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: openLandscapePage,
          ),
        ),
        Positioned(
          child: ValueListenableBuilder(
            valueListenable: controller.candleRequestListener,
            builder: (context, request, child) {
              return Offstage(
                offstage: !request.state.showLoading,
                child: Container(
                  key: const ValueKey('loadingView'),
                  alignment: AlignmentDirectional.center,
                  padding: EdgeInsetsDirectional.all(32.r),
                  child: SizedBox.square(
                    dimension: controller.settingConfig.loading.size,
                    child: CircularProgressIndicator(
                      strokeWidth: controller.settingConfig.loading.strokeWidth,
                      backgroundColor:
                          controller.settingConfig.loading.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        controller.settingConfig.loading.valueColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  List<TooltipInfo>? onCrossCustomTooltip(
    CandleModel? current, {
    CandleModel? prev,
  }) {
    if (current == null) return [];
    final s = S.of(context);
    final klineTheme = ref.read(bitFlexiKlineThemeProvider);
    final lableStyle = TextStyle(color: klineTheme.textColor, fontSize: 10.sp);
    final valueStyle = TextStyle(color: klineTheme.textColor, fontSize: 10.sp);
    final valStyle = current.isLong
        ? TextStyle(color: klineTheme.long, fontSize: 10.sp)
        : TextStyle(color: klineTheme.short, fontSize: 10.sp);
    final p = req.precision;
    return <TooltipInfo>[
      TooltipInfo(
        label: s.tooltipTime,
        labelStyle: lableStyle,
        value: current.formatDateTimeByTimeBar(req.timeBar),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipOpen,
        labelStyle: lableStyle,
        value: formatPrice(current.o, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipHigh,
        labelStyle: lableStyle,
        value: formatPrice(current.h, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipLow,
        labelStyle: lableStyle,
        value: formatPrice(current.l, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipClose,
        labelStyle: lableStyle,
        value: formatPrice(current.c, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipAmount,
        labelStyle: lableStyle,
        value: formatPrice(current.v, precision: p, showThousands: true),
        valueStyle: valueStyle,
      ),
      TooltipInfo(
        label: s.tooltipChg,
        labelStyle: lableStyle,
        value: formatPrice(current.change, precision: p, showThousands: true),
        valueStyle: valStyle,
      ),
      TooltipInfo(
        label: s.tooltipChgRate,
        labelStyle: lableStyle,
        value: formatPercentage(current.changeRate),
        valueStyle: valStyle,
      ),
      TooltipInfo(
        label: s.tooltipRange,
        labelStyle: lableStyle,
        value: prev != null
            ? formatPercentage(current.rangeRate(prev))
            : formatPrice(current.range, precision: p),
        valueStyle: valStyle,
      ),
    ];
  }
}
