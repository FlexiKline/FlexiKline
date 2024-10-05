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
import '../extension/render/draw_path.dart';
import '../framework/overlay.dart';

class TrendLineDrawObject extends DrawObject {
  TrendLineDrawObject(super.overlay);

  @override
  void draw(IDrawContext context, Canvas canvas, Size size) {
    List<Offset> dotList = [];
    for (var point in points) {
      if (point?.offset.isFinite == true) {
        dotList.add(point!.offset);
      }
    }
    context.logd('TrendLine dotList]\t:$dotList');
    canvas.drawLineType(
      line.type,
      Path()..addPolygon(dotList, false),
      line.linePaint,
    );
  }
}
