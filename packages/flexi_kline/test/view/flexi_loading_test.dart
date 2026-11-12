// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Loading 容器：只负责按加载状态显隐业务传入的指示器。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'LOADING',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

const _indicator = SizedBox(key: ValueKey('indicator'), width: 10, height: 10);

Future<void> _pumpLoading(WidgetTester tester, FlexiKlineController controller) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: FlexiLoading(controller: controller, child: _indicator),
    ),
  );
}

void main() {
  testWidgets('加载中展示传入的指示器, 加载结束后隐藏', (tester) async {
    final controller = createChartController();
    addTearDown(() => disposeChart(tester, controller));

    controller.updateSettingConfig((config) => config.copyWith(autoLoadMoreData: true));
    controller.switchKlineData(_spec);
    await _pumpLoading(tester, controller);
    expect(find.byKey(_indicator.key!), findsOneWidget);

    controller.stopLoading(spec: _spec);
    await tester.pump();
    expect(find.byKey(_indicator.key!), findsNothing);
  });

  testWidgets('autoLoadMoreData 关闭时加载中也不展示', (tester) async {
    final controller = createChartController();
    addTearDown(() => disposeChart(tester, controller));

    controller.updateSettingConfig((config) => config.copyWith(autoLoadMoreData: false));
    controller.switchKlineData(_spec);
    await _pumpLoading(tester, controller);

    expect(find.byKey(_indicator.key!), findsNothing);
  });

  testWidgets('未传 child 时展示默认文字提示', (tester) async {
    final controller = createChartController();
    addTearDown(() => disposeChart(tester, controller));

    controller.updateSettingConfig((config) => config.copyWith(autoLoadMoreData: true));
    controller.switchKlineData(_spec);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FlexiLoading(controller: controller),
      ),
    );

    expect(find.text('Loading…'), findsOneWidget);
  });

  testWidgets('FlexiKlineWidget 未传 loadingBuilder 时使用默认 FlexiLoading', (tester) async {
    final scene = await pumpChartInListView(
      tester,
      spec: _spec,
      candles: [CandleModel(timestamp: 60000, open: 1, high: 1, low: 1, close: 1, volume: 1)],
    );
    addTearDown(() => disposeChart(tester, scene.chart));

    expect(find.byType(FlexiLoading), findsOneWidget);
  });
}
