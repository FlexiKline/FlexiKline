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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flexi_kline/src/core/binding_base.dart';
import 'package:flexi_kline/src/core/interface.dart';
import 'package:flutter/material.dart';

import 'interface.dart';

abstract class IndicatorChart implements IPaintChart, IPaintCross {
  late final Rect rect;
}

abstract class IndicatorProxy extends IndicatorChart with StateMixin {
  IndicatorProxy(KlineController controller) {
    this.controller = controller;
  }
}

mixin StateMixin on IndicatorChart implements IState {
  late final KlineController controller;

  void init() {
    rect;
  }

  @override
  double get dyFactor => controller.dyFactor;
}
