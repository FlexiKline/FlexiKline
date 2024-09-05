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
import '../core/export.dart';
import 'common.dart';

/// Overlay 绘制点坐标
class Point {
  Point({
    required this.ts,
    required this.value,
    this.offsetRate = 0,
  });

  final int ts;
  final Decimal value;
  final double offsetRate;

  /// 当前canvas中的坐标(实时更新)
  double? dx;
  double? dy;

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

  /// 已开始绘制
  bool get isStarted => points.first == null;

  /// 当前绘制中
  bool get isDrawing => points.first != null;

  /// 当前绘制已完成, 修正中.
  bool get isModfying => points.fold(true, (ret, item) => ret && item != null);

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

  // DrawObject createDrawObject();

  void updateDrawObject(
    KlineBindingBase controller,
    covariant DrawObject drawObject,
  ) {
    drawObject
      .._zIndex = zIndex
      .._lock = lock
      .._visible = visible
      .._mode = mode
      .._line = line
      .._points = points;
  }
}

abstract class DrawObject {
  DrawObject({
    required Overlay overlay,
  })  : id = overlay.id,
        key = overlay.key,
        type = overlay.type,
        _zIndex = overlay.zIndex,
        _lock = overlay.lock,
        _visible = overlay.visible,
        _mode = overlay.mode,
        _line = overlay.line,
        _points = overlay.points;

  final int id;
  final String key;
  final IDrawType type;

  int _zIndex;
  int get zIndex => _zIndex;

  bool _lock;
  bool get lock => _lock;

  bool _visible;
  bool get visible => _visible;

  MagnetMode _mode;
  MagnetMode get mode => _mode;

  LineConfig _line;
  LineConfig get line => _line;

  List<Point?> _points;
  List<Point?> get points => _points;

  bool hitTest(Offset position) => false;

  void drawOverlay(Canvas canvas, Size size);
}
