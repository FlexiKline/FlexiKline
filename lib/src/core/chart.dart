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
mixin ChartBinding
    on KlineBindingBase, SettingBinding
    implements IChart, IState, IConfig {
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
    if (!curKlineData.canPaintChart) {
      logd('chartBinding paintChart data is being prepared!');
      return;
    }

    /// 检查主图和副图的PaintObject是否都创建了.
    ensurePaintObjectInstance();

    /// 初始化主图展示的数据.
    mainIndicator.paintObject?.doInitData(
      list: curKlineData.list,
      start: curKlineData.start,
      end: curKlineData.end,
    );

    /// 通过paintObject绘制主图
    mainIndicator.paintObject?.doPaintChart(canvas, size);

    /// 开始绘制副图
    if (subIndicators.isNotEmpty) {
      int i = 0;
      for (var indicator in subIndicators) {
        /// 为每个副图指标动态绑定槽位.
        indicator.paintObject?.bindSolt(i++);

        /// 初始化副图指标展示数据.
        indicator.paintObject?.doInitData(
          list: curKlineData.list,
          start: curKlineData.start,
          end: curKlineData.end,
        );

        /// 绘制副图的指标图
        indicator.paintObject?.doPaintChart(canvas, size);
      }
    }
  }
}
