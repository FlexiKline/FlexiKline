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
  late final KlineController controller;
  final CandleReq req = CandleReq(instId: 'BTC-USDT', bar: '1d');
  @override
  void initState() {
    super.initState();
    controller = KlineController();
    controller
      ..setMainSize(Size(
        ScreenUtil().screenWidth,
        ScreenUtil().screenWidth,
      ))
      ..candleWidth = 7;

    genRandomCandleList(count: 100).then((list) {
      controller.setCandleData(req, list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: KlineWidget(
          controller: controller,
        ),
        // child: TestBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          valueNotifier.value++;
          appendCandleList(
            model: controller.curCandleData.list.first,
            count: randomCount,
          ).then((list) {
            controller.appendCandleData(req, list);
          });
        },
        child: Text('Add'),
      ),
    );
  }
}