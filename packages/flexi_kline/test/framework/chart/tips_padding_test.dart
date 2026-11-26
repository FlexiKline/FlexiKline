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

/// 回归测试：主区 tips 区域高度由 `_tipsAreaHeight` 承载，不写入 padding。
///
/// 锁定「每帧无条件同步、量化后可双向跟随」这条保证：主区激活集合或子指标声明变化后，
/// tips 区域高度在下一次绘制中自动跟随，不依赖任何显式复位调用。
///
/// 观察点是 `topRect.bottom`（即 `chartRect.top`）而非 `padding` —— 一期把 tips 从 padding
/// 剥离后，`padding` 恒等于 `indicator.padding`，tips 的让位体现在几何边界上。
library;

import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart' show CandleModel, FlexiCandleModel, MinMax;
// 直接引入内部库，使框架内部的 do* 绘制调度扩展（MainPaintDelegateExt）对包内测试可见。
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

/// 单个测试指标贡献的 tips 行高。
const tipsRow = 12.0;

/// 主区声明 padding；`FakePaintContext.mainRect` 为 `Rect.zero`，故 `drawableRect.top == 0`，
/// 期望的 `topRect.bottom` 就是 `padding.top + tips 高度`。
const basePadding = EdgeInsets.only(top: 4, bottom: 8);

/// 未让出 tips 区域时的 `topRect.bottom`。
const noTipsArea = 4.0;

const mainSize = Size(300, 300);

class _Scene {
  _Scene({required int declared, required Set<int> activated, bool drawBelowTipsArea = true})
    : context = FakePaintContext(),
      declarations = [
        for (var i = 0; i < declared; i++) TestDirectIndicator(key: directKey(i), tipsHeight: tipsRow),
      ] {
    config = FakeFlexiKlineConfiguration(
      mainChildren: activated.map<IIndicatorKey>(directKey).toSet(),
      mainIndicatorDefaultSize: mainSize,
      mainIndicatorDefaultPadding: basePadding,
      drawBelowTipsArea: drawBelowTipsArea,
    );
    manager = IndicatorPaintObjectManager(configuration: config);
    manager.mountIndicators(
      context: context,
      candle: candle,
      time: time,
      mainIndicators: declarations,
      subIndicators: const [],
    );
  }

  final FakePaintContext context;
  final TestCandleIndicator candle = TestCandleIndicator();
  final TestTimeIndicator time = TestTimeIndicator();

  /// 主区指标声明（非激活集合），[updateDeclarations] 的 old 侧输入。
  final List<Indicator> declarations;

  late final FakeFlexiKlineConfiguration config;
  late final IndicatorPaintObjectManager manager;

  MainPaintObject get main => manager.mainPaintObject;

  /// 主区 tips 区域的下边界，即 `chartRect.top`。
  double get tipsAreaBottom => main.topRect.bottom;

  /// 驱动一帧主区绘制，走 cross 态或普通态对应的 tips 分支。
  void paintFrame() {
    final canvas = Canvas(PictureRecorder());
    if (context.isCrossing) {
      main.doPaintCross(canvas, Offset.zero);
    } else {
      main.doPaintChart(canvas, main.size);
    }
  }

  /// 只改主区指标声明、不动激活集合，模拟 Widget 侧声明变化。
  void updateDeclarations(List<Indicator> next) {
    manager.updateIndicators(
      context: context,
      oldCandle: candle,
      newCandle: candle,
      oldTime: time,
      newTime: time,
      oldMainIndicators: declarations,
      newMainIndicators: next,
      oldSubIndicators: const [],
      newSubIndicators: const [],
    );
  }

  /// 期望的 tips 区域下边界：有 tips 时为 tips 上方与下方各一份 padding.top 加 [rows] 行 tips，
  /// 没有 tips 时只留 padding.top。
  double expected(int rows) => rows == 0 ? noTipsArea : basePadding.top * 2 + rows * tipsRow;
}

