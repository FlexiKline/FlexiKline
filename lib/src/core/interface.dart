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

part of 'core.dart';

//////// State ///////

/// 数据状态接口API
// abstract interface class IState {
//   /// 切换[req]请求指定的蜡烛数据
//   /// [req] 待切换的[CandleReq]
//   /// [useCacheFirst] 优先使用缓存. 注: 如果有缓存数据(说明之前加载过), loading不会展示.
//   /// return
//   ///   1. true:  代表使用了缓存, [curKlineData]的请求状态为[RequestState.none], 不展示loading
//   ///   2. false: 代表未使用缓存; 且[curKlineData]数据会被清空(如果有).
//   bool switchKlineData(CandleReq req, {bool useCacheFirst = true});

//   /// 结束加载中状态
//   /// [forceStopCurReq] 强制结束当前请求蜡烛数据[curKlineData]的加载中状态
//   /// [request]和[reqKey]指定要结束加载状态的请求, 如果[request]请求的状态非[RequestState.none], 即结束加载中状态
//   void stopLoading({
//     CandleReq? request,
//     String? reqKey,
//     bool forceStopCurReq = false,
//   });

//   /// 更新[list]到[req]请求指定的[KlineData]中
//   Future<void> updateKlineData(CandleReq req, List<CandleModel> list);

//   /// 当前平移结束(惯性平移之前)时,检查并加载更多蜡烛数据
//   /// [panDistance] 代表数据将要惯性平移的偏移量
//   /// [panDuration] 代表数据将要惯性平移的时长(单们ms)
//   void checkAndLoadMoreCandlesWhenPanEnd({
//     double? panDistance,
//     int? panDuration,
//   });

//   KlineData get curKlineData;

//   String get curDataKey;

//   /// 首根蜡烛是否移出屏幕监听器
//   ValueListenable<bool> get isFirstCandleMoveOffScreenListener;

//   /// 蜡烛请求监听器
//   ValueListenable<CandleReq> get candleRequestListener;

//   /// 当前KlineData绘制范围监听器
//   // ValueListenable<Range?> get candleDrawIndexListener;

//   /// TimeBar监听器

//   /// 将dx转换为蜡烛数据.
//   CandleModel? dxToCandle(double dx);

//   /// 将[dx]精确转换时间戳
//   int? dxToTimestamp(double dx);

//   /// 将时间戳[ts]精确转换为dx坐标
//   double? timestampToDx(int ts);

//   /// 将[dx]转换为当前绘制区域对应的蜡烛的下标.
//   int? dxToIndex(double dx);

//   /// 将index转换为当前绘制区域对应的X轴坐标. 如果超出范围, 则返回null.
//   double? indexToDx(int index, {bool check = false});

//   /// 将value转换为dy坐标值
//   double? valueToDy(BagNum value, {bool correct = false});

//   /// 将dy坐标值转换为value
//   BagNum? dyToValue(double dy, {bool check = false});

//   /// 当前canvas绘制区域第一根蜡烛绘制的偏移量
//   double get startCandleDx;

//   /// 代表当前绘制区域相对于startIndex右侧的偏移量.
//   double get paintDxOffset;

//   /// 画布是否可以从右向左进行平移.
//   bool get canPanRTL;

//   /// 画布是否可以从左向右进行平移.
//   bool get canPanLTR;

//   /// 计算绘制蜡烛图的起始数组索引下标和绘制偏移量
//   void calculateCandleDrawIndex();

//   /// 平移图表
//   void moveChart(GestureData data);

//   /// 缩放图表
//   void scaleChart(GestureData data);
// }

/// Setting API
abstract interface class ISetting {
  /// Canvas区域大小监听器
  ValueListenable<Rect> get canvasSizeChangeListener;

  /// 主区指标集
  MultiPaintObjectIndicator get mainIndicator;

  MultiPaintObjectBox? get mainPaintObject;

  /// 副区指标集
  List<Indicator> get subRectIndicators;

  /// 画板Size = [mainRect] + [subRect]
  Rect get canvasRect;

  /// 主区Size
  Rect get mainRect;

  /// 副区Size
  Rect get subRect;

  /// TimeIndicator区域大小
  Rect get timeRect;

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
  Map<IIndicatorKey, dynamic> getIndicatorCalcParams();

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

  /// DrawConfig
  DrawConfig get drawConfig;

  /// TooltipConfig
  TooltipConfig get tooltipConfig;
}

