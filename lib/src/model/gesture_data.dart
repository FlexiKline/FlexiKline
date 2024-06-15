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

import 'package:flutter/material.dart';

import '../framework/common.dart';

enum GestureState {
  start,
  update,
  end,
}

enum GestureType {
  tap,
  long,
  pan,
  scale,
}

class GestureData {
  GestureData._internal({
    required this.type,
    required Offset offset,
    double scale = 1.0,
    GestureState state = GestureState.start,
    this.initPosition = ScalePosition.auto,
  })  : _prevOffset = offset,
        _offset = offset,
        _scale = scale,
        _prevScale = scale,
        _state = state;

  GestureData.tap(Offset offset)
      : this._internal(offset: offset, type: GestureType.tap);
  GestureData.long(Offset offset)
      : this._internal(offset: offset, type: GestureType.long);
  GestureData.pan(Offset offset)
      : this._internal(offset: offset, type: GestureType.pan);
  GestureData.scale(
    Offset offset, {
    double scale = 1.0,
    required ScalePosition position,
  }) : this._internal(
          offset: offset,
          scale: scale,
          type: GestureType.scale,
          initPosition: position,
        );

  final GestureType type;
  final ScalePosition initPosition;

  late double _scale;
  double get scale => _scale;
  set scale(double val) {
    _prevScale = _scale;
    _scale = val;
  }

  late double _prevScale = 0.0;
  double get scaleDelta {
    return scale - _prevScale;
  }

  GestureState _state;
  GestureState get state => _state;

  // 最新Offset
  late Offset _offset;
  Offset get offset => _offset;
  set offset(Offset val) {
    _prevOffset = _offset;
    _offset = val;
  }

  // 上一个Offset
  late Offset _prevOffset;
  Offset get prevOffset => _prevOffset;

  /// X轴移动增量.
  /// 注: 小于0: 向左滑动; 大于0: 向右滑动
  double get dxDelta => offset.dx - prevOffset.dx;

  /// Y轴移动增量.
  /// 注: 小于0: 向上滑动; 大于0: 向下滑动
  double get dyDelta => offset.dy - prevOffset.dy;

  bool get isPan => type == GestureType.pan;
  // 是否平移
  bool get moved => isPan && offset != prevOffset;

  bool get isScale => type == GestureType.scale;
  // 是否缩放
  bool get scaled => type == GestureType.scale && scale != 1.0;

  bool get isEnd => state == GestureState.end;

  void update(
    Offset newOffset, {
    double? newScale,
  }) {
    _state = GestureState.update;
    offset = newOffset;
    if (newScale != null) {
      scale = newScale;
    }
  }

  void end() {
    _prevOffset = offset;
    _state = GestureState.end;
  }

  @override
  String toString() {
    return 'GestureData(type:${type.name}, $offset, scale:$scale, state:$state)';
  }
}
