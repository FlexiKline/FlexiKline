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

/// 绘制 overlay 的持久化与跨 Controller 追平。
///
/// 被测场景是横竖屏切换：两个 Controller 共享同一份 [IConfiguration]，各自持有独立的
/// overlay 对象树，靠 `$symbol-draw_overlay_list_config` 这个存储键往返同步。指标侧靠
/// 共享 [FlexiKlineConfig] 实例即可实时可见，overlay 侧不行——它不在 [FlexiKlineConfig]
/// 里，必须经落盘 + 重载。
///
/// 观察点是 `hitTestDrawObject`：它是 overlay 对象树唯一的公开出口，也正是用户能感知的
/// 结果（线在图上、点得中）。因此每次断言前都要驱动一帧——`initPoints` 只在 `paintDraw`
/// 里跑，不画就没有屏幕坐标，刚从存储加载的 overlay 的 offset 恒为 `Offset.infinite`。
///
/// 覆盖边界：Controller 与 `OverlayDrawObjectManager` 之间的落盘/加载编排。
/// **不覆盖**：手势识别、Widget 布局、命中判据本身。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
// overlay 的存储读写是框架内部契约，[IConfigurationExt] 被公开 barrel 显式 hide，
// 直接断言落盘结果须引内部库。
import 'package:flexi_kline/src/framework/configuration.dart' show IConfigurationExt;
import 'package:flutter/widgets.dart' show Canvas, Color, Offset, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _spec = KlineSpec(
  symbol: 'DRAW-OVERLAY-SYNC',
  interval: FlexiTimeInterval(1, TimeUnit.minute),
);

/// 画布宽度：不给则 `mainRect` 宽为 0，`timestampToDx` 无从换算。
const _canvasWidth = 400.0;

