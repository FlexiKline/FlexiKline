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

  // DrawParams get drawParams => config.drawParams;
  double get hitTestMinDistance => config.hitTestMinDistance;

  LineConfig get crosshairConfig {
    if (_crosshair != null) return _crosshair!;
    _crosshair = config.crosshair.ensure(lineColor);
    return _crosshair!;
  }

  PointConfig get crosspointConfig {
    if (_crosspoint != null) return _crosspoint!;
    _crosspoint = config.crosspoint.ensure(
      themeColor: lineColor,
      themeBorderColor: lineColor,
    );
    return _crosspoint!;
  }

  Paint? get ticksGapBgPaint {
    if (_ticksGapBgPaint != null) return _ticksGapBgPaint;
    final opacity = config.ticksGapBgOpacity.clamp(0.0, 1.0);
    if (opacity == 0) return null;
    _ticksGapBgPaint = Paint()
      ..color = lineColor.withAlpha(opacity.alpha)
      ..style = PaintingStyle.fill;
    return _ticksGapBgPaint;
  }

  TextAreaConfig get ticksTextConfig {
    if (_ticksText != null) return _ticksText!;
    _ticksText = config.ticksText.ensure(
      themeTextColor: white,
      themeBackgroundColor: lineColor,
    );
    return _ticksText!;
  }

  PointConfig get drawPointConfig {
    if (_drawPoint != null) return _drawPoint!;
    _drawPoint = config.drawPoint.ensure(
      themeColor: lineColor,
      themeBorderColor: lineColor,
    );
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
    lineType ??= line.type;
    setDrawLineConfig(
      line.copyWith(
        type: lineType,
        paint: line.paint.copyWith(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
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

mixin DrawObjectMixin on DrawStateObject, PaintResourceOwner {
  /// 同一时刻最多画两个刻度, 多留一个给拖动中的来回切换。
  late final _timeTicks = own(LabelPainter(capacity: 3));
  late final _valueTicks = own(LabelPainter(capacity: 3));

  void doDidChangeTheme(IFlexiKlineTheme theme) {
    didChangeTheme(theme);
  }

  /// 绘制[points]中所有点.
  void drawPoints(DrawContext context, Canvas canvas) {
    for (final point in points) {
      if (point == null) continue;
      if (point == pointer || point.index == pointer?.index) {
        if (moving) {
          drawPointer(context, canvas, point.offset, null);
        } else {
          canvas.drawCirclePoint(point.offset, crosspointConfig);
        }
      } else if (point.offset.isFinite) {
        canvas.drawCirclePoint(point.offset, drawPointConfig);
      }
    }
  }

  /// 绘制选择圆和选择绘制线
  void drawConnectingLine(DrawContext context, Canvas canvas, Size size) {
    Offset? last;
    for (final point in points) {
      if (point != null) {
        final offset = point.offset;
        canvas.drawCirclePoint(offset, drawPointConfig);
        if (last != null) {
          final linePath = Path()
            ..moveTo(offset.dx, offset.dy)
            ..lineTo(last.dx, last.dy);
          canvas.drawLineByConfig(
            linePath,
            crosshairConfig,
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
    DrawContext context,
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
    canvas.drawLineByConfig(
      path,
      crosshairConfig,
    );

    if (last != null && last.isFinite) {
      final linePath = Path()
        ..moveTo(pointer.dx, pointer.dy)
        ..lineTo(last.dx, last.dy);
      canvas.drawLineByConfig(
        linePath,
        crosshairConfig,
      );
    }
    canvas.drawCirclePoint(pointer, crosspointConfig);
  }

  Rect? _valueTicksRect;
  Rect? get valueTicksRect => _valueTicksRect;

  /// 绘制刻度(时间/价值)
  void drawAxisTicksText(DrawContext context, Canvas canvas, Rect bounds) {
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
      double topDy = bounds.top;
      double bottomDy = bounds.bottom;

      /// 判断顺序绘制顺序
      final position = pointer?.offset;
      if (position != null && position.dy == bounds.top) {
        topDy = bounds.bottom;
        bottomDy = bounds.top;
      }

      // 先绘制文本, 拿到当前帧的实际宽度
      final topSize = drawValueTicks(
        context,
        canvas,
        topDy,
        drawableRect: mainRect,
      );
      final bottomSize = drawValueTicks(
        context,
        canvas,
        bottomDy,
        drawableRect: mainRect,
      );
      final maxWidth = math.max(topSize.width, bottomSize.width);

      // 用当前帧文本宽度绘制背景(opacity极低, 叠在文本上方无视觉影响)
      if (maxWidth > 0) {
        final top = topDy + topSize.height / 2 - (ticksTextConfig.borderRadius?.topLeft.y ?? 0);
        final bottom = bottomDy - bottomSize.height / 2 + (ticksTextConfig.borderRadius?.bottomLeft.y ?? 0);
        _valueTicksRect = Rect.fromLTRB(
          mainRect.right - config.spacing - maxWidth,
          top.clamp(mainRect.top, mainRect.bottom),
          mainRect.right - config.spacing,
          bottom.clamp(mainRect.top, mainRect.bottom),
        );
        if (ticksGapBgPaint != null) {
          canvas.drawRect(_valueTicksRect!, ticksGapBgPaint!);
        }
      } else {
        _valueTicksRect = null;
      }
    } else {
      final size = drawValueTicks(
        context,
        canvas,
        bounds.top,
        drawableRect: mainRect,
      );
      if (size.width > 0) {
        _valueTicksRect = Rect.fromLTWH(
          mainRect.right - config.spacing - size.width,
          bounds.top,
          size.width,
          size.height,
        );
      } else {
        _valueTicksRect = null;
      }
    }
  }

  /// 在[drawableRect]区域上, 绘制由[dx]指定的时间刻度
  @protected
  Size drawTimeTicks(
    DrawContext context,
    Canvas canvas,
    double dx, {
    Rect? drawableRect,
  }) {
    final ts = context.dxToTimestamp(dx);
    if (ts == null) return Size.zero;

    final unit = context.klineData.interval.unit;
    drawableRect ??= context.timeRect;
    return _timeTicks
        .paint(
          canvas,
          (ts, unit),
          build: () => formatTimeTicksText(ts, unit),
          style: ticksTextConfig.toLabelStyle(),
          anchor: Offset(dx, drawableRect.top),
          align: Alignment.topCenter,
        )
        .size;
  }

  /// 在[drawableRect]区域的右侧, 绘制由[dy]指定的价值刻度
  @protected
  Size drawValueTicks(
    DrawContext context,
    Canvas canvas,
    double dy, {
    Rect? drawableRect,
  }) {
    final value = context.dyToValue(dy);
    if (value == null) return Size.zero;

    final precision = context.klineData.precision;
    drawableRect ??= context.mainRect;
    return _valueTicks
        .paint(
          canvas,
          (value, precision),
          build: () => formatValueTicksText(value, precision: precision),
          style: ticksTextConfig.toLabelStyle(),
          anchor: Offset(drawableRect.right - config.spacing, dy),
          align: Alignment.centerRight,
          bounds: drawableRect,
        )
        .size;
  }

  /// 格式化时间刻度文本
  @protected
  String formatTimeTicksText(int ts, [TimeUnit? unit]) {
    return ts.dateTimeInMillisecond.formatByUnit(unit);
  }

  /// 格式化价值刻度文本
  @protected
  String formatValueTicksText(FlexiNum value, {int precision = 0}) {
    return formatPrice(
      value.toDecimal(),
      precision: precision,
      cutInvalidZero: false,
    );
  }
}

extension DrawContextExt on DrawContext {
  /// 以当前蜡烛图绘制参数为基础, 将绘制参数[point]转换Offset坐标.
  Offset? calculateDrawPointOffset(Point point) {
    final dx = timestampToDx(point.ts);
    if (dx == null) return null;

    return Offset(dx, valueToDy(point.value));
  }

  /// 以当前蜡烛图绘制数据为基础, 将[object]的所有point的坐标更新为蜡烛数据坐标
  void updateDrawObjectPointsData(DrawObject object) {
    for (final point in object.points) {
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

  /// 将[offset]吸附到蜡烛坐标: 横轴吸到所在蜡烛中心(空白区按蜡烛宽度外推);
  /// 纵轴吸到该蜡烛 OHLC 中最近的价位, 弱磁吸只在 [DrawConfig.magnetMinDistance] 像素内生效。
  Offset magneticSnap(Offset offset) {
    if (drawMagnet.isNormal) return offset;

    final index = dxToIndex(offset.dx);
    final dx = indexToDx(index);
    final candle = klineData.get(index);
    if (candle == null) return Offset(dx, offset.dy);

    var dy = offset.dy, distance = double.infinity;
    for (final value in [candle.high, candle.open, candle.close, candle.low]) {
      final valueDy = valueToDy(value);
      final d = (valueDy - offset.dy).abs();
      if (d < distance) (dy, distance) = (valueDy, d);
    }
    if (drawMagnet.isWeak && distance > drawConfig.magnetMinDistance) dy = offset.dy;
    return Offset(dx, dy);
  }

  /// 整体平移[object]后把它拉回蜡烛中心所需的横向位移。
  ///
  /// 只有所有点相对各自蜡烛中心的偏移相同(即平移前已对齐蜡烛网格)才返回位移, 否则返回 null,
  /// 免得把自由绘制的对象拉变形。
  double? magneticShift(DrawObject object) {
    double? shift;
    for (final point in object.points) {
      if (point == null) return null;
      final dx = point.offset.dx;
      final d = indexToDx(dxToIndex(dx)) - dx;
      shift ??= d;
      if ((d - shift).abs() > precisionError) return null;
    }
    return shift;
  }
}
