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

/// 回归测试：主区 tips 区域撑高的 `padding.top` 必须能回落。
///
/// 绘制期只增不减，收缩靠离散时机复位。锁定「离散时机复位 + 下一帧重新增长」这条保证，
/// 覆盖 addMainPaintObject / removePaintObject / restoreSize / reload 四个入口。
library;

import 'dart:ui';

// 直接引入内部库，使框架内部的 do* 调度与布局复位扩展（MainPaintDelegateExt）对包内测试可见。
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 单个测试指标贡献的 tips 行高。
const tipsRow = 12.0;

/// 主区声明 padding，即 tips 撑高的基准值。
const basePadding = EdgeInsets.only(top: 4, bottom: 8);

const mainSize = Size(300, 300);

class _Scene {
  _Scene({required int declared, required Set<int> activated, bool drawBelowTipsArea = true})
      : context = FakePaintContext() {
    config = FakeFlexiKlineConfiguration(
      mainChildren: activated.map<IIndicatorKey>(directKey).toSet(),
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
        for (var i = 0; i < declared; i++) TestDirectIndicator(key: directKey(i), tipsHeight: tipsRow),
      ],
      subIndicators: const [],
    );
  }

  final FakePaintContext context;
  late final FakeFlexiKlineConfiguration config;
  late final IndicatorPaintObjectManager manager;

  MainPaintObject get main => manager.mainPaintObject;
  EdgeInsets get padding => main.padding;

  /// 驱动一帧主区绘制，走 cross 态或普通态对应的 tips 分支。
  void paintFrame() {
    final canvas = Canvas(PictureRecorder());
    if (context.isCrossing) {
      main.doPaintCross(canvas, Offset.zero);
    } else {
      main.doPaintChart(canvas, main.size);
    }
  }

  /// 主区期望 padding：基准值加 [rows] 行 tips。
  EdgeInsets expected(int rows) => basePadding.copyWith(top: basePadding.top + rows * tipsRow);
}

void main() {
  group('v2.3.x/MainPaintObject/tips区域padding回落', () {
    test('逐个激活撑高、逐个隐藏回落，全部隐藏后回到声明 padding', () {
      final scene = _Scene(declared: 3, activated: {0, 1, 2});

      expect(scene.padding, basePadding, reason: '首帧绘制前只有声明值');

      scene.paintFrame();
      expect(scene.padding, scene.expected(3), reason: '3 个指标各贡献一行 tips');

      scene.manager.removeMainPaintObject(directKey(2));
      scene.paintFrame();
      expect(scene.padding, scene.expected(2), reason: '隐藏 1 个后应回落到 2 行');

      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();
      expect(scene.padding, scene.expected(1));

      scene.manager.removeMainPaintObject(directKey(0));
      scene.paintFrame();
      expect(
        scene.padding,
        basePadding,
        reason: '全部隐藏后只剩不绘制 tips 的蜡烛，padding 必须回到 indicator.padding 原始值',
      );
    });

    test('全部隐藏后 combine 子对象的 padding 随主区回落', () {
      final scene = _Scene(declared: 2, activated: {0, 1});
      scene.paintFrame();

      final candle = scene.manager.candlePaintObject;
      expect(candle.padding, scene.expected(2), reason: 'combine 子对象用主区下发的 padding');

      scene.manager.removeMainPaintObject(directKey(0));
      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();

      expect(
        candle.padding,
        basePadding,
        reason: 'tips 高度归零后绘制期不再触发下发，子对象只能靠复位追平；否则顶部残留空白',
      );
    });

    test('addMainPaintObject 复位 padding，不等下一帧', () {
      // 声明 2 个但只激活 1 个，留一个用于后续激活。
      final scene = _Scene(declared: 2, activated: {0});
      scene.paintFrame();
      expect(scene.padding, scene.expected(1));

      scene.manager.addMainPaintObject(directKey(1), scene.context);
      expect(
        scene.padding,
        basePadding,
        reason: '激活同样改变 tips 行数，须与隐藏对称复位；否则新增后 tips 变矮会残留',
      );

      scene.paintFrame();
      expect(scene.padding, scene.expected(2), reason: '复位后下一帧应重新增长到实际高度');
    });

    test('restoreSize 复位 padding', () {
      final scene = _Scene(declared: 1, activated: {0});
      scene.paintFrame();
      expect(scene.padding, scene.expected(1));

      scene.manager.restoreHeight();

      expect(
        scene.padding,
        basePadding,
        reason: 'restoreSize 的语义是复位窗口局部布局状态，_tmpPadding 属于这一类',
      );
    });

    test('reload 返回空 diff 时也复位 padding', () {
      final scene = _Scene(declared: 1, activated: {0});
      scene.paintFrame();
      expect(scene.padding, scene.expected(1));

      final diff = scene.manager.reloadFlexiKlineConfig();

      expect(
        [...diff.mainToShow, ...diff.mainToHide, ...diff.subToShow, ...diff.subToHide],
        isEmpty,
        reason: '激活集合一致时 reload 不走 show/hide，复位必须由 reload 自己做',
      );
      expect(
        scene.padding,
        basePadding,
        reason: 'reload 换了 indicator 即换了 padding 基准，旧基准上撑高的值已失效',
      );

      scene.paintFrame();
      expect(scene.padding, scene.expected(1));
    });

    test('cross 态下同样撑高与回落', () {
      final scene = _Scene(declared: 2, activated: {0, 1});
      scene.context.isCrossing = true;

      scene.paintFrame();
      expect(scene.padding, scene.expected(2), reason: 'doPaintCross 有一份同源的增长逻辑');

      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();
      expect(scene.padding, scene.expected(1), reason: 'cross 态共用同一份复位时机');
    });

    test('drawBelowTipsArea 为 false 时 padding 不参与 tips 计算', () {
      final scene = _Scene(declared: 2, activated: {0, 1}, drawBelowTipsArea: false);

      scene.paintFrame();
      expect(scene.padding, basePadding, reason: '该分支不撑高 padding');

      scene.manager.removeMainPaintObject(directKey(1));
      scene.paintFrame();
      expect(scene.padding, basePadding);
    });

    test('缩放态进出不产生 padding 漂移', () {
      final scene = _Scene(declared: 2, activated: {0, 1});
      scene.paintFrame();
      expect(scene.padding, scene.expected(2));

      // 缩放中 isFirstDrawTipsArea 为 false，绘制期不写 padding。
      scene.context.isChartZooming = true;
      scene.paintFrame();
      scene.paintFrame();
      expect(scene.padding, scene.expected(2), reason: '缩放期绘制不应改变 padding');

      scene.context.isChartZooming = false;
      scene.paintFrame();
      expect(scene.padding, scene.expected(2), reason: '退出缩放后回到同一高度，无漂移');
    });
  });
}
