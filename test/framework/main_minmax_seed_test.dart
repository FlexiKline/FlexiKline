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

/// 主区可见区间的**播种**模式。
///
/// `MainPaintObject.updateMinMax` 的首个子对象是整个区间的播种者：此刻没有既有端点可继承计算
/// 模式，只能由数据源指定。播种的是谁取决于 zIndex 升序（`IndicatorObject.compareTo`），而宿主
/// 能传任意值——一个 zIndex 比蜡烛（-1）更小的业务指标就会抢到播种位。
///
/// 播种没有归一时，这样一个返回 Decimal 区间的业务指标会把 `ComputeMode.fast` 的主区顶成
/// Decimal：本该是 double 的坐标换算变成每帧 BigInt 运算，且该端点在 `MinMax.lerp` 下 scale
/// 逐帧累加，`toDouble()` 先返回 Infinity 再返回 NaN，最后在主区画网格线时抛
/// `FormatException: NaN is not a valid format`。
library;

import 'package:decimal/decimal.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/framework/chart/indicator.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

const _mainRect = Rect.fromLTWH(0, 0, 300, 400);
final _combineKey = directKey(0);

/// zIndex 小于蜡烛(-1), 于是抢在蜡烛之前播种主区区间; 区间恒为 Decimal 支撑。
class _DecimalRangeIndicator extends DirectIndicator {
  _DecimalRangeIndicator({required super.key})
    : super(height: 100, autoActivate: false, zIndex: -2, padding: EdgeInsets.zero);

  @override
  DirectPaintObject<DirectIndicator> createPaintObject() => _DecimalRangePaintObject();
}

