import 'package:decimal/decimal.dart';

import '../core/candle_data.dart';
import '../utils/num_util.dart';
import 'candle_model/candle_model.dart';
import 'candle_req/candle_req.dart';
import '../constant.dart';

export './candle_model/candle_model.dart';
export './candle_req/candle_req.dart';
export './gesture.dart';
export './card_info.dart';

extension CandleDataExt on CandleData {
  String get instId => req.instId;
  int get precision => req.precision;
  String get key => req.key;
  String get reqKey => req.reqKey;

  bool get invalid => req.instId.isEmpty;

  DateTime? get nextUpdateDateTime {
    final lastModel = list.firstOrNull;
    if (lastModel != null) {
      return lastModel.nextUpdateDateTime(req.bar);
    }
    return null;
  }

  TimeBar? get timerBar => req.timerBar;
}

extension CandleReqExt on CandleReq {
  String get key => "$instId-$bar";
  String get reqKey => "$instId-$bar-$before-$after";

  TimeBar? get timerBar => TimeBar.convert(bar);
}

extension CandleModelExt on CandleModel {
  DateTime get dateTime {
    datetime ??= DateTime.fromMillisecondsSinceEpoch(timestamp);
    return datetime!;
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

  Decimal get change => close - open;

  double get changeRate => (change / open).toDouble() * 100;
}
