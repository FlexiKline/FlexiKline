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

import 'package:decimal/decimal.dart';

import '../config/line_config/line_config.dart';
import '../core/export.dart';
import 'common.dart';
import 'draw_object.dart';
import 'serializers.dart';

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
abstract class Overlay {
  Overlay({
    required this.key,
    required this.type,
    this.zIndex = 0,
    this.lock = false,
    this.visible = true,
    this.mode = MagnetMode.normal,

    /// [type]类型的绘制需要的步数
    required int steps,

    /// 绘制线配置, 默认值:drawConfig.crosshair
    required this.line,
  }) : points = List.filled(3, null);

  final String key;
  final DrawType type;
  int zIndex;
  bool lock;
  bool visible;
  MagnetMode mode;
  LineConfig line;

  List<Point?> points;

  DrawObject createDrawObject(KlineBindingBase controller);
}
