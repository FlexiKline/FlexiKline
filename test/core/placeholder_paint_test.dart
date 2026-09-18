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

/// 数据未就绪那一帧的 `paintPlaceholder` 编排。
///
/// 观察点是各绘制入口的**调用序列**（由 [TestAnimatedIndicator] 的共享 sink 收集），因为这条
/// 路径上三件事只会「行为错、不报错」：
///
/// - **加载态与正常态互斥**：接到 `doPaintChart` 上会让假设数据就绪的 `paint` 实现拿到空数据。
/// - **主区子指标必须被问到**：主区容器自己不画东西，少了 `MainPaintDelegateExt` 的覆写，通用
///   实现只问到容器，主区指标在加载态永远没有落笔机会——画面上什么都没有，但不报错。
/// - **主区先于副区**：与网格线同序，副区要对齐的 dx 由主区产出。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'PLACEHOLDER', interval: FlexiTimeInterval(1, TimeUnit.day));
const _canvasWidth = 400.0;

const _mainKey = ExternalIndicatorKey('placeholder-main');
const _subKey = ExternalIndicatorKey('placeholder-sub');

void main() {
  /// 主区、副区各挂一个动画指标，两者共享 [sink] 以便断言跨 pane 的先后。
  ///
  /// [candles] 为空即加载态（`canPaintChart` 为 false）。
  Future<({ControllerScenario scene, List<String> sink})> arrange(
    WidgetTester tester, {
    required List<CandleModel> candles,
  }) async {
    final sink = <String>[];
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      candles,
      canvasWidth: _canvasWidth,
      mainIndicators: [TestAnimatedIndicator(key: _mainKey, name: 'main', sink: sink)],
      subIndicators: [TestAnimatedIndicator(key: _subKey, name: 'sub', sink: sink)],
    );
    scene.controller.flushPendingKlineData();
    return (scene: scene, sink: sink);
  }

  /// 驱动一帧 chart 绘制。
  ///
  /// 冲帧用 `pumpWidget`：绘制排下的 post-frame 回调自己不 `scheduleFrame`，没有 widget 树时
  /// `pump()` 不产生真帧，回调会活到本用例 dispose 之后、在下一个用例的首帧里炸。
  Future<void> paintFrame(WidgetTester tester, FlexiKlineController chart) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  group('v2.5.0/加载态占位绘制', () {
    testWidgets('数据未就绪: 主区与副区都走 placeholder, 都不走 paint', (tester) async {
      final (scene: scene, sink: sink) = await arrange(tester, candles: const []);

      await paintFrame(tester, scene.controller);

      // 前提在绘制之后断言: `canPaintChart` 读的区间由 `paintChart` 内的
      // `calculatePaintChartRange` 写入, 绘制之前它恒为初始的无效值。
      expect(scene.controller.klineData.canPaintChart, isFalse, reason: '前提: 处于加载态');
      expect(sink, contains('main.placeholder'));
      expect(sink, contains('sub.placeholder'));
      expect(sink.where((c) => c.endsWith('.paint')), isEmpty);
    });

    testWidgets('数据就绪: 走 paint, 不走 placeholder', (tester) async {
      final (scene: scene, sink: sink) = await arrange(tester, candles: genFlatCandleList());

      await paintFrame(tester, scene.controller);

      expect(scene.controller.klineData.canPaintChart, isTrue, reason: '前提: 数据已就绪');
      expect(sink, contains('main.paint'));
      expect(sink, contains('sub.paint'));
      expect(sink.where((c) => c.endsWith('.placeholder')), isEmpty);
    });

    testWidgets('加载态: 主区占位早于副区', (tester) async {
      final (scene: scene, sink: sink) = await arrange(tester, candles: const []);

      await paintFrame(tester, scene.controller);

      // 先确认两者都到场再比先后: `indexOf` 缺失时返回 -1, 光比大小会让「主区根本没被问到」
      // 这种更严重的错误静默通过。
      expect(sink, containsAll(<String>['main.placeholder', 'sub.placeholder']));
      expect(
        sink.indexOf('main.placeholder'),
        lessThan(sink.indexOf('sub.placeholder')),
        reason: '与网格线同序: 副区要对齐的 dx 由主区产出',
      );
    });

    testWidgets('加载态: 副区占位晚于自己的网格线', (tester) async {
      // 占位压在网格之上, 与正常态 doPaintChart 内部「网格线是本 pane 第一笔」一致。
      final (scene: scene, sink: sink) = await arrange(tester, candles: const []);

      await paintFrame(tester, scene.controller);

      expect(sink, containsAll(<String>['sub.gridLines', 'sub.placeholder']));
      expect(sink.indexOf('sub.gridLines'), lessThan(sink.indexOf('sub.placeholder')));
    });

    testWidgets('加载态每帧都问一次, 不是只在首帧', (tester) async {
      final (scene: scene, sink: sink) = await arrange(tester, candles: const []);

      await paintFrame(tester, scene.controller);
      await paintFrame(tester, scene.controller);

      expect(sink.where((c) => c == 'main.placeholder').length, 2);
      expect(sink.where((c) => c == 'sub.placeholder').length, 2);
    });
  });
}
