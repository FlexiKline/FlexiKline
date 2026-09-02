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

/// 缩放区间（Y 轴由用户接管）的所有权与作用范围。
///
/// 锁定三条不变量：
/// 1. 缩放区间一经设定，可见区间变化不重算它；
/// 2. 缩放区间只下发给 combine 子对象，[PaintMode.alone] 的子对象恒随可见数据自动重算；
/// 3. 清除缩放区间后自动路径立即重建，不会因早退拿到缩放期间的过期值。
///
/// 直接调 `setZoomMinMax` 驱动，绕开手势层：本文件测的是区间的所有权，不是缩放手势。
/// 手势到区间的链路见 `test/core/chart_zoom_test.dart`。
library;

// 直接引入内部库，使框架内部的 do* 调度扩展对包内测试可见。
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _mainRect = Rect.fromLTWH(0, 0, 300, 300);

/// combine 子对象的 key；与主区共享坐标系，接受缩放区间下发。
final _combineKey = directKey(0);

/// alone 子对象的 key；独立坐标系，不接受下发。
final _aloneKey = directKey(1);

MinMax _mm(num max, num min) => MinMax(
      max: FlexiNum.fromNum(max),
      min: FlexiNum.fromNum(min),
    );

class _Scene {
  _Scene() : context = (FakePaintContext()..mainRect = _mainRect) {
    declarations = [
      TestRangeIndicator(key: _combineKey),
      TestRangeIndicator(key: _aloneKey, paintMode: PaintMode.alone),
    ];
    config = FakeFlexiKlineConfiguration(
      mainChildren: {_combineKey, _aloneKey},
      mainIndicatorDefaultSize: _mainRect.size,
      mainIndicatorDefaultPadding: EdgeInsets.zero,
    );
    manager = IndicatorPaintObjectManager(configuration: config);
    manager.mountIndicators(
      context: context,
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: declarations,
      subIndicators: const [],
    );
  }

  final FakePaintContext context;
  late final List<Indicator> declarations;
  late final FakeFlexiKlineConfiguration config;
  late final IndicatorPaintObjectManager manager;

  MainPaintObject get main => manager.mainPaintObject;

  TestRangePaintObject get combineChild => (declarations[0] as TestRangeIndicator).object!;
  TestRangePaintObject get aloneChild => (declarations[1] as TestRangeIndicator).object!;

  /// 驱动一帧可见区间更新。
  void updateRange(int start, int end, {double panSmoothFactor = 1.0}) {
    main.doUpdateVisibleMinMax(
      mainPaneIndex,
      start: start,
      end: end,
      panSmoothFactor: panSmoothFactor,
    );
  }
}

