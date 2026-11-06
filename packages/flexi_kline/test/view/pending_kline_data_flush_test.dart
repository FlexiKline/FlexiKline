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

/// 挂载前已到达的数据在 [FlexiKlineWidget] 挂载时的处理。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

void main() {
  // 复现宿主的布局：监听 spec 的兄弟组件先构建，图表在另一个父组件的 build 中才挂载
  // （如横屏页的 AppBar 标题与 OrientationBuilder 里的图表）。
  Widget host(FlexiKlineController controller, {required bool showChart, required List<KlineSpec> seen}) {
    return MaterialApp(
      home: Column(
        children: [
          ValueListenableBuilder<KlineSpec>(
            valueListenable: controller.klineSpecListenable,
            builder: (context, spec, _) {
              seen.add(spec);
              return Text(spec.symbol);
            },
          ),
          Expanded(
            child: Builder(
              builder: (context) => showChart
                  ? FlexiKlineWidget(controller: controller, candle: TestCandleIndicator(), time: TestTimeIndicator())
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  testWidgets('挂载前到达的数据不在 build 阶段通知监听者，挂载后照常生效', (tester) async {
    final controller = createChartController();
    const spec = KlineSpec(symbol: 'BTCUSDT', interval: FlexiTimeInterval(1, TimeUnit.minute));
    final seen = <KlineSpec>[];
    controller.switchKlineData(spec);

    await tester.pumpWidget(host(controller, showChart: false, seen: seen));
    controller.replaceKlineData(spec, genFlatCandleList(count: 50));

    await tester.pumpWidget(host(controller, showChart: true, seen: seen));
    expect(tester.takeException(), isNull);
    await pumpUntilChart(tester, () => controller.klineData.isNotEmpty, 'pending data flushed');

    await tester.pump();
    expect(seen.last, controller.klineData.spec, reason: '监听者收到合并后的 spec');
    expect(controller.klineData.length, 50);

    await disposeChart(tester, controller);
  });
}
