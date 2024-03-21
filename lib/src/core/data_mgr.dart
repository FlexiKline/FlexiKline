import 'package:flutter/material.dart';

import '../model/export.dart';
import 'binding_base.dart';
import 'setting.dart';

abstract interface class IDataSourceMgr {
  void setCandleData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  });

  void appendCandleData(CandleReq req, List<CandleModel> list);
}

abstract interface class IDataScopeMgr {
  void moveCandle(int leftTs, int rightTs);
}

mixin DataMgrBinding
    on KlineBindingBase, SettingBinding
    implements IDataSourceMgr, IDataScopeMgr {
  @override
  void initBinding() {
    super.initBinding();
    logd('dataMgr init');
  }

  final Map<String, CandleData> _candleDataCache = {};

  CandleData _curCandleData = CandleData.empty;
  CandleData get curCandleData => _curCandleData;
  set curCandleData(val) {
    /// TODO 预处理数据
    _curCandleData = val;
  }

  String get curDataKey => curCandleData.key;

  /// 触发重绘蜡烛线.
  void markRepainCandle() => repaintCandle.value++;
  ValueNotifier<int> repaintCandle = ValueNotifier(0);

  @override
  void setCandleData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  }) {
    final data = _candleDataCache[req.key] ?? CandleData(req, List.of(list));
    data.mergeCandleList(list, replace: replace);
    _candleDataCache[req.key] = data;
    if (curCandleData.invalid || req.key == curDataKey) {
      curCandleData = data;
      _calcuateCandleDataDrawParams(reset: true);
    }
  }

  @override
  void appendCandleData(CandleReq req, List<CandleModel> list) {
    final data = _candleDataCache[req.key] ?? CandleData(req, List.of(list));
    data.mergeCandleList(list);
    _candleDataCache[req.key] = data;
    if (req.key == curDataKey) {
      _calcuateCandleDataDrawParams();
    }
  }

  /// 计算绘制所需要的参数.
  void _calcuateCandleDataDrawParams({
    bool reset = false, // 是否从头开始绘制.
  }) {
    if (reset) curCandleData.reset();
    curCandleData.calcuateDrawParams(
      maxCandleCount,
      candleActualWidth,
      canvasWidth, // 暂无用
    );

    markRepainCandle();
  }

  @override
  void moveCandle(int leftTs, int rightTs) {
    // 计算leftTs与rightTs在curCandleData的下标. 更新repaintCandle
  }
}
