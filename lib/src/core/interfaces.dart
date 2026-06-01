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

/// 设置相关 API。
abstract interface class ISetting {
  /// 画布区域变化监听器。
  ValueListenable<Rect> get canvasSizeChangeListener;

  /// 保存配置。
  void storeFlexiKlineConfig({
    bool storeDrawOverlays = true,
  });

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
}

/// Grid 图层 API。
abstract interface class IGrid {
  void markRepaintGrid();
}

/// Chart 图层 API。
abstract interface class IChart {
  void markRepaintChart({bool reset = false});
}

/// Cross 图层 API。
abstract interface class ICross {
  void markRepaintCross();
}

/// Draw 图层 API。
abstract interface class IDraw {
  void markRepaintDraw();
}

/// Indicator 绘制上下文。
abstract interface class IPaintContext implements IStorage, ILogger {
  IFlexiKlineTheme get theme;

  /// 是否允许指标写回布局高度。
  ///
  /// adapt 下写回原始高度；fixed 下只写入临时高度。
  bool get isAllowUpdateLayoutHeight;

  /// 指标图是否已开始缩放
  bool get isStartZoomChart;

  /// 当前画布内第一根蜡烛的绘制偏移。
  double get startCandleDx;

  /// 当前绘制区域相对 startIndex 右侧的偏移。
  double get paintDxOffset;

  /// 是否正在绘制Cross
  bool get isCrossing;

  KlineData get curKlineData;

  /// K线规格变化监听器
  ValueListenable<KlineSpec> get klineSpecListener;

  /// K线加载状态变化监听器
  ValueListenable<KlineLoadingState> get loadingStateListener;

  /// SettingConfig
  SettingConfig get settingConfig;

  /// GridConfig
  GridConfig get gridConfig;

  /// CrossConfig
  CrossConfig get crossConfig;

  /// GestureConfig
  GestureConfig get gestureConfig;

  double get candleWidth;

  double get candleSpacing;

  double get candleActualWidth;

  double get candleWidthHalf;

  /// 将value转换为蜡烛图中dy坐标值
  double valueToDyOnCandle(FlexiNum value, {bool correct = false});

  /// 将dy坐标值转换为蜡烛图中value
  FlexiNum? dyToValueOnCandle(double dy, {bool check = false});

  /// 画布区域。
  Rect get canvasRect;

  /// 主区区域。
  Rect get mainRect;

  /// 副区区域。
  Rect get subRect;

  /// 时间轴区域。
  Rect get timeRect;

  /// 指标图缩放滑竿区域。
  Rect get chartZoomSlideBarRect;

  /// 计算 [slot] 对应副区的 top。
  double calculateIndicatorTop(int slot);

  Offset? get crossOffset;

  /// 取消当前Cross事件
  void cancelCross();

  /// 获取 [key] 对应的计算数据存储位置
  ///
  /// 仅对 [DataIndicatorKey]（数据指标）有效。
  int? getDataIndex(DataIndicatorKey key);

  /// 获取指标数量
  int get indicatorCount;

  /// 重绘
  void requestRepaint();
}

/// Overlay 绘制上下文。
abstract interface class IDrawContext implements IStorage, ILogger {
  IFlexiKlineTheme get theme;

  /// 画布区域。
  Rect get canvasRect;

  /// 主区区域。
  Rect get mainRect;

  /// 时间轴区域。
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
  FlexiCandleModel? dxToCandle(double dx);

  /// 将[dx]精确转换时间戳
  int? dxToTimestamp(double dx);

  /// 将时间戳[ts]精确转换为dx坐标
  double? timestampToDx(int ts);

  /// 将[dx]转换为当前绘制区域对应的蜡烛的下标.
  int? dxToIndex(double dx);

  /// 将index转换为当前绘制区域对应的X轴坐标. 如果超出范围, 则返回null.
  double? indexToDx(int index, {bool check = false});

  /// 将value转换为dy坐标值
  double? valueToDy(FlexiNum value, {bool correct = false});

  /// 将dy坐标值转换为value
  FlexiNum? dyToValue(double dy, {bool check = false});
}
