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

/// Draw 绘制环境：主题与绘制配置。
abstract interface class DrawEnvironment {
  /// 当前主题。
  IFlexiKlineTheme get theme;

  /// 绘制配置。
  DrawConfig get drawConfig;
}

/// Draw 绘制数据：K 线数据源。
abstract interface class DrawDataScope {
  /// 当前 K 线数据源。
  KlineData get klineData;
}

/// Draw 绘制几何：区域、蜡烛尺寸与坐标换算。
abstract interface class DrawGeometryScope {
  /// 画布区域。
  Rect get canvasRect;

  /// 主区区域。
  Rect get mainRect;

  /// 时间轴区域。
  Rect get timeRect;

  /// 当前蜡烛图蜡烛宽度的一半。
  double get candleWidthHalf;

  /// 将 dx 转换为蜡烛数据。
  FlexiCandleModel? dxToCandle(double dx);

  /// 将 [dx] 精确转换时间戳。
  int? dxToTimestamp(double dx);

  /// 将时间戳 [ts] 精确转换为 dx 坐标。
  double? timestampToDx(int ts);

  /// 将 [dx] 转换为当前绘制区域对应的蜡烛下标。
  int? dxToIndex(double dx);

  /// 将 index 转换为当前绘制区域对应的 X 轴坐标；如果超出范围，则返回 null。
  double? indexToDx(int index, {bool check = false});

  /// 将 value 转换为 dy 坐标值。
  double? valueToDy(FlexiNum value, {bool correct = false});

  /// 将 dy 坐标值转换为 value。
  FlexiNum? dyToValue(double dy, {bool check = false});
}

/// Draw 绘制运行态：当前绘制交互状态。
abstract interface class DrawRuntimeScope {
  /// 当前磁吸模式。
  MagnetMode get drawMagnet;
}

/// Overlay 对外可见的绘制上下文。
abstract interface class DrawContext
    implements
        DrawEnvironment,
        DrawDataScope,
        DrawGeometryScope,
        DrawRuntimeScope,
        IStorage,
        ILogger {}
