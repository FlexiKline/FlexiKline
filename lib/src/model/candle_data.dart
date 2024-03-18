import 'package:decimal/decimal.dart';

import 'candle_model/candle_model.dart';
import 'candle_req/candle_req.dart';

class CandleData {
  final CandleReq req;
  List<CandleModel> _list = [];

  List<CandleModel> get list => _list;
  set list(List<CandleModel> val) {
    _list = val;
    calcuateMaxMin();
  }

  Decimal max = Decimal.zero;
  Decimal min = Decimal.zero;

  static final CandleData empty = CandleData(
    CandleReq(instId: ""),
    List.empty(growable: true),
  );

  CandleData(this.req, List<CandleModel> list) {
    if (list.isEmpty) {
      reset();
      return;
    }
    this.list = list;
  }

  String get instId => req.instId;

  void reset() {
    max = Decimal.zero;
    min = Decimal.zero;
  }

  void calcuateMaxMin() {
    CandleModel m = list.first;
    Decimal max = m.high;
    Decimal min = m.low;
    for (var i = 0; i < list.length; i++) {
      m = list[i];

      if (i == 0) {
        req.after ??= m.timestamp;
      }
      if (i == list.length - 1) {
        req.before ??= m.timestamp;
      }

      max = m.high > max ? m.high : max;
      min = m.low < min ? m.low : min;
    }
  }

  void addNewCandleList(CandleReq req, List<CandleModel> list) {
    
  }
}
