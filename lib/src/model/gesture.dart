import 'dart:ui';

import 'package:flutter/material.dart';

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
  })  : _preOffset = offset,
        _offset = offset,
        _scale = scale,
        _state = state;

  GestureData.tap(Offset offset)
      : this._internal(offset: offset, type: GestureType.tap);
  GestureData.long(Offset offset)
      : this._internal(offset: offset, type: GestureType.long);
  GestureData.pan(Offset offset)
      : this._internal(offset: offset, type: GestureType.pan);
  GestureData.scale(Offset offset)
      : this._internal(offset: offset, type: GestureType.scale);

  final GestureType type;

  double _scale;
  double get scale => _scale;
  GestureState _state;
  GestureState get state => _state;

  // 最新Offset
  late Offset _offset;
  Offset get offset => _offset;
  set offset(Offset val) {
    _preOffset = _offset;
    _offset = val;
  }

  // 上一个Offset
  late Offset _preOffset;
  Offset get preOffset => _preOffset;

  /// X轴移动增量.
  /// 注: 小于0: 向左滑动; 大于0: 向右滑动
  double get dxDelta => offset.dx - preOffset.dx;

  /// Y轴移动增量.
  /// 注: 小于0: 向上滑动; 大于0: 向下滑动
  double get dyDelta => offset.dy - preOffset.dy;

  // 是否缩放数据
  bool get isScale => scale != 1.0;

  // 是否移动过
  bool get moved => offset != preOffset;

  // 是否缩放过
  bool get scaled => isScale && moved;

  void update(
    Offset offset, {
    double? scale,
  }) {
    _state = GestureState.update;
    this.offset = offset;
    if (scale != null) {
      _scale = scale;
    }
  }

  void end() {
    _preOffset = offset;
    _state = GestureState.end;
  }
}
