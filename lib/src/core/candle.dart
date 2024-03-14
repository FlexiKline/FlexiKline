import 'package:flutter/widgets.dart';

import '../model/export.dart';

abstract interface class ICandle {
  void updateCandleList(List<CandleModel> list);

  void addCandleList(List<CandleModel> list);

  void addCandle(CandleModel candleModel) {
    addCandleList([candleModel]);
  }
}

abstract interface class ICandlePinter {
  void paint(Canvas canvas, Size size);
}

class CandleController extends ChangeNotifier implements ICandle {
  List<CandleModel> _list = List.empty(growable: true);

  @override
  void addCandle(CandleModel candleModel) {
    _list.add(candleModel);
    notifyListeners();
  }

  @override
  void addCandleList(List<CandleModel> list) {
    _list.addAll(list);
    notifyListeners();
  }

  @override
  void updateCandleList(List<CandleModel> list) {
    _list = list;
    notifyListeners();
  }
}

mixin CandleBindings on CandleController implements ICandlePinter, ICandle {
  @override
  void paint(Canvas canvas, Size size) {}
}
