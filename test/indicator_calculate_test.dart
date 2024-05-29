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
import 'dart:developer';
import 'dart:isolate';

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:isolate/isolate.dart';

class CalcuData {
  final List<CandleModel> candleList;

  CalcuData({required this.candleList});
}

void main() {
  test('isolate_compute', () async {
    final result = await compute((data) {}, CalcuData(candleList: []));
  });

  test('scheduleTask', () {
    SchedulerBinding.instance.scheduleTask(() {
      // TODO
    }, Priority.idle);
  });

  test('isolate base', () async {});
}
