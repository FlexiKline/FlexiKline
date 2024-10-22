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

import '../core/interface.dart';
import '../data/kline_data.dart';
import '../extension/export.dart';
import '../framework/draw/overlay.dart';

class PriceLineDrawObject extends DrawObject {
  PriceLineDrawObject(super.overlay, super.config);

  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(
      points.length == 1,
      'HorizontalLine only takes one point, but it has ${points.length}',
    );
    final first = points.firstOrNull?.offset;
    if (first == null) return false;

    final mainRect = context.mainRect;
    if (!mainRect.include(first)) return false;

    final distance = position.distanceToRayLine(
      first,
      Offset(mainRect.right, first.dy),
    );
    return distance <= hitTestMinDistance;
  }

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    assert(
      points.length == 1,
      'PriceLine only takes one point, but it has ${points.length}',
    );
    final first = points.firstOrNull?.offset;
    if (first == null) return;
    final mainRect = context.mainRect;
    if (!mainRect.include(first)) {
      context.logi('draw($type), but first:$first not in mainRect.');
      return;
    }

    // 画线
    canvas.drawLineByConfig(
      Path()
        ..addPolygon(
          [first, Offset(mainRect.right, first.dy)],
          false,
        ),
      line,
    );

    // 画价值文本区域
    final value = context.dyToValue(first.dy);
    if (value != null) {
      final valTxt = formatValueTicksText(
        value,
        precision: context.curKlineData.precision,
      );
      final ticksText = drawParams.priceText ?? ticksTextConfig;
      final margin = drawParams.priceTextMargin;
      canvas.drawTextArea(
        offset: Offset(
          first.dx + margin.left,
          first.dy - ticksText.areaHeight - margin.bottom,
        ),
        text: valTxt,
        textConfig: ticksText,
        drawDirection: DrawDirection.ltr,
        // drawableRect: drawableRect,
      );
    }
  }
}
