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

import '../core/export.dart';
import '../data/export.dart';
import '../extension/export.dart';
import '../framework/export.dart';
import '../model/export.dart';
import '../utils/export.dart';

class KDJIndicator extends SinglePaintObjectIndicator {
  KDJIndicator({
    super.key = const ValueKey(IndicatorType.kdj),
    required super.height,
    super.tipsHeight,
    super.padding,
  });

  @override
  KDJPaintObject createPaintObject(KlineBindingBase controller) {
    return KDJPaintObject(controller: controller, indicator: this);
  }
}

class KDJPaintObject extends SinglePaintObjectBox<KDJIndicator> {
  KDJPaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  MinMax? initData({
    required List<CandleModel> list,
    required int start,
    required int end,
  }) {
    return null;
  }

  @override
  void paintChart(Canvas canvas, Size size) {}

  @override
  void onCross(Canvas canvas, Offset offset) {}

  @override
  Size? paintTips(Canvas canvas, {CandleModel? model, Offset? offset}) {
    return null;
  }
}
