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

import 'package:decimal/decimal.dart';

import '../config/line_config/line_config.dart';
import 'common.dart';

/// Overlay 绘制点坐标
class Point {
  Point({
    required this.ts,
    required this.value,
    this.offsetRate = 0,
    this.offset = Offset.infinite,
  });

  final int ts;
  final Decimal value;
  final double offsetRate;

  /// 当前canvas中的坐标(实时更新)
  Offset offset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          ts == other.ts &&
          value == other.value &&
          offsetRate == other.offsetRate;

  @override
  int get hashCode =>
      runtimeType.hashCode ^ ts.hashCode ^ value.hashCode ^ offsetRate.hashCode;
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
class Overlay {
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

  // factory Overlay.type(
  //   IDrawType type,
  //   IDraw drawBinding,
  // ) {
  //   return Overlay(
  //     key: drawBinding.chartKey,
  //     type: type,
  //     line: drawBinding.drawLineConfig,
  //   );
  // }

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
  Offset pointer = Offset.infinite;

  /// 已开始绘制
  bool get isStarted => points.first == null;

  /// 当前绘制中
  bool get isDrawing =>
      points.firstWhere((e) => e == null, orElse: () => null) == null;

  /// 当前绘制已完成, 修正中.
  bool get isEditing => points.fold(true, (ret, item) => ret && item != null);

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

  /// 更新point到Overlay的[points]中, 标志着完成一步.
  /// 1. 如果更新后, 还剩最后一步没有完成. 则返回true, 代表着下一步可以调用drawObject开始绘制了.
  /// 2.
  void updatePoint(Point point) {
    int? index;
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p == null) {
        // 说明当前overlay未完成绘制, 填充它.
        index = i;
        break;
      } else if (point.offset - p.offset > const Offset(2, 2)) {
        // 说明命中
        index = i;
      }
    }
    if (index != null) {
      points[index] = point;
    }
  }

  // DrawObject createDrawObject();

  // void updateDrawObject(
  //   KlineBindingBase controller,
  //   covariant DrawObject drawObject,
  // ) {
  //   drawObject
  //     .._zIndex = zIndex
  //     .._lock = lock
  //     .._visible = visible
  //     .._mode = mode
  //     .._line = line
  //     .._points = points
  //     .._pointer = pointer;
  // }
}

abstract class DrawObject {
  DrawObject(this.overlay);

  final Overlay overlay;
  // DrawObject({
  //   required Overlay overlay,
  // })  : id = overlay.id,
  //       key = overlay.key,
  //       type = overlay.type,
  //       _zIndex = overlay.zIndex,
  //       _lock = overlay.lock,
  //       _visible = overlay.visible,
  //       _mode = overlay.mode,
  //       _line = overlay.line,
  //       _points = overlay.points,
  //       _pointer = overlay.pointer;

  // final int id;
  // final String key;
  // final IDrawType type;

  int get id => overlay.id;
  String get key => overlay.key;
  IDrawType get type => overlay.type;

  // int _zIndex;
  // int get zIndex => _zIndex;
  int get zIndex => overlay.zIndex;

  // bool _lock;
  // bool get lock => _lock;
  bool get lock => overlay.lock;

  // bool _visible;
  // bool get visible => _visible;
  bool get visible => overlay.visible;

  // MagnetMode _mode;
  // MagnetMode get mode => _mode;
  MagnetMode get mode => overlay.mode;

  // LineConfig _line;
  // LineConfig get line => _line;
  LineConfig get line => overlay.line;

  // List<Point?> _points;
  // List<Point?> get points => _points;
  List<Point?> get points => overlay.points;

  // Offset _pointer;
  // Offset get pointer => _pointer;
  Offset get pointer => overlay.pointer;

  bool hitTest(Offset position) => false;

  void drawOverlay(Canvas canvas, Size size);

  void dispose() {
    /// 清理操作.
  }
}