void main() {
  /// 建一个已挂载、已开启绘制、已注册测试绘制工具的 Controller。
  ///
  /// 注册必须早于 `switchKlineData`：切标的那一刻 `onSymbolChanged` 就要按存储里的
  /// overlay 逐个 `generateDrawObject`，构造器还没注册的话已落盘的 overlay 会被静默丢弃。
  /// 所以这里自己 new controller，而不是让 [ControllerScenario] 代建。
  /// 驱动一帧 chart 绘制。
  ///
  /// 冲帧要用 `pumpWidget`：绘制排下的 post-frame 回调自己不 `scheduleFrame`，没有 widget
  /// 树时 `pump()` 不产生真帧，回调会活到本用例 dispose 之后，在下一个用例的首帧里炸。
  Future<void> paintChartFrame(WidgetTester tester, FlexiKlineController chart) async {
    chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Future<FlexiKlineController> mountChart(
    WidgetTester tester,
    FakeFlexiKlineConfiguration config,
  ) async {
    final controller = FlexiKlineController(configuration: config);
    registerTestDrawObject(controller);
    final scenario = ControllerScenario(controller: controller);
    await scenario.initWithData(
      _spec,
      genFlatCandleList(),
      canvasWidth: _canvasWidth,
      // 绘制点落盘的是蜡烛坐标（ts / value），需要 Y 轴映射真的可用；默认的
      // [MinMax.zero] 会让 `dyToValue` 算出无意义的值。
      candle: TestCandleIndicator(visibleMinMaxFromData: true),
    );
    addTearDown(scenario.dispose);
    // 数据在挂载前入队，不 flush 的话 klineData 为空，`dxToTimestamp` 恒为 null，
    // 绘制点的 ts 停在 -1，落盘内容重建不出来。
    controller.flushPendingKlineData();
    await paintChartFrame(tester, controller);
    return controller;
  }

  /// 驱动一帧 draw 图层，让树上每个 overlay 的 points 拿到当前屏幕坐标。
  void paintDrawFrame(FlexiKlineController controller) {
    controller.paintDraw(Canvas(PictureRecorder()), controller.canvasRect.size);
  }

  /// 存储里所有 overlay 的序列化内容。
  ///
  /// 取 JSON 而不是读 [Overlay] 的字段: 那些字段是 `@protected`, 且落盘断言关心的正是
  /// 序列化后的形态 —— 字段对了而序列化漏了, 重建一样拿不到。
  List<Map<String, dynamic>> storedOverlays(FakeFlexiKlineConfiguration config) {
    return config.getDrawOverlayList(_spec.symbol).map((e) => e.toJson()).toList();
  }

  /// 取主区内一条水平线段的两端，线段落在可见蜡烛范围内。
  ({Offset from, Offset to}) lineEnds(FlexiKlineController controller) {
    final mainRect = controller.mainRect;
    final dy = mainRect.center.dy;
    return (
      from: Offset(mainRect.right - 120, dy),
      to: Offset(mainRect.right - 40, dy),
    );
  }

  group('v2.5.0/FlexiKlineController/draw-overlay-persist', () {
    testWidgets('完成绘制后 overlay 落盘', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);

      drawTestLine(controller, from: ends.from, to: ends.to);

      expect(
        config.getDrawOverlayList(_spec.symbol),
        hasLength(1),
        reason: '绘制完成即 overlay 的终态，此刻不落盘，进程内其他 Controller 与'
            '下次冷启动都读不到它——用户的线会凭空消失。',
      );
    });

    testWidgets('多个 overlay 各自落盘', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);

      drawTestLine(controller, from: ends.from, to: ends.to);
      // 同类型再次 startDraw 是「取消选中」语义, 必须先退出编辑态才能画下一条;
      // 换类型是为了两者身份不同, 见 [testDrawLineType2]。
      controller.prepareDraw(force: true);
      drawTestLine(
        controller,
        from: ends.from.translate(0, -60),
        to: ends.to.translate(0, -60),
        type: testDrawLineType2,
      );

      expect(config.getDrawOverlayList(_spec.symbol), hasLength(2));
    });

    /// 每个改动 [Overlay] 持久化字段的动作都必须落盘, 否则 sync 会把它回退。
    ///
    /// 断言取「存储里的值等于内存里的值」而不是「落盘被调用过」: 前者才排除
    /// 「落盘了但落的是改动前的快照」。
    testWidgets('改样式后落盘的是新样式', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      const target = Color(0xFFAB1234);

      controller.changeDrawLineStyle(color: target, strokeWidth: 4);

      final paint = storedOverlays(config).single['line']['paint'] as Map<String, dynamic>;
      expect(paint['color'], '0x${target.toARGB32().toRadixString(16)}');
      expect(paint['strokeWidth'], 4);
    });

    testWidgets('锁定后落盘 lock', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);

      controller.setDrawLockState(true);

      expect(storedOverlays(config).single['lock'], isTrue);
    });

    testWidgets('改层级后落盘 zIndex', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      // 再画一条并选回第一条, 让上移/下移有可比对象。
      controller.prepareDraw(force: true);
      final other = (from: ends.from.translate(0, -60), to: ends.to.translate(0, -60));
      drawTestLine(controller, from: other.from, to: other.to, type: testDrawLineType2);
      paintDrawFrame(controller);
      final first = controller.hitTestDrawObject(ends.from);
      expect(first, isNotNull, reason: '前置: 第一条线仍可命中');
      controller.onDrawSelect(first!);

      controller.moveDrawStateObjectToTop();

      final stored = storedOverlays(config);
      expect(stored, hasLength(2));
      final topId = stored.reduce(
        (a, b) => (a['zIndex'] as int) > (b['zIndex'] as int) ? a : b,
      )['id'];
      expect(
        topId,
        first.id,
        reason: '置顶把 zIndex 抬到最高, 落盘内容必须反映它, 否则 sync 后层级回退。',
      );
    });

    testWidgets('移动结束后落盘的是新坐标', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      paintDrawFrame(controller);
      int firstTs() => (storedOverlays(config).single['points'] as List).first['ts'] as int;
      final tsBefore = firstTs();

      // 整体平移: 命中线段起手, 不带指针。
      expect(controller.onDrawMoveStart(ends.from), isTrue, reason: '前置: 命中线段');
      controller.onDrawMoveUpdate(ends.from.translate(-40, 0), const Offset(-40, 0));
      controller.onDrawMoveEnd();

      expect(
        firstTs(),
        isNot(tsBefore),
        reason: '移动改的是 points 的蜡烛坐标, 落盘必须跟上, 否则 sync 后线跳回原位。',
      );
    });

    testWidgets('storeFlexiKlineConfig 不再负责 overlay', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      final before = storedOverlays(config);

      controller.storeFlexiKlineConfig();

      expect(
        storedOverlays(config),
        before,
        reason: 'overlay 已写穿落盘, store 只管 FlexiKlineConfig; 若它还顺手重写一遍'
            'overlay, 从属侧一次 store 就会用自己的树覆盖拥有者一侧。',
      );
    });

    testWidgets('后建的 Controller 加载到已落盘的 overlay', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final portrait = await mountChart(tester, config);
      final ends = lineEnds(portrait);
      drawTestLine(portrait, from: ends.from, to: ends.to);

      // 转横屏：新 Controller，同一份 configuration，同一个 symbol。
      final landscape = await mountChart(tester, config);
      paintDrawFrame(landscape);

      expect(
        landscape.hitTestDrawObject(ends.from),
        isNotNull,
        reason: '新 Controller 在 switchKlineData 时按 symbol 加载 overlay；'
            '竖屏那条线必须出现在横屏的对象树上。',
      );
    });
  });

  group('v2.5.0/FlexiKlineController/draw-overlay-sync', () {
    testWidgets('sync 追平对侧新增的 overlay', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final portrait = await mountChart(tester, config);
      final landscape = await mountChart(tester, config);
      final ends = lineEnds(landscape);

      // 横屏画一条线，退回竖屏时竖屏走 sync 追平。
      drawTestLine(landscape, from: ends.from, to: ends.to);
      portrait.syncFlexiKlineConfig();
      paintDrawFrame(portrait);

      expect(
        portrait.hitTestDrawObject(ends.from),
        isNotNull,
        reason: 'overlay 不在 FlexiKlineConfig 里，共享配置实例带不动它；'
            'sync 必须重新从存储加载 overlay 列表，否则横屏画的线退回竖屏就不见了。',
      );
    });

    testWidgets('sync 不丢弃本侧已有的 overlay', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);

      controller.syncFlexiKlineConfig();
      paintDrawFrame(controller);

      expect(
        controller.hitTestDrawObject(ends.from),
        isNotNull,
        reason: 'sync 从存储重建对象树，本侧刚画的 overlay 必须已在存储里；'
            '否则「追平对侧」会以「清空本侧」为代价。',
      );
    });

    testWidgets('sync 后 overlay 用上新的 DrawConfig', (tester) async {
      final config = FakeFlexiKlineConfiguration(
        enableStorage: true,
        enableDraw: true,
        shareConfigInstance: true,
      );
      final controller = await mountChart(tester, config);
      final ends = lineEnds(controller);
      drawTestLine(controller, from: ends.from, to: ends.to);
      // 取一个离线段 5px 的点：默认 hitTestMinDistance 是 10，收紧到 1 后应不再命中。
      final nearLine = ends.from.translate(20, -5);
      paintDrawFrame(controller);
      expect(
        controller.hitTestDrawObject(nearLine),
        isNotNull,
        reason: '前置：默认 hitTestMinDistance(10) 下离线段 5px 的点命中',
      );

      controller.updateDrawConfig((c) => c.copyWith(hitTestMinDistance: 1));
      controller.syncFlexiKlineConfig();
      paintDrawFrame(controller);

      expect(
        controller.hitTestDrawObject(nearLine),
        isNull,
        reason: 'DrawObject 持有的是构造期传入的 DrawConfig 快照；sync 换掉配置后'
            '必须重建对象，否则新配置对已存在的 overlay 永远不生效。',
      );
      // 线段上的点仍要命中：否则「新配置生效」与「对象树被清空」不可区分，
      // 这条会在树被清空时以错误的理由变绿。
      expect(
        controller.hitTestDrawObject(ends.to.translate(-20, 0)),
        isNotNull,
        reason: '收紧命中半径只应改变判据，不应让 overlay 从树上消失。',
      );
    });
  });
}
