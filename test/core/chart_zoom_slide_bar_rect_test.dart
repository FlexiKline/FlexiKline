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

/// zoom 滑竿热区的**自动**来源：绘制编排拿主区 Y 轴刻度文本的实测宽度算出热区并提交，见
/// `ChartBinding._syncChartZoomSlideBarRect`。
///
/// 全部用例都在 controller 层，因为宽度的单调增长态就在 `chartZoomSlideBarRect` 里——蜡烛只
/// 交出一个 `double`，自己不存热区。
///
/// 观察点是**提交次数**而不是 `chartZoomSlideBarRect` 的值：后者是 `ValueNotifier`，同值写入
/// 不通知，「稳定态不重复提交」在那里根本观测不到。提交走 `addPostFrameCallback`，每帧提一次
/// 就是每帧挂一个空转回调。
///
/// 现有 zoom 用例（`chart_zoom_test`、`gesture_owner_priority_test`、
/// `move_to_date_time_widget_test`）一律走 `useCustomZoomRect: true` 并显式注入热区，不覆盖
/// 这条自动路径。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _day = FlexiTimeInterval(1, TimeUnit.day);
const _hour = FlexiTimeInterval(1, TimeUnit.hour);
const _canvasWidth = 400.0;

KlineSpec _spec({String symbol = 'ZOOM-BAR', int precision = 2, FlexiTimeInterval interval = _day}) {
  return KlineSpec(symbol: symbol, interval: interval, precision: precision);
}

/// 三位整数的价格：`precision` 2 时刻度文本恒为 `1xx.xx`。
List<CandleModel> _threeDigits() => genFlatCandleList(high: 180, low: 100);

/// 六位整数的价格：同 `precision` 下比 [_threeDigits] 多三个字符。
List<CandleModel> _sixDigits() => genFlatCandleList(high: 180000, low: 100000);

/// 一位整数的价格：同 `precision` 下比 [_threeDigits] 少两个字符。
List<CandleModel> _oneDigit() => genFlatCandleList(high: 1.8, low: 1);

