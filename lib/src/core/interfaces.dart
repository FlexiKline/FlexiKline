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

/// Overlay 绘制上下文。
abstract interface class IDrawContext implements IStorage, ILogger {
  IFlexiKlineTheme get theme;

  /// 画布区域。
  Rect get canvasRect;

  /// 主区区域。
  Rect get mainRect;

  /// 时间轴区域。
  Rect get timeRect;

  /// 当前 K 线数据源。
  KlineData get klineData;

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
