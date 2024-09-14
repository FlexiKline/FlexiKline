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

import '../extension/render/draw_circle.dart';
import '../config/line_config/line_config.dart';
import '../config/point_config/point_config.dart';
import '../model/bag_num.dart';
import 'common.dart';

/// Overlay 绘制点坐标
class Point {
  Point({
    this.index = -1,
    this.offset = Offset.infinite,
    this.ts = -1,
    this.value = BagNum.zero,
    this.offsetRate = 0,
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

  int ts;
  BagNum value;
  double offsetRate;

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
/// [visible] 是否单独隐藏
/// [mode] 磁吸模式
/// [steps] 指定Overlay需要几个点来完成绘制操作, 决定points的数量
/// [line] Overlay绘制时线配置
class Overlay implements Comparable<Overlay> {
  Overlay({
    required this.key,
    required this.type,
    this.zIndex = 0,
    this.lock = false,
    this.visible = true,
    this.mode = MagnetMode.normal,

    /// 绘制线配置, 默认值:drawConfig.drawLine
    required this.line,
  })  : id = DateTime.now().millisecondsSinceEpoch,
        points = List.filled(type.steps, null);

  final int id;
  final String key;
  final IDrawType type;
  int zIndex;
  bool lock;
  bool visible;
  MagnetMode mode;
  LineConfig line;

  List<Point?> points;

  /// 当前指针位置
  Point? pointer;

  DrawObject? object;

  bool get hasPointer => pointer != null;

  int get steps => points.length;

  /// 已开始绘制
  bool get isStarted => points.first == null;

  /// 最开始的状态, 即所有points均为空
  bool get isInitial => points.fold(true, (ret, item) => ret && item == null);

  /// 当前绘制中
  bool get isDrawing =>
      points.firstWhere((e) => e == null, orElse: () => null) == null;

  /// 即将完成
  bool get isComplete {
    return pointer != null && pointer!.index == steps - 1;
  }

  /// 当前绘制已完成, 修正中.
  bool get isEditing => points.fold(true, (ret, item) => ret && item != null);

  /// 添加指针[p]到[points]中, 并准备下一个指针
  void addPointer(Point p) {
    final index = p.index;
    assert(index >= 0 && index < steps, "point is invalid");
    assert(points[index] == null, 'The points[$index] is not empyt!');
    points[index] = p;

    if (index + 1 >= steps) {
      pointer = null;
    } else {
      pointer = Point.pointer(index + 1, p.offset);
    }
  }

  void updatePointer(Point p) {
    final index = p.index;
    assert(index >= 0 && index < steps, "point is invalid");
    assert(points[index] != null, 'The points[$index] is not empyt!');
    points[index] = p;
    pointer = null;
  }

  @mustCallSuper
  void dispose() {
    object?.dispose();
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
    return "Overlay(id:$id, key:$key, type:$type)";
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
  bool get visible => _overlay.visible;
  MagnetMode get mode => _overlay.mode;
  LineConfig get line => _overlay.line;
  Iterable<Point?> get points {
    if (_overlay.pointer == null) return _overlay.points;
    final pointerIndex = _overlay.pointer!.index;
    int index = 0;
    return _overlay.points.map((point) {
      // 如果当前指针与point的index相等(编辑状态)或者与points中的位置相等(绘制状态), 则使用pointer数据.
      if (point?.index == pointerIndex || index == pointerIndex) {
        return _overlay.pointer;
      }
      index++;
      return point;
    });
  }
  // Point? get pointer => overlay.pointer;
}

abstract class DrawObject<T extends Overlay> extends OverlayObject
    with DrawObjectMixin {
  const DrawObject(super.overlay);

  /// 碰撞测试[position]是否命中Overlay
  bool hitTest(Offset position) => false;

  /// 绘制Overlay
  void drawOverlay(Canvas canvas, Size size);

  @mustCallSuper
  void dispose() {
    _overlay.object = null;
  }
}

mixin DrawObjectMixin on OverlayObject {
  /// 绘制[points]中所有点为圆圈, 使用[pointConfig]作为配置
  void drawPointsAsCircles(Canvas canvas, PointConfig pointConfig) {
    for (var point in points) {
      if (point?.offset != null) {
        canvas.drawCirclePoint(point!.offset, pointConfig);
      }
    }
  }
}
