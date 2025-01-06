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

class OverlayObject implements Comparable<OverlayObject> {
  const OverlayObject(this._overlay, this.config);

  final Overlay _overlay;
  final DrawConfig config;

  int get id => _overlay.id;
  String get key => _overlay.key;
  IDrawType get type => _overlay.type;
  int get zIndex => _overlay.zIndex;
  bool get lock => _overlay.lock;
  LineConfig get line => _overlay.line;
  List<Point?> get points => _overlay.points;

  Color get lineColor => line.paint.color;
  int get steps => points.length;

  int get nextIndex => _overlay.nextIndex;

  /// 已开始绘制
  bool get isStarted => points.first == null;

  /// 最开始的状态, 即所有points均为空
  bool get isInitial => points.fold(true, (ret, item) => ret && item == null);

  /// 当前绘制中
  bool get isDrawing => points.fold(false, (ret, item) => ret || item == null);

  /// 当前绘制已完成, 修正中.
  bool get isEditing => points.fold(true, (ret, item) => ret && item != null);

  Overlay clone() {
    return Overlay(key: key, type: type, line: line);
  }

  void assertCheck([bool ignore = false]) {
    if (ignore) return;
    assert(
      points.length == type.steps,
      '${type.id}(${type.groupId}) only takes ${type.steps} point, but it has ${points.length}',
      //'${type.id}(${type.groupId}) draw points.length:${points.length} must be equals ${type.steps}',
    );
  }

  // void setDrawParam<T>(T params) {
  //   // ignore: avoid_dynamic_calls
  //   dynamic _defaultToEncodable(dynamic object) => object.toJson();
  //   _overlay._extra = _defaultToEncodable(params);
  // }

  // T? getDrawParam<T>(T? Function(Map<String, dynamic> json) fromJson) {
  //   if (_overlay._extra != null && _overlay._extra!.isNotEmpty) {
  //     try {
  //       return fromJson(_overlay._extra!);
  //     } catch (err) {
  //       debugPrint('$type getDrawParam catch an exception > ${err.toString()}');
  //     }
  //   }
  //   return null;
  // }

  @override
  int compareTo(OverlayObject other) {
    return _overlay.compareTo(other._overlay);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OverlayObject && _overlay == other._overlay);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ _overlay.hashCode;
}

abstract class DrawStateObject extends OverlayObject with DrawConfigMixin {
  DrawStateObject(super.overlay, super.config);

  /// 当前指针位置
  Point? _pointer;
  Point? get pointer => _pointer;

  /// 即将完成
  bool get isReady {
    return pointer != null && pointer!.index == steps - 1;
  }

  /// 当前overlay是否在移动中
  bool _moving = false;
  bool get moving => _moving;
  void setMoveing(bool isMoving) {
    _moving = isMoving;
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

  Point? get firstPoint => points.first;
  Point? get lastPoint => points.last;

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
  Rect? getTicksMarksBounds() {
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

/// 绘制接口
abstract interface class IDrawObject {
  /// 获取绘制参数. 用于自定义[DrawObject]时定制参数.
  dynamic getDrawParams(IDrawContext context);

  /// 初始化[DrawObject]绑定的[Overlay]中所有points坐标为当前绘制区别坐标.
  bool initPoints(IDrawContext context);

  /// 更新指针[point]的[offset]
  void onUpdateDrawPoint(Point point, Offset offset);

  /// 命中测试
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false});

  /// 构建Overlay
  void drawing(IDrawContext context, Canvas canvas, Size size);

  /// 绘制Overlay
  void draw(IDrawContext context, Canvas canvas, Size size);
}

abstract class DrawObject<T extends Overlay> extends DrawStateObject
    with DrawObjectMixin
    implements IDrawObject {
  DrawObject(super.overlay, super.config);

  @override
  dynamic getDrawParams(IDrawContext context) {}

  /// 初始化所有绘制点坐标
  @override
  bool initPoints(IDrawContext context) {
    for (var point in points) {
      if (point == null) return false;
      final offset = context.calcuateDrawPointOffset(point);
      if (offset == null) return false;
      point._offset = offset;
    }
    return true;
  }

  /// 更新指针[point]的[offset]
  /// 实现类中通过此接口控制每一个point的offset位置校正.
  @override
  void onUpdateDrawPoint(Point point, Offset offset) {
    point._offset = offset;
  }

  Point? hitTestPoint(IDrawContext context, Offset position) {
    assert(position.isFinite, 'hitTestPoint > position$position is infinite!');
    for (var point in points) {
      if (point?.offset.isFinite == true) {
        final distance = (position - point!.offset).distance;
        // assert(() {
        //   context.logd('hitTestPoint $position > ${point.index} = $distance');
        //   return true;
        // }());
        if (distance <= hitTestMinDistance) {
          return point;
        }
      }
    }
    return null;
  }

  /// 碰撞测试[position]是否命中Overlay
  @override
  bool hitTest(IDrawContext context, Offset position, {bool isMove = false}) {
    assert(points.isNotEmpty, 'hitTest points.length must be greater than 0');
    Point? last;
    for (var point in points) {
      if (point?.offset.isFinite == true && last != null) {
        final distance = position.distanceToLineSegment(
          last.offset,
          point!.offset,
        );
        assert(() {
          context.logd(
            'hitTest $position to [${point.offset}, ${last?.offset}] = $distance',
          );
          return true;
        }());

        if (distance <= hitTestMinDistance) {
          return true;
        }
      }
      last = point;
    }
    return false;
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
    _cleanTmpConfig();
    _pointer = null;
    _moving = false;
  }
}
