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

class OverlayObject {
  OverlayObject(this._overlay);

  final Overlay _overlay;

  int get id => _overlay.id;
  String get key => _overlay.key;
  IDrawType get type => _overlay.type;
  int get zIndex => _overlay.zIndex;
  bool get lock => _overlay.lock;
  bool get moving => _overlay.moving;
  MagnetMode get mode => _overlay.mode;
  LineConfig get line => _overlay.line;
  Color get lineColor => line.paint.color;
  List<Point?> get points => _overlay.points;
  int get steps => points.length;
  Point? get pointer => _overlay.pointer;
  bool get isReady => _overlay.isReady;
  bool get isDrawing => _overlay.isDrawing;
  bool get isEditing => _overlay.isEditing;
  bool get isInitial => _overlay.isInitial;
  int get nextIndex => _overlay.nextIndex;

  /// 获取所有Point点列表,
  /// 包括pointer.
  Iterable<Point?> get allPoints {
    final pointer = this.pointer;
    if (pointer == null) return points;
    return points.mapIndexed((index, point) {
      if (index == pointer.index) return pointer;
      return point;
    });
  }

  /// 查找距离[dx]或[dy]小于[range]的最小point
  /// 如果同时指定, 则计算(dx, dy)到[allPoints]中点距离最小于[range]的point
  Point? findPoint({
    double? dx,
    double? dy,
    double range = 5,
  }) {
    if (range <= 0 || (dx == null && dy == null)) return null;
    Point? result;
    for (var point in allPoints) {
      if (point == null || point.offset.isInfinite) continue;
      double newRange = range;
      if (dx != null && dy != null) {
        newRange = (Offset(dx, dy) - point.offset).distance;
      } else if (dx != null) {
        newRange = (dx - point.offset.dx).abs();
      } else if (dy != null) {
        newRange = (dy - point.offset.dy).abs();
      }
      if (newRange < range) {
        result = point;
        range = newRange;
      }
    }
    return result;
  }

  /// 计算所有point点构成的刻度区域矩形.
  Rect? getTickMarksBounds() {
    Offset? pre, offset;
    Rect? bounds;
    for (var point in allPoints) {
      offset = point?.offset;
      if (offset == null || offset.isInfinite) continue;
      bounds = Rect.fromPoints(pre ?? offset, offset);
      pre = offset;
    }
    return bounds;
  }

  DrawConfig? _config;
  LineConfig? _crosshair;
  PointConfig? _crosspoint;
  Paint? _ticksGapBgPaint;
  TextAreaConfig? _tickText;
  PointConfig? _drawPoint;
}

/// 绘制样式配置管理
extension OverlayObjectExt on OverlayObject {
  LineConfig getCrosshairConfig(DrawConfig config) {
    if (_crosshair != null) return _crosshair!;
    _crosshair = config.crosshair;
    if (config.useDrawLineColor) {
      _crosshair = config.crosshair.copyWith(
        paint: _crosshair!.paint.copyWith(color: lineColor),
      );
    }
    return _crosshair!;
  }

