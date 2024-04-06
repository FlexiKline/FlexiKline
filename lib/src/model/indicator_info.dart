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

import '../constant.dart';

sealed class Indicator {
  Indicator({
    required this.type,
    this.drawInSub = true,
  });

  final IndicatorType type;
  final bool drawInSub;
}

class CandleIndicator extends Indicator {
  CandleIndicator() : super(type: IndicatorType.candle, drawInSub: false);
}

class MAParam {
  final int count;
  final Color color;

  MAParam({required this.count, required this.color});
}

class MAIndicator extends Indicator {
  MAIndicator({
    required this.calcParams,
  }) : super(type: IndicatorType.ma, drawInSub: false);

  final List<MAParam> calcParams;
}

class VolumeIndicator extends Indicator {
  VolumeIndicator() : super(type: IndicatorType.volume, drawInSub: true);
}
