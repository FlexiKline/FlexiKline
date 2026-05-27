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

/// FlexiKlineWidget + LayoutBuilder 最小集成测试。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_indicators.dart';
import '../helpers/test_kline_config.dart';

FlexiKlineController _createController({
  FlexiLayoutMode initialLayoutMode = FlexiLayoutMode.adapt,
  Size? initialFixedSize,
}) {
  return FlexiKlineController(
    configuration: TestFlexiKlineConfiguration(
      mainIndicatorDefaultSize: const Size(400, 300),
    ),
    initialLayoutMode: initialLayoutMode,
    initialFixedSize: initialFixedSize,
  );
}

Future<void> _pumpAwayTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('adapt: LayoutBuilder applies parent width', (tester) async {
    final controller = _createController();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 333,
            height: 480,
            child: FlexiKlineWidget(
              controller: controller,
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(controller.layoutMode, FlexiLayoutMode.adapt);
    expect(controller.mainSize.width, closeTo(333, 1.0));

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpAwayTimers(tester);
    controller.dispose();
  });

  testWidgets('fixed: LayoutBuilder applies bounded constraints', (tester) async {
    final controller = _createController(
      initialLayoutMode: FlexiLayoutMode.fixed,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 520,
            child: FlexiKlineWidget(
              controller: controller,
              candle: TestCandleIndicator(),
              time: TestTimeIndicator(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(controller.fixedSize, isNotNull);
    expect(controller.canvasRect.width, closeTo(360, 1.0));
    expect(controller.canvasRect.height, closeTo(520, 1.0));

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpAwayTimers(tester);
    controller.dispose();
  });

  testWidgets('fixed: scrollable parent uses initialFixedSize height', (tester) async {
    final controller = _createController(
      initialLayoutMode: FlexiLayoutMode.fixed,
      initialFixedSize: const Size(320, 420),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 600,
            child: ListView(
              children: [
                FlexiKlineWidget(
                  controller: controller,
                  candle: TestCandleIndicator(),
                  time: TestTimeIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(controller.fixedSize, equals(const Size(360, 420)));
    expect(controller.canvasRect.size, equals(const Size(360, 420)));

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpAwayTimers(tester);
    controller.dispose();
  });
}
