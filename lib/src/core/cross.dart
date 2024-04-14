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
import '../model/export.dart';
import '../render/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin CrossBinding
    on KlineBindingBase, SettingBinding
    implements ICross, IState, IConfig {
  @override
  void initBinding() {
    super.initBinding();
    logd('init cross');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose cross');
  }

  final ValueNotifier<int> _repaintCross = ValueNotifier(0);
  @override
  Listenable get repaintCross => _repaintCross;
  void _markRepaint() {
    checkAndCreatePaintObject();
    _repaintCross.value++;
  }

  //// Cross ////
  @override
  void markRepaintCross() => _markRepaint();

  // 是否正在绘制Cross
  @override
  bool get isCrossing => offset?.isFinite == true;
  // 当前Cross焦点.
  @override
  Offset? get crossingOffset => _offset;
  Offset? _offset;
  Offset? get offset => _offset;
  set offset(Offset? val) {
    if (val != null) {
      _offset = correctCrossOffset(val);
    } else {
      _offset = null;
    }
  }

  /// 矫正Cross
  Offset? correctCrossOffset(Offset offset) {
    if (offset.isInfinite) return null;

    // X轴按蜡烛线移动.
    offset = offset.clamp(canvasRect);
    final diff = (startCandleDx - offset.dx) % candleActualWidth;
    final dx = offset.dx + diff - candleWidthHalf;
    return Offset(dx, offset.dy);

    // 当超出边界时, X轴平滑移动.
    // if (canvasRect.contains(offset)) {
    //   final diff = (startCandleDx - offset.dx) % candleActualWidth;
    //   final dx = offset.dx + diff - candleWidthHalf;
    //   return Offset(dx, offset.dy);
    // } else {
    //   return offset.clamp(canvasRect);
    // }
  }

  /// 绘制最新价与十字线
  @override
  void paintCross(Canvas canvas, Size size) {
    if (isCrossing) {
      final offset = this.offset;
      if (offset == null || offset.isInfinite) {
        return;
      }

      /// 绘制Cross Line
      paintCrossLine(canvas, offset);

      mainIndicator.paintObject?.onCross(canvas, offset);

      int i = 0;
      for (var indicator in subIndicators) {
        indicator.paintObject?.bindSolt(i++);
        indicator.paintObject?.onCross(canvas, offset);
      }

      // if (showCrossYAxisTickMark) {
      //   /// 绘制Cross Y轴价钱刻度
      //   paintCrossYAxisPriceMark(canvas, offset);
      // }

      // if (showCrossXAxisTickMark) {
      //   /// 绘制Cross X轴时间刻度
      //   paintCrossXAxisTimeMark(canvas, offset);
      // }

      // if (showPopupCandleCard) {
      //   /// 绘制Cross 命中的蜡烛数据弹窗
      //   paintPopupCandleCard(canvas, offset);
      // }
    }
  }

  @override
  @protected
  bool handleTap(GestureData data) {
    if (isCrossing) {
      offset = null;
      markRepaintCross();
      return super.handleTap(data); // 不处理, 向上传递事件.
    }
    logd('handleTap cross > ${data.offset}');
    // 更新并校正起始焦点.
    offset = data.offset;
    markRepaintCross();
    return true;
  }

  @override
  @protected
  void handleMove(GestureData data) {
    if (!isCrossing) {
      return super.handleMove(data);
    }
    offset = data.offset;
    markRepaintCross();
  }

  @override
  @protected
  void handleScale(GestureData data) {
    if (isCrossing) {
      logd('handleMove cross > ${data.offset}');
      // 注: 当前正在展示Cross, 不能缩放, 直接return拦截.
      return;
    }
    return super.handleScale(data);
  }

  /// 绘制Cross Line
  @protected
  void paintCrossLine(Canvas canvas, Offset offset) {
    final path = Path()
      ..moveTo(mainDrawLeft, offset.dy)
      ..lineTo(mainDrawRight, offset.dy)
      ..moveTo(offset.dx, 0)
      ..lineTo(offset.dx, canvasHeight);

    canvas
      ..drawDashPath(
        path,
        crossLinePaint,
        dashes: crossLineDashes,
      )
      ..drawCircle(
        offset,
        crossPointRadius,
        crossPointPaint,
      );
  }
}
