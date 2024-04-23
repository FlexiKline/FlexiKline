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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../config.dart';
import '../repo/mock.dart';
import '../test/canvas_test.dart';
import '../widgets/time_bar.dart';
import 'main_nav_page.dart';

class MyDemoPage extends ConsumerStatefulWidget {
  const MyDemoPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyDemoPageState();
}

class _MyDemoPageState extends ConsumerState<MyDemoPage> {
  late final FlexiKlineController controller1;
  late final FlexiKlineController controller2;

  final req1 = CandleReq(
    instId: 'BTC-USDT',
    bar: TimeBar.m15.bar,
    precision: 4,
  );

  final CandleReq req2 = CandleReq(
    instId: 'BTC-USDT-SWAP',
    bar: TimeBar.D1.bar,
    precision: 4,
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
    initController1();
    initController2();
  }

  void onTapTimeBar1(TimeBar value) {
    req1.bar = value.bar;
    Future.delayed(const Duration(seconds: 3), () {
      controller1.setKlineData(req1, [
        // TODO: 测试代码.
      ]);
    });
  }

  void initController1() {
    controller1 = FlexiKlineController(
      logger: LogPrintImpl(
        debug: kDebugMode,
        tag: 'Demo1',
      ),
    );
    controller1.setMainSize(Size(
      ScreenUtil().screenWidth,
      300,
    ));
    genLocalCandleList().then((list) {
      controller1.setKlineData(req1, list);
    });
  }

  // void onTapTimeBar2(TimeBar value) {
  //   req2.bar = value.bar;
  //   Future.delayed(const Duration(seconds: 3), () {
  //     controller2.setKlineData(req2, [
  //       // TODO: 测试代码.
  //     ]);
  //   });
  // }

  void initController2() {
    controller2 = FlexiKlineController(
      logger: LogPrintImpl(
        debug: kDebugMode,
        tag: 'Demo2',
      ),
    );
    controller2.setMainSize(Size(
      ScreenUtil().screenWidth,
      ScreenUtil().screenWidth,
    ));

    controller2
      ..candleMaxWidth = 30
      ..candleWidth = 8;

    genCustomCandleList(count: 500).then((list) {
      controller2.setKlineData(req2, list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          children: [
            FlexiTimeBar(
              timeBars: timBarList,
              currTimeBar: req1.timerBar,
              onTapTimeBar: onTapTimeBar1,
            ),
            FlexiKlineWidget(
              key: const ValueKey('1'),
              controller: controller1,
            ),
            Container(
              height: 20,
              color: theme.dividerColor,
            ),
            // KlineWidget(
            //   key: const ValueKey('2'),
            //   controller: controller2,
            // ),
            // SizedBox(height: 20),
            // GestureTest(),
            TestBody(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CandleModel newModel = controller1.curKlineData.latest!;
          newModel = newModel.copyWith(
            timestamp: DateTime.fromMillisecondsSinceEpoch(newModel.timestamp)
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          );
          controller1.appendKlineData(
            req1,
            [newModel],
          );
        },
        child: const Text('Add'),
      ),
    );
  }
}
