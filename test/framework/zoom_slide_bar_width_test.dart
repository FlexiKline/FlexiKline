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

/// zoom 滑竿热区宽度的单调增长：`CandleBasePaintObject._reportZoomSlideBarRect`。
///
/// 热区宽度来自主区 Y 轴刻度文本的实测宽度，而文本长度随缩放、平移改变（整数位跨量级、
/// step 换档），逐帧照实上报会让命中区左右抖动，表现为「刚才能拖、现在拖不到」。
///
/// 观察点是上报本身而不是 controller 的 `chartZoomSlideBarRect`：后者是 `ValueNotifier`，
/// 同值写入不通知，「稳定态零上报」这条根本观测不到。所以这里用假 context 收下每一次
/// 上报，宽度回缩、重复上报、清空后不重新上报都会留下痕迹。
///
/// controller 那一侧的自动上报链路由 `core/chart_zoom_slide_bar_report_test` 守。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/support.dart';

/// 主区尺寸。高度取 indicator 声明的 300，让 `chartRect` 与 `drawableRect` 等高。
const _mainWidth = 400.0;
const _mainHeight = 300.0;

void main() {
  /// 文本度量走 `TextPainter`，没有绑定就拿不到字体。
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 三位整数的价格区间：`precision` 2 时刻度文本恒为 `1xx.xx`，长度与主区高度无关。
  void setShortRange(_ZoomBarScene scene) => scene.setRange(min: 100, max: 180);

  /// 六位整数的价格区间：同一 `precision` 下比 [setShortRange] 多三个字符。
  void setLongRange(_ZoomBarScene scene) => scene.setRange(min: 100000, max: 180000);

  group('v2.5.0/主区Y轴/滑竿宽度', () {
    test('刻度文本变短: 热区宽度不回缩, 且不再上报', () {
      final scene = _ZoomBarScene();
      setLongRange(scene);
      scene.paintFrame();
      final wide = scene.lastReport.width;

      setShortRange(scene);
      scene.paintFrame();

      expect(scene.lastReport.width, wide, reason: '宽度回缩会让 zoom 命中区在缩放中途左右跳');
      expect(scene.reports, hasLength(1), reason: '宽度取 max 后 Rect 未变, 不该再上报');
    });

    test('刻度文本变长: 宽度扩大并上报', () {
      final scene = _ZoomBarScene();
      setShortRange(scene);
      scene.paintFrame();
      final narrow = scene.lastReport.width;

      setLongRange(scene);
      scene.paintFrame();

      expect(scene.reports, hasLength(2));
      expect(scene.lastReport.width, greaterThan(narrow), reason: '文本变长必须撑开热区, 否则拖不到滑竿');
      expect(scene.lastReport.right, _mainWidth, reason: '热区始终贴主区右缘');
    });

    test('稳定态: 连续绘制只上报一次', () {
      final scene = _ZoomBarScene();
      setShortRange(scene);
      scene.paintFrame();
      scene.paintFrame();
      scene.paintFrame();

      expect(scene.reports, hasLength(1), reason: '每帧上报会每帧提交一次 post-frame 回调');
    });

    test('换标的: 宽度重新收敛, 不沿用上一个标的', () {
      final scene = _ZoomBarScene(precision: 8);
      setShortRange(scene);
      scene.paintFrame();
      final wide = scene.lastReport.width;

      // 价格区间不动, 只换标的与精度: 小数位由 8 位降到 2 位, 文本随之变短。
      scene.switchSymbol(symbol: 'OTHER', precision: 2);
      scene.paintFrame();

      expect(scene.reports, hasLength(2), reason: '清空后首帧必须重新上报, 否则热区一直是空的');
      expect(scene.lastReport.width, lessThan(wide), reason: '沿用上一个标的的宽度会让热区盖住图表');
    });

    /// 判据是 symbol 而不是 `spec.key`：后者含 interval，用它会把每次换周期也当成换标的，
    /// 让宽度在同一个标的上反复重新收敛。
    test('切周期: 宽度不清空', () {
      final scene = _ZoomBarScene(precision: 8);
      setShortRange(scene);
      scene.paintFrame();
      final wide = scene.lastReport.width;

      scene.switchInterval();
      // 同标的换周期后让文本变短: 清空过就会跟着缩回去。
      scene.setRange(min: 1, max: 1.8);
      scene.paintFrame();

      expect(scene.reports, hasLength(1));
      expect(scene.lastReport.width, wide, reason: '价格量级不随周期变, 没有重新收敛的理由');
    });

    test('主题变化: 宽度重新收敛', () {
      final scene = _ZoomBarScene(precision: 8);
      setShortRange(scene);
      scene.paintFrame();
      final wide = scene.lastReport.width;

      // 同 precision 下缩短文本: 整数位从三位降到一位。不清空则宽度停在 [wide]。
      scene.setRange(min: 1, max: 1.8);
      scene.paintFrame();
      expect(scene.lastReport.width, wide, reason: '前置条件: 单调增长本应吃掉这次变短');

      scene.notifyThemeChanged();
      scene.paintFrame();

      expect(scene.reports, hasLength(2));
      expect(scene.lastReport.width, lessThan(wide), reason: '主题可换字体, 旧宽度不再可信');
    });

    test('主区高度变化: 宽度不变也重新上报', () {
      final scene = _ZoomBarScene();
      setShortRange(scene);
      scene.paintFrame();
      final before = scene.lastReport;

      scene.resizeMain(240);
      // 真实帧里 computeVisibleMinMax 每帧重写区间, dyFactor 随之跟上新高度。
      setShortRange(scene);
      scene.paintFrame();

      expect(scene.reports, hasLength(2), reason: '只比宽度会漏掉 grid resize 与指标增删');
      expect(scene.lastReport.width, before.width, reason: '前置条件: 本用例要求宽度不变');
      expect(scene.lastReport.height, 240);
      expect(scene.lastReport.top, 0);
    });

    test('宿主接管热区(useCustomZoomRect): 一次都不上报', () {
      final scene = _ZoomBarScene(useCustomZoomRect: true);
      setShortRange(scene);
      scene.paintFrame();
      setLongRange(scene);
      scene.paintFrame();

      expect(scene.reports, isEmpty);
    });
  });
}

