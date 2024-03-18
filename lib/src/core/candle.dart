import 'package:flutter/material.dart';
import 'package:kline/src/model/candle_data.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'config.dart';

abstract interface class ICandleProduce {
  void updateCandleList(CandleReq req, List<CandleModel> list);

  void addNewCandleList(CandleReq req, List<CandleModel> list);

  void addNewCandle(CandleReq req, CandleModel candleModel);
}

abstract interface class ICandlePinter {
  void paintCandle(Canvas canvas, Size size);
}

mixin CandleBinding
    on KlineBindingBase, ConfigBinding
    implements ICandlePinter, ICandleProduce {
  @override
  void initBinding() {
    super.initBinding();
    logd('candle init');
    // _instance = this;
  }

  final Map<String, CandleData> _candleDataCache = {};

  final ValueNotifier<CandleData> _curCandleData = ValueNotifier(
    CandleData.empty,
  );

  Listenable get repaintCandle => _curCandleData;

  CandleData get candleData => _curCandleData.value;

  // static CandleBindings get instance =>
  //     KlineBindingBase.checkInstance(_instance);
  // static CandleBindings? _instance;

  @override
  void addNewCandle(CandleReq req, CandleModel candleModel) {
    addNewCandleList(req, [candleModel]);
  }

  @override
  void addNewCandleList(CandleReq req, List<CandleModel> list) {
    CandleData data;
    if (_candleDataCache.containsKey(req.key)) {
      data = _candleDataCache[req.key]!;
      data.addNewCandleList(req, list);
      _curCandleData.value = data;
    }
  }

  @override
  void updateCandleList(CandleReq req, List<CandleModel> list) {
    CandleData data;
    if (_candleDataCache.containsKey(req.key)) {
      data = _candleDataCache[req.key]!;
      data.list = list;
    } else {
      data = CandleData(req, list);
      _candleDataCache[req.key] = data;
    }
    _curCandleData.value = data;
  }

  @override
  void paintCandle(Canvas canvas, Size size) {
    // final candle = candleList.first;
    // canvas.drawString(
    //   string: candle.toString(),
    //   fontSize: 10,
    //   fontColor: Colors.red,
    //   backgroundRadius: 2,
    //   offset: const Offset(20, 20),
    //   alignment: Alignment.center,
    //   backgroundColor: Colors.white60,
    //   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    // );
  }
}
