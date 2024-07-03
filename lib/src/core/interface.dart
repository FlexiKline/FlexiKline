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

import '../config/export.dart';
import '../data/export.dart';
import '../framework/export.dart';
import '../model/export.dart';

/// 手势事件的处理接口
///
/// 注: 必须首先调用super.handlexxx(); 向其他绘制模块传递手势数据.
/// 否则, 此事件的处理仅限出当前绘制模块.
/// 调用顺序参看kline_controller.dart的mixin倒序.
// abstract interface class IGestureHandler {
//   @mustCallSuper
//   bool handleTap(GestureData data);

//   @mustCallSuper
//   void handleMove(GestureData data);
//   @mustCallSuper
//   void handleScale(GestureData data);

//   @mustCallSuper
//   void handleLongPress(GestureData data);
//   @mustCallSuper
//   void handleLongMove(GestureData data);
// }

// /// 手势事件的处理接口默认实现.
// mixin GestureHanderImpl implements IGestureHandler {
//   /// 点击事件
//   ///
//   /// 在触控设备上Gesture框架的设计:
//   ///   1. 当返回true时, 代表Cross事件处理.
//   ///   2. 当返回false时, 代表非Cross事件处理.
//   @override
//   bool handleTap(GestureData data) => false;
//   @override
//   void handleMove(GestureData data) {}
//   @override
//   void handleScale(GestureData data) {}
//   @override
//   void handleLongPress(GestureData data) {}
//   @override
//   void handleLongMove(GestureData data) {}
// }

//////// State ///////

/// 数据状态接口API
abstract interface class IState {
  /// 切换[req]请求指定的蜡烛数据
  /// [req] 待切换的[CandleReq]
  /// [useCacheFirst] 优先使用缓存. 注: 如果有缓存数据(说明之前加载过), loading不会展示.
  /// return
  ///   1. true:  代表使用了缓存, [curKlineData]的请求状态为[RequestState.none], 不展示loading
  ///   2. false: 代表未使用缓存; 且[curKlineData]数据会被清空(如果有).
  bool switchKlineData(CandleReq req, {bool useCacheFirst = true});

  /// 结束加载中状态
  /// [forceStopCurReq] 强制结束当前请求蜡烛数据[curKlineData]的加载中状态
  /// [request]和[reqKey]指定要结束加载状态的请求, 如果[request]请求的状态非[RequestState.none], 即结束加载中状态
  void stopLoading({
    CandleReq? request,
    String? reqKey,
    bool forceStopCurReq = false,
  });

  /// 更新[list]到[req]请求指定的[KlineData]中
  Future<void> updateKlineData(CandleReq req, List<CandleModel> list);

  /// 当前平移结束(惯性平移之前)时,检查并加载更多蜡烛数据
  /// [panDistance] 代表数据将要惯性平移的偏移量
  /// [panDuration] 代表数据将要惯性平移的时长(单们ms)
  void checkAndLoadMoreCandlesWhenPanEnd({
    double? panDistance,
    int? panDuration,
  });

  KlineData get curKlineData;

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

  /// 平移图表
  void moveChart(GestureData data);

  /// 缩放图表
  void scaleChart(GestureData data);
}

/// Setting API
abstract interface class ISetting {
  /// 主区指标集
  MultiPaintObjectIndicator get mainIndicator;

  /// 副区指标集
  List<Indicator> get subRectIndicators;

  /// 画板Size = [mainRect] + [subRect]
  Rect get canvasRect;

  /// 主区Size
  Rect get mainRect;

  /// 副区Size
  Rect get subRect;

  /// 计算[slot]位置指标的Top坐标
  double calculateIndicatorTop(int slot);

  /// 检查并确保当前指标PaintObject实例化.
  void ensurePaintObjectInstance();

  /// Config

  /// 保存到本地
  void storeFlexiKlineConfig();

  /// 更新配置[config]
  void updateFlexiKlineConfig(FlexiKlineConfig config);

  /// 待计算的指标参数集合
  Map<ValueKey, dynamic> getIndicatorCalcParams();

  /// IndicatorsConfig
  IndicatorsConfig get indicatorsConfig;

  /// SettingConfig
  SettingConfig get settingConfig;

  /// SettingConfig
  GestureConfig get gestureConfig;

  /// GridConfig
  GridConfig get gridConfig;

  /// CrossConfig
  CrossConfig get crossConfig;

  /// TooltipConfig
  TooltipConfig get tooltipConfig;
}

/// Chart图层API
abstract interface class IChart {
  Listenable get repaintIndicatorChart;

  void paintChart(Canvas canvas, Size size);

  void markRepaintChart({bool reset = false});
}

/// Cross图层API
abstract interface class ICross {
  Listenable get repaintCross;

  void paintCross(Canvas canvas, Size size);

  void markRepaintCross();

  /// 是否正在绘制Cross
  bool get isCrossing;

  /// 开始Cross事件
  /// [force] 将会强制启动cross事件.
  /// 当返回true时, 说明已开始展示Corss; 否则, 说明之前处在Cross, 结束上次的Cross事件.
  bool startCross(GestureData data, {bool force = false});

  /// 更新Cross事件数据.
  void updateCross(GestureData data);

  /// 取消当前Cross事件
  void cancelCross();
}

/// Grid图层API
abstract interface class IGrid {
  void markRepaintGrid();
}