  PointConfig getCrosspointConfig(DrawConfig config) {
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

  Paint? getTicksGapBgPaint(DrawConfig config) {
    if (_ticksGapBgPaint != null) return _ticksGapBgPaint;
    final opacity = config.ticksGapBgOpacity.clamp(0.0, 1.0);
    if (opacity == 0) return null;
    if (config.useDrawLineColor) {
      _ticksGapBgPaint = Paint()
        ..color = lineColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;
    } else if (config.tickText.background != null &&
        config.tickText.background!.alpha != 0) {
      _ticksGapBgPaint = Paint()
        ..color = config.tickText.background!.withOpacity(opacity)
        ..style = PaintingStyle.fill;
    }
    return _ticksGapBgPaint;
  }

  TextAreaConfig getTickTextConfig(DrawConfig config) {
    if (_tickText != null) return _tickText!;
    _tickText = config.tickText;
    if (config.useDrawLineColor) {
      _tickText = _tickText!.copyWith(background: lineColor);
    }
    return _tickText!;
  }

  PointConfig getDrawPointConfig(DrawConfig config) {
    if (_drawPoint != null) return _drawPoint!;
    _drawPoint = config.drawPoint;
    if (config.useDrawLineColor) {
      _drawPoint = _drawPoint!.copyWith(borderColor: lineColor);
    }
    return _drawPoint!;
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
      _ticksGapBgPaint = null;
      _drawPoint = null;
      _tickText = null;
      _crosspoint = null;
      _crosshair = null;
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
}

/// 绘制接口
abstract interface class IDrawObject {
  /// 获取绘制参数. 用于自定义[DrawObject]时定制参数.
  dynamic getDrawParams(IDrawContext context);

  /// 初始化[DrawObject]绑定的[Overlay]中所有points坐标为当前绘制区别坐标.
  bool initPoints(IDrawContext context);

  /// 命中测试
  bool hitTest(
    IDrawContext context,
    Offset position, {
    bool isMove = false,
  });

  /// 更新指针[point]的[offset]
  void onUpdatePoint(Point point, Offset offset, {bool isMove = false});

  /// 移动Overlay
  void onMoveOverlay(Offset delta);

  /// 构建Overlay
  void drawing(IDrawContext context, Canvas canvas, Size size);

  /// 绘制Overlay
  void draw(IDrawContext context, Canvas canvas, Size size);
}

abstract class DrawObject<T extends Overlay> extends OverlayObject
    with DrawObjectMixin
    implements IDrawObject {
  DrawObject(super.overlay);

  @override
  dynamic getDrawParams(IDrawContext context) {}

  /// 初始化所有绘制点坐标
  @override
  bool initPoints(IDrawContext context) {
    for (var point in _overlay.points) {
      if (point == null) return false;
      final succeed = context.updatePointByValue(point);
      if (!succeed) return false;
    }
    return true;
  }

  Point? hitTestPoint(IDrawContext context, Offset position) {
    assert(position.isFinite, 'hitTestPoint > position$position is infinite!');
    for (var point in points) {
      if (point?.offset.isFinite == true) {
        final distance = (position - point!.offset).distance;
        assert(() {
          context.logd('hitTestPoint $position > ${point.index} = $distance');
          return true;
        }());
        if (distance <= context.config.hitTestMinDistance) {
          return point;
        }
      }
    }
    return null;
  }

  /// 碰撞测试[position]是否命中Overlay
  @override
  bool hitTest(
    IDrawContext context,
    Offset position, {
    bool isMove = false,
  }) {
    assert(points.isNotEmpty, 'hitTest points.length must be greater than 0');
    Point? last;
    for (var point in points) {
      if (point?.offset.isFinite == true && last != null) {
        final distance = position.distanceToLine(
          last.offset,
          point!.offset,
        );
        assert(() {
          context.logd(
            'hitTest $position to [${point.offset}, ${last?.offset}] = $distance',
          );
          return true;
        }());

        if (distance <= context.config.hitTestMinDistance) {
          return true;
        }
      }
      last = point;
    }
    return false;
  }

  /// 更新指针[point]的[offset]
  /// 实现类中通过此接口控制每一个point的offset位置校正.
  @override
  void onUpdatePoint(Point point, Offset offset, {bool isMove = false}) {
    point.offset = offset;
  }

  /// 移动Overlay
  @override
  void onMoveOverlay(Offset delta) {
    for (var point in points) {
      if (point?.offset.isFinite == true) {
        point?.offset += delta;
      }
    }
  }

  /// 构建Overlay
  @override
  void drawing(IDrawContext context, Canvas canvas, Size size) {
    drawConnectingLine(context, canvas, size);
  }

  /// 绘制Overlay
  @override
  void draw(IDrawContext context, Canvas canvas, Size size);

  @mustCallSuper
  void dispose() {
    _overlay._object = null;
  }
}

mixin DrawObjectMixin on OverlayObject {
  /// 绘制[points]中所有点.
  void drawPoints(
    IDrawContext context,
    Canvas canvas, {
    bool isMoving = false,
  }) {
    final pointConfig = getDrawPointConfig(context.config);
    final crosspointConfig = getCrosspointConfig(context.config);
    for (var point in points) {
      if (point == null) continue;
      if (point == pointer || point.index == pointer?.index) {
        canvas.drawCirclePoint(point.offset, crosspointConfig);
      } else if (point.offset.isFinite) {
        canvas.drawCirclePoint(point.offset, pointConfig);
      }
    }
  }

  /// 绘制连接线
  void drawConnectingLine(IDrawContext context, Canvas canvas, Size size) {
    final config = context.config;
    Offset? last;
    final pointConfig = getDrawPointConfig(config);
    final crosshairConfig = getCrosshairConfig(config);
    for (var point in points) {
      if (point != null) {
        final offset = point.offset;
        canvas.drawCirclePoint(offset, pointConfig);
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
    final crosshairConfig = getCrosshairConfig(context.config);
    final crosspointConfig = getCrosspointConfig(context.config);
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
  void drawTick(
    IDrawContext context,
    Canvas canvas,
    Rect bounds,
  ) {
    final mainRect = context.mainRect;
    final timeRect = context.timeRect;
    final tickTextConfig = getTickTextConfig(context.config);
    final ticksGapBgPaint = getTicksGapBgPaint(context.config);

    /// 绘制时间刻度
    if (bounds.width > 0 && ticksGapBgPaint != null) {
      // 绘制left到right刻度之间的背景
      canvas.drawRect(
        Rect.fromLTRB(
          bounds.left,
          timeRect.top,
          bounds.right,
          timeRect.top + tickTextConfig.areaHeight,
        ),
        ticksGapBgPaint,
      );

      double startDx = bounds.left;
      double endDx = bounds.right;

      /// 当前判断顺序绘制顺序
      final position = pointer?.offset;
      if (moving && position != null && position.dx == bounds.left) {
        startDx = bounds.right;
        endDx = bounds.left;
      }

      drawTimeTick(
        context,
        canvas,
        startDx,
        drawableRect: timeRect,
        tickTextConfig: tickTextConfig,
      );
      drawTimeTick(
        context,
        canvas,
        endDx,
        drawableRect: timeRect,
        tickTextConfig: tickTextConfig,
      );
    } else {
      drawTimeTick(
        context,
        canvas,
        bounds.left,
        drawableRect: timeRect,
        tickTextConfig: tickTextConfig,
      );
    }

    /// 绘制价值刻度
    if (bounds.height > 0) {
      // 绘制top到bottom刻度之间的背景
      final txtWidth = valueTickSize?.width ?? 0;
      if (txtWidth > 0 && ticksGapBgPaint != null) {
        canvas.drawRect(
          Rect.fromLTRB(
            mainRect.right - context.config.spacing - txtWidth,
            bounds.top.clamp(mainRect.top, mainRect.bottom),
            mainRect.right - context.config.spacing,
            bounds.bottom.clamp(mainRect.top, mainRect.bottom),
          ),
          ticksGapBgPaint,
        );
      }

      double topDy = bounds.top;
      double bottomDy = bounds.bottom;

      /// 判断顺序绘制顺序
      final position = pointer?.offset;
      if (moving && position != null && position.dy == bounds.top) {
        topDy = bounds.bottom;
        bottomDy = bounds.top;
      }

      _valueTickSize = drawValueTick(
        context,
        canvas,
        topDy,
        drawableRect: mainRect,
        tickTextConfig: tickTextConfig,
      );
      _valueTickSize = drawValueTick(
        context,
        canvas,
        bottomDy,
        drawableRect: mainRect,
        tickTextConfig: tickTextConfig,
      );
    } else {
      _valueTickSize = drawValueTick(
        context,
        canvas,
        bounds.top,
        drawableRect: mainRect,
        tickTextConfig: tickTextConfig,
      );
    }
  }

  /// 在[drawableRect]区域上, 绘制由[dx]指定的时间刻度
  @protected
  Size drawTimeTick(
    IDrawContext context,
    Canvas canvas,
    double dx, {
    Rect? drawableRect,
    TextAreaConfig? tickTextConfig,
  }) {
    // TODO: 此处考虑直接从dx转换为ts
    int? index = context.dxToIndex(dx);
    if (index == null) return Size.zero;

    final klineData = context.curKlineData;
    final ts = klineData.indexToTimestamp(index);
    if (ts == null) return Size.zero;

    final timeTxt = formatTimeTick(ts, bar: klineData.timeBar);

    drawableRect ??= context.timeRect;
    tickTextConfig ??= getTickTextConfig(context.config);
    return canvas.drawTextArea(
      offset: Offset(
        dx,
        drawableRect.top,
      ),
      text: timeTxt,
      textConfig: tickTextConfig,
      drawDirection: DrawDirection.center,
      // drawableRect: drawableRect,
    );
  }

  /// 在[drawableRect]区域的右侧, 绘制由[dy]指定的价值刻度
  @protected
  Size drawValueTick(
    IDrawContext context,
    Canvas canvas,
    double dy, {
    Rect? drawableRect,
    TextAreaConfig? tickTextConfig,
  }) {
    final value = context.dyToValue(dy);
    if (value == null) return Size.zero;

    final valTxt = formatValueTick(
      value,
      precision: context.curKlineData.precision,
    );

    final txtSpacing = context.config.spacing;
    tickTextConfig ??= getTickTextConfig(context.config);
    final centerOffset = tickTextConfig.areaHeight / 2;
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
      textConfig: tickTextConfig,
      drawDirection: DrawDirection.rtl,
      drawableRect: drawableRect,
    );
  }

  /// 格式化时间刻度文本
  @protected
  String formatTimeTick(int ts, {TimeBar? bar}) {
    return formatDateTimeByTimeBar(ts, bar: bar);
  }

  /// 格式化价值刻度文本
  /// TODO: 此处考虑与[CandlePaintObject].formatMarkValueOnCross保持统一.
  @protected
  String formatValueTick(BagNum value, {int precision = 0}) {
    return formatNumber(value.toDecimal(), precision: precision);
  }
}
