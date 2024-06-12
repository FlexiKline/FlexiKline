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
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import '../providers/instruments_provider.dart';
import '../providers/default_kline_config.dart';
import '../widgets/flexi_kline_indicator_bar.dart';
import '../widgets/flexi_kline_mark_view.dart';
import '../widgets/market_ticker_view.dart';
import '../widgets/flexi_kline_setting_bar.dart';
import '../widgets/select_symbol_title_view.dart';
import 'kline_page_data_update_mixin.dart';
import 'main_nav_page.dart';

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
    );

    controller.onCrossI18nTooltipLables = tooltipLables;

    controller.onLoadMoreCandles = loadMoreCandles;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initKlineData(req);
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
        title: SelectSymbolTitleView(
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarketTickerView(
                instId: req.instId,
                precision: req.precision,
              ),
              FlexiKlineSettingBar(
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
            iconSize: 16.r,
            icon: const Icon(Icons.open_in_full_rounded),
            onPressed: () {
              // TODO: 待实现
            },
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
                  alignment: request.state == RequestState.initLoading
                      ? AlignmentDirectional.center
                      : AlignmentDirectional.centerStart,
                  padding: EdgeInsetsDirectional.all(32.r),
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
              );
            },
          ),
        )
      ],
    );
  }
}