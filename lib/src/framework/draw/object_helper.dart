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

part of 'overlay.dart';

mixin DrawConfigMixin on OverlayObject {
  LineConfig? _crosshair;
  PointConfig? _crosspoint;
  Paint? _ticksGapBgPaint;
  TextAreaConfig? _ticksText;
  PointConfig? _drawPoint;

  DrawParams get drawParams => config.drawParams;
  double get hitTestMinDistance => config.hitTestMinDistance;

  LineConfig get crosshairConfig {
    if (_crosshair != null) return _crosshair!;
    _crosshair = config.crosshair;
    if (config.useDrawLineColor) {
      _crosshair = config.crosshair.copyWith(
        paint: _crosshair!.paint.copyWith(color: lineColor),
      );
    }
    return _crosshair!;
  }

  PointConfig get crosspointConfig {
    if (_crosspoint != null) return _crosspoint!;
    _crosspoint = config.crosspoint;
    if (config.useDrawLineColor) {
      _crosspoint = config.crosspoint.copyWith(
        color: lineColor,
        borderColor: lineColor.withOpacity(
          _crosspoint!.borderColor?.opacity ?? 0,
        ),
      );
    }
    return _crosspoint!;
  }

  Paint? get ticksGapBgPaint {
    if (_ticksGapBgPaint != null) return _ticksGapBgPaint;
    final opacity = config.ticksGapBgOpacity.clamp(0.0, 1.0);
    if (opacity == 0) return null;
    if (config.useDrawLineColor) {
      _ticksGapBgPaint = Paint()
        ..color = lineColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;
    } else if (config.ticksText.background != null &&
        config.ticksText.background!.alpha != 0) {
      _ticksGapBgPaint = Paint()
        ..color = config.ticksText.background!.withOpacity(opacity)
        ..style = PaintingStyle.fill;
    }
    return _ticksGapBgPaint;
  }

  TextAreaConfig get ticksTextConfig {
    if (_ticksText != null) return _ticksText!;
    _ticksText = config.ticksText;
    if (config.useDrawLineColor) {
      _ticksText = _ticksText!.copyWith(background: lineColor);
    }
    return _ticksText!;
  }

  PointConfig get drawPointConfig {
    if (_drawPoint != null) return _drawPoint!;
    _drawPoint = config.drawPoint;
    if (config.useDrawLineColor) {
      _drawPoint = _drawPoint!.copyWith(borderColor: lineColor);
    }
    return _drawPoint!;
  }

  void setDrawLockState(bool isLock) {
    _overlay.lock = isLock;
  }

  void setDrawLineConfig(LineConfig line) {
    _overlay.line = line;
  }

  bool changeDrawLineStyle({
    Color? color,
    double? strokeWidth,
    LineType? lineType,
  }) {
    if (color == null && strokeWidth == null && lineType == null) {
      return false;
    }
    if (color != null) {
      _cleanTmpConfig();
    }
    color ??= line.paint.color;
    strokeWidth ??= line.paint.strokeWidth;
    lineType ??= lineType;
    setDrawLineConfig(line.copyWith(
      type: lineType,
      paint: line.paint.copyWith(
        color: color,
        strokeWidth: strokeWidth,
      ),
    ));
    return true;
  }

  void _cleanTmpConfig() {
    _ticksGapBgPaint = null;
    _drawPoint = null;
    _ticksText = null;
    _crosspoint = null;
    _crosshair = null;
  }
}

mixin DrawObjectMixin on DrawStateObject {
  /// 绘制[points]中所有点.
  void drawPoints(IDrawContext context, Canvas canvas) {
    for (var point in points) {
      if (point == null) continue;
      if (point == pointer || point.index == pointer?.index) {
        canvas.drawCirclePoint(point.offset, crosspointConfig);
      } else if (point.offset.isFinite) {
        canvas.drawCirclePoint(point.offset, drawPointConfig);
      }
    }
  }

  /// 绘制连接线
  void drawConnectingLine(IDrawContext context, Canvas canvas, Size size) {
    Offset? last;
    for (var point in points) {
      if (point != null) {
        final offset = point.offset;
        canvas.drawCirclePoint(offset, drawPointConfig);
        if (last != null) {
          final linePath = Path()
            ..moveTo(offset.dx, offset.dy)
            ..lineTo(last.dx, last.dy);
          canvas.drawLineType(
            crosshairConfig.type,
            linePath,
            crosshairConfig.linePaint,
            dashes: crosshairConfig.dashes,
          );
        }
        last = offset;
      } else if (pointer != null) {
        drawPointer(context, canvas, pointer!.offset, last);
        break;
      }
    }
  }

  /// 绘制指针
  void drawPointer(
    IDrawContext context,
    Canvas canvas,
    Offset pointer,
    Offset? last,
  ) {
    final mainRect = context.mainRect;
    final path = Path()
      ..moveTo(mainRect.left, pointer.dy)
      ..lineTo(mainRect.right, pointer.dy)
      ..moveTo(pointer.dx, mainRect.top)
      ..lineTo(pointer.dx, mainRect.bottom);
    canvas.drawLineType(
      crosshairConfig.type,
      path,
      crosshairConfig.linePaint,
      dashes: crosshairConfig.dashes,
    );

    if (last != null && last.isFinite) {
      final linePath = Path()
        ..moveTo(pointer.dx, pointer.dy)
        ..lineTo(last.dx, last.dy);
      canvas.drawLineType(
        crosshairConfig.type,
        linePath,
        crosshairConfig.linePaint,
        dashes: crosshairConfig.dashes,
      );
    }
    canvas.drawCirclePoint(pointer, crosspointConfig);
  }

  Size? __valueTickSize;
  Size? get valueTickSize => __valueTickSize;
  set _valueTickSize(Size size) {
    if (__valueTickSize != null) {
      if (size.width < __valueTickSize!.width) {
        __valueTickSize = size;
      }
    } else {
      __valueTickSize = size;
    }
  }

  /// 绘制刻度(时间/价值)
  void drawAxisTicksText(IDrawContext context, Canvas canvas, Rect bounds) {
    final mainRect = context.mainRect;
    final timeRect = context.timeRect;

    /// 绘制时间刻度
    if (bounds.width > 0 && ticksGapBgPaint != null) {
      // 绘制left到right刻度之间的背景
      canvas.drawRect(
        Rect.fromLTRB(
          bounds.left,
          timeRect.top,
          bounds.right,
          timeRect.top + ticksTextConfig.areaHeight,
        ),
        ticksGapBgPaint!,
      );

      double startDx = bounds.left;
      double endDx = bounds.right;

      /// 当前判断顺序绘制顺序
      final position = pointer?.offset;
      if (position != null && position.dx == bounds.left) {
        startDx = bounds.right;
        endDx = bounds.left;
      }

      drawTimeTicks(
        context,
        canvas,
        startDx,
        drawableRect: timeRect,
      );
      drawTimeTicks(
        context,
        canvas,
        endDx,
        drawableRect: timeRect,
      );
    } else {
      drawTimeTicks(
        context,
        canvas,
        bounds.left,
        drawableRect: timeRect,
      );
    }

    /// 绘制价值刻度
    if (bounds.height > 0) {
      // 绘制top到bottom刻度之间的背景
      final txtWidth = valueTickSize?.width ?? 0;
      if (txtWidth > 0 && ticksGapBgPaint != null) {
        canvas.drawRect(
          Rect.fromLTRB(
            mainRect.right - config.spacing - txtWidth,
            bounds.top.clamp(mainRect.top, mainRect.bottom),
            mainRect.right - config.spacing,
            bounds.bottom.clamp(mainRect.top, mainRect.bottom),
          ),
          ticksGapBgPaint!,
        );
      }

      double topDy = bounds.top;
      double bottomDy = bounds.bottom;

      /// 判断顺序绘制顺序
      final position = pointer?.offset;
      if (position != null && position.dy == bounds.top) {
        topDy = bounds.bottom;
        bottomDy = bounds.top;
      }

      _valueTickSize = drawValueTicks(
        context,
        canvas,
        topDy,
        drawableRect: mainRect,
      );
      _valueTickSize = drawValueTicks(
        context,
        canvas,
        bottomDy,
        drawableRect: mainRect,
      );
    } else {
      _valueTickSize = drawValueTicks(
        context,
        canvas,
        bounds.top,
        drawableRect: mainRect,
      );
    }
  }

  /// 在[drawableRect]区域上, 绘制由[dx]指定的时间刻度
  @protected
  Size drawTimeTicks(
    IDrawContext context,
    Canvas canvas,
    double dx, {
    Rect? drawableRect,
  }) {
    final ts = context.dxToTimestamp(dx);
    if (ts == null) return Size.zero;

    final klineData = context.curKlineData;
    final timeTxt = formatTimeTicksText(ts, bar: klineData.timeBar);

    drawableRect ??= context.timeRect;
    return canvas.drawTextArea(
      offset: Offset(
        dx,
        drawableRect.top,
      ),
      text: timeTxt,
      textConfig: ticksTextConfig,
      drawDirection: DrawDirection.center,
      // drawableRect: drawableRect,
    );
  }

  /// 在[drawableRect]区域的右侧, 绘制由[dy]指定的价值刻度
  @protected
  Size drawValueTicks(
    IDrawContext context,
    Canvas canvas,
    double dy, {
    Rect? drawableRect,
  }) {
    final value = context.dyToValue(dy);
    if (value == null) return Size.zero;

    final valTxt = formatValueTicksText(
      value,
      precision: context.curKlineData.precision,
    );

    final txtSpacing = config.spacing;
    final centerOffset = ticksTextConfig.areaHeight / 2;
    drawableRect ??= context.mainRect;
    return canvas.drawTextArea(
      offset: Offset(
        drawableRect.right - txtSpacing,
        (dy - centerOffset).clamp(
          drawableRect.top,
          drawableRect.bottom - centerOffset,
        ),
      ),
      text: valTxt,
      textConfig: ticksTextConfig,
      drawDirection: DrawDirection.rtl,
      drawableRect: drawableRect,
    );
  }

  /// 格式化时间刻度文本
  @protected
  String formatTimeTicksText(int ts, {TimeBar? bar}) {
    return formatDateTimeByTimeBar(ts, bar: bar);
  }

  /// 格式化价值刻度文本
  /// TODO: 此处考虑与[CandlePaintObject].formatMarkValueOnCross保持统一.
  @protected
  String formatValueTicksText(BagNum value, {int precision = 0}) {
    return formatNumber(value.toDecimal(), precision: precision);
  }
}

