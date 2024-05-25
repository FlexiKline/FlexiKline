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

import 'package:example/generated/l10n.dart';
import 'package:example/src/theme/flexi_theme.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../providers/ok_kline_provider.dart';
import '../repo/mock.dart';
import '../test/canvas_demo.dart';
import '../widgets/flexi_indicator_bar.dart';
import '../widgets/flexi_time_bar.dart';
import 'main_nav_page.dart';

class MyDemoPage extends ConsumerStatefulWidget {
  const MyDemoPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyDemoPageState();
}

class _MyDemoPageState extends ConsumerState<MyDemoPage> {
  late final FlexiKlineController controller1;

  Map<TooltipLabel, String> tooltipLables() {
    return {
      TooltipLabel.time: S.current.tooltipTime,
      TooltipLabel.open: S.current.tooltipOpen,
      TooltipLabel.high: S.current.tooltipHigh,
      TooltipLabel.low: S.current.tooltipLow,
      TooltipLabel.close: S.current.tooltipClose,
      TooltipLabel.chg: S.current.tooltipChg,
      TooltipLabel.chgRate: S.current.tooltipChgRate,
      TooltipLabel.range: S.current.tooltipRange,
      TooltipLabel.amount: S.current.tooltipAmount,
      TooltipLabel.turnover: S.current.tooltipTurnover,
    };
  }

  final req1 = CandleReq(
    instId: 'BTC-USDT',
    bar: TimeBar.m15.bar,
    precision: 2,
  );

  final List<TimeBar> timBarList = const [
    TimeBar.m15,
    TimeBar.H1,
    TimeBar.H4,
    TimeBar.D1
  ];

  @override
  void initState() {
    super.initState();

    controller1 = FlexiKlineController(
      configuration: OkFlexiKlineConfiguration(),
      logger: LogPrintImpl(
        debug: kDebugMode,
        tag: 'Demo1',
      ),
    );

    controller1.onCrossI18nTooltipLables = tooltipLables;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      loadCandleData1(req1);
    });
  }

  Future<void> loadCandleData1(CandleReq request) async {
    try {
      controller1.startLoading(request, useCacheFirst: true);
      genRandomCandleList(count: 300, bar: request.timeBar!).then((list) {
        controller1.setKlineData(request, list);
      });
    } finally {
      controller1.stopLoading();
    }
  }

  void onTapTimeBar(TimeBar value) {
    req1.bar = value.bar;
    setState(() {});
    loadCandleData1(req1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.read(themeProvider);
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
              controller: controller1,
              onTapTimeBar: onTapTimeBar,
            ),
            FlexiKlineWidget(
              key: const ValueKey('Kline1'),
              controller: controller1,
            ),
            FlexiIndicatorBar(
              controller: controller1,
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
          final latest = controller1.curKlineData.latest;
          DateTime dateTime;
          if (latest != null) {
            dateTime = DateTime.fromMillisecondsSinceEpoch(latest.timestamp)
                .add(Duration(
              milliseconds: controller1.curKlineData.req.timeBar!.milliseconds,
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
          controller1.appendKlineData(req1, newList);
        },
        child: const Text('Add'),
      ),
    );
  }
}
