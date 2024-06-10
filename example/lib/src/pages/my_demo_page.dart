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
import '../repo/mock.dart';
import '../test/canvas_demo.dart';
import '../widgets/flexi_kline_indicator_bar.dart';
import '../widgets/flexi_kline_mark_view.dart';
import '../widgets/flexi_kline_setting_bar.dart';
import 'main_nav_page.dart';

class MyDemoPage extends ConsumerStatefulWidget {
  const MyDemoPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyDemoPageState();
}

class _MyDemoPageState extends ConsumerState<MyDemoPage> {
  late final FlexiKlineController controller;
  late final DefaultFlexiKlineConfiguration configuration;

  final req = CandleReq(
    instId: 'BTC-USDT',
    bar: TimeBar.D1.bar,
    precision: 2,
  );

  final logger = LogPrintImpl(
    debug: kDebugMode,
    tag: 'Demo1',
  );

  @override
  void initState() {
    super.initState();
    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: logger,
    );

    controller.onCrossI18nTooltipLables = tooltipLables;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadCandleData(req);
    });
  }

  Future<void> loadCandleData(CandleReq request) async {
    try {
      controller.startLoading(request);

      logger.logd('loadCandleData Begin ${DateTime.now()}');
      final list = await genRandomCandleList(
        count: 50000,
        bar: request.timeBar!,
      );
      logger.logd('loadCandleData End ${DateTime.now()}');

      await controller.updateKlineData(request, list);
    } finally {
      controller.stopLoading(request);
    }
  }

  void onTapTimeBar(TimeBar value) {
    req.bar = value.bar;
    loadCandleData(req);
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
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            mainNavScaffoldKey.currentState?.openDrawer();
          },
          child: const Icon(Icons.menu_outlined),
        ),
        title: const Text('MyDemo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        },
        child: const Text('Add'),
      ),
    );
  }
}
