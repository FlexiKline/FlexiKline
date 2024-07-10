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
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../config.dart';
import '../providers/default_kline_config.dart';
import '../repo/mock.dart';
import 'components/flexi_kline_indicator_bar.dart';
import 'components/flexi_kline_mark_view.dart';
import 'components/flexi_kline_setting_bar.dart';

class AccurateKlineDemoPage extends ConsumerStatefulWidget {
  const AccurateKlineDemoPage({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AccurateKlinePageState();
}

class _AccurateKlinePageState extends ConsumerState<AccurateKlineDemoPage> {
  late final FlexiKlineController controller1;
  late final FlexiKlineController controller2;
  late final DefaultFlexiKlineConfiguration configuration;

  late CandleReq req1;
  late CandleReq req2;

  final logger = LogPrintImpl(
    debug: kDebugMode,
    tag: 'Demo',
  );

  @override
  void initState() {
    super.initState();
    req1 = CandleReq(
      instId: 'SATS-USDT',
      bar: TimeBar.H1.bar,
      precision: 33,
      displayName: 'Sats',
    );
    req2 = CandleReq(
      instId: 'SATS-USDT',
      bar: TimeBar.H1.bar,
      precision: 4,
      displayName: 'Sats',
    );
    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller1 = FlexiKlineController(
      configuration: configuration,
      logger: logger,
    );
    // controller1.computeMode = ComputeMode.accurate;
    controller2 = FlexiKlineController(
      configuration: configuration,
      logger: logger,
    );

    controller1.onLoadMoreCandles = loadMoreCandles;
    controller2.onLoadMoreCandles = loadMoreCandles;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initKlineData1(req1);
      initKlineData2(req2);
    });
  }

  /// 初始化加载K线蜡烛数据.
  Future<void> initKlineData1(CandleReq request) async {
    controller1.switchKlineData(request);
    final list = await genLocalMinusculeCandleList();
    await controller1.updateKlineData(request, list);
  }

  /// 初始化加载K线蜡烛数据.
  Future<void> initKlineData2(CandleReq request) async {
    controller2.switchKlineData(request);
    final list = await genLocalCandleList();
    await controller2.updateKlineData(request, list);
  }

  Future<void> loadMoreCandles(CandleReq request) async {
    SmartDialog.showToast('This is a simulation operation!');
  }

  void onTapTimeBar1(TimeBar bar) {
    if (bar.bar != req1.bar) {
      req1 = req1.copyWith(bar: bar.bar);
      setState(() {});
      initKlineData1(req1);
    }
  }

  void onTapTimeBar2(TimeBar bar) {
    if (bar.bar != req2.bar) {
      req2 = req2.copyWith(bar: bar.bar);
      setState(() {});
      initKlineData2(req2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return Scaffold(
      backgroundColor: theme.pageBg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Fast Vs Accurate'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlexiKlineSettingBar(
              controller: controller1,
              onTapTimeBar: onTapTimeBar1,
            ),
            FlexiKlineWidget(
              key: const ValueKey('accurateKline'),
              controller: controller1,
              mainBackgroundView: FlexiKlineMarkView(
                margin: EdgeInsetsDirectional.only(bottom: 10.r, start: 10.r),
              ),
            ),
            FlexiKlineIndicatorBar(
              controller: controller1,
            ),
            Container(
              height: 20.r,
              color: theme.dividerLine,
            ),
            FlexiKlineSettingBar(
              controller: controller2,
              onTapTimeBar: onTapTimeBar2,
            ),
            FlexiKlineWidget(
              key: const ValueKey('fastKline'),
              controller: controller2,
              mainBackgroundView: FlexiKlineMarkView(
                margin: EdgeInsetsDirectional.only(bottom: 10.r, start: 10.r),
              ),
            ),
            FlexiKlineIndicatorBar(
              controller: controller2,
            ),
            Container(
              height: 80.r,
              color: theme.dividerLine,
            ),
          ],
        ),
      ),
    );
  }
}
