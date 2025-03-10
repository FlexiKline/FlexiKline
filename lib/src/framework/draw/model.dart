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
    this.ts = -1,
    this.value = BagNum.zero,
    Offset? offset,
  }) : _offset = offset ?? Offset.infinite;

  factory Point.pointer(int index, Offset offset) {
    assert(index >= 0, 'invalid index($index)');
    assert(offset.isFinite, 'invalid offset($offset)');
    return Point(
      index: index,
      offset: offset,
    );
  }

  final int index;

  /// 蜡烛图时间
  int ts;

  /// 蜡烛图价值
  BagNum value;

  /// 当前canvas中的临时坐标(实时更新)
  Offset _offset;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Offset get offset => _offset;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Point &&
            runtimeType == other.runtimeType &&
            index == other.index &&
            ts == other.ts &&
            value == other.value);
  }

  @override
  int get hashCode {
    return runtimeType.hashCode ^ index.hashCode ^ ts.hashCode ^ value.hashCode;
  }

  @override
  String toString() {
    return 'Point($index, $ts, $value, $offset)';
  }

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
  Map<String, dynamic> toJson() => _$PointToJson(this);
}

/// Overlay基础配置
/// [key] 指定当前Overlay属于哪个[KlineData], 取KlineData.req.key
/// [type] 绘制类型
/// [zIndex] Overlay绘制顺序
/// [lock] 是否锁定
/// [steps] 指定Overlay需要几个点来完成绘制操作, 决定points的数量
/// [line] Overlay绘制时线配置
@FlexiOverlaySerializable
class Overlay implements Comparable<Overlay> {
  Overlay({
    required this.id,
    required this.key,
    required this.type,
    this.zIndex = 0,
    this.lock = false,

    /// 绘制线配置, 默认值:drawConfig.drawLine
    required this.line,
    required this.points,
  });

  factory Overlay.fromType({
    required String key,
    required IDrawType type,
    required LineConfig line,
  }) =>
      Overlay(
        id: DateTime.now().millisecondsSinceEpoch,
        key: key,
        type: type,
        line: line,
        points: List.filled(type.steps, null),
      );

  final int id;
  final String key;
  final IDrawType type;

  @protected
  final List<Point?> points;
  @protected
  int zIndex;
  @protected
  bool lock;
  @protected
  LineConfig line;
  // 额外数据, 内部控制序列化与反序列化
  // Map<String, dynamic>? _extra;

  int get steps => points.length;

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

  @override
  int compareTo(Overlay other) {
    return zIndex - other.zIndex;
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
    return "Overlay(id:$id, key:$key, type:$type) > points:$points";
  }

  factory Overlay.fromJson(Map<String, dynamic> json) =>
      _$OverlayFromJson(json);
  Map<String, dynamic> toJson() => _$OverlayToJson(this);
}
