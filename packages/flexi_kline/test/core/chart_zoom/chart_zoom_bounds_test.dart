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

/// Y 轴缩放的取值边界：单次手势的系数由 `maxZoomPerGesture` 决定，跨度由 `minZoomSpanRatio` /
/// `maxZoomSpanRatio` 钳制；触摸与滚轮共用同一套边界，到界后反向输入立即生效。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'zoom_scene.dart';

void main() {
  /// 缩放系数的取值边界由 `maxZoomPerGesture` 单参数决定。
  ///
  /// 观察量取「跨度倍数」= 缩放后跨度 / 缩放前跨度，它就是 `scaleAroundCenter` 收到的系数。
  group('系数边界', () {
    /// 沿滑竿从 [fromDy] 拖到 [toDy]，返回本轮实际生效的缩放系数。
    ///
    /// 每次先复位到自动区间，避免上一轮的缩放区间成为本轮快照。
    Future<double> measureCoeff(
      WidgetTester tester,
      FlexiKlineController chart,
      double fromDy,
      double toDy,
    ) async {
      chart.exitChartZoom();
      await paintFrame(tester, chart);
      final baseSpan = rangeSpan(chart);

      final dx = sliderRect(chart).center.dx;
      final from = Offset(dx, fromDy);
      expect(chart.onChartZoomStart(from), isTrue);
      chart.onChartZoomUpdate(toDy);
      await paintFrame(tester, chart);

      return rangeSpan(chart) / baseSpan;
    }

    testWidgets('角点取到 [1 / M, M]，两端互为倒数', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final m = chart.gestureConfig.maxZoomPerGesture;
      final rect = chart.mainChartRect;

      // 抓顶边拖到底边 = 距底距离从 height 变 0, 取到最大压缩。
      expect(await measureCoeff(tester, chart, rect.top, rect.bottom), closeTo(m, 1e-6));
      // 抓底边拖到顶边 = 反向, 取到最大放大。
      expect(await measureCoeff(tester, chart, rect.bottom, rect.top), closeTo(1 / m, 1e-6));
    });

    testWidgets('边界与主图区高度无关', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final rectBefore = chart.mainChartRect;
      final before = await measureCoeff(tester, chart, rectBefore.top, rectBefore.bottom);

      chart.exitChartZoom();
      chart.setMainSize(Size(chart.mainSize.width, chart.mainSize.height + 120));
      await paintFrame(tester, chart);
      expect(chart.mainChartRect.height, isNot(closeTo(rectBefore.height, 1)), reason: '前置条件: 高度必须真的变了');

      final rectAfter = chart.mainChartRect;
      final after = await measureCoeff(tester, chart, rectAfter.top, rectAfter.bottom);

      // 软化项按高度成比例派生, 所以比值与高度约掉 —— 换了主区高度手感不变。
      expect(after, closeTo(before, 1e-6));
    });

    testWidgets('maxZoomPerGesture 调大即按比例放宽边界', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);
      chart.updateGestureConfig((config) => config.copyWith(maxZoomPerGesture: 12));

      final rect = chart.mainChartRect;
      expect(await measureCoeff(tester, chart, rect.top, rect.bottom), closeTo(12, 1e-6));
      expect(await measureCoeff(tester, chart, rect.bottom, rect.top), closeTo(1 / 12, 1e-6));
    });

    testWidgets('系数恒为正：拉满缩小也不会越过 0 让 Y 轴翻转', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);
      // 取配置允许的最灵敏值, 这是系数最容易接近 0 的一端。
      chart.updateGestureConfig((config) => config.copyWith(maxZoomPerGesture: 20));

      final rect = chart.mainChartRect;
      final coeff = await measureCoeff(tester, chart, rect.bottom, rect.top);

      expect(coeff, greaterThan(0), reason: '负系数会让 max/min 互换、dyFactor 变负');
      expect(rangeMax(chart), greaterThan(rangeMin(chart)), reason: '区间不得反转');
    });
  });

  /// 跨度两端都有界，越界时钳制而不是拒绝写入：界由配置给出，触摸与滚轮共用一套，到界后反向输入立即生效。
  group('跨度界限', () {
    /// 若越界就拒绝写入，区间不变，下一格同样被拒，滚轮就永久失效。只有先用触摸压到界上、
    /// 再用滚轮反向，才会走到这条路径，所以用例同时驱动两条输入链。
    testWidgets('触摸压到界上之后，反向滚轮必须立即生效', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      // 先用滚轮缩一次，让滚轮链也参与本轮缩放。
      expect(chart.onChartZoomStep(wheelShrink), isTrue);
      await paintFrame(tester, chart);

      // 再用触摸滑竿连拉三轮，把跨度压到界上。
      for (var i = 0; i < 3; i++) {
        fullShrinkGesture(chart);
        await paintFrame(tester, chart);
      }
      final bottomed = rangeSpan(chart);
      expect(bottomed, lessThan(autoSpan), reason: '前置条件: 触摸必须已经缩小过跨度');

      // 反向滚轮：朝允许区域走的输入不该被拒。
      chart.onChartZoomStep(wheelExpand);
      await paintFrame(tester, chart);

      expect(
        rangeSpan(chart),
        greaterThan(bottomed),
        reason: '一格滚轮抬不回界内就被拒 => 区间不变 => 下一格同样被拒, 永久卡死',
      );
    });

    /// 每轮手势的快照都是上一轮的缩放结果，多轮叠加也必须停在界上。
    testWidgets('重复触摸满程缩小必须停在界上', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final stable = await shrinkUntilStable(tester, chart, () => fullShrinkGesture(chart));
      expect(stable, greaterThan(0), reason: '界必须是正跨度');

      fullShrinkGesture(chart);
      await paintFrame(tester, chart);

      // 比值而非差值: 无界实现下两者都趋零, 绝对差会假绿。
      expect(
        rangeSpan(chart) / stable,
        closeTo(1.0, 1e-6),
        reason: '触摸链同样受界约束, 不能靠反复抬手重抓无限叠加',
      );
    });

    /// 界是全局的：基准取接管那一刻的自动区间，与先用哪条输入链无关。
    testWidgets('可达界与经过哪条输入链无关', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      // 路径 A: 纯滚轮缩到底。
      final spanA = await shrinkUntilStable(tester, chart, () => chart.onChartZoomStep(0.5));

      chart.exitChartZoom();
      await paintFrame(tester, chart);
      expect(rangeSpan(chart), closeTo(autoSpan, 1e-9), reason: '前置条件: 必须已复位');

      // 路径 B: 先触摸一轮, 再用滚轮缩到底。
      fullShrinkGesture(chart);
      await paintFrame(tester, chart);
      final spanB = await shrinkUntilStable(tester, chart, () => chart.onChartZoomStep(0.5));

      expect(spanB, closeTo(spanA, 1e-9), reason: '界只取决于配置, 不取决于用哪条链先缩');
    });

    /// 钳制不得在触摸链上引入新的锁死: 到界后回拖必须立刻跟手, 不能因为「已经到界」而僵住。
    testWidgets('到界后反向触摸拖动立刻跟手', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final bottomed = await shrinkUntilStable(tester, chart, () => fullShrinkGesture(chart));

      fullExpandGesture(chart);
      await paintFrame(tester, chart);

      expect(
        rangeSpan(chart),
        greaterThan(bottomed * 1.5),
        reason: '到界只限制继续同向, 不限制回头',
      );
    });

    testWidgets('minZoomSpanRatio 决定放大方向的界', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      chart.updateSettingConfig((config) => config.copyWith(minZoomSpanRatio: 0.25));
      await paintFrame(tester, chart);

      final stable = await shrinkUntilStable(tester, chart, () => fullShrinkGesture(chart));
      expect(stable, closeTo(autoSpan * 0.25, 1e-6), reason: '界 = 接管跨度 × 配置倍率');
    });

    testWidgets('maxZoomSpanRatio 决定缩小方向的界', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      chart.updateSettingConfig((config) => config.copyWith(maxZoomSpanRatio: 3));
      await paintFrame(tester, chart);

      final stable = await shrinkUntilStable(tester, chart, () => fullExpandGesture(chart));
      expect(stable, closeTo(autoSpan * 3, 1e-6), reason: '界 = 接管跨度 × 配置倍率');
    });

    /// [SettingConfig] 是 const 构造、原样存值，越界修正在 `SettingBinding` 的 getter 里。
    /// 少了那层夹取，`minZoomSpanRatio: 5` 会让下界(×5)高于上界方向的起点，于是「缩小」手势
    /// 反而把视野放大 5 倍——配置写错的代价从「界不合理」升级成「手势方向反了」。
    testWidgets('倒置的配置被夹回合法区间，不会让手势反向', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      chart.updateSettingConfig((config) => config.copyWith(minZoomSpanRatio: 5));
      await paintFrame(tester, chart);

      final stable = await shrinkUntilStable(tester, chart, () => fullShrinkGesture(chart));
      expect(stable, closeTo(autoSpan, 1e-6), reason: '下界被夹到 1: 缩不下去, 但也不该反向放大');

      fullExpandGesture(chart);
      await paintFrame(tester, chart);
      expect(rangeSpan(chart), greaterThan(autoSpan), reason: '上界不受影响, 放大方向照常');
    });

    /// 账本记的是「相对接管那一刻」的倍率，退出缩放态就是放弃这次接管，账本必须归 1，
    /// 否则重新进入时会以上一次的倍率继续计量，界的位置随历史漂移。
    testWidgets('退出缩放后重新进入，能缩到同一个界', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      final first = await shrinkUntilStable(tester, chart, () => fullShrinkGesture(chart));

      chart.exitChartZoom();
      await paintFrame(tester, chart);
      expect(rangeSpan(chart), closeTo(autoSpan, 1e-9), reason: '前置条件: 必须已复位');

      final second = await shrinkUntilStable(tester, chart, () => fullShrinkGesture(chart));
      expect(second, closeTo(first, 1e-9), reason: '界不随接管次数漂移');
    });

    /// 比较型守卫对 `NaN` 恒为 false，跨度一旦溢出，`NaN` 会写进缩放区间，纵向平移随之失效。
    testWidgets('持续放大不得把区间推成非有限值', (tester) async {
      final scene = await arrange(tester);
      final chart = scene.controller;
      await paintFrame(tester, chart);

      // 每步 ×8，400 步足以越过 double 上限（20 × 8^340 已超 1.8e308）。
      // 循环内不重绘：`onChartZoomStep` 读的是缩放区间本身，不经过绘制。
      for (var i = 0; i < 400; i++) {
        chart.onChartZoomStep(8);
      }
      await paintFrame(tester, chart);

      expect(rangeMax(chart).isFinite, isTrue, reason: '区间上端必须始终有限');
      expect(rangeMin(chart).isFinite, isTrue, reason: '区间下端必须始终有限');
      expect(rangeMax(chart), greaterThan(rangeMin(chart)), reason: '区间不得退化为零跨度或反转');
    });
  });
}