void main() {
  group('v2.4.1/MainPaintObject/tips区域高度跟随', () {
    test('逐个激活撑高、逐个隐藏回落，全部隐藏后回到声明 padding', () {
      final scene = _Scene(declared: 3, activated: {0, 1, 2});

      expect(scene.tipsAreaBottom, noTipsArea, reason: '首帧绘制前未让出 tips 区域');

      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(3), reason: '3 个指标各贡献一行 tips');

      scene.manager.removeMainPaintObject(directKey(2));
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(2), reason: '隐藏 1 个后应回落到 2 行');

      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(1));

      scene.manager.removeMainPaintObject(directKey(0));
      scene.paintFrame();
      expect(
        scene.tipsAreaBottom,
        noTipsArea,
        reason: '全部隐藏后只剩不绘制 tips 的蜡烛，tips 区域必须归零、蜡烛区域无残留空白',
      );
    });

    test('padding 全程不被 tips 撑高', () {
      final scene = _Scene(declared: 3, activated: {0, 1, 2});
      scene.paintFrame();

      expect(scene.main.padding, basePadding, reason: 'tips 已从 padding 剥离，绘制期不再回写布局');
      expect(
        scene.manager.candlePaintObject.padding,
        basePadding,
        reason: 'combine 子对象的 padding 同样不含 tips',
      );
    });

    test('combine 子对象的 tips 区域随主区同步', () {
      final scene = _Scene(declared: 2, activated: {0, 1});
      scene.paintFrame();

      final candle = scene.manager.candlePaintObject;
      expect(candle.topRect.bottom, scene.expected(2), reason: 'combine 子对象与主区共享 chartRect');

      scene.manager.removeMainPaintObject(directKey(0));
      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();

      expect(
        candle.topRect.bottom,
        noTipsArea,
        reason: 'tips 高度归零后子对象必须一起归零；否则蜡烛与网格整体下移、顶部残留空白',
      );
    });

    test('激活新指标后下一帧跟随', () {
      // 声明 2 个但只激活 1 个，留一个用于后续激活。
      final scene = _Scene(declared: 2, activated: {0});
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(1));

      scene.manager.addMainPaintObject(directKey(1), scene.context);
      scene.paintFrame();

      expect(
        scene.tipsAreaBottom,
        scene.expected(2),
        reason: '激活改变 tips 行数，汇总每帧无条件同步，无需在 append 处显式复位',
      );
    });

    test('已激活指标的声明更新使 tips 变矮后跟随', () {
      final scene = _Scene(declared: 1, activated: {0});
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(1));

      // 同一 key 换成更矮的 tips 声明，激活集合不变，不走 add/remove。
      scene.updateDeclarations([TestDirectIndicator(key: directKey(0), tipsHeight: tipsRow / 4)]);
      scene.paintFrame();

      expect(
        scene.tipsAreaBottom,
        basePadding.top * 2 + tipsRow / 4,
        reason:
            '声明更新不经过 add/remove，旧实现需要额外补一次失效；'
            '汇总方案下同一次绘制即跟随',
      );
    });

    test('restoreSize 不影响 tips 区域', () {
      final scene = _Scene(declared: 1, activated: {0});
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(1));

      scene.manager.restoreHeight();

      expect(
        scene.tipsAreaBottom,
        scene.expected(1),
        reason: 'tips 已与窗口局部布局状态解耦，复位尺寸不该连带丢掉 tips 区域',
      );
    });

    test('sync 不影响 tips 区域', () {
      final scene = _Scene(declared: 1, activated: {0});
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(1));

      final diff = scene.manager.syncFlexiKlineConfig();

      expect(
        [...diff.mainToShow, ...diff.mainToHide, ...diff.subToShow, ...diff.subToHide],
        isEmpty,
        reason: '激活集合一致时 sync 不走 show/hide',
      );
      expect(
        scene.tipsAreaBottom,
        scene.expected(1),
        reason: 'tips 不再挂在 padding 上，换 indicator 实例不会让它失效',
      );

      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(1));
    });

    test('cross 态下同样跟随', () {
      final scene = _Scene(declared: 2, activated: {0, 1});
      scene.context.isCrossing = true;

      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(2), reason: 'doPaintCross 共用 doPaintTips');

      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(1), reason: '同步点唯一，cross 态自动覆盖');
    });

    test('drawBelowTipsArea 为 false 时不让出 tips 区域', () {
      final scene = _Scene(declared: 2, activated: {0, 1}, drawBelowTipsArea: false);

      scene.paintFrame();
      expect(scene.tipsAreaBottom, noTipsArea, reason: '该分支 tips 叠加绘制在图表之上');

      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();
      expect(scene.tipsAreaBottom, noTipsArea);
    });

    test('缩放态进出不产生 tips 区域漂移', () {
      final scene = _Scene(declared: 2, activated: {0, 1});
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(2));

      // 缩放中 isFirstDrawTipsArea 为 false，doPaintTips 不执行。
      scene.context.isChartZooming = true;
      scene.paintFrame();
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(2), reason: '缩放期保持退出前的高度');

      scene.context.isChartZooming = false;
      scene.paintFrame();
      expect(scene.tipsAreaBottom, scene.expected(2), reason: '退出缩放后重新同步到同一高度，无漂移');
    });

    test('稳定态不重复失效边界缓存', () {
      final scene = _Scene(declared: 2, activated: {0, 1});
      scene.paintFrame();

      final rect = scene.main.topRect;
      scene.paintFrame();
      scene.paintFrame();

      expect(
        scene.main.topRect,
        same(rect),
        reason:
            '量化后稳定态汇总值不变，doPaintTips 应提前 return；'
            '否则边界缓存每帧重建，绘制期布局反复变化即抖动',
      );
    });

    test('副区指标不受影响', () {
      final context = FakePaintContext();
      final config = FakeFlexiKlineConfiguration(
        subKeys: {directKey(9)},
        mainIndicatorDefaultSize: mainSize,
        mainIndicatorDefaultPadding: basePadding,
        drawBelowTipsArea: true,
      );
      final manager = IndicatorPaintObjectManager(configuration: config);
      manager.mountIndicators(
        context: context,
        candle: TestCandleIndicator(),
        time: TestTimeIndicator(),
        mainIndicators: const [],
        subIndicators: [TestDirectIndicator(key: directKey(9), tipsHeight: tipsRow)],
      );

      final sub = manager.getSubPaintObject(directKey(9))!;
      final before = sub.topRect;
      sub.doPaintChart(Canvas(PictureRecorder()), Size(0, sub.height));

      expect(
        sub.topRect,
        same(before),
        reason: '副区 tips 叠加绘制、不让出区域，一期不改变其几何',
      );
    });
  });

  group('MainPaintObject/tips 起点', () {
    test('首行从 padding.top 起绘，后续行依次下移', () {
      final scene = _RowScene();
      scene.paintChart(_model(150));

      expect(scene.tipsRects.map((r) => r.top), [basePadding.top, basePadding.top + _RowObject.rowHeight * 2]);
    });

    test('行序按加入主区的先后，不随 zIndex', () {
      // 后加入的指标 zIndex 更小(如成交量柱要压在蜡烛之下), 图形层级在下, tips 仍排在后面。
      final scene = _RowScene(zIndexes: const [0, -2]);
      scene.paintChart(_model(50));

      expect(scene.tipsRectOf(0).top, basePadding.top, reason: '先加入的指标排第一行');
      expect(scene.tipsRectOf(1).top, basePadding.top + _RowObject.rowHeight, reason: '后加入的 zIndex 更小也排在其后');
    });

    test('drawBelowTipsArea 为 false 时首行同样从 padding.top 起绘', () {
      final scene = _RowScene(drawBelowTipsArea: false);
      scene.paintChart(_model(150));

      expect(scene.tipsRects.first.top, basePadding.top);
      expect(scene.main.topRect.bottom, noTipsArea, reason: '不让出区域');
    });
  });
}

