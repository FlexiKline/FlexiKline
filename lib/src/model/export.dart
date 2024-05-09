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

import '../utils/num_util.dart';
import './candle_model/candle_model.dart';
import './candle_req/candle_req.dart';
import '../constant.dart';
import 'bag_num.dart';

export './candle_model/candle_model.dart';
export './candle_req/candle_req.dart';
export './gesture_data.dart';
export './card_info.dart';
export './minmax.dart';
export './bag_num.dart';

extension CandleReqExt on CandleReq {
  String get key => "$instId-$bar";
  String get reqKey => "$instId-$bar-$before-$after";

  TimeBar? get timerBar => TimeBar.convert(bar);

  void update(CandleReq req) {
    if (instId == req.instId) {
      // instId = req.instId;
      after = req.after;
      before = req.before;
      bar = req.bar;
      limit = req.limit;
      precision = req.precision;
    }
  }
}

extension CandleModelExt on CandleModel {
  DateTime get dateTime {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  String formatDateTimeByTimeBar(TimeBar bar) {
    final dt = dateTime;
    if (bar.milliseconds >= Duration.millisecondsPerDay) {
      // 展示: 年/月/日
      return '${dt.year}/${twoDigits(dt.month)}/${twoDigits(dt.day)}';
    } else if (bar.milliseconds >= Duration.millisecondsPerMinute) {
      // 展示: 月/日 时:分
      return '${twoDigits(dt.month)}/${twoDigits(dt.day)} ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
    } else {
      // 展示: 时:分:秒
      return '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}:${twoDigits(dt.second)}';
    }
  }

  DateTime? nextUpdateDateTime(String bar) {
    final timeBar = TimeBar.convert(bar);
    if (timeBar != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        timestamp + timeBar.milliseconds,
        isUtc: timeBar.isUtc,
      );
    }
    return null;
  }

  BagNum get change => close - open;

  double get changeRate {
    if (change.isZero) return 0;
    return (change / open).toDouble() * 100;
  }
}
