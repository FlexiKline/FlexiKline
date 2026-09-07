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

/// `PaintGridTicksMixin` 的三个 resolve：把 `GridTickMode` 分派到取位算法，并接上本对象的
/// 坐标体系。取位算法本身（等分、固定间距、nice 取整）在 `test/utils/grid_tick_test.dart` 里
/// 直接测，本组只测分派、默认 bounds 与值的往返。
///
/// 三处最容易做错的地方：
///
/// 一是**两个 resolve 的端点语义与默认 bounds 都相反**。`resolveHorizontalDys` 不含两端、取
/// `drawableRect`——两端有 grid 层的顶边框与 pane 分隔线，横线又要横穿整个可绘制区；
/// `resolveDysByCount` 含两端、取 `chartRect`——副区没有边框，贴顶贴底的两条正是该指标在可视
/// 区的极值，而文本落在图表区内。搞反了不会报错，只会让主区多一条重合线、副区刻度整体偏移。
///
/// 二是 **nice 的值不再由算法一路传下来**，改由画文本时 `dyToValue(check: false)` 现算。
/// 只要 `valueToDy` / `dyToValue` 不是严格互逆，刻度文本就会显示成不等差的数字，而线的位置
/// 看起来完全正常。
///
/// 三是 **nice 在区间不可用时必须退化**，否则加载中的主区一条横线都没有。
library;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_formatter/flexi_formatter.dart' show formatPrice;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/utils/grid_tick_util.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'GRID-RESOLVE', interval: FlexiTimeInterval(1, TimeUnit.day));

/// 主区留白 20：让 nice 刻度有机会落到 `minMax` 之外的留白区，值反算那条用例才不空转。
const _mainPadding = EdgeInsets.symmetric(vertical: 20);

const _flatHigh = 107.0;
const _flatLow = 93.0;

/// 与位置无关的独立矩形：size 模式的算法只吃「长度」，用它把长度钉成整数，断言才能写死。
Rect _boundsOfHeight(double height) => Rect.fromLTWH(0, 0, 400, height);

Rect _boundsOfWidth(double width) => Rect.fromLTWH(0, 0, width, 300);