FlexiCandleModel _model(num close) => FlexiCandleModel.init(
  candle: CandleModel(timestamp: 1, open: close, high: close, low: close, close: close, volume: 1),
  count: 4,
);

/// 主区挂两个 [_RowIndicator]，tips 行高随蜡烛变化。
class _RowScene {
  _RowScene({bool drawBelowTipsArea = true, List<int> zIndexes = const [0, 0]}) : context = FakePaintContext() {
    final config = FakeFlexiKlineConfiguration(
      mainChildren: {directKey(0), directKey(1)},
      mainIndicatorDefaultSize: mainSize,
      mainIndicatorDefaultPadding: basePadding,
      drawBelowTipsArea: drawBelowTipsArea,
    );
    manager = IndicatorPaintObjectManager(configuration: config);
    manager.mountIndicators(
      context: context,
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: [
        _RowIndicator(key: directKey(0), zIndex: zIndexes[0]),
        _RowIndicator(key: directKey(1), zIndex: zIndexes[1]),
      ],
      subIndicators: const [],
    );
  }

  final FakePaintContext context;
  late final IndicatorPaintObjectManager manager;

  MainPaintObject get main => manager.mainPaintObject;

  /// 最近一帧 [index] 号指标收到的 tipsRect。
  Rect tipsRectOf(int index) => (main.getChildPaintObject(directKey(index))! as _RowObject).lastTipsRect!;

  /// 最近一帧各子指标收到的 tipsRect，按 zIndex 排序后的遍历顺序。
  List<Rect> get tipsRects => [
    for (final object in main.children)
      if (object is _RowObject) ?object.lastTipsRect,
  ];

  void paintChart(FlexiCandleModel model) => main.doPaintTips(Canvas(PictureRecorder()), model: model);
}

/// close >= 100 时 tips 折成两行，否则一行，模拟数值位数不同导致换行数变化。
class _RowIndicator extends DirectIndicator {
  _RowIndicator({required super.key, super.zIndex}) : super(height: 100, autoActivate: false, padding: EdgeInsets.zero);

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _RowObject();
}

class _RowObject extends DirectPaintObject<_RowIndicator> {
  static const rowHeight = tipsRow;

  Rect? lastTipsRect;

  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size, {required int start, required int end}) {}
  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) {
    lastTipsRect = tipsRect;
    if (model == null) return null;
    return Size(tipsRect?.width ?? 0, model.close >= 100 ? rowHeight * 2 : rowHeight);
  }
}
