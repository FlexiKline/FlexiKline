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

import 'package:flutter/material.dart';

import '../extension/export.dart';
import '../framework/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 负责绘制图层
///
mixin DrawBinding on KlineBindingBase, SettingBinding implements IDraw, IState {
  @override
  void initState() {
    super.initState();
    logd('initState draw');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
    _repaintDraw.dispose();
  }

  final ValueNotifier<int> _repaintDraw = ValueNotifier(0);
  @override
  Listenable get repaintDraw => _repaintDraw;
  void _markRepaint() {
    _repaintDraw.value++;
  }

  @override
  void markRepaintDraw() {
    if (isDrawing) {
      _updateOffset(_offset);
      _markRepaint();
    }
  }

  /// 是否在绘制中
  final ValueNotifier<bool> _isDrawing = ValueNotifier(false);
  ValueNotifier<bool> get isDrawingLinstener => _isDrawing;
  @override
  bool get isDrawing => _isDrawing.value;

  Offset? _offset;
  void _updateOffset(Offset? val) {
    if (val != null) {
      _offset = val;
    } else {
      _offset = null;
    }
  }

  /// 矫正Cross
  Offset? _correctDrawOffset(Offset val) {
    if (val.isInfinite) return null;

    // Horizontal轴按蜡烛线移动.
    val = val.clamp(canvasRect);
    final diff = startCandleDx - val.dx;
    if (!crossConfig.moveByCandleInBlank && diff < 0) return val;
    return Offset(
      val.dx + diff % candleActualWidth - candleWidthHalf,
      val.dy,
    );

    // 当超出边界时, 校正到边界.
    // if (canvasRect.contains(val)) {
    //   final diff = (startCandleDx - val.dx) % candleActualWidth;
    //   final dx = val.dx + diff - candleWidthHalf;
    //   return Offset(dx, val.dy);
    // } else {
    //   return val.clamp(canvasRect);
    // }
  }

  final ValueNotifier<DrawType?> currentDrawType = ValueNotifier(null);

  @override
  void startDraw(DrawType type) {
    if (type == currentDrawType.value) {
      currentDrawType.value = null;
      _isDrawing.value = false;
    } else {
      currentDrawType.value = type;
      _isDrawing.value = true;
    }
  }

  // @override
  // bool startCross(GestureData data, {bool force = false}) {
  //   if (drawConfig.enable) {
  //     if (force || isDrawing) {
  //       logd('handleTap draw > $force > ${data.offset}');
  //       // 更新并校正起始焦点.
  //       _updateOffset(data.offset);
  //       _markRepaint();
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  // @override
  // void updateCross(GestureData data) {
  //   if (drawConfig.enable && isDrawing) {
  //     _updateOffset(data.offset);
  //     _markRepaint();
  //   }
  // }

  // @override
  // void cancelCross() {
  //   if (isDrawing || _offset != null) {
  //     _updateOffset(null);
  //     _markRepaint();
  //   }
  // }

  /// 绘制Draw图层
  @override
  void paintDraw(Canvas canvas, Size size) {
    if (!drawConfig.enable || !isDrawing) return;

    final offset = _offset;
    if (offset == null || offset.isInfinite) {
      return;
    }

    paintDrawCrossLine(canvas, offset);
  }

  void paintDrawCrossLine(Canvas canvas, Offset offset) {
    final path = Path()
      ..moveTo(mainChartLeft, offset.dy)
      ..lineTo(mainChartRight, offset.dy)
      ..moveTo(offset.dx, 0)
      ..lineTo(offset.dx, canvasHeight);

    canvas.drawLineType(
      drawConfig.crosshair.type,
      path,
      drawConfig.crosshairPaint,
      dashes: drawConfig.crosshair.dashes,
    );

    canvas.drawCircle(
      offset,
      drawConfig.point.radius,
      drawConfig.pointPaint,
    );

    if (drawConfig.border != null) {
      canvas.drawCircle(
        offset,
        drawConfig.border!.radius,
        drawConfig.borderPaint!,
      );
    }
  }
}
