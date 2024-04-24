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

import '../model/export.dart';
import 'base_data.dart';

mixin CandleData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init CANDLE');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose CANDLE');
  }

  Decimal max = Decimal.zero;
  Decimal min = Decimal.zero;
  Decimal maxVol = Decimal.zero;
  Decimal minVol = Decimal.zero;
  CandleModel? startModel;
  CandleModel? endModel;

  /// 根据[start, end]下标计算最大最小值
  void calculateMaxmin() {
    if (list.isEmpty) return;
    CandleModel m = list[start];
    max = m.high;
    min = m.low;
    maxVol = m.vol;
    minVol = m.vol;
    for (var i = start; i < end; i++) {
      m = list[i];

      if (i == 0) {
        startModel = m;
      }
      if (i == end - 1) {
        endModel = m;
      }

      max = m.high > max ? m.high : max;
      min = m.low < min ? m.low : min;

      maxVol = m.vol > maxVol ? m.vol : maxVol;
      minVol = m.vol < minVol ? m.vol : minVol;
    }

    // 增加vol区域的margin为高度的1/10
    final volH = maxVol == minVol ? Decimal.one : maxVol - minVol;
    final margin = volH * twentieth;
    maxVol += margin;
    minVol -= margin;
  }
}