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
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin CrossBinding
    on KlineBindingBase, SettingBinding
    implements ICross, IState, IConfig, IChart {
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
    _repaintCross.value++;
  }

  //// Cross ////
  @override
  void markRepaintCross() => _markRepaint();

  // 是否正在绘制Cross
  @override
  bool get isCrossing => offset?.isFinite == true;

  // 取消当前Cross事件
  @override
  void cancelCross() {
    offset = null;
    markRepaintCross();
  }

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

      CandleModel? model;
      if (showLatestTipsInBlank) {
        model = offsetToCandle(offset);
        // 如果当前model为空, 则根据offset.dx计算当前model是最新的, 还是最后的.
        if (model == null) {
          if (offset.dx > startCandleDx) {
            model = curKlineData.latest;
          } else {
            model = curKlineData.list.last;
          }
        }
      }

      ensurePaintObjectInstance();

      /// 绘制Cross Line
      paintCrossLine(canvas, offset);

      mainIndicator.paintObject?.doOnCross(canvas, offset, model: model);

      int i = 0;
      for (var indicator in subIndicators) {
        indicator.paintObject?.bindSolt(i++);
        indicator.paintObject?.doOnCross(canvas, offset);
      }
    }
  }

  @override
  @protected
  bool handleTap(GestureData data) {
    if (isCrossing) {
      offset = null;
      markRepaintChart(); // 当Cross事件结束后, 调用markRepaintChart绘制Painting图层首根蜡烛的tips信息.
      markRepaintCross();
      return super.handleTap(data); // 不处理, 向上传递事件.
    }
    logd('handleTap cross > ${data.offset}');
    // 更新并校正起始焦点.
    offset = data.offset;
    markRepaintCross();
    markRepaintChart(); // 当Cross事件启动后, 调用markRepaintChart清理Painting图层的tips信息.
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