class _DecimalRangePaintObject extends DirectPaintObject<_DecimalRangeIndicator> {
  @override
  MinMax? computeVisibleMinMax(int start, int end) => MinMax(
    max: FlexiNum.fromDecimal(Decimal.parse('60000.12')),
    min: FlexiNum.fromDecimal(Decimal.parse('59500.34')),
  );

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

class _Scene {
  _Scene({ComputeMode mode = ComputeMode.fast})
    : context = (FakePaintContext()
        ..mainRect = _mainRect
        ..klineData = KlineData(
          const KlineSpec(symbol: '', interval: invalidInterval),
          list: List.empty(growable: false),
          computeMode: mode,
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
      mainIndicators: [_DecimalRangeIndicator(key: _combineKey)],
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
  group('主区区间播种按 klineData.computeMode', () {
    test('fast 模式：播种的 Decimal 端点被转成 double', () {
      final scene = _Scene();
      scene.frame();

      expect(scene.main.minMax.max.mode, ComputeMode.fast);
      expect(scene.main.minMax.min.mode, ComputeMode.fast);
      // 只换支撑类型, 数值按 fast 模式的精度保留。
      expect(scene.main.minMax.max.toDouble(), closeTo(60000.12, 1e-9));
      expect(scene.main.minMax.min.toDouble(), closeTo(59500.34, 1e-9));
    });

    test('accurate 模式：播种保持 Decimal, 不是一律转 double', () {
      final scene = _Scene(mode: ComputeMode.accurate);
      scene.frame();

      expect(scene.main.minMax.max.mode, ComputeMode.accurate);
      expect(scene.main.minMax.min.mode, ComputeMode.accurate);
    });

    /// 播种走 `setMinMax`, 归一是那个入口的后置条件, 不依赖调用方先处理。
    test('直接调用 updateMinMax 播种：不依赖调用方先归一', () {
      final scene = _Scene();
      scene.main.updateMinMax(
        MinMax(
          max: FlexiNum.fromDecimal(Decimal.parse('200.5')),
          min: FlexiNum.fromDecimal(Decimal.parse('5.25')),
        ),
      );

      expect(scene.main.minMax.max.mode, ComputeMode.fast);
      expect(scene.main.minMax.min.mode, ComputeMode.fast);
      expect(scene.main.minMax.max.toDouble(), 200.5);
    });

    /// `MinMax.reset` 恒复制, 所以 `setMinMax` 接管的是副本: 调用方的对象不会被 `expandByRatios`
    /// 就地改写。这条保证了 `computeVisibleMinMax` 可以缓存并复用同一个 MinMax 实例。
    test('setMinMax 不修改入参：调用方的实例可安全复用', () {
      final scene = _Scene();
      final input = MinMax(max: FlexiNum.fromNum(50.0), min: FlexiNum.fromNum(50.0));

      scene.main.setMinMax(input);

      expect(input.max.toDouble(), 50.0, reason: '入参不应被 expandByRatios 改写');
      expect(input.min.toDouble(), 50.0);
      expect(scene.main.minMax.max.toDouble(), greaterThan(50.0), reason: '退化区间应已外扩');
      expect(identical(scene.main.minMax, input), isFalse);
    });

    /// 非有限端点既换算不出坐标, 也过不了 accurate 模式的 `Decimal.parse`, 必须在写入点拒绝 ——
    /// 不能只靠那条 assert: release 下 assert 被完全剥除, `MinMax.reset` 会照样执行并抛
    /// `FormatException`。
    ///
    /// 这里只能验到 debug 契约(assert 抛)与状态不变量(区间保持上一帧)。release 下走的是 assert
    /// 之后的 `return`, 那条路径由 Dart 的 assert 语义保证, 不在测试可达范围内。
    test('setMinMax 拒绝非有限端点：区间保持上一帧, dyFactor 不被污染', () {
      for (final mode in ComputeMode.values) {
        final scene = _Scene(mode: mode);
        scene.frame();
        final before = scene.main.minMax.max.toDouble();

        expect(
          () => scene.main.setMinMax(
            MinMax(max: FlexiNum.fromNum(double.nan), min: FlexiNum.fromNum(0)),
          ),
          throwsA(isA<AssertionError>()),
          reason: '$mode: debug 下应由 assert 点名业务指标',
        );
        expect(scene.main.minMax.max.toDouble(), before, reason: '$mode: 应保留上一帧区间');
        expect(scene.main.dyFactor.isFinite, isTrue, reason: '$mode: dyFactor 不应被污染');
      }
    });

    test('setZoomMinMax 同样归一计算模式', () {
      final scene = _Scene();
      scene.main.setZoomMinMax(
        MinMax(
          max: FlexiNum.fromDecimal(Decimal.parse('300')),
          min: FlexiNum.fromDecimal(Decimal.parse('100')),
        ),
      );

      expect(scene.main.minMax.max.mode, ComputeMode.fast);
      expect(scene.main.minMax.min.mode, ComputeMode.fast);
    });

    /// 用户现场: fast 模式 + zIndex -2 的业务指标返回 Decimal 区间 + 连续平移。
    ///
    /// 修复前 `dyFactor` 在第 155 帧变成非有限值(60fps 下不到 3 秒), 随后 `dyToValue` 在
    /// `Decimal.parse('NaN')` 抛 FormatException, 表现为主区画网格线时崩溃。
    test('fast 模式连续平移 400 帧：dyFactor 始终有限, dyToValue 不抛', () {
      final scene = _Scene();

      for (int i = 1; i <= 400; i++) {
        scene.frame(panSmoothFactor: 0.15);
        expect(scene.main.dyFactor.isFinite, isTrue, reason: '第 $i 帧 dyFactor 非有限');
        expect(
          () => scene.main.dyToValue(scene.main.chartRect.top, check: false),
          returnsNormally,
          reason: '第 $i 帧 dyToValue 抛异常',
        );
      }
    });

    /// accurate 模式下端点**本就该是** Decimal, 归一后仍是 Decimal —— 这条路径上不存在任何
    /// 「污染」。它依然会崩, 因为 `MinMax.lerp` 的自乘让 Decimal 的 scale 逐帧累加。
    ///
    /// 这条用例是 [MinMax] 精度收口不可省的证明: 只撤销收口(模式归一全部保留)时它在第 153 帧
    /// 失败。
    ///
    /// 不能在循环前插一帧 `panSmoothFactor: 1.0`: 那会把 `_smoothMinMax` 置空, 于是之后每帧都
    /// 命中 `doUpdateVisibleMinMax` 的早退分支(start/end 未变 + `_smoothMinMax == null`),
    /// `smoothMinMax` 一次都不执行, 用例变成空转。
    test('accurate 模式连续平移 400 帧：无任何模式污染, 精度收口仍不可省', () {
      final scene = _Scene(mode: ComputeMode.accurate);

      for (int i = 1; i <= 400; i++) {
        scene.frame(panSmoothFactor: 0.15);
        if (i == 1) {
          expect(scene.main.minMax.max.mode, ComputeMode.accurate, reason: '前提：端点本就是 Decimal');
        }
        expect(
          scene.main.minMax.diffDivisor.toDouble().isFinite,
          isTrue,
          reason: '第 $i 帧 diffDivisor 换算为非有限值',
        );
        expect(
          () => scene.main.dyToValue(scene.main.chartRect.top, check: false),
          returnsNormally,
          reason: '第 $i 帧 dyToValue 抛异常',
        );
      }
    });
  });
}
