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

/// 绘制磁吸单测: 单点吸附 `magneticSnap` 与整体平移后的对齐 `magneticShift`。
///
/// 覆盖层级: controller 的绘制入口与 DrawContext 扩展。
/// 不覆盖: 手势识别与 Widget 坐标转换。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart' show Canvas, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'DRAW-MAGNET', interval: FlexiTimeInterval(1, TimeUnit.minute));

void main() {
  late FlexiKlineController chart;

  /// 蜡烛 OHLC 恒为 100 / 110 / 90 / 105。
  Future<void> arrange(WidgetTester tester) async {
    chart = FlexiKlineController(
      configuration: FakeFlexiKlineConfiguration(enableDraw: true, shareConfigInstance: true),
    );
    registerTestDrawObject(chart);
    final scene = ControllerScenario(controller: chart);
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: 400,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    chart.flushPendingKlineData();
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  double dyOf(num value) => chart.valueToDy(FlexiNum.fromNum(value));

  /// 可视区内靠近最新端的一根。
  const index = 197;

  group('magneticSnap', () {
    testWidgets('normal 不吸附', (tester) async {
      await arrange(tester);
      final offset = Offset(chart.indexToDx(index) + 2, dyOf(107));

      expect(chart.magneticSnap(offset), offset);
    });

    testWidgets('strong 吸到所在蜡烛中心与最近的 OHLC 价位', (tester) async {
      await arrange(tester);
      chart.setDrawMagnetMode(MagnetMode.strong);
      final dx = chart.indexToDx(index);

      expect(chart.magneticSnap(Offset(dx + 2, dyOf(150))), Offset(dx, dyOf(110)), reason: '高于 high 吸到 high');
      expect(chart.magneticSnap(Offset(dx - 2, dyOf(60))), Offset(dx, dyOf(90)), reason: '低于 low 吸到 low');
      expect(chart.magneticSnap(Offset(dx, dyOf(106))), Offset(dx, dyOf(105)), reason: '实体内吸到最近的 close');
      expect(chart.magneticSnap(Offset(dx, dyOf(96))), Offset(dx, dyOf(100)), reason: '下影线内吸到最近的 open');
    });

    testWidgets('weak 只在 magnetMinDistance 内吸附纵轴, 横轴照常吸到中心', (tester) async {
      await arrange(tester);
      chart.setDrawMagnetMode(MagnetMode.weak);
      final dx = chart.indexToDx(index);
      final minDistance = chart.drawConfig.magnetMinDistance;

      final near = dyOf(110) - minDistance / 2;
      expect(chart.magneticSnap(Offset(dx + 2, near)), Offset(dx, dyOf(110)));

      // low 与 open 正中: 到两者距离相同且都超出吸附距离。
      final middle = (dyOf(90) + dyOf(100)) / 2;
      expect(dyOf(90) - middle, greaterThan(minDistance), reason: '前置: 中点须超出吸附距离');
      expect(chart.magneticSnap(Offset(dx + 2, middle)), Offset(dx, middle));
    });

    testWidgets('空白区横轴吸到外推的蜡烛格, 纵轴不吸', (tester) async {
      await arrange(tester);
      chart.setDrawMagnetMode(MagnetMode.strong);
      final blank = chart.klineData.length + 1;
      final offset = Offset(chart.indexToDx(blank) + 2, dyOf(107));

      expect(chart.magneticSnap(offset), Offset(chart.indexToDx(blank), offset.dy));
    });
  });

  group('magneticShift', () {
    testWidgets('已对齐蜡烛的对象整体平移结束后拉回蜡烛中心', (tester) async {
      await arrange(tester);
      chart.setDrawMagnetMode(MagnetMode.strong);
      final y = dyOf(105);
      drawTestLine(chart, from: Offset(chart.indexToDx(index - 10), y), to: Offset(chart.indexToDx(index), y));
      final object = chart.drawState.object!;
      final grab = Offset(chart.indexToDx(index - 5), y);

      expect(chart.onDrawMoveStart(grab), isTrue);
      final w = chart.candleActualWidth;
      chart.onDrawMoveUpdate(grab, Offset(-w * 2 - w / 3, 0));
      chart.onDrawMoveEnd();

      expect(object.points[0]!.offset.dx, closeTo(chart.indexToDx(index - 12), 1e-6));
      expect(object.points[1]!.offset.dx, closeTo(chart.indexToDx(index - 2), 1e-6));
    });

    testWidgets('各点相对蜡烛中心偏移不同(含正负对称)时不拉动', (tester) async {
      await arrange(tester);
      final y = dyOf(105);
      // normal 下自由绘制: 两点分别在中心右侧、左侧 2 像素, 偏移大小相同但方向相反。
      drawTestLine(
        chart,
        from: Offset(chart.indexToDx(index - 10) + 2, y),
        to: Offset(chart.indexToDx(index) - 2, y),
      );
      chart.setDrawMagnetMode(MagnetMode.strong);

      expect(chart.magneticShift(chart.drawState.object!), isNull);
    });
  });
}