/// Grid图层API
abstract interface class IGrid {
  // Listenable get repaintGridBg;

  void markRepaintGrid();
}

/// Chart图层API
abstract interface class IChart {
  // Listenable get repaintIndicatorChart;

  // void paintChart(Canvas canvas, Size size);

  void markRepaintChart({bool reset = false});
}

/// Cross图层API
abstract interface class ICross {
  // Listenable get repaintCross;

  // void paintCross(Canvas canvas, Size size);

  void markRepaintCross();

  /// 是否正在绘制Cross
  // bool get isCrossing;

  // Offset? get crossOffset;

  /// 开始Cross事件
  /// [force] 将会强制启动cross事件.
  /// 当返回true时, 说明已开始展示Corss; 否则, 说明之前处在Cross, 结束上次的Cross事件.
  // bool startCross(GestureData data, {bool force = false});

  /// 更新Cross事件数据.
  // void updateCross(GestureData data);

  /// 取消当前Cross事件
  // void cancelCross();
}

/// Draw图层API
abstract interface class IDraw {
  // Listenable get repaintDraw;

  void markRepaintDraw();

  /// 当前绘制DrawState
  // DrawState get drawState;

  /// 绘制状态监听器
  // ValueListenable<DrawState> get drawStateLinstener;

  /// 绘制指针监听器(用于放大镜)
  // ValueListenable<Point?> get drawPointerListener;

  /// 测试[position]位置上是否命中当前已完成绘制操作的Overly.
  // DrawObject? hitTestDrawObject(Offset position);

  // void paintDraw(Canvas canvas, Size size);

  /// 绘制准备
  // void prepareDraw();

  /// 选择绘制图形
  // void startDraw(IDrawType type, {bool isInitPointer = true});

  /// 退出绘制
  // void exitDraw();
}

/// PaintContext 绘制Indicator功能集合
abstract interface class IPaintContext implements ILogger {
//   /// 当前canvas绘制区域第一根蜡烛绘制的偏移量
  double get startCandleDx;

//   /// 代表当前绘制区域相对于startIndex右侧的偏移量.
  double get paintDxOffset;

  /// 是否正在绘制Cross
  bool get isCrossing;

  KlineData get curKlineData;

  //   /// 蜡烛请求监听器
  ValueListenable<CandleReq> get candleRequestListener;

  /// SettingConfig
  SettingConfig get settingConfig;

  /// GridConfig
  GridConfig get gridConfig;

  /// CrossConfig
  CrossConfig get crossConfig;

  double get candleWidth;

  double get candleActualWidth;

  double get candleWidthHalf;

  /// 画板Size = [mainRect] + [subRect]
  Rect get canvasRect;

  /// 主区Size
  Rect get mainRect;

  /// 副区Size
  Rect get subRect;

  /// TimeIndicator区域大小
  Rect get timeRect;

  /// 计算[slot]位置指标的Top坐标
  double calculateIndicatorTop(int slot);

  Offset? get crossOffset;

  /// 取消当前Cross事件
  void cancelCross();
}

/// DrawContext 绘制Overlay功能集合
abstract interface class IDrawContext implements ILogger {
  /// 画板Size = [mainRect] + [subRect]
  Rect get canvasRect;

  /// 主区Size
  Rect get mainRect;

  /// TimeIndicator区域大小
  Rect get timeRect;

  /// 当前KlineData数据源
  KlineData get curKlineData;

  /// 当前磁吸模式
  MagnetMode get drawMagnet;

  /// 绘制配置
  DrawConfig get drawConfig;

  /// 当前蜡烛图蜡烛宽度的一半
  double get candleWidthHalf;

  /// 将dx转换为蜡烛数据.
  CandleModel? dxToCandle(double dx);

  /// 将[dx]精确转换时间戳
  int? dxToTimestamp(double dx);

  /// 将时间戳[ts]精确转换为dx坐标
  double? timestampToDx(int ts);

  /// 将[dx]转换为当前绘制区域对应的蜡烛的下标.
  int? dxToIndex(double dx);

  /// 将index转换为当前绘制区域对应的X轴坐标. 如果超出范围, 则返回null.
  double? indexToDx(int index, {bool check = false});

  /// 将value转换为dy坐标值
  double? valueToDy(BagNum value, {bool correct = false});

  /// 将dy坐标值转换为value
  BagNum? dyToValue(double dy, {bool check = false});
}