extension IDrawContextExt on IDrawContext {
  /// 以当前蜡烛图绘制参数为基础, 将绘制参数[point]转换Offset坐标.
  Offset? calcuateDrawPointOffset(Point point) {
    final dy = valueToDy(point.value);
    if (dy == null) return null;

    final dx = timestampToDx(point.ts);
    if (dx == null) return null;

    return Offset(dx, dy);
  }

  /// 以当前蜡烛图绘制数据为基础, 将[object]的所有point的坐标更新为蜡烛数据坐标
  void updateDrawObjectPointsData(DrawObject object) {
    for (var point in object.points) {
      if (point != null) {
        updateDrawPointData(point);
      }
    }
  }

  /// 以当前蜡烛图绘制数据为基础, 将[point]的坐标更新为蜡烛数据坐标
  bool updateDrawPointData(Point point) {
    final offset = point.offset;
    final ts = dxToTimestamp(offset.dx);
    if (ts == null) return false;

    final value = dyToValue(offset.dy);
    if (value == null) return false;

    point.ts = ts;
    point.value = value;
    return true;
  }

  /// 将[offset]吸附到蜡烛坐标上
  Offset magneticSnap(Offset offset) {
    if (drawMagnet.isNormal) return offset;

    double dx = offset.dx, dy = offset.dy;
    final index = dxToIndex(dx);
    if (index != null) {
      dx = indexToDx(index)! - candleWidthHalf;
    }
    BagNum? value = dyToValue(dy);
    final candle = curKlineData.getCandle(index);
    if (value != null && candle != null) {
      final high = candle.high;
      final low = candle.low;
      final minDistance = drawConfig.magnetMinDistance;
      if (value > high) {
        final highDy = valueToDy(high);
        if (highDy != null) {
          if (drawMagnet.isWeak && (highDy - dy) <= minDistance) {
            dy = highDy;
          } else if (drawMagnet.isStrong) {
            dy = highDy;
          }
        }
      } else if (value < low) {
        final lowDy = valueToDy(low);
        if (lowDy != null) {
          if (drawMagnet.isWeak && (dy - lowDy) <= minDistance) {
            dy = lowDy;
          } else if (drawMagnet.isStrong) {
            dy = lowDy;
          }
        }
      } else {
        BagNum midLow, midHigh;
        if (candle.isLong) {
          midLow = candle.open;
          midHigh = candle.close;
        } else {
          midLow = candle.close;
          midHigh = candle.open;
        }
        BagNum? result;
        if (value < midLow) {
          result = (midLow - value) > (value - low) ? low : midLow;
        } else if (value < midHigh) {
          result = (midHigh - value) > (value - midLow) ? midLow : midHigh;
        } else if (value < high) {
          result = (high - value) > (value - midHigh) ? midHigh : high;
        }
        if (result != null) dy = valueToDy(result) ?? dy;
      }
    }
    return Offset(dx, dy);
  }

  /// 检测[object]中所有point到所在蜡烛中心的距离是否相等.
  /// 如果相等, 则可以进行磁吸操作
  bool isMagneticDrawObject(DrawObject object) {
    double? first;
    for (var point in object.points) {
      final pointDx = point?.offset.dx;
      if (pointDx == null) return false;
      final index = dxToIndex(pointDx);
      if (index == null) return false;
      final dx = indexToDx(index)! - candleWidthHalf;
      // 计算point实际dx坐标与当前所在蜡烛中心坐标距离.
      final deltaDx = (pointDx - dx).abs();
      first ??= deltaDx;
      // 如果当前point的deltaDx与第一个point的deltaDx不相同, 则不可进行磁吸操作
      if ((deltaDx - first).abs() > precisionError) return false;
    }
    return true;
  }
}