void main() {
  /// 建场景并灌一份数据。热区由默认配置驱动：`useCustomZoomRect` 为 false、`showYAxisTick`
  /// 为 true，正是要守的那条路径。
  Future<_SpyController> arrange(
    WidgetTester tester, {
    List<CandleModel>? candles,
    int precision = 2,
  }) async {
    final controller = _SpyController();
    final scene = ControllerScenario(controller: controller);
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec(precision: precision),
      candles ?? _threeDigits(),
      canvasWidth: _canvasWidth,
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    controller.flushPendingKlineData();
    return controller;
  }

  /// 画一帧并让提交落地。
  ///
  /// 显式排一帧：提交走 `addPostFrameCallback`，而它自己不 `scheduleFrame`，`tester.pump()`
  /// 只在有帧已被调度时才真跑一帧。
  Future<void> paintFrame(WidgetTester tester, _SpyController chart) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    tester.binding.scheduleFrame();
    await tester.pump();
  }

  /// 换一份价格量级不同的数据，让刻度文本的长度变化。
  void replacePrices(_SpyController chart, List<CandleModel> candles) {
    chart.replaceKlineData(chart.klineData.spec, candles);
    chart.flushPendingKlineData();
  }

  group('v2.5.0/zoom滑竿热区/自动来源', () {
    testWidgets('默认配置: 绘制一帧即生效, 贴主区右缘取全高', (tester) async {
      final chart = await arrange(tester);
      expect(chart.chartZoomSlideBarRect, Rect.zero, reason: '绘制前热区应为空');

      await paintFrame(tester, chart);

      final rect = chart.chartZoomSlideBarRect;
      expect(rect.isEmpty, isFalse, reason: '绘制后热区必须已生效, 否则 zoom 手势整体失效');
      expect(rect.right, chart.mainRect.right);
      expect(rect.top, chart.mainRect.top);
      expect(rect.height, chart.mainRect.height);
    });

    testWidgets('刻度文本变长: 宽度扩大', (tester) async {
      final chart = await arrange(tester);
      await paintFrame(tester, chart);
      final narrow = chart.chartZoomSlideBarRect.width;

      replacePrices(chart, _sixDigits());
      await paintFrame(tester, chart);

      expect(chart.chartZoomSlideBarRect.width, greaterThan(narrow), reason: '文本变长必须撑开热区, 否则拖不到滑竿');
      expect(chart.chartZoomSlideBarRect.right, chart.mainRect.right, reason: '热区始终贴主区右缘');
    });

    testWidgets('刻度文本变短: 宽度不回缩, 且不再提交', (tester) async {
      final chart = await arrange(tester, candles: _sixDigits());
      await paintFrame(tester, chart);
      final wide = chart.chartZoomSlideBarRect.width;

      replacePrices(chart, _threeDigits());
      await paintFrame(tester, chart);

      expect(chart.chartZoomSlideBarRect.width, wide, reason: '宽度回缩会让 zoom 命中区在缩放中途左右跳');
      expect(chart.commits, hasLength(1), reason: '取 max 后 Rect 未变, 不该再提交');
    });

    testWidgets('稳定态: 连续绘制只提交一次', (tester) async {
      final chart = await arrange(tester);
      await paintFrame(tester, chart);
      await paintFrame(tester, chart);
      await paintFrame(tester, chart);

      expect(chart.commits, hasLength(1), reason: '每帧提交等于每帧挂一个 post-frame 空转回调');
    });

    /// 只比宽度不比整个 `Rect` 就会漏掉这一路：grid resize 与指标增删都改主区高度而不改文本长度。
    testWidgets('主区高度变化: 宽度不变也重新提交', (tester) async {
      final chart = await arrange(tester);
      await paintFrame(tester, chart);
      final before = chart.chartZoomSlideBarRect;

      expect(chart.setMainSize(const Size(_canvasWidth, 240)), isTrue, reason: '前置条件: 主区高度必须真的改了');
      await paintFrame(tester, chart);

      final rect = chart.chartZoomSlideBarRect;
      expect(chart.commits, hasLength(2), reason: '热区高度不跟上, 主区缩小后滑竿会伸到副区里');
      expect(rect.width, before.width, reason: '前置条件: 本用例要求宽度不变');
      expect(rect.height, 240);
      expect(rect.top, chart.mainRect.top);
    });

    testWidgets('换标的: 宽度重新收敛, 不沿用上一个标的', (tester) async {
      final chart = await arrange(tester, precision: 8);
      await paintFrame(tester, chart);
      final wide = chart.chartZoomSlideBarRect.width;

      // 价格区间不动, 只换标的与精度: 小数位由 8 位降到 2 位, 文本随之变短。
      final next = _spec(symbol: 'OTHER', precision: 2);
      chart.switchKlineData(next);
      expect(chart.chartZoomSlideBarRect, Rect.zero, reason: '换标的即清零, 下一帧才重新收敛');
      chart.replaceKlineData(next, _threeDigits());
      chart.flushPendingKlineData();
      await paintFrame(tester, chart);

      expect(chart.chartZoomSlideBarRect.width, lessThan(wide), reason: '沿用上一个标的的宽度会让热区盖住图表');
    });

    /// 判据是 symbol 而不是 `spec.key`：后者含 interval，用它会把每次换周期也当成换标的，让宽度
    /// 在同一个标的上反复重新收敛。
    testWidgets('切周期: 宽度不清零', (tester) async {
      final chart = await arrange(tester, precision: 8);
      await paintFrame(tester, chart);
      final wide = chart.chartZoomSlideBarRect.width;

      final next = _spec(precision: 8, interval: _hour);
      chart.switchKlineData(next);
      expect(chart.chartZoomSlideBarRect.width, wide, reason: '价格量级不随周期变, 没有重新收敛的理由');
      // 同标的换周期后让文本变短: 清零过就会跟着缩回去。
      chart.replaceKlineData(next, _oneDigit());
      chart.flushPendingKlineData();
      await paintFrame(tester, chart);

      expect(chart.chartZoomSlideBarRect.width, wide);
      expect(chart.commits, hasLength(1));
    });

    testWidgets('主题变化: 宽度重新收敛', (tester) async {
      final chart = await arrange(tester, precision: 8);
      await paintFrame(tester, chart);
      final wide = chart.chartZoomSlideBarRect.width;

      // 同 precision 下缩短文本: 整数位从三位降到一位。不清零则宽度停在 [wide]。
      replacePrices(chart, _oneDigit());
      await paintFrame(tester, chart);
      expect(chart.chartZoomSlideBarRect.width, wide, reason: '前置条件: 单调增长本应吃掉这次变短');

      chart.onThemeChanged();
      expect(chart.chartZoomSlideBarRect, Rect.zero, reason: '主题可换字体, 旧宽度不再可信');
      await paintFrame(tester, chart);

      expect(chart.chartZoomSlideBarRect.width, lessThan(wide));
    });

    testWidgets('宿主接管热区(useCustomZoomRect): 一次都不提交', (tester) async {
      final chart = await arrange(tester);
      chart.updateGestureConfig((config) => config.copyWith(useCustomZoomRect: true));

      await paintFrame(tester, chart);
      replacePrices(chart, _sixDigits());
      await paintFrame(tester, chart);

      expect(chart.commits, isEmpty, reason: '宿主接管时框架不该写这块矩形');
      expect(chart.chartZoomSlideBarRect, Rect.zero);
    });

    /// 刻度文本关掉后没有可度量的宽度，`paintYAxisTickLabels` 返回 null，热区无从产生。
    testWidgets('showYAxisTick 关闭: 一次都不提交', (tester) async {
      final chart = await arrange(tester);
      chart.updateSettingConfig((config) => config.copyWith(showYAxisTick: false));

      await paintFrame(tester, chart);

      expect(chart.commits, isEmpty);
      expect(chart.chartZoomSlideBarRect, Rect.zero);
    });
  });
}

/// 记下每一次热区提交的 controller。
///
/// `setChartZoomSlideBarRect` 是热区的唯一写入口，覆写它即可直接数提交次数——比从
/// `chartZoomSlideBarRect` 的值反推可靠，后者同值写入不留痕迹。
class _SpyController extends FlexiKlineController {
  _SpyController() : super(configuration: FakeFlexiKlineConfiguration());

  final List<Rect> commits = [];

  @override
  void setChartZoomSlideBarRect(Rect rect) {
    commits.add(rect);
    super.setChartZoomSlideBarRect(rect);
  }
}
