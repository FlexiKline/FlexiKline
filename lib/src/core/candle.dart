import 'package:flutter/material.dart';

import '../model/export.dart';
import '../render/export.dart';
import 'binding_base.dart';
import 'config.dart';

abstract interface class ICandleProduce {
  void updateCandleList(List<CandleModel> list);

  void addNewCandleList(List<CandleModel> list);

  void addNewCandle(CandleModel candleModel);
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

  final ValueNotifier<List<CandleModel>> _candleListenable = ValueNotifier(
    List.empty(growable: true),
  );

  Listenable get repaintCandle => _candleListenable;

  List<CandleModel> get candleList => _candleListenable.value;

  // static CandleBindings get instance =>
  //     KlineBindingBase.checkInstance(_instance);
  // static CandleBindings? _instance;

  @override
  void addNewCandle(CandleModel candleModel) {
    addNewCandleList([candleModel]);
  }

  @override
  void addNewCandleList(List<CandleModel> list) {
    _candleListenable.value = [..._candleListenable.value, ...list];
  }

  @override
  void updateCandleList(List<CandleModel> list) {
    _candleListenable.value = list;
  }

  @override
  void paintCandle(Canvas canvas, Size size) {
    final candle = candleList.first;
    background;
    updateBackground();
    canvas.drawString(
      string: candle.toString(),
      fontSize: 10,
      fontColor: Colors.red,
      backgroundRadius: 2,
      offset: const Offset(20, 20),
      alignment: Alignment.center,
      backgroundColor: Colors.white60,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    );
  }
}
