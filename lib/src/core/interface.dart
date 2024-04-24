// Copyright 2024 Andy.Zhao
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';

import 'package:flutter/material.dart';

import '../framework/export.dart';
import '../model/export.dart';
import 'data.dart';

/// Gesture 事件处理接口
abstract interface class IGestureEvent {
  /// 点击
  void onTapUp(TapUpDetails details);

  /// 原始移动
  void onPointerMove(PointerMoveEvent event);

  /// 移动, 缩放
  void onScaleStart(ScaleStartDetails details);
  void onScaleUpdate(ScaleUpdateDetails details);
  void onScaleEnd(ScaleEndDetails details);

  /// 长按
  void onLongPressStart(LongPressStartDetails details);
  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details);
  void onLongPressEnd(LongPressEndDetails details);
}

/// 手势事件的处理接口
/// 注: 必须首页调用super.handlexxx(); 向其他绘制模块传递手势数据.
/// 否则, 此事件的处理仅限出当前绘制模块.
/// 调用顺序参看kline_controller.dart的mixin倒序.
abstract interface class IGestureHandler {
  @mustCallSuper
  bool handleTap(GestureData data);

  @mustCallSuper
  void handleMove(GestureData data);
  @mustCallSuper
  void handleScale(GestureData data);

  @mustCallSuper
  void handleLongPress(GestureData data);
  @mustCallSuper
  void handleLongMove(GestureData data);
}

mixin GestureHanderImpl implements IGestureHandler {
  @override
  bool handleTap(GestureData data) => false;
  @override
  void handleMove(GestureData data) {}
  @override
  void handleScale(GestureData data) {}
  @override
  void handleLongPress(GestureData data) {}
  @override
  void handleLongMove(GestureData data) {}
}

//////// State ///////

/// 数据源更新
abstract interface class IState {
  void setKlineData(
    CandleReq req,
    List<CandleModel> list, {
    bool replace = false,
  });

  void appendKlineData(CandleReq req, List<CandleModel> list);

  CalcuDataManager? getCalcuMgrByReq(CandleReq req);
  CalcuDataManager? getCalcuMgr(String key);
  CalcuDataManager? get curCalcuMgr;

  KlineData get curKlineData;

  /// 蜡烛总数
  int get totalCandleCount;

  /// 最大绘制宽度
  double get maxPaintWidth;

  /// 绘制区域高度 / 当前绘制的蜡烛数据高度.
  // double get dyFactor;

  /// 将offset指定的dy转换为当前坐标Y轴对应价钱.
  // Decimal? offsetToPrice(Offset offset);
  // Decimal? dyToPrice(double dy);

  /// 将价钱转换为Y轴坐标.
  // double priceToDy(Decimal price);

  /// 当前Cross命中的Model
  // CandleModel? get crossingCandle;

  /// 将offset转换为蜡烛数据
  CandleModel? offsetToCandle(Offset offset);

  /// 将offset指定的dx转换为当前绘制区域对应的蜡烛的下标.
  int offsetToIndex(Offset offset);
  int dxToIndex(double dx);

  /// 将index转换为当前绘制区域对应的X轴坐标. 如果超出范围, 则返回null.
  double? indexToDx(int index);

  /// 当前canvas绘制区域第一根蜡烛绘制的偏移量
  double get startCandleDx;

  /// 代表当前绘制区域相对于startIndex右侧的偏移量.
  double get paintDxOffset;

  /// 画布是否可以从右向左进行平移.
  bool get canPanRTL;

  /// 画布是否可以从左向右进行平移.
  bool get canPanLTR;

  /// 计算绘制蜡烛图的起始数组索引下标和绘制偏移量
  void calculateCandleDrawIndex();
}

/// Config接口
abstract interface class IConfig {
  MultiPaintObjectIndicator get mainIndicator;
  Queue<Indicator> get subIndicators;
  List<double> get subIndicatorHeightList;
  double calculateIndicatorTop(int slot);
  double get subRectHeight;
  void ensurePaintObjectInstance();
  void addIndicatorInMain(SinglePaintObjectIndicator indicator);
  void delIndicatorInMain(Key key);
  void addIndicatorInSub(Indicator indicator);
  void delIndicatorInSub(Key key);
}

//// Chart层绘制接口
abstract interface class IChart {
  Listenable get repaintIndicatorChart;

  void paintChart(Canvas canvas, Size size);

  void markRepaintChart();
}

//// 最新价与十字线绘制API
abstract interface class ICross {
  Listenable get repaintCross;

  void paintCross(Canvas canvas, Size size);

  void markRepaintCross();

  /// 是否正在绘制Cross
  bool get isCrossing;

  Offset? get crossingOffset;
}
