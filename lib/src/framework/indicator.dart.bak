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

import 'package:flexi_kline/src/model/export.dart';
import 'package:flutter/material.dart';

import '../constant.dart';

const mainDrawIndex = -1;

abstract class Indicator {
  Indicator({
    required this.type,
    this.tipsHeight = 0.0,
    this.padding = EdgeInsets.zero,
  });

  final IndicatorType type;
  EdgeInsets padding = EdgeInsets.zero;
  double tipsHeight = 0.0;

  // 绘制过程中决定.
  int _drawIndex = mainDrawIndex;
  int get drawIndex => _drawIndex;
  @protected
  set drawIndex(int val) => _drawIndex = val;
}

extension IndicatorExt on Indicator {
  bool get drawInMain => drawIndex == mainDrawIndex;
  bool get drawInSub => drawIndex > mainDrawIndex;
  bool get isComposite => type.isComposite;
  void update(Indicator indicator) {
    drawIndex = indicator.drawIndex;
    tipsHeight = indicator.tipsHeight;
    padding = indicator.padding;
  }
}

abstract class CompositeIndicator extends Indicator {
  CompositeIndicator({
    super.tipsHeight,
    super.padding,
  }) : super(type: IndicatorType.composite);

  final Map<IndicatorType, Indicator> _indicators = {};
  Map<IndicatorType, Indicator> get indicators => _indicators;

  /// 追加指标. 并返回旧的指标(如果存在)
  Indicator? appendIndicator(Indicator indicator) {
    if (indicator.isComposite) return null;
    Indicator? oldIndicator;
    if (indicators.containsKey(indicator.type)) {
      oldIndicator = indicators.remove(indicator.type);
    }
    indicator.update(this);
    indicators[indicator.type] = indicator;
    return oldIndicator;
  }

  Indicator? delIndicator(IndicatorType type) {
    if (type.isComposite) return null;
    final deleted = indicators.remove(type);
    return deleted;
  }
}

class MainIndicator extends CompositeIndicator {
  MainIndicator({
    super.tipsHeight,
    super.padding,
  }) {
    drawIndex = mainDrawIndex;
    // 默认给主图增加蜡烛图
    appendIndicator(CandleIndicator(
      tipsHeight: tipsHeight,
      padding: padding,
    ));
  }
}

class CandleIndicator extends Indicator {
  CandleIndicator({
    super.tipsHeight,
    super.padding,
  }) : super(type: IndicatorType.candle);
}

class MAParam {
  final int count;
  final Color color;

  MAParam({required this.count, required this.color});
}

class MAIndicator extends Indicator {
  MAIndicator({
    required this.calcParams,
    super.tipsHeight,
    super.padding,
  }) : super(type: IndicatorType.ma);

  final List<MAParam> calcParams;
}

class VolumeIndicator extends Indicator {
  VolumeIndicator({
    super.tipsHeight,
    super.padding,
  }) : super(type: IndicatorType.volume);
}

class VolumeMAIndicator extends CompositeIndicator {
  VolumeMAIndicator({
    super.tipsHeight,
    super.padding,
  }) {
    appendIndicator(VolumeIndicator(
      tipsHeight: tipsHeight,
      padding: padding,
    ));
    appendIndicator(MainIndicator(
      tipsHeight: tipsHeight,
      padding: padding,
    ));
  }
}
