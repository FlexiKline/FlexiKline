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

/// 控制器驱动的展开: 默认关闭、首次加载、spec 切换、可见性、减少动画与取消。
library;

import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(symbol: 'REVEAL', interval: FlexiTimeInterval(1, TimeUnit.day));
const _otherSpec = KlineSpec(symbol: 'REVEAL_OTHER', interval: FlexiTimeInterval(1, TimeUnit.day));

const _visible = TickerModeData(enabled: true, forceFrames: false);

/// 记录 `paint` 收到的区间; 展开期间由 `paintReveal` 默认实现截断终点。
class _RangeIndicator extends ExternalIndicator {
  _RangeIndicator() : super(key: const ExternalIndicatorKey('reveal-range'), height: 80, padding: EdgeInsets.zero);

  final List<(int, int)> ranges = [];

  @override
  _RangePaintObject createPaintObject() => _RangePaintObject();
}

class _RangePaintObject extends ExternalPaintObject<_RangeIndicator> {
  @override
  void paint(Canvas canvas, Size size, {required int start, required int end}) {
    indicator.ranges.add((start, end));
  }
}

const _hidden = TickerModeData(enabled: false, forceFrames: false);

void main() {
  /// 通过平台调度器模拟系统「减少动画」标志, 测试结束后还原。
  void setSystemDisableAnimations(bool value) {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: value);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  }

  /// [setting] 在首次绘制前写入控制器; 未指定时为默认配置(展开关闭)。
  Future<ControllerScenario> arrange(WidgetTester tester, {SettingConfig? setting}) async {
    final scene = ControllerScenario();
    addTearDown(scene.dispose);
    await scene.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: 400,
      mainIndicators: [TestAnimatedIndicator(key: const ExternalIndicatorKey('reveal-main'))],
      subIndicators: [TestAnimatedIndicator(key: const ExternalIndicatorKey('reveal-sub'))],
    );
    scene.controller.flushPendingKlineData();
    if (setting != null) scene.controller.settingConfig = setting;
    return scene;
  }

  const enabled = SettingConfig(reveal: RevealConfig(enabled: true));

  /// 驱动一帧 chart 绘制, 与 placeholder_paint_test 的写法一致。
  Future<void> paintFrame(WidgetTester tester, FlexiKlineController chart) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  /// 推进时间让流水线已调度的节流定时器到期。流水线 tick 按真实时钟的 interval 调度,
  /// 测试结束前若仍有未到期的定时器, flutter_test 会报告残留定时器。
  Future<void> drainPipeline(WidgetTester tester) => tester.pump(const Duration(seconds: 1));

  group('默认关闭', () {
    testWidgets('未开启时首次绘制即为终态', (tester) async {
      final scene = await arrange(tester);

      await paintFrame(tester, scene.controller);

      expect(scene.controller.revealProgress, 1.0);
    });
  });

  group('controllerFirst', () {
    testWidgets('首次可绘制时从 0 开始, 走完停在 1', (tester) async {
      final scene = await arrange(tester, setting: enabled);

      await paintFrame(tester, scene.controller);
      expect(scene.controller.revealProgress, 0.0);

      await tester.pumpAndSettle();
      expect(scene.controller.revealProgress, 1.0);
    });

    testWidgets('展开中再次绘制不重新开始', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      await paintFrame(tester, scene.controller);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final before = scene.controller.revealProgress;
      expect(before, greaterThan(0.0), reason: '前提: 动画已推进');

      await paintFrame(tester, scene.controller);

      expect(scene.controller.revealProgress, greaterThanOrEqualTo(before));
      await drainPipeline(tester);
    });

    testWidgets('首次到达时不可见则不播, 之后可见也不补播', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      scene.controller.setTickerMode(_hidden);

      scene.controller.paintChart(Canvas(PictureRecorder()), scene.controller.canvasRect.size);
      expect(scene.controller.revealProgress, 1.0, reason: '不启动, 不依赖 tick 收尾');

      scene.controller.setTickerMode(_visible);
      await paintFrame(tester, scene.controller);
      expect(scene.controller.revealProgress, 1.0, reason: '首次可绘制已消费, 之后可见也不补播');
    });

    testWidgets('spec 切换不重播', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      await paintFrame(tester, scene.controller);
      await tester.pumpAndSettle();

      scene.controller
        ..switchKlineData(_otherSpec)
        ..replaceKlineData(_otherSpec, genFlatCandleList())
        ..flushPendingKlineData();
      await paintFrame(tester, scene.controller);

      expect(scene.controller.revealProgress, 1.0);
    });
  });

  group('specFirstLoad', () {
    const setting = SettingConfig(reveal: RevealConfig(enabled: true, trigger: RevealTrigger.specFirstLoad));

    testWidgets('新 spec 首次加载后展开, 回切已缓存的 spec 不展开', (tester) async {
      final scene = await arrange(tester, setting: setting);
      await paintFrame(tester, scene.controller);
      await tester.pumpAndSettle();
      expect(scene.controller.revealProgress, 1.0);

      scene.controller
        ..switchKlineData(_otherSpec)
        ..replaceKlineData(_otherSpec, genFlatCandleList())
        ..flushPendingKlineData();
      await paintFrame(tester, scene.controller);
      expect(scene.controller.revealProgress, 0.0, reason: '新 spec 首次可绘制应展开');
      await tester.pumpAndSettle();

      scene.controller.switchKlineData(_spec);
      await paintFrame(tester, scene.controller);
      expect(scene.controller.revealProgress, 1.0, reason: '缓存命中不展开');
    });

    testWidgets('未加载完成即切回缓存 spec, 待定展开作废', (tester) async {
      final scene = await arrange(tester, setting: setting);
      await paintFrame(tester, scene.controller);
      await tester.pumpAndSettle();

      scene.controller.switchKlineData(_otherSpec);
      scene.controller.switchKlineData(_spec);
      await paintFrame(tester, scene.controller);

      expect(scene.controller.revealProgress, 1.0, reason: '_otherSpec 的请求不能带到 _spec 上');
    });
  });

  group('specFirstLoad 之后的数据替换', () {
    const setting = SettingConfig(reveal: RevealConfig(enabled: true, trigger: RevealTrigger.specFirstLoad));

    testWidgets('下拉刷新替换当前 spec 的数据不展开', (tester) async {
      final scene = await arrange(tester, setting: setting);
      await paintFrame(tester, scene.controller);
      await tester.pumpAndSettle();

      scene.controller
        ..replaceKlineData(_spec, genFlatCandleList())
        ..flushPendingKlineData();
      await paintFrame(tester, scene.controller);

      expect(scene.controller.revealProgress, 1.0, reason: '展开只属于未命中缓存的切换');
    });

    testWidgets('增量更新不展开', (tester) async {
      final scene = await arrange(tester, setting: setting);
      await paintFrame(tester, scene.controller);
      await tester.pumpAndSettle();

      scene.controller
        ..updateLatestKlineData(_spec, [genFlatCandleList().last])
        ..flushPendingKlineData();
      await paintFrame(tester, scene.controller);

      expect(scene.controller.revealProgress, 1.0);
      await drainPipeline(tester);
    });

    testWidgets('缓存命中后拉到的最新数据不展开', (tester) async {
      final scene = await arrange(tester, setting: setting);
      await paintFrame(tester, scene.controller);
      await tester.pumpAndSettle();

      scene.controller.switchKlineData(_otherSpec);
      scene.controller
        ..replaceKlineData(_otherSpec, genFlatCandleList())
        ..flushPendingKlineData();
      await tester.pumpAndSettle();
      scene.controller.switchKlineData(_spec);
      await paintFrame(tester, scene.controller);
      expect(scene.controller.revealProgress, 1.0, reason: '切回命中缓存, 之后的替换不再展开');

      scene.controller
        ..replaceKlineData(_spec, genFlatCandleList())
        ..flushPendingKlineData();
      await paintFrame(tester, scene.controller);
      expect(scene.controller.revealProgress, 1.0, reason: '命中后的最新数据替换同样不展开');
    });
  });

  group('绘制区间', () {
    testWidgets('展开中 paint 的终点随进度截断, 结束后为完整区间', (tester) async {
      final indicator = _RangeIndicator();
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, genFlatCandleList(), canvasWidth: 400, mainIndicators: [indicator]);
      scene.controller.flushPendingKlineData();
      scene.controller.settingConfig = enabled;

      await paintFrame(tester, scene.controller);
      final data = scene.controller.klineData;
      final full = (math.max(data.start - 1, 0), math.min(data.end + 1, data.length));
      expect(indicator.ranges.last.$2, full.$1, reason: '首帧进度为 0, 终点即起点');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await paintFrame(tester, scene.controller);
      final mid = indicator.ranges.last;
      expect(mid.$2, greaterThan(full.$1), reason: '前提: 动画已推进');
      expect(mid.$2, lessThan(full.$2), reason: '展开中终点小于完整区间');

      await tester.pumpAndSettle();
      await paintFrame(tester, scene.controller);
      expect(indicator.ranges.last, full, reason: '展开结束后按完整区间绘制');
    });
  });

  group('起点', () {
    testWidgets('启动帧的耗时不计入展开, 首个 tick 的进度为 0', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      // 与 paintChart 同序: 先算绘制区间, 再在帧内启动展开, Ticker 以该帧的时间戳为零点。
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        scene.controller
          ..calculatePaintChartRange()
          ..beginRevealIfPending();
      });
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 100));

      expect(scene.controller.revealProgress, lessThan(0.01), reason: '首个可见帧不应跳到 1/4 左右');
      await tester.pump(const Duration(milliseconds: 200));
      expect(scene.controller.revealProgress, greaterThan(0.0), reason: '之后正常推进');
      await drainPipeline(tester);
    });
  });

  group('副区', () {
    testWidgets('副区指标同样随进度截断绘制区间', (tester) async {
      final sub = _RangeIndicator();
      final scene = ControllerScenario();
      addTearDown(scene.dispose);
      await scene.initWithData(_spec, genFlatCandleList(), canvasWidth: 400, subIndicators: [sub]);
      scene.controller.flushPendingKlineData();
      scene.controller.settingConfig = enabled;

      await paintFrame(tester, scene.controller);
      final data = scene.controller.klineData;
      final full = (math.max(data.start - 1, 0), math.min(data.end + 1, data.length));
      expect(sub.ranges.last.$2, full.$1, reason: '首帧进度为 0, 副区终点即起点');

      await tester.pumpAndSettle();
      await paintFrame(tester, scene.controller);
      expect(sub.ranges.last, full, reason: '展开结束后副区按完整区间绘制');
    });
  });

  group('取消', () {
    testWidgets('cancelReveal 立即落在终态', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      await paintFrame(tester, scene.controller);
      expect(scene.controller.revealProgress, 0.0, reason: '前提: 动画已开始');

      scene.controller.cancelReveal();

      expect(scene.controller.revealProgress, 1.0);
    });

    testWidgets('切换 spec key 时取消', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      await paintFrame(tester, scene.controller);

      scene.controller.switchKlineData(_otherSpec);

      expect(scene.controller.revealProgress, 1.0);
    });

    testWidgets('展开中开启减少动画, 下一次 tick 落到终态', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      await paintFrame(tester, scene.controller);
      await tester.pump(const Duration(milliseconds: 150));
      expect(scene.controller.revealProgress, greaterThan(0.0), reason: '前提: 动画已推进');

      setSystemDisableAnimations(true);
      await tester.pump(const Duration(milliseconds: 16));

      expect(scene.controller.revealProgress, 1.0);
    });

    testWidgets('减少动画开启时首次绘制不展开', (tester) async {
      final scene = await arrange(tester, setting: enabled);
      setSystemDisableAnimations(true);

      scene.controller.paintChart(Canvas(PictureRecorder()), scene.controller.canvasRect.size);

      expect(scene.controller.revealProgress, 1.0, reason: '不启动, 不依赖 tick 收尾');
    });
  });
}
