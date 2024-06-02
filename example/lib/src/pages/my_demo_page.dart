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

import 'dart:math' as math;

import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../providers/default_flexi_kline_config.dart';
import '../repo/mock.dart';
import '../test/canvas_demo.dart';
import '../widgets/flexi_indicator_bar.dart';
import '../widgets/flexi_kline_mark_view.dart';
import '../widgets/flexi_time_bar.dart';
import 'main_nav_page.dart';

class MyDemoPage extends ConsumerStatefulWidget {
  const MyDemoPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyDemoPageState();
}

class _MyDemoPageState extends ConsumerState<MyDemoPage> {
  late final FlexiKlineController controller;
  late final DefaultFlexiKlineConfiguration configuration;

  final req1 = CandleReq(
    instId: 'BTC-USDT',
    bar: TimeBar.m15.bar,
    precision: 2,
  );

  @override
  void initState() {
    super.initState();
    configuration = DefaultFlexiKlineConfiguration(ref: ref);
    controller = FlexiKlineController(
      configuration: configuration,
      logger: LogPrintImpl(
        debug: kDebugMode,
        tag: 'Demo1',
      ),
    );

    controller.onCrossI18nTooltipLables = tooltipLables;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadCandleData1(req1);
    });
  }

  Future<void> loadCandleData1(CandleReq request) async {
    try {
      controller.startLoading(request, useCacheFirst: true);

      Future<List<CandleModel>> getCandleData(TimeBar timeBar) async =>
          await genRandomCandleList(
            count: 500,
            bar: timeBar,
          );
      final list = await compute(getCandleData, request.timeBar!);

      controller.setKlineData(request, list);
      setState(() {});
    } finally {
      controller.stopLoading();
    }
  }

  void onTapTimeBar(TimeBar value) {
    req1.bar = value.bar;
    loadCandleData1(req1);
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
            FlexiTimeBar(
              controller: controller,
              onTapTimeBar: onTapTimeBar,
            ),
            FlexiKlineWidget(
              key: const ValueKey('MyKlineDemo'),
              controller: controller,
              mainBackgroundView: const FlexiKlineMarkView(),
            ),
            FlexiIndicatorBar(
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
          DateTime dateTime;
          if (latest != null) {
            dateTime = DateTime.fromMillisecondsSinceEpoch(latest.timestamp)
                .add(Duration(
              milliseconds: controller.curKlineData.req.timeBar!.milliseconds,
            ));
          } else {
            dateTime = DateTime.now();
          }

          /// 随机生成[count] 个以 [dateTime]为基准的新数据
          final newList = await genRandomCandleList(
            count: math.Random().nextInt(3),
            dateTime: dateTime,
            isHistory: false,
          );
          controller.appendKlineData(req1, newList);
        },
        child: const Text('Add'),
      ),
    );
  }
}
