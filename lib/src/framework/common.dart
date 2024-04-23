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

enum IndicatorType {
  candle,
  volume,
  ma,
  maVol,
  ema,
  macd;
}

class MaParam {
  final String label;
  final int count;
  final Color color;

  MaParam({required this.label, required this.count, required this.color});
}

class EMAParam {
  final String label;
  final int count;
  final Color color;

  EMAParam({required this.label, required this.count, required this.color});
}
