import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kline/kline.dart';

import 'mock.dart';
import 'test.dart';

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
  late final KlineController controller1;
  late final KlineController controller2;
  final CandleReq req = CandleReq(instId: 'BTC-USDT', bar: TimeBar.D1.bar);
  @override
  void initState() {
    super.initState();
    debugPrint('initState screenWidth:${ScreenUtil().screenWidth}');
    initController1();
    initController2();
  }

  void initController1() {
    controller1 = KlineController();
    controller1.setMainSize(Size(
      ScreenUtil().screenWidth,
      ScreenUtil().screenWidth * 0.75,
    ));

    genRandomCandleList(count: 500).then((list) {
      controller1.setCandleData(req, list);
    });
  }

  void initController2() {
    controller2 = KlineController();
    controller2.setMainSize(Size(
      ScreenUtil().screenWidth,
      ScreenUtil().screenWidth,
    ));

    controller2
      ..candleMaxWidth = 50
      ..candleWidth = 50;

    genCustomCandleList(count: 500).then((list) {
      controller2.setCandleData(req, list);
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
            // KlineWidget(
            //   key: const ValueKey('1'),
            //   controller: controller1,
            // ),
            SizedBox(height: 20),
            KlineWidget(
              key: const ValueKey('2'),
              controller: controller2,
            ),
            SizedBox(height: 20),
            TestBody(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // valueNotifier.value++;
          // appendCandleList(
          //   model: controller1.curCandleData.list.first,
          //   count: randomCount,
          // ).then((list) {
          //   controller1.appendCandleData(req, list);
          // });
          CandleModel newModel = controller2.curCandleData.latest!;
          newModel = newModel.copyWith(
            timestamp: DateTime.fromMillisecondsSinceEpoch(newModel.timestamp)
                .add(const Duration(days: 1))
                .millisecondsSinceEpoch,
          );
          controller2.appendCandleData(
            req,
            [newModel],
          );
        },
        child: Text('Add'),
      ),
    );
  }
}
