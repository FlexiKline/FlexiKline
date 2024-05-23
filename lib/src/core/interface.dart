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

import 'package:flutter/material.dart';

import '../data/export.dart';
import '../framework/export.dart';
import '../model/export.dart';

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
  void setKlineData(CandleReq req, List<CandleModel> list);

  void appendKlineData(CandleReq req, List<CandleModel> list);

  KlineData get curKlineData;

  bool get canPaintChart;

  /// 蜡烛总数
  int get totalCandleCount;

  /// 最大绘制宽度
  double get maxPaintWidth;

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
abstract interface class ISetting {
  MultiPaintObjectIndicator get mainIndicator;
  List<Indicator> get subRectIndicators;
  double calculateIndicatorTop(int slot);
  double get subRectHeight;
  void ensurePaintObjectInstance();
  void updateMainIndicatorParam({
    double? height,
    EdgeInsets? padding,
  });
}

//// Chart层绘制接口
abstract interface class IChart {
  Listenable get repaintIndicatorChart;

  void paintChart(Canvas canvas, Size size);

  void markRepaintChart({bool reset = false});
}

//// 最新价与十字线绘制API
abstract interface class ICross {
  Listenable get repaintCross;

  // CrossConfig get crossConfig;

  void paintCross(Canvas canvas, Size size);

  void markRepaintCross();

  /// 是否正在绘制Cross
  bool get isCrossing;

  /// 取消当前Cross事件
  void cancelCross();
}

abstract interface class IGrid {
  // GridConfig get gridConfig;
  void markRepaintGrid();
}
