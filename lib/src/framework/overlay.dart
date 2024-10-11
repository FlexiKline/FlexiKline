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

import '../constant.dart';
import '../core/interface.dart';
import '../data/kline_data.dart';
import '../extension/export.dart';
import '../config/line_config/line_config.dart';
import '../model/bag_num.dart';
import '../model/range.dart';
import '../utils/date_time.dart';
import '../utils/decimal_format_util.dart';
import 'common.dart';

/// Overlay 绘制点坐标
class Point {
  Point({
    this.index = -1,
    this.offset = Offset.infinite,
    this.ts = -1,
    this.value = BagNum.zero,
    this.patch = 0,
  });

  static Point pointer(int index, Offset offset) {
    assert(index >= 0, 'invalid index($index)');
    assert(offset.isFinite, 'invalid offset($offset)');
    return Point(
      index: index,
      offset: offset,
    );
  }

  final int index;

  /// 当前canvas中的坐标(实时更新)
  Offset offset;

  /// 蜡烛图时间
  int ts;

  /// 蜡烛图价值
  BagNum value;

  /// 用于对[ts]和[value]组成坐标的修正
  double patch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          ts == other.ts &&
          value == other.value;

  @override
  int get hashCode =>
      runtimeType.hashCode ^ index.hashCode ^ ts.hashCode ^ value.hashCode;

  @override
  String toString() {
    return 'Point($index, $offset, $ts, $value)';
  }
}

/// Overlay基础配置
/// [key] 指定当前Overlay属于哪个[KlineData], 取KlineData.req.key
/// [type] 绘制类型
/// [zIndex] Overlay绘制顺序
/// [lock] 是否锁定
/// [mode] 磁吸模式
/// [steps] 指定Overlay需要几个点来完成绘制操作, 决定points的数量
/// [line] Overlay绘制时线配置
class Overlay implements Comparable<Overlay> {
  Overlay({
    required this.key,
    required this.type,
    this.zIndex = 0,
    this.lock = false,
    this.mode = MagnetMode.normal,

    /// 绘制线配置, 默认值:drawConfig.drawLine
    required this.line,
  })  : id = DateTime.now().millisecondsSinceEpoch,
        points = List.filled(type.steps, null);

  final int id;
  final String key;
  final IDrawType type;
  final List<Point?> points;

  int zIndex;
  bool lock;
  MagnetMode mode;
  LineConfig line;

  /// 当前指针位置
  Point? _pointer;
  Point? get pointer => _pointer;

  /// 当前overlay是否在移动中
  bool _moving = false;
  bool get moving => _moving;

  DrawObject? object;

  bool get hasPointer => pointer != null;

  int get steps => points.length;

  /// 已开始绘制
  bool get isStarted => points.first == null;

  /// 最开始的状态, 即所有points均为空
  bool get isInitial => points.fold(true, (ret, item) => ret && item == null);

  /// 当前绘制中
  bool get isDrawing => points.fold(false, (ret, item) => ret || item == null);

  /// 即将完成
  bool get isReady {
    return pointer != null && pointer!.index == steps - 1;
  }

  /// 当前绘制已完成, 修正中.
  bool get isEditing => points.fold(true, (ret, item) => ret && item != null);

  int get nextIndex {
    final index = points.indexWhere((p) => p == null);
    return index != -1 ? index : points.length - 1;
  }

  Range? get timeRange {
    int? start, end, tmp;
    for (var p in points) {
      tmp = p?.ts;
      if (tmp != null && tmp > 0) {
        start ??= tmp;
        end ??= tmp;
        start = start > tmp ? start : tmp;
        end = end < tmp ? end : tmp;
      }
    }
    if (start != null && end != null) {
      return Range(start, end);
    }
    return null;
  }

  /// 添加指针[p]到[points]中, 并准备下一个指针
  void addPointer(Point p) {
    final index = p.index;
    assert(index >= 0 && index < steps, "point is invalid");
    assert(points[index] == null, 'The points[$index] is not empyt!');
    points[index] = p;

    if (index + 1 >= steps) {
      _pointer = null;
    } else {
      _pointer = Point.pointer(index + 1, p.offset);
    }
  }

  void confirmPointer() {
    if (pointer == null) return;
    final index = pointer!.index;
    assert(index >= 0 && index < steps, "point is invalid");
    assert(points[index] != null, 'The points[$index] is not empyt!');
    points[index] = pointer;
    _pointer = null;
    _moving = false;
  }

  void setPointer(Point? p) {
    if (p != null && p.index >= 0 && p.index < steps) {
      _pointer = p;
    } else {
      _pointer = null;
    }
  }

  void setMoveing(bool isMoving) {
    _moving = isMoving;
  }

  @mustCallSuper
  void dispose() {
    object?.dispose();
    object = null;
  }

  @override
  int compareTo(Overlay other) {
    return other.zIndex - zIndex;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is Overlay &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        key == other.key &&
        type == other.type) {
      // equals 其他属性?
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash =
        runtimeType.hashCode ^ id.hashCode ^ key.hashCode ^ type.hashCode;
    // combine其他属性?
    return hash;
  }

  @override
  String toString() {
    return "Overlay(id:$id, key:$key, type:$type) > pointer:$pointer < points:$points";
  }
}

class OverlayObject {
  const OverlayObject(this._overlay);

  final Overlay _overlay;

  int get id => _overlay.id;
  String get key => _overlay.key;
  IDrawType get type => _overlay.type;
  int get zIndex => _overlay.zIndex;
  bool get lock => _overlay.lock;
  bool get moving => _overlay.moving;
  MagnetMode get mode => _overlay.mode;
  LineConfig get line => _overlay.line;
  List<Point?> get points => _overlay.points;
  int get steps => points.length;
  Point? get pointer => _overlay.pointer;
  bool get isReady => _overlay.isReady;

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

