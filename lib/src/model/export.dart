import 'candle_data.dart';
import 'candle_model/candle_model.dart';
import 'candle_req/candle_req.dart';

export './candle_model/candle_model.dart';
export './candle_req/candle_req.dart';
export './candle_data.dart';

extension CandleDataExt on CandleData {
  String get key => req.key;
  String get reqKey => req.reqKey;

  bool get invalid => req.instId.isEmpty;
}

extension CandleReqExt on CandleReq {
  String get key => "$instId-$bar";
  String get reqKey => "$instId-$bar-$before-$after";
}

extension CandleModelExt on CandleModel {
  DateTime get dateTime {
    datetime ??= DateTime.fromMillisecondsSinceEpoch(timestamp);
    return datetime!;
  }
}
