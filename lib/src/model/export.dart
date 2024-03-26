import 'candle_model/candle_model.dart';
import 'candle_req/candle_req.dart';
import '../constant.dart';
import '../core/candle_data.dart';

export './candle_model/candle_model.dart';
export './candle_req/candle_req.dart';
export './gesture.dart';

extension CandleDataExt on CandleData {
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
}
