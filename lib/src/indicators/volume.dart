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

import '../core/export.dart';
import '../model/export.dart';
import '../framework/export.dart';

class VolumeIndicator extends PaintObjectIndicator {
  VolumeIndicator({
    required super.key,
    super.tipsHeight,
    super.padding,
  });

  @override
  PaintObject createPaintObject(KlineBindingBase controller) =>
      VolumePaintObject(
        controller: controller,
        indicator: this,
      );
}

class VolumePaintObject extends PaintObjectBox<VolumeIndicator> {
  VolumePaintObject({
    required super.controller,
    required super.indicator,
  });

  Decimal _max = Decimal.zero;
  Decimal _min = Decimal.zero;

  final Decimal twentieth = (Decimal.one / Decimal.fromInt(20)).toDecimal();

  @override
  void initData(List<CandleModel> list, {int start = 0, int end = 0}) {
    if (list.isEmpty || start < 0 || end > list.length) return;
    CandleModel m = list[start];
    _max = m.vol;
    _min = m.vol;
    for (var i = start + 1; i < end; i++) {
      m = list[i];
      _max = m.vol > _max ? m.vol : _max;
      _min = m.vol < _min ? m.vol : _min;
    }
    // 增加vol区域的margin为高度的1/10
    final volH = _max == _min ? Decimal.one : _max - _min;
    final margin = volH * twentieth;
    _max += margin;
    _min -= margin;
  }

  @override
  Decimal get maxVal => _max;

  @override
  Decimal get minVal => _min;

  @override
  void paintChart(Canvas canvas, Size size) {}

  @override
  void onCross(Canvas canvas, Offset offset) {}
}
