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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flexi_kline/flexi_kline.dart';

import 'mock.dart';
import 'src/gesture_test.dart';
import 'src/canvas_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MyHomePage(title: 'Flutter Demo Home Page'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FlexiKlineController controller1;
  late final FlexiKlineController controller2;
  final CandleReq req = CandleReq(
    instId: 'BTC-USDT',
    bar: TimeBar.D1.bar,
    precision: 4,
  );
  @override
  void initState() {
    super.initState();
    debugPrint('initState screenWidth:${ScreenUtil().screenWidth}');
    initController1();
    initController2();
  }

  void initController1() {
    controller1 = FlexiKlineController(debug: true);
    controller1.setMainSize(Size(
      ScreenUtil().screenWidth,
      300,
    ));

    // genRandomCandleList(count: 500).then((list) {
    //   controller1.setKlineData(req, list);
    // });
    genLocalCandleList().then((list) {
      final req = CandleReq(
        instId: 'BTC-USDT-SWAP',
        bar: TimeBar.m15.bar,
        precision: 4,
      );
      controller1.setKlineData(req, list);
    });
  }

  void initController2() {
    controller2 = FlexiKlineController(debug: false);
    controller2.setMainSize(Size(
      ScreenUtil().screenWidth,
      ScreenUtil().screenWidth,
    ));

    controller2
      ..candleMaxWidth = 30
      ..candleWidth = 8;

    genCustomCandleList(count: 500).then((list) {
      controller2.setKlineData(req, list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FlexiKlineWidget(
              key: const ValueKey('1'),
              controller: controller1,
            ),
            SizedBox(height: 20),
            // KlineWidget(
            //   key: const ValueKey('2'),
            //   controller: controller2,
            // ),
            // SizedBox(height: 20),
            // GestureTest(),
            // TestBody(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // valueNotifier.value++;
          // appendCandleList(
          //   model: controller1.curKlineData.list.first,
          //   count: randomCount,
          // ).then((list) {
          //   controller1.appendKlineData(req, list);
          // });
          CandleModel newModel = controller2.curKlineData.latest!;
          newModel = newModel.copyWith(
            timestamp: DateTime.fromMillisecondsSinceEpoch(newModel.timestamp)
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          );
          controller2.appendKlineData(
            req,
            [newModel],
          );
        },
        child: Text('Add'),
      ),
    );
  }
}
