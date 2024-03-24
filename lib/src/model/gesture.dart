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
    this.scale = 1.0,
    this.state = GestureState.start,
  }) : _offset = offset;

  GestureData.long(Offset offset)
      : this._internal(offset: offset, type: GestureType.long);
  GestureData.pan(Offset offset)
      : this._internal(offset: offset, type: GestureType.pan);
  GestureData.scale(Offset offset)
      : this._internal(offset: offset, type: GestureType.scale);

  final GestureType type;
  // 上一个Offset
  Offset _preOffset = Offset.infinite;
  Offset get preOffset => _preOffset;
  // 最新Offset
  late Offset _offset;
  Offset get offset => _offset;
  set offset(Offset val) {
    _preOffset = _offset;
    _offset = val;
  }

  double scale;
  GestureState state;

  bool get isScale => scale != 1.0;

  void update(
    Offset offset, {
    double scale = 1.0,
  }) {
    state = GestureState.update;
    this.offset = offset;
    this.scale = scale;
  }
}
