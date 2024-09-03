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

import '../config/line_config/line_config.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/gesture_data.dart';
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
    currentDrawType.addListener(() {});
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
    _repaintDraw.dispose();
  }

  @override
  String get chartKey => curDataKey;

  @override
  LineConfig get lineConfig => drawConfig.drawLine;

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

  final ValueNotifier<DrawType?> currentDrawType = ValueNotifier(null);
  bool get isStartDraw => currentDrawType.value != null;

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

  @override
  void onConfirm(GestureData data) {
    if (!isStartDraw) return;
    _offset = data.offset;
    _markRepaint();
  }

  @override
  void onDrawStart(GestureData data) {
    if (drawConfig.enable) {
      if (isDrawing) {
        logd('handleTap draw > ${data.offset}');
        // 更新并校正起始焦点.
        _updateOffset(data.offset);
        _markRepaint();
        return;
      }
    }
    return;
  }

  @override
  void onDrawUpdate(GestureData data) {
    if (drawConfig.enable && isDrawing) {
      _updateOffset(data.offset);
      _markRepaint();
    }
  }

  @override
  void onDrawEnd() {
    if (isDrawing || _offset != null) {
      _updateOffset(null);
      _markRepaint();
    }
  }

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
      drawConfig.crosshair.linePaint,
      dashes: drawConfig.crosshair.dashes,
    );

    canvas.drawCirclePoint(offset, drawConfig.crosspoint);

    canvas.drawCirclePoint(offset, drawConfig.drawDot);
  }
}
