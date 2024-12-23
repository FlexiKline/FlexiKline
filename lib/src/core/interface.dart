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

/// Setting API
abstract interface class ISetting {
  /// Canvas区域大小监听器
  ValueListenable<Rect> get canvasSizeChangeListener;

  /// Config ///

  /// 保存到本地
  void storeFlexiKlineConfig();

  /// 更新配置[config]
  void updateFlexiKlineConfig(FlexiKlineConfig config);

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
  void markRepaintGrid();
}

/// Chart图层API
abstract interface class IChart {
  void markRepaintChart({bool reset = false});
}

/// Cross图层API
abstract interface class ICross {
  void markRepaintCross();
}

/// Draw图层API
abstract interface class IDraw {
  void markRepaintDraw();
}

/// PaintContext 绘制Indicator功能集合
abstract interface class IPaintContext implements ILogger {
  // ITimeRectConfig? get timeRectConfig;

  /// 当前canvas绘制区域第一根蜡烛绘制的偏移量
  double get startCandleDx;

  /// 代表当前绘制区域相对于startIndex右侧的偏移量.
  double get paintDxOffset;

  /// 是否正在绘制Cross
  bool get isCrossing;

  KlineData get curKlineData;

  /// 蜡烛请求监听器
  ValueListenable<CandleReq> get candleRequestListener;

  /// SettingConfig
  SettingConfig get settingConfig;

  /// GridConfig
  GridConfig get gridConfig;

  /// CrossConfig
  CrossConfig get crossConfig;

  double get candleWidth;

  double get candleSpacing;

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

  /// 获取[key]对应的计算数据存储位置
  int? getDataIndex(IIndicatorKey key);

  /// 获取指标数量
  int get indicatorCount;
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
