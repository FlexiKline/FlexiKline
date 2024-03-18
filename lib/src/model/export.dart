import 'candle_data.dart';
import 'candle_req/candle_req.dart';

export './candle_model/candle_model.dart';
export './candle_req/candle_req.dart';

extension CandleDataExt on CandleData {
  String get reqKey => req.key;
}

extension CandleReqExt on CandleReq {
  String get key => "$instId-$bar-$before-$after";
}