void main() {
  /// 建 controller、灌数据并绘制一帧，交回已就位的主区蜡烛绘制对象。
  ///
  /// 必须绘制：`drawableRect` 与 `minMax` 都要等一帧编排走完才有值，resolve 全靠它们。
  Future<TestCandlePaintObject> arrange(WidgetTester tester) async {
    final scene = ControllerScenario(
      config: FakeFlexiKlineConfiguration(mainIndicatorDefaultPadding: _mainPadding),
    );
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      genFlatCandleList(high: _flatHigh, low: _flatLow),
      canvasWidth: 400,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    scene.controller.flushPendingKlineData();
    await paintChartFrame(tester, scene.controller);
    return scene.candle.object!;
  }

  group('v2.5.0/网格线/算位置', () {
    testWidgets('横线的 count: 分派到等分, 两端一条都不占', (tester) async {
      final object = await arrange(tester);
      final bounds = _boundsOfHeight(300);

      final dys = object.horizontalDysOf(const GridTickMode.count(5), bounds: bounds);

      expect(dys, [60.0, 120.0, 180.0, 240.0]);
      for (final dy in dys) {
        expect(dy, isNot(bounds.top), reason: '顶端是 grid 层的顶边框');
        expect(dy, isNot(bounds.bottom), reason: '底端是 grid 层的 pane 分隔线');
      }
    });

    testWidgets('横线的 size: 分派到固定间距, 余量平分两端', (tester) async {
      final object = await arrange(tester);

      expect(object.horizontalDysOf(const GridTickMode.size(60), bounds: _boundsOfHeight(300)), [
        60.0,
        120.0,
        180.0,
        240.0,
      ]);
      expect(object.horizontalDysOf(const GridTickMode.size(60), bounds: _boundsOfHeight(320)), [
        70.0,
        130.0,
        190.0,
        250.0,
      ]);
    });

    testWidgets('resolveDysByCount: 含两端, 首末恰为 bounds 的顶与底', (tester) async {
      final object = await arrange(tester);
      final bounds = _boundsOfHeight(300);

      final dys = object.dysByCountOf(3, bounds: bounds);

      expect(dys.length, 3, reason: '副区口径的参数是刻度数, 不是间隔数');
      expect(dys.first, bounds.top, reason: '贴顶那条是该指标在可视区的最大值');
      expect(dys.last, bounds.bottom, reason: '贴底那条是最小值');
      expect(dys[1], bounds.center.dy);
    });

    /// 副区历来按 chartRect 摆刻度文本（文本落在图表区内），主区横线按 drawableRect 横穿整区。
    /// 两个 resolve 的默认 bounds 因此不同，改一处就会让副区刻度整体偏移到留白里。
    testWidgets('默认 bounds: 横线取 drawableRect, 副区刻度取 chartRect', (tester) async {
      final object = await arrange(tester);

      final dys = object.horizontalDysOf(const GridTickMode.count(2));
      expect(dys.single, closeTo(object.drawableRect.center.dy, 1e-9));

      final ticks = object.dysByCountOf(3);
      expect(ticks.first, object.chartRect.top);
      expect(ticks.last, object.chartRect.bottom);
    });

    testWidgets('nice: 反算回来的值与算法原值格式化后逐个相同', (tester) async {
      final object = await arrange(tester);
      final bounds = object.drawableRect;

      final dys = object.horizontalDysOf(const GridTickMode.nice(targetDivisions: 5), bounds: bounds);
      expect(dys.length, greaterThanOrEqualTo(3), reason: '前置条件: 刻度太少断言会空转');

      // 算法的原值: 与 mixin 内部同一组入参。
      final top = object.dyToValue(bounds.top, check: false)!.toDouble();
      final bottom = object.dyToValue(bounds.bottom, check: false)!.toDouble();
      final expected = computePriceTicks(
        bottom: bottom,
        top: top,
        targetCount: 5,
        precision: object.klineData.precision,
      ).values;
      expect(dys.length, expected.length);

      // 8 位是本仓库最深的显示精度: 往返只经一次乘、一次除, 相对误差约 1e-16, 在这个量级的
      // 价格上是 1e-14 绝对误差, formatPrice 的四舍五入会吸收掉。
      for (final precision in [2, 8]) {
        for (var i = 0; i < dys.length; i++) {
          final restored = object.dyToValue(dys[i], check: false);
          expect(restored, isNotNull, reason: 'check: false 漏了会让整条刻度静默消失');
          expect(
            formatPrice(restored!.toDecimal(), precision: precision, cutInvalidZero: false),
            formatPrice(expected[i].toFlexiNum().toDecimal(), precision: precision, cutInvalidZero: false),
            reason: 'precision $precision 下第 $i 条刻度的反算值与算法原值不一致',
          );
        }
      }
    });

    /// 门禁前那一趟也要有网格线：位置只依赖几何，没有区间同样能画。
    testWidgets('nice: 无数据时退化为同 divisions 的 count', (tester) async {
      final scene = ControllerScenario(
        config: FakeFlexiKlineConfiguration(mainIndicatorDefaultPadding: _mainPadding),
      );
      addTearDown(scene.dispose);
      await scene.initWithData(
        _spec,
        const [],
        canvasWidth: 400,
        candle: TestCandleIndicator(visibleMinMaxFromData: true),
      );
      scene.controller.flushPendingKlineData();
      await paintChartFrame(tester, scene.controller);
      final object = scene.candle.object!;
      expect(object.klineData.canPaintChart, isFalse, reason: '前置条件: 本条要的就是无数据态');

      final bounds = _boundsOfHeight(300);
      expect(
        object.horizontalDysOf(const GridTickMode.nice(targetDivisions: 5), bounds: bounds),
        object.horizontalDysOf(const GridTickMode.count(5), bounds: bounds),
      );
    });

    testWidgets('竖线: count 与 size 按宽度切分, 同样避开两端', (tester) async {
      final object = await arrange(tester);

      expect(object.verticalDxsOf(const GridTickMode.count(5), bounds: _boundsOfWidth(300)), [
        60.0,
        120.0,
        180.0,
        240.0,
      ]);
      expect(object.verticalDxsOf(const GridTickMode.size(60), bounds: _boundsOfWidth(320)), [
        70.0,
        130.0,
        190.0,
        250.0,
      ]);
    });

    /// 竖线永不按值取整（网格作为视觉参考系必须稳定），所以 nice 在纵向是配置错误而不是一种
    /// 取位方式。debug 下 assert 抛出把它拦在开发期；release 下退化为同 divisions 的 count，
    /// 那条路径开着 assert 观测不到。
    testWidgets('竖线: nice 在 debug 下 assert 抛出', (tester) async {
      final object = await arrange(tester);

      expect(
        () => object.verticalDxsOf(const GridTickMode.nice(), bounds: _boundsOfWidth(300)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
