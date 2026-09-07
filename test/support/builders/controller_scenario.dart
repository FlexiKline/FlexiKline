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

/// Controller 级薄 arrange 脚手架。
library;

import 'dart:ui' show PictureRecorder;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/widgets.dart' show Canvas;
import 'package:flutter_test/flutter_test.dart';

import '../doubles/fake_kline_config.dart';
import '../doubles/test_indicators.dart';

/// 驱动一帧图表绘制，让 `doUpdateVisibleMinMax` 走完一轮并泵掉这一帧。
///
/// [ControllerScenario.initWithData] 不绘制，所以任何依赖 `minMax` 已算出的断言
/// （Y 轴映射、缩放、能否开始缩放）都要先调一次本方法。
///
/// 必须泵帧：`calculatePaintChartRange` 会排一个 post-frame 回调去写 notifier，不泵掉它
/// 会活到本用例 dispose 之后，在下一个用例的首帧里炸「used after disposed」。
Future<void> paintChartFrame(WidgetTester tester, FlexiKlineController chart) async {
  chart.paintChart(Canvas(PictureRecorder()), chart.canvasRect.size);
  await tester.pump();
}

/// Controller 级场景构建器
class ControllerScenario {
  /// [controller] 供需要观察 controller 自身调用的用例传入 spy 子类；传了它 [config] 就无效，
  /// configuration 由调用方在构造 controller 时给。
  ControllerScenario({FakeFlexiKlineConfiguration? config, FlexiKlineController? controller})
      : controller = controller ??
            FlexiKlineController(
              configuration: config ?? FakeFlexiKlineConfiguration(),
            );

  final FlexiKlineController controller;

  /// 本次挂载使用的蜡烛指标，供用例切换图表类型等。
  late final TestCandleIndicator candle;

  /// switch → update → mount → initState 完整链。
  ///
  /// [canvasWidth] 模拟 widget 层的 `LayoutBuilder` 上报宽度。不传时 `mainRect`
  /// 宽度为 0，任何依赖画布几何的断言（如按位置分派 tap）都会落空。
  Future<void> initWithData(
    KlineSpec spec,
    List<CandleModel> candles, {
    List<Indicator> mainIndicators = const [],
    List<Indicator> subIndicators = const [],
    double? canvasWidth,
    TestCandleIndicator? candle,
  }) async {
    controller.switchKlineData(spec);
    controller.replaceKlineData(spec, candles);
    this.candle = candle ?? TestCandleIndicator();
    controller.mountIndicators(
      candle: this.candle,
      time: TestTimeIndicator(),
      mainIndicators: mainIndicators,
      subIndicators: subIndicators,
    );
    controller.initState();
    if (canvasWidth != null) {
      controller.setAdaptLayoutMode(width: canvasWidth);
    }
  }

  void dispose() => controller.dispose();
}
