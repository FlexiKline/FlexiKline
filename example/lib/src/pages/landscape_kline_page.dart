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

import 'package:example/src/router.dart';
import 'package:example/src/theme/export.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import '../providers/default_kline_config.dart';
import '../utils/screen_util.dart';
import '../widgets/flexi_kline_landscape_indicator_bar.dart';
import '../widgets/flexi_kline_landscape_setting_bar.dart';
import '../widgets/flexi_kline_mark_view.dart';
import '../widgets/market_ticker_landscape_view.dart';
import 'kline_page_data_update_mixin.dart';

class LandscapeKlinePage extends ConsumerStatefulWidget {
  const LandscapeKlinePage({
    super.key,
    required this.candleReq,
  });

  final CandleReq candleReq;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LandscapeKlinePageState();
}

class _LandscapeKlinePageState extends ConsumerState<LandscapeKlinePage>
    with KlinePageDataUpdateMixin<LandscapeKlinePage> {
  late final Size prevSize;
  late final FlexiKlineController controller;
  late final DefaultFlexiKlineConfiguration configuration;
  @override
  FlexiKlineController get flexiKlineController => controller;

  @override
  void initState() {
    super.initState();
    setScreenLandscape();

    req = widget.candleReq;
    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: LoggerImpl(
        tag: "OkLandscapeFlexiKline",
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
  void dispose() {
    // setScreenPortrait();
    super.dispose();
  }

  Future<void> exitPage() async {
    await setScreenPortrait();
    exit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        controller.logd('zp::: LandscapeKlinePage onPopInvoked:$didPop');
        exitPage();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.pageBg,
          leading: const SizedBox.shrink(),
          leadingWidth: 4.r,
          title: MarketTickerLandscapeView(
            instId: req.instId,
            precision: req.precision,
            long: controller.settingConfig.longColor,
            short: controller.settingConfig.shortColor,
          ),
          titleSpacing: 0,
          toolbarHeight: 30.r,
          actions: [
            GestureDetector(
              onTap: exitPage,
              child: Container(
                width: 50.r,
                height: 30.r,
                alignment: AlignmentDirectional.center,
                child: Icon(
                  Icons.fullscreen_exit_rounded,
                  size: 28.r,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size(ScreenUtil().screenWidth, 30.r),
            child: FlexiKlineLandscapeSettingBar(
              controller: controller,
              onTapTimeBar: onTapTimerBar,
            ),
          ),
        ),
        backgroundColor: theme.pageBg,
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3.r,
                  backgroundColor: theme.markBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.t1,
                  ),
                ),
              );
            }
            return _buildBodyView(context);
          },
        ),
      ),
    );
  }

  Widget _buildBodyView(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              controller.logd('zp::: LandscapeKlinePage:$constraints');
              controller.setLandCanvasSize(
                Size(constraints.maxWidth, constraints.maxHeight),
              );
              return FlexiKlineWidget(
                controller: controller,
                mainBackgroundView: FlexiKlineMarkView(
                  margin: EdgeInsetsDirectional.only(
                    bottom: 10.r,
                    start: 36.r,
                  ),
                ),
                mainforegroundViewBuilder: _buildKlineMainForgroundView,
              );
            },
          ),
        ),
        SizedBox(
          width: 50.r,
          child: Stack(
            children: [
              FlexiKlineLandscapeIndicatorBar(
                controller: controller,
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildKlineMainForgroundView(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return ValueListenableBuilder(
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
    );
  }
}
