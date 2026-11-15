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

/// 主区可见区间的**播种**与写入。
///
/// `MainPaintObject.updateMinMax` 的首个子对象是整个区间的播种者, 播种的是谁取决于 zIndex 升序
/// （`IndicatorObject.compareTo`）, 而宿主能传任意值: 一个 zIndex 比蜡烛（-1）更小的业务指标就会
/// 抢到播种位。播种与之后的合并都经 `setMinMax` 写入 `_minMax`。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/support.dart';

const _mainRect = Rect.fromLTWH(0, 0, 300, 400);
final _combineKey = directKey(0);

/// zIndex 小于蜡烛(-1), 于是抢在蜡烛之前播种主区区间。
class _SeedRangeIndicator extends DirectIndicator {
  _SeedRangeIndicator({required super.key})
    : super(height: 100, autoActivate: false, zIndex: -2, padding: EdgeInsets.zero);

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _SeedRangePaintObject();
}

class _SeedRangePaintObject extends DirectPaintObject<_SeedRangeIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => MinMax(max: 60000.12, min: 59500.34);

  @override
  void paint(Canvas canvas, Size size, {required int start, required int end}) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

class _Scene {
  _Scene()
    : context = (FakePaintContext()
        ..mainRect = _mainRect
        ..klineData = KlineData(
          const KlineSpec(symbol: '', interval: invalidInterval),
          list: List.empty(growable: false),
        )) {
    config = FakeFlexiKlineConfiguration(
      mainChildren: {_combineKey},
      mainIndicatorDefaultSize: _mainRect.size,
      mainIndicatorDefaultPadding: EdgeInsets.zero,
    );
    manager = IndicatorPaintObjectManager(configuration: config);
    manager.mountIndicators(
      context: context,
      candle: TestCandleIndicator(),
      time: TestTimeIndicator(),
      mainIndicators: [_SeedRangeIndicator(key: _combineKey)],
      subIndicators: const [],
    );
  }

  final FakePaintContext context;
  late final FakeFlexiKlineConfiguration config;
  late final IndicatorPaintObjectManager manager;

  MainPaintObject get main => manager.mainPaintObject;

  /// 走一帧。[panSmoothFactor] < 1 即平移平滑期, `_smoothMinMax` 会逐帧自插值。
  void frame({double panSmoothFactor = 1.0}) {
    main.doUpdateVisibleMinMax(
      mainPaneIndex,
      start: 0,
      end: 5,
      panSmoothFactor: panSmoothFactor,
    );
  }
}

void main() {
  group('主区区间播种与写入', () {
    test('zIndex 小于蜡烛的业务指标播种主区区间', () {
      final scene = _Scene();
      scene.frame();

      expect(scene.main.minMax.max, closeTo(60000.12, 1e-9));
      expect(scene.main.minMax.min, closeTo(59500.34, 1e-9));
    });

    /// `setMinMax` 接管的是副本: 主区会就地合并子对象区间、退化区间会被 `expandByRatios` 外扩,
    /// 都不能改到调用方的对象。这条保证了 `computeVisibleMinMax` 可以缓存并复用同一个 MinMax 实例。
    test('setMinMax 不修改入参：调用方的实例可安全复用', () {
      final scene = _Scene();
      final input = MinMax(max: 50, min: 50);

      scene.main.setMinMax(input);

      expect(input.max, 50.0, reason: '入参不应被 expandByRatios 改写');
      expect(input.min, 50.0);
      expect(scene.main.minMax.max, greaterThan(50.0), reason: '退化区间应已外扩');
      expect(identical(scene.main.minMax, input), isFalse);
    });

    test('setZoomMinMax 不修改入参', () {
      final scene = _Scene();
      final input = MinMax(max: 300, min: 100);

      scene.main.setZoomMinMax(input);

      expect(identical(scene.main.minMax, input), isFalse);
      expect(scene.main.minMax.max, 300.0);
      expect(scene.main.minMax.min, 100.0);
    });

    /// 非有限端点换算不出坐标, 必须在写入点拒绝, 不能只靠那条 assert: release 下 assert 被剥除。
    ///
    /// 这里只能验到 debug 契约(assert 抛)与状态不变量(区间保持上一帧)。release 下走的是 assert
    /// 之后的 `return`, 那条路径由 Dart 的 assert 语义保证, 不在测试可达范围内。
    test('setMinMax 拒绝非有限端点：区间保持上一帧, dyFactor 不被污染', () {
      final scene = _Scene();
      scene.frame();
      final before = scene.main.minMax.max;

      expect(
        () => scene.main.setMinMax(MinMax(max: double.nan, min: 0)),
        throwsA(isA<AssertionError>()),
        reason: 'debug 下应由 assert 点名业务指标',
      );
      expect(scene.main.minMax.max, before, reason: '应保留上一帧区间');
      expect(scene.main.dyFactor.isFinite, isTrue, reason: 'dyFactor 不应被污染');
    });

    test('连续平移 400 帧：dyFactor 始终有限, dyToValue 不抛', () {
      final scene = _Scene();

      for (int i = 1; i <= 400; i++) {
        scene.frame(panSmoothFactor: 0.15);
        expect(scene.main.dyFactor.isFinite, isTrue, reason: '第 $i 帧 dyFactor 非有限');
        expect(
          () => scene.main.dyToValue(scene.main.chartRect.top),
          returnsNormally,
          reason: '第 $i 帧 dyToValue 抛异常',
        );
      }
    });
  });
}
