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

/// 水平线族（水平趋势线 / 水平射线）的移动语义。
///
/// 这两个工具用 `onUpdateDrawPoint` 把两点的 dy 强行对齐，从而保证线始终水平。但该钩子
/// 同时是**整体平移**与**拖动单点**的唯一入口（见 `DrawBinding.onDrawMoveUpdate`），
/// 对齐的基准取错就会把「保持水平」变成「锁死价位」——线只能左右动，再也调不了价格。
///
/// 覆盖边界：`onUpdateDrawPoint` 的坐标修正。
/// **不覆盖**：手势识别、命中分派、绘制像素。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/draw_object_scenario.dart';

void main() {
  /// 水平线族的两个工具行为一致，用同一组用例跑。
  final cases = <String, ({IDrawType type, DrawObject Function(Overlay, DrawConfig) builder})>{
    'horizontalTrendLine': (
      type: horizontalTrendLine,
      builder: HorizontalTrendLineDrawObject.new,
    ),
    'horizontalRayLine': (
      type: horizontalRayLine,
      builder: HorizontalRayLineDrawObject.new,
    ),
  };

  for (final MapEntry(key: name, value: spec) in cases.entries) {
    group('v2.5.0/$name/move', () {
      DrawObject arrange() => buildEditingObject(
        spec.builder,
        type: spec.type,
        offsets: const [Offset(60, 150), Offset(180, 150)],
      );

      test('绘制完成时两点已对齐到同一 dy', () {
        final object = buildEditingObject(
          spec.builder,
          type: spec.type,
          // 第二点给一个不同的 dy，模拟用户手抖。
          offsets: const [Offset(60, 150), Offset(180, 210)],
        );

        // 绘制期的对齐发生在 onUpdateDrawPoint，落点后补一次即可复现。
        dragPoint(object, 1, const Offset(180, 210));

        expect(object.points[1]!.offset.dy, 150, reason: '水平线的两点必须共 dy');
      });

      test('整体平移改变 dy', () {
        final object = arrange();

        translateObject(object, const Offset(-40, 25));

        expect(
          object.points.map((p) => p!.offset).toList(),
          const [Offset(20, 175), Offset(140, 175)],
          reason:
              '对齐基准取「本次平移后的第一点」而不是「平移前的第一点」，'
              '否则 dy 恒等于旧值，整条线永远无法上下移动。',
        );
      });

      test('拖动第一点带着整条线走', () {
        final object = arrange();

        dragPoint(object, 0, const Offset(60, 90));

        expect(
          object.points.map((p) => p!.offset).toList(),
          const [Offset(60, 90), Offset(180, 90)],
          reason: '拖第一点应把两点一起抬到新 dy；只对齐「自己到自己」等于拖不动。',
        );
      });

      test('拖动第二点只改自己的 dx，dy 吸附到第一点', () {
        final object = arrange();

        dragPoint(object, 1, const Offset(240, 90));

        expect(
          object.points.map((p) => p!.offset).toList(),
          const [Offset(60, 150), Offset(240, 150)],
          reason: '拖第二点是调线长，不应把第一点也拉走。',
        );
      });
    });
  }
}