  /// 查找距离[dx]与[dy]小于[range]的最小point
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
}

abstract class DrawObject<T extends Overlay> extends OverlayObject
    with DrawObjectMixin {
  DrawObject(super.overlay);

  /// 初始化所有绘制点坐标
  bool initPoint(IDrawContext context) {
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
  void onUpdatePoint(Point point, Offset offset, {bool isMove = false}) {
    point.offset = offset;
  }

  /// 移动Overlay
  void onMoveOverlay(Offset delta) {
    for (var point in points) {
      if (point?.offset.isFinite == true) {
        point?.offset += delta;
      }
    }
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

  /// 绘制刻度
  void drawTick(
    IDrawContext context,
    Canvas canvas,
    Rect bounds,
  ) {
    final mainRect = context.mainRect;
    final timeRect = context.timeRect;
    final tickText = context.config.tickText;

    /// 绘制时间刻度
    if (bounds.width > 0) {
      // 绘制left到right刻度之间的背景
      canvas.drawRect(
        Rect.fromLTRB(
          bounds.left,
          timeRect.top,
          bounds.right,
          timeRect.top + tickText.areaHeight,
        ),
        context.config.gapBgPaint,
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
      );
      drawTimeTick(
        context,
        canvas,
        endDx,
        drawableRect: timeRect,
      );
    } else {
      drawTimeTick(
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
      if (txtWidth > 0) {
        canvas.drawRect(
          Rect.fromLTRB(
            mainRect.right - context.config.spacing - txtWidth,
            bounds.top.clamp(mainRect.top, mainRect.bottom),
            mainRect.right - context.config.spacing,
            bounds.bottom.clamp(mainRect.top, mainRect.bottom),
          ),
          context.config.gapBgPaint,
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
      );
      _valueTickSize = drawValueTick(
        context,
        canvas,
        bottomDy,
        drawableRect: mainRect,
      );
    } else {
      _valueTickSize = drawValueTick(
        context,
        canvas,
        bounds.top,
        drawableRect: mainRect,
      );
    }
  }

  /// 构建Overlay
  void drawing(IDrawContext context, Canvas canvas, Size size) {
    final config = context.config;
    Offset? last;
    for (var point in points) {
      if (point != null) {
        final offset = point.offset;
        canvas.drawCirclePoint(offset, config.drawPoint);
        if (last != null) {
          final linePath = Path()
            ..moveTo(offset.dx, offset.dy)
            ..lineTo(last.dx, last.dy);
          canvas.drawLineType(
            config.crosshair.type,
            linePath,
            config.crosshair.linePaint,
            dashes: config.crosshair.dashes,
          );
        }
        last = offset;
      } else if (pointer != null) {
        drawPointer(context, canvas, pointer!.offset, last);
        break;
      }
    }
  }

  /// 绘制Overlay
  void draw(IDrawContext context, Canvas canvas, Size size);

  @mustCallSuper
  void dispose() {
    _overlay.object = null;
  }
}

mixin DrawObjectMixin on OverlayObject {
  /// 绘制[points]中所有点.
  void drawPoints(
    IDrawContext context,
    Canvas canvas, {
    bool isMoving = false,
  }) {
    for (var point in points) {
      if (point == null) continue;
      if (point == pointer || point.index == pointer?.index) {
        canvas.drawCirclePoint(point.offset, context.config.crosspoint);
      } else if (point.offset.isFinite) {
        canvas.drawCirclePoint(point.offset, context.config.drawPoint);
      }
    }
  }

  void drawPointer(
    IDrawContext context,
    Canvas canvas,
    Offset pointer,
    Offset? last,
  ) {
    final mainRect = context.mainRect;
    final config = context.config;
    final path = Path()
      ..moveTo(mainRect.left, pointer.dy)
      ..lineTo(mainRect.right, pointer.dy)
      ..moveTo(pointer.dx, mainRect.top)
      ..lineTo(pointer.dx, mainRect.bottom);
    canvas.drawLineType(
      config.crosshair.type,
      path,
      config.crosshair.linePaint,
      dashes: config.crosshair.dashes,
    );

    if (last != null && last.isFinite) {
      final linePath = Path()
        ..moveTo(pointer.dx, pointer.dy)
        ..lineTo(last.dx, last.dy);
      canvas.drawLineType(
        config.crosshair.type,
        linePath,
        config.crosshair.linePaint,
        dashes: config.crosshair.dashes,
      );
    }
    canvas.drawCirclePoint(pointer, config.crosspoint);
  }

  /// 在[drawableRect]区域上, 绘制由[dx]指定的时间刻度
  @protected
  Size drawTimeTick(
    IDrawContext context,
    Canvas canvas,
    double dx, {
    Rect? drawableRect,
  }) {
    // TODO: 此处考虑直接从dx转换为ts
    int? index = context.dxToIndex(dx);
    if (index == null) return Size.zero;

    final klineData = context.curKlineData;
    final ts = klineData.indexToTimestamp(index);
    if (ts == null) return Size.zero;

    final timeTxt = formatTimeTick(ts, bar: klineData.timeBar);

    drawableRect ??= context.timeRect;
    return canvas.drawTextArea(
      offset: Offset(
        dx,
        drawableRect.top,
      ),
      text: timeTxt,
      textConfig: context.config.tickText,
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
  }) {
    final value = context.dyToValue(dy);
    if (value == null) return Size.zero;

    final valTxt = formatValueTick(
      value,
      precision: context.curKlineData.precision,
    );

    final txtSpacing = context.config.spacing;
    final tickText = context.config.tickText;
    final centerOffset = tickText.areaHeight / 2;
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
      textConfig: tickText,
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