/// 直接驱动 [CandleBasePaintObject] 的 Y 轴刻度两趟绘制，并收下每一次热区上报。
///
/// 不经 controller：那条路上的上报走 `addPostFrameCallback` 落进 `ValueNotifier`，同值
/// 写入被吞，数不出上报次数。
class _ZoomBarScene {
  _ZoomBarScene({int precision = 2, bool useCustomZoomRect = false}) {
    context.data = _dataWith(precision: precision);
    context.gesture = GestureConfig(useCustomZoomRect: useCustomZoomRect);
    context.mainRect = const Rect.fromLTWH(0, 0, _mainWidth, _mainHeight);
    object.bind(indicator, context);
  }

  static const _day = FlexiTimeInterval(1, TimeUnit.day);
  static const _hour = FlexiTimeInterval(1, TimeUnit.hour);

  /// `padding` 为零，`height` 与主区等高：`chartRect` 因此等于 `drawableRect`。
  final indicator = TestCandleIndicator(height: _mainHeight);
  final context = _ReportSpyContext();
  final object = _SpyCandlePaintObject();

  List<Rect> get reports => context.reports;
  Rect get lastReport => context.reports.last;

  /// 设定 Y 轴区间：刻度文本的长度由它与 `precision` 共同决定。
  void setRange({required num min, required num max}) {
    object.setMinMax(MinMax(min: FlexiNum.fromNum(min), max: FlexiNum.fromNum(max)));
  }

  /// 换标的：替换数据并派发依赖变化，与 `IndicatorPaintObjectManager.notifySpecChanged`
  /// 在 `spec.key` 变化时做的事一致。
  void switchSymbol({required String symbol, required int precision}) {
    _switchTo(_dataWith(symbol: symbol, precision: precision));
  }

  /// 切周期：同标的，只换 interval，`spec.key` 同样变化。
  void switchInterval() {
    final spec = context.data.spec;
    _switchTo(KlineData(spec.copyWith(interval: _hour)));
  }

  void _switchTo(KlineData data) {
    final oldSpec = context.data.spec;
    context.data = data;
    object.notifyDependenciesChanged(oldSpec);
  }

  void resizeMain(double height) {
    context.mainRect = Rect.fromLTWH(0, 0, _mainWidth, height);
    object.resetPaintBounding();
  }

  void notifyThemeChanged() => object.notifyThemeChanged();

  /// 驱动 Y 轴刻度的两趟绘制：网格线一趟产出本帧刻度，画文本一趟度量宽度并上报。
  ///
  /// 位置经返回值在两趟之间传递，与 `ChartBinding.paintChart` 里的局部变量同一形状。
  void paintFrame() {
    final canvas = Canvas(PictureRecorder());
    final size = context.mainRect.size;
    final dys = object.paintLinesAndTakeDys(canvas, size);
    object.paintYAxisTickLabels(canvas, size, dys: dys);
  }
}

KlineData _dataWith({String symbol = 'ZOOM-BAR-WIDTH', required int precision}) => KlineData(
      KlineSpec(
        symbol: symbol,
        interval: _ZoomBarScene._day,
        precision: precision,
      ),
    );

/// 记录每一次热区上报的假 context；`klineData` 与 `gestureConfig` 由测试驱动。
class _ReportSpyContext extends FakePaintContext {
  final List<Rect> reports = [];

  KlineData data = KlineData.empty;
  GestureConfig gesture = GestureConfig();

  @override
  KlineData get klineData => data;

  @override
  GestureConfig get gestureConfig => gesture;

  @override
  void reportChartZoomSlideBarRect(Rect rect) => reports.add(rect);
}

/// 最小可绘制的蜡烛对象：只需要基类的 Y 轴刻度能力。
class _SpyCandlePaintObject extends CandleBasePaintObject<TestCandleIndicator> {
  /// 挂载入口：`mount` 对外受保护，子类内调用是它的正常用法。
  void bind(TestCandleIndicator indicator, PaintContext context) => mount(indicator, context);

  /// 主题变化钩子入口，同上。
  void notifyThemeChanged() => didChangeTheme();

  /// 依赖变化钩子入口，同上。
  void notifyDependenciesChanged(KlineSpec oldSpec) => didChangeDependencies(oldSpec);

  /// 网格线那一趟的入口：`paintGridLines` 是 `@protected`，它服务实现者而不是公开 API，
  /// 用例只能经子类转发。
  List<double> paintLinesAndTakeDys(Canvas canvas, Size size) {
    return paintGridLines(canvas, size).dys;
  }

  @override
  FlexiChartType resolveChartType() => FlexiChartType.barSolid;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  Size? paintTips(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}
