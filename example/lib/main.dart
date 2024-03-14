import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kline/kline.dart';

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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  @override
  void initState() {
    super.initState();
    controller = KlineController();

    controller.addCandle(model);
  }

  CandleModel model = CandleModel.fromJson({
    "open": "1",
    "close": "2",
    "high": "3",
    "low": "4",
    "volume": "5",
    "date": DateTime.now().millisecondsSinceEpoch,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
          ),
          body: Center(
            child: KlineWidget(
              controller: controller,
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              valueNotifier.value++;
              controller.addCandle(CandleModel.fromJson({
                "open": "11",
                "close": "22",
                "high": "33",
                "low": "44",
                "volume": "55",
                "date": DateTime.now().millisecondsSinceEpoch,
              }));
            },
            child: Text('Add'),
          ),
        );
      },
    );
  }
}
