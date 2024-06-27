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

import '../framework/export.dart';
import 'binding_base.dart';
import 'interface.dart';

/// 负责绘制蜡烛图以及相关指标图
mixin ChartBinding on KlineBindingBase implements IChart, IState {
  @override
  void initState() {
    super.initState();
    logd('initState indicator');
    startLastPriceCountDownTimer();
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose indicator');
    _repaintCandle.dispose();
    _lastPriceCountDownTimer?.cancel();
    _lastPriceCountDownTimer = null;
  }

  final ValueNotifier<int> _repaintCandle = ValueNotifier(0);
  @override
  Listenable get repaintIndicatorChart => _repaintCandle;
  void _markRepaint() {
    _repaintCandle.value++;
  }

  //// Latest Price ////
  Timer? _lastPriceCountDownTimer;
  @protected
  void markRepaintLastPrice({bool latestPriceUpdated = false}) {
    // 最新价已更新, 且首根蜡烛在可视区域内.
    // _reset = latestPriceUpdated && paintDxOffset <= 0;
    _markRepaint();
  }

  /// 控制doInitState操作是否重置计算结果
  bool _reset = false;

  /// 触发重绘蜡烛线.
  @override
  @protected
  void markRepaintChart({bool reset = false}) {
    _reset = reset;
    _markRepaint();
  }

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
    if (!curKlineData.canPaintChart) {
      logd('chartBinding paintChart data is being prepared!');
      return;
    }

    /// 检查主区和副区的PaintObject是否都创建了.
    ensurePaintObjectInstance();

    int solt = mainIndicatorSlot;
    for (var indicator in [mainIndicator, ...subRectIndicators]) {
      /// 初始化副区指标数据.
      indicator.paintObject?.doInitState(
        solt++,
        start: curKlineData.start,
        end: curKlineData.end,
        reset: _reset,
      );

      /// 绘制副区的指标图
      indicator.paintObject?.doPaintChart(canvas, size);
    }

    if (_reset) _reset = false;
  }
}