void main() {
  group('v2.4.1/缩放价格区间/所有权', () {
    test('未设缩放区间：主区走自动合并，minMax 随可见区间变化', () {
      final scene = _Scene();

      scene.updateRange(0, 5);
      // combine 子对象贡献 [0, 50]；alone 子对象不参与合并。
      expect(scene.main.minMax.min.toDouble(), 0.0);
      expect(scene.main.minMax.max.toDouble(), 50.0);

      scene.updateRange(2, 8);
      expect(scene.main.minMax.min.toDouble(), 2.0);
      expect(scene.main.minMax.max.toDouble(), 80.0);
    });

    test('setZoomMinMax 后 minMax 返回缩放区间，dyFactor 随之重算', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      expect(scene.main.dyFactor, closeTo(300 / 50, 1e-9));

      scene.main.setZoomMinMax(_mm(200, 100));

      expect(scene.main.minMax.max.toDouble(), 200.0);
      expect(scene.main.minMax.min.toDouble(), 100.0);
      // chartRect.height 不变, 分母换成缩放跨度 100。
      expect(scene.main.dyFactor, closeTo(300 / 100, 1e-9));
    });

    test('缩放态下改变可见区间：主区 minMax 不变', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.main.setZoomMinMax(_mm(200, 100));

      scene.updateRange(2, 8);
      expect(scene.main.minMax.max.toDouble(), 200.0);
      expect(scene.main.minMax.min.toDouble(), 100.0);

      scene.updateRange(30, 90);
      expect(scene.main.minMax.max.toDouble(), 200.0);
      expect(scene.main.minMax.min.toDouble(), 100.0);
    });

    test('缩放态下 combine 子对象取到与主区一致的缩放区间', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.main.setZoomMinMax(_mm(200, 100));
      scene.updateRange(2, 8);

      expect(scene.combineChild.minMax.max.toDouble(), 200.0);
      expect(scene.combineChild.minMax.min.toDouble(), 100.0);
    });

    test('缩放态下 alone 子对象仍随可见区间自动重算，不接受下发', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.main.setZoomMinMax(_mm(200, 100));

      scene.updateRange(2, 8);
      // 自己算出的 [2, 80], 不是主区的 [100, 200]。
      expect(scene.aloneChild.minMax.min.toDouble(), 2.0);
      expect(scene.aloneChild.minMax.max.toDouble(), 80.0);

      scene.updateRange(3, 9);
      expect(scene.aloneChild.minMax.min.toDouble(), 3.0);
      expect(scene.aloneChild.minMax.max.toDouble(), 90.0);
    });

    test('缩放态下子对象的 computeVisibleMinMax 仍随可见区间变化被调用', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.main.setZoomMinMax(_mm(200, 100));

      final aloneBefore = scene.aloneChild.computeCount;
      final combineBefore = scene.combineChild.computeCount;

      scene.updateRange(2, 8);

      expect(scene.aloneChild.computeCount, aloneBefore + 1, reason: 'alone 子对象必须重算');
      expect(scene.combineChild.computeCount, combineBefore + 1, reason: '蜡烛一类的数据派生缓存靠这一遍刷新');
      expect(scene.aloneChild.lastStart, 2);
      expect(scene.aloneChild.lastEnd, 8);
    });

    test('clearZoomMinMax 后回到自动重算值，不会拿到缩放期间的过期值', () {
      final scene = _Scene();
      scene.updateRange(2, 8);
      scene.main.setZoomMinMax(_mm(200, 100));
      scene.updateRange(2, 8);
      expect(scene.main.minMax.max.toDouble(), 200.0);

      scene.main.clearZoomMinMax();
      // 可见区间与缩放期间完全一致: 若 _minMax 未被清掉, 早退分支会返回过期值。
      scene.updateRange(2, 8);

      expect(scene.main.minMax.min.toDouble(), 2.0);
      expect(scene.main.minMax.max.toDouble(), 80.0);
    });

    test('缩放态下不做平滑插值：panSmoothFactor < 1 也返回精确缩放区间', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.main.setZoomMinMax(_mm(200, 100));

      scene.updateRange(2, 8, panSmoothFactor: 0.15);

      expect(scene.main.minMax.max.toDouble(), 200.0);
      expect(scene.main.minMax.min.toDouble(), 100.0);
    });

    test('combine 子对象代理主区 minMax，与主区是同一引用', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.main.setZoomMinMax(_mm(200, 100));

      scene.updateRange(2, 8);

      // 改后 combine 子对象直接代理 _parent!.minMax, 是同一个实例。
      expect(
        identical(scene.combineChild.minMax, scene.main.minMax),
        isTrue,
        reason: 'combine 子对象代理主区 minMax, 应为同一引用',
      );
      expect(scene.combineChild.minMax.max.toDouble(), 200.0);
      expect(scene.combineChild.minMax.min.toDouble(), 100.0);
    });

    test('缩放期间 combine 子对象的自动缓存保持新鲜，退出即刻可用', () {
      final scene = _Scene();
      scene.updateRange(2, 8);
      scene.main.setZoomMinMax(_mm(200, 100));
      // 缩放期间换过可见区间, 子对象按新区间算过自己那份。
      scene.updateRange(4, 6);
      expect(scene.combineChild.minMax.max.toDouble(), 200.0, reason: '渲染用缩放区间');

      scene.main.clearZoomMinMax();
      scene.updateRange(4, 6);

      // 主区合并到子对象按 (4, 6) 算出的 [4, 60], 而非缩放期间的任何残留。
      expect(scene.main.minMax.min.toDouble(), 4.0);
      expect(scene.main.minMax.max.toDouble(), 60.0);
      expect(scene.combineChild.minMax.max.toDouble(), 60.0);
    });
  });

  group('v2.5.0/minMax 显示值分离与 combine 代理', () {
    test('smoothMinMax 不污染 _minMax：连续平滑期收敛目标不被覆盖', () {
      final scene = _Scene();
      // 第一帧：建立初始区间 [0, 50]
      scene.updateRange(0, 5);
      expect(scene.main.minMax.max.toDouble(), 50.0);

      // 第二帧带 smooth：可见区间变到 [2, 80]，首帧 smooth 从 _minMax 开始
      scene.updateRange(2, 8, panSmoothFactor: 0.15);
      expect(scene.main.minMax.max.toDouble(), closeTo(80.0, 0.01));

      // 第三帧带 smooth：可见区间变到 [4, 120]，此时 _smoothMinMax 已存在
      scene.updateRange(4, 12, panSmoothFactor: 0.15);
      final smoothedMax = scene.main.minMax.max.toDouble();
      expect(smoothedMax, greaterThan(80.0), reason: '插值应向新目标值收敛');
      expect(smoothedMax, lessThan(120.0), reason: '平滑活跃时 minMax 应返回插值，不是目标值');

      // 第四帧 factor=1.0：平滑结束，minMax 应为最新目标值
      scene.updateRange(4, 12, panSmoothFactor: 1.0);
      expect(scene.main.minMax.max.toDouble(), 120.0, reason: '平滑结束后 minMax 应回到纯净目标值');
    });

    test('combine 子对象正常态代理主区 minMax（非 zoom）', () {
      final scene = _Scene();
      scene.updateRange(0, 5);

      // combine 子对象的 minMax 应该等于主区合并后的值
      expect(scene.combineChild.minMax.max.toDouble(), scene.main.minMax.max.toDouble());
      expect(scene.combineChild.minMax.min.toDouble(), scene.main.minMax.min.toDouble());

      // 可见区间变化后，combine 跟着变
      scene.updateRange(3, 9);
      expect(scene.combineChild.minMax.max.toDouble(), scene.main.minMax.max.toDouble());
      expect(scene.combineChild.minMax.min.toDouble(), scene.main.minMax.min.toDouble());
    });

    test('combine 子对象在 smooth 期也代理主区的平滑值', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.updateRange(2, 8, panSmoothFactor: 0.15);

      // combine 子对象和主区拿到同一个平滑后的值
      expect(
        identical(scene.combineChild.minMax, scene.main.minMax),
        isTrue,
        reason: 'combine 子对象代理主区 minMax（含 smooth）',
      );
    });

    test('alone 子对象不代理主区，始终用自己的区间', () {
      final scene = _Scene();
      scene.updateRange(0, 5);

      // alone 子对象的 minMax 是自己 computeVisibleMinMax 的结果
      // TestRangePaintObject.rangeOf(0, 5) = MinMax(min: 0, max: 50)
      expect(scene.aloneChild.minMax.min.toDouble(), 0.0);
      expect(scene.aloneChild.minMax.max.toDouble(), 50.0);

      // 但不应是主区的同一引用
      expect(
        identical(scene.aloneChild.minMax, scene.main.minMax),
        isFalse,
        reason: 'alone 子对象有独立的 minMax 实例',
      );
    });

    test('zoom 状态只存在于 MainPaintObject，子对象无 zoom 状态', () {
      final scene = _Scene();
      scene.updateRange(0, 5);
      scene.main.setZoomMinMax(_mm(200, 100));
      scene.updateRange(2, 8);

      // 主区有 zoom
      expect(scene.main.hasZoomMinMax, isTrue);

      // combine 子对象无 zoom 字段（通过代理 parent 获取 zoom 区间）
      expect(scene.combineChild.minMax.max.toDouble(), 200.0);
      expect(scene.combineChild.minMax.min.toDouble(), 100.0);

      // alone 子对象完全不受 zoom 影响
      expect(scene.aloneChild.minMax.min.toDouble(), 2.0);
      expect(scene.aloneChild.minMax.max.toDouble(), 80.0);
    });

    test('clearZoomMinMax 后 combine 子对象立即回到自动合并值', () {
      final scene = _Scene();
      scene.updateRange(2, 8);
      scene.main.setZoomMinMax(_mm(200, 100));
      scene.updateRange(4, 6);

      // zoom 态下 combine 代理的是 zoom 区间
      expect(scene.combineChild.minMax.max.toDouble(), 200.0);

      scene.main.clearZoomMinMax();
      scene.updateRange(4, 6);

      // 退出 zoom 后 combine 代理的是主区自动合并值
      expect(scene.combineChild.minMax.max.toDouble(), 60.0);
      expect(scene.combineChild.minMax.min.toDouble(), 4.0);
      expect(
        identical(scene.combineChild.minMax, scene.main.minMax),
        isTrue,
      );
    });
  });
}
