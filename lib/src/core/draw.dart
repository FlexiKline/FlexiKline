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

import 'package:flutter/foundation.dart';

import '../config/line_config/line_config.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/gesture_data.dart';
import '../overlay/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 图形绘制层
/// 每一种图形绘制主要分为以下几步:
/// 1. 启动绘制绘制功能, 此时会阻隔事件传递到chart/cross层
/// 2. 选择绘制图类型, 此时会主动进行第一绘制点待确认状态, 即会以主图区域中心点坐标绘制十字线.
/// 3. 移动绘制点, 并确认第一绘制点, 并转换成蜡烛数据坐标记录到[Overlay]的points的first位置.
/// 4. 重复步骤3, 确认绘制图类型所需要的所有绘制点.
/// 5. 绘制完成后, 当前绘制图形默认为选中状态.
mixin DrawBinding on KlineBindingBase, SettingBinding implements IDraw, IState {
  @override
  void initState() {
    super.initState();
    logd('initState draw');
    _drawStateListener.addListener(() {
      // 子状态更新
      final state = _drawStateListener.value;
      _drawTypeListener.value = state.overlay?.type;
      _drawEditingListener.value = state.isEditing;
    });
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose draw');
    _drawTypeListener.dispose();
    _drawEditingListener.dispose();
    _drawStateListener.dispose();
    _repaintDraw.dispose();
  }

  @override
  String get chartKey => curDataKey;

  @override
  LineConfig get drawLineConfig => drawConfig.drawLine;

  final ValueNotifier<int> _repaintDraw = ValueNotifier(0);

  @override
  Listenable get repaintDraw => _repaintDraw;
  void _markRepaint() {
    _repaintDraw.value++;
  }

  @override
  void markRepaintDraw() {
    _markRepaint();
  }

  /// DrawType的Overlay对应DrawObject的构建生成器集合
  final Map<IDrawType, DrawObjectBuilder> _overlayBuilders = {
    DrawType.horizontalLine: HorizontalLineDrawObject.new,
  };

  Iterable<IDrawType>? _supportDrawType;
  Iterable<IDrawType> get supportDrawType {
    return _supportDrawType ??= _overlayBuilders.keys;
  }

  /// 自定义overlay绘制对象构建器
  void customOverlayDrawObjectBuilder(
    IDrawType type,
    DrawObjectBuilder builder,
  ) {
    _overlayBuilders[type] = builder;
    _supportDrawType = null;
  }

  final _drawStateListener = ValueNotifier(DrawState.exited());
  final _drawTypeListener = ValueNotifier<IDrawType?>(null);
  final _drawEditingListener = ValueNotifier(false);

  DrawState get drawState => _drawStateListener.value;

  @override
  ValueListenable<DrawState> get drawStateLinstener => _drawStateListener;

  @override
  ValueListenable<IDrawType?> get drawTypeListener => _drawTypeListener;

  @override
  ValueListenable<bool> get drawEditingListener => _drawEditingListener;

  @override
  void onDrawPrepare() {
    // 如果已不是退出状态, 则无需变更状态.
    if (!drawState.isExited) return;
    _drawStateListener.value = const Prepared();
  }

  @override
  void onDrawStart(IDrawType type) {
    _drawStateListener.value = Started(type.createOverlay(this));
  }

  @override
  void onDrawUpdate(GestureData data) {
    if (!drawState.isEditing) return;
    _drawStateListener.value = Drawing(drawState.overlay);
  }

  @override
  void onDrawConfirm(GestureData data) {
    if (!drawState.isEditing) return;
  }

  @override
  void onDrawSelect(Overlay overlay) {
    if (!drawState.isPrepared) return;
    _drawStateListener.value = DrawState.edit(overlay);
  }

  @override
  void onDrawExit() {
    _drawStateListener.value = const Exited();
  }

  /// 绘制Draw图层
  @override
  void paintDraw(Canvas canvas, Size size) {
    if (!drawConfig.enable) return;

    // final offset = _offset;
    // if (offset == null || offset.isInfinite) {
    //   return;
    // }

    // paintDrawCrossLine(canvas, offset);
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
