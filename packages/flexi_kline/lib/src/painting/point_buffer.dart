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

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'paint_resource.dart';

/// 同一画笔的点 / 线段批次, 每帧攒坐标、一次 drawRawPoints 画完。
///
/// 缓冲只增不减, 由持有者跨帧复用: 稳态零分配。
final class PointBuffer implements PaintResource {
  Float32List _data = Float32List(256);
  int _length = 0;

  bool get isEmpty => _length == 0;

  void add(double x, double y) {
    if (_length + 2 > _data.length) _grow();
    _data[_length++] = x;
    _data[_length++] = y;
  }

  /// 一条线段 = 两个点; 配合 [ui.PointMode.lines]。
  void addSegment(double x1, double y1, double x2, double y2) {
    add(x1, y1);
    add(x2, y2);
  }

  /// 画完即清空, 下一帧从头攒。
  void flush(Canvas canvas, ui.PointMode mode, Paint paint) {
    if (_length == 0) return;
    canvas.drawRawPoints(mode, Float32List.sublistView(_data, 0, _length), paint);
    _length = 0;
  }

  @override
  void reset() => _length = 0;

  /// 归还缓冲内存; 之后若再 add 会按最小容量重新分配。
  @override
  void dispose() {
    _length = 0;
    _data = Float32List(0);
  }

  void _grow() => _data = Float32List(math.max(256, _data.length * 2))..setAll(0, _data);
}
