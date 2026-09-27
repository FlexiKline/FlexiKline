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

import 'dart:ui';

import 'package:flexi_kline/flexi_kline.dart';

import 'draw_param.dart';
import 'draw_tools_config.dart';

class ArrowLineDrawObject extends DrawObject {
  ArrowLineDrawObject(super.overlay, super.config);

  static ArrowLineDrawParam get drawParam => DrawToolsConfig.instance.arrowLine;

  @override
  bool hitTest(DrawContext context, Offset position, {bool isMove = false}) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return false;
    }

    final distance = position.distanceToLineSegment(first, second);
    return distance <= hitTestMinDistance;
  }

  @override
  void draw(DrawContext context, Canvas canvas, Size size) {
    assertCheck();

    final first = points.firstOrNull?.offset;
    final second = points.secondOrNull?.offset;
    if (first == null || second == null) {
      return;
    }

    // 画线
    canvas.drawLineByConfig(
      Path()..addPolygon([first, second], false),
      line,
    );

    // 画箭头
    final drawRect = context.mainRect;
    if (drawRect.contains(second)) {
      final vector = (first - second).normalized() * drawParam.arrowsLen;
      final arrow1 = vector.rotate(drawParam.arrowsRadians) + second;
      final arrow2 = vector.rotate(-drawParam.arrowsRadians) + second;

      canvas.drawLineByConfig(
        Path()..addPolygon([second, arrow1], false),
        line,
      );
      canvas.drawLineByConfig(
        Path()..addPolygon([second, arrow2], false),
        line,
      );
    }
  }
}
