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

/// 测试用绘制工具：两点直线。
///
/// 仓库本体不含任何 [DrawObject] 实现（绘制工具由使用方经
/// `registerDrawObjectBuilder` 注册），所以手势测试必须自带一个。
/// 刻意不覆写 [hitTest]：命中判据正是被测对象，要用框架默认的线段距离判定。
library;

import 'package:flexi_kline/flexi_kline.dart';
// painting 而非 widgets: widgets 的 Overlay widget 与绘制框架的 Overlay 同名。
import 'package:flutter/painting.dart';

/// 两点直线类型，[FlexiDrawType.steps] 为 2。
const testDrawLineType = FlexiDrawType('test_draw_line', 2, groupId: 'test');

/// 只实现绘制契约的最小 [DrawObject]。
class TestDrawObject extends DrawObject<Overlay> {
  TestDrawObject(super.overlay, super.config);

  /// 绘制过程与结果都不产生像素：测试只关心手势与命中，不做像素断言。
  @override
  void drawing(DrawContext context, Canvas canvas, Size size) {}

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {}
}

/// 注册 [testDrawLineType] 的构造器。挂载 controller 后调用一次即可。
void registerTestDrawObject(FlexiKlineController controller) {
  controller.registerDrawObjectBuilder(
    testDrawLineType,
    (overlay, config) => TestDrawObject(overlay, config),
  );
}

/// 走完整绘制流程画出一条两点直线，并停在 `Editing` 状态。
///
/// 必须传 `isInitPointer: false`：否则 `startDraw` 会把第一个点预置到 `mainRect`
/// 中心，测试就控制不了它的位置。两次确认之间必须插一次 [onDrawUpdate]——
/// [DrawObject.addPointer] 让下一个 pointer 继承上一个点的 offset，不更新的话两点重合。
void drawTestLine(
  FlexiKlineController controller, {
  required Offset from,
  required Offset to,
}) {
  controller.startDraw(testDrawLineType, isInitPointer: false);
  controller.onDrawConfirm(GestureData.tap(from));
  controller.onDrawUpdate(GestureData.pan(to));
  controller.onDrawConfirm(GestureData.tap(to));
}
