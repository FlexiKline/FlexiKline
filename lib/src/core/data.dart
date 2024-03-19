import 'package:flutter/widgets.dart';

import '../model/export.dart';
import 'binding_base.dart';

abstract interface class IDataSourceMgr {
  void setCandleData(CandleReq req, List<CandleModel> list);

  void appendCandleData(CandleReq req, List<CandleModel> list);
}

abstract interface class IDataScopeMgr {
  void moveCandle(int leftTs, int rightTs);
}

mixin DataBinding on KlineBindingBase implements IDataSourceMgr, IDataScopeMgr {
  @override
  void initBinding() {
    super.initBinding();
    logd('data init');
    _curCandleData = CandleData.empty;
  }

  final Map<String, CandleData> _candleDataCache = {};

  late CandleData _curCandleData;
  CandleData get curCandleData => _curCandleData;
  set curCandleData(val) {
    /// TODO 预处理数据
    _curCandleData = val;
  }

  String get curDataKey => curCandleData.key;

  ValueNotifier<int> repaintCandle = ValueNotifier(0);
  void makeRepainCandle() => repaintCandle.value++;

  @override
  void setCandleData(CandleReq req, List<CandleModel> list) {
    final data = _candleDataCache[req.key] ?? CandleData(req, List.of(list));
    data.mergeCandleList(list);
    _candleDataCache[req.key] = data;
    if (curCandleData.invalid) {
      curCandleData = data;
    }
    if (req.key == curDataKey) {
      makeRepainCandle();
      // TODO: 数据处理
    }
  }

  @override
  void appendCandleData(CandleReq req, List<CandleModel> list) {
    final data = _candleDataCache[req.key] ?? CandleData(req, List.of(list));
    data.mergeCandleList(list);
    if (req.key == curDataKey) {
      makeRepainCandle();
      // TODO: 数据处理
    }
  }

  @override
  void moveCandle(int leftTs, int rightTs) {
    // 计算leftTs与rightTs在curCandleData的下标. 更新repaintCandle
  }
}
