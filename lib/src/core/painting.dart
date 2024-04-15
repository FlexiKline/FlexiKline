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

import 'dart:async';

import 'package:flutter/material.dart';

import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

/// 绘制蜡烛图以及相关指标数据
mixin PaintingBinding
    on KlineBindingBase, SettingBinding
    implements IPainting, IState, IConfig {
  @override
  void initBinding() {
    super.initBinding();
    logd('init indicator');
    startLastPriceCountDownTimer();
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose indicator');
    _lastPriceCountDownTimer?.cancel();
    _lastPriceCountDownTimer = null;
  }

  final ValueNotifier<int> _repaintCandle = ValueNotifier(0);
  @override
  Listenable get repaintIndicatorChart => _repaintCandle;
  void _markRepaint() {
    _repaintCandle.value++;
  }

  //// Last Price ////
  Timer? _lastPriceCountDownTimer;
  @protected
  void markRepaintLastPrice() => _markRepaint();

  /// 触发重绘蜡烛线.
  @override
  @protected
  void markRepaintChart() => _markRepaint();

  @protected
  void startLastPriceCountDownTimer() {
    _lastPriceCountDownTimer?.cancel();
    markRepaintLastPrice();
    _lastPriceCountDownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        markRepaintLastPrice();
      },
    );
  }

  DateTime _lastPaintTime = DateTime.now();
  int get diffTime {
    // 计算两次绘制时间差
    return _lastPaintTime
        .difference(_lastPaintTime = DateTime.now())
        .inMilliseconds
        .abs();
  }

  @override
  void paintChart(Canvas canvas, Size size) {
    // logd('$diffTime paintChart >>>>');
    checkAndCreatePaintObject();
    mainIndicator.paintObject?.initData(
      curKlineData.list,
      start: curKlineData.start,
      end: curKlineData.end,
    );

    mainIndicator.paintObject?.paintChart(canvas, size);

    int i = 0;
    for (var indicator in subIndicators) {
      indicator.paintObject?.bindSolt(i++);
      indicator.paintObject?.initData(
        curKlineData.list,
        start: curKlineData.start,
        end: curKlineData.end,
      );
      indicator.paintObject?.paintChart(canvas, size);
    }
  }
}
