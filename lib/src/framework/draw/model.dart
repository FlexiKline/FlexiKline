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

/// Overlay 绘制点坐标
@FlexiOverlaySerializable
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
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
  Map<String, dynamic> toJson() => _$PointToJson(this);
}

/// Overlay基础配置
/// [key] 指定当前Overlay属于哪个[KlineData], 取KlineData.req.key
/// [type] 绘制类型
/// [zIndex] Overlay绘制顺序
/// [lock] 是否锁定
/// [mode] 磁吸模式
/// [steps] 指定Overlay需要几个点来完成绘制操作, 决定points的数量
/// [line] Overlay绘制时线配置
@FlexiOverlaySerializable
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
  @protected
  LineConfig line;
  LineConfig get lineConfig => line;

  /// 当前指针位置
  Point? _pointer;
  Point? get pointer => _pointer;

  /// 当前overlay是否在移动中
  bool _moving = false;
  bool get moving => _moving;

  DrawObject? _object;
  DrawObject? get object => _object;

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
    _object?.dispose();
    _object = null;
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

  factory Overlay.fromJson(Map<String, dynamic> json) =>
      _$OverlayFromJson(json);
  Map<String, dynamic> toJson() => _$OverlayToJson(this);
}
