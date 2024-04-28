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

import '../constant.dart';
import '../model/export.dart';
import 'base_data.dart';
import 'boll_data.dart';
import 'candle_data.dart';
import 'ema_data.dart';
import 'kdj_data.dart';
import 'ma_data.dart';
import 'macd_data.dart';
import 'mavol_data.dart';

class KlineData extends BaseData
    with CandleData, MAData, MAVOLData, EMAData, MACDData, KDJData, BOLLData {
  KlineData(
    super.req, {
    super.list,
    super.logger,
  });

  static final KlineData empty = KlineData(
    CandleReq(instId: "", bar: ""),
    list: List.empty(growable: false),
  );
}

extension KlineDataExt on KlineData {
  String get instId => req.instId;
  int get precision => req.precision;
  String get key => req.key;
  String get reqKey => req.reqKey;
  TimeBar? get timerBar => req.timerBar;

  bool get invalid => req.instId.isEmpty;

  DateTime? get nextUpdateDateTime {
    final lastModel = list.firstOrNull;
    if (lastModel != null) {
      return lastModel.nextUpdateDateTime(req.bar);
    }
    return null;
  }
}
