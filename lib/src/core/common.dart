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

/// 布局模式
sealed class LayoutMode {
  const LayoutMode(this.prevMode);

  final LayoutMode? prevMode;

  Size get mainSize;

  /// 更新当前布局模式的[size]
  /// [sync] 是否同步到[mainSize]中.
  ///   Adapt模式下仅同步更新高度
  LayoutMode update(Size size, [bool sync = false]);

  bool get isFixed => this is FixedLayoutMode;
  bool get isAdapt => this is AdaptLayoutMode;
  bool get isNormal => this is NormalLayoutMode;
}

/// 正常模式(可自由调节宽高)
class NormalLayoutMode extends LayoutMode {
  const NormalLayoutMode(this.mainSize) : super(null);

  /// 主区正常模式下大小
  @override
  final Size mainSize;

  @override
  NormalLayoutMode update(Size size, [bool sync = false]) {
    return NormalLayoutMode(size);
  }
}

/// 自适应模式(Web/桌面端根据父布局[宽度]变化而变化)
class AdaptLayoutMode extends LayoutMode {
  /// 适配模式可以从正常模式进入
  const AdaptLayoutMode._(this.mainSize, [NormalLayoutMode? mode]) : super(mode);

  /// 根据[mainSize]与[mode]生成AdaptLayoutMode
  factory AdaptLayoutMode(Size mainSize, [LayoutMode? mode]) {
    switch (mode) {
      case null:
        return AdaptLayoutMode._(mainSize);
      case NormalLayoutMode():
        return AdaptLayoutMode._(mainSize, mode);
      case AdaptLayoutMode():
      case FixedLayoutMode():
        return AdaptLayoutMode._(
          mainSize,
          mode.prevMode is NormalLayoutMode ? mode.prevMode as NormalLayoutMode : null,
        );
    }
  }

  /// 主区适配宽度模式下大小
  @override
  final Size mainSize;

  @override
  AdaptLayoutMode update(Size size, [bool sync = false]) {
    if (prevMode != null && prevMode is NormalLayoutMode) {
      if (sync) {
        return AdaptLayoutMode._(
          size,
          NormalLayoutMode(Size(
            prevMode!.mainSize.width,
            size.height,
          )),
        );
      } else {
        return AdaptLayoutMode._(size, prevMode as NormalLayoutMode);
      }
    }
    return AdaptLayoutMode._(size);
  }
}

/// 固定大小模式(全屏/横屏)
class FixedLayoutMode extends LayoutMode {
  const FixedLayoutMode._(this.fixedSize, LayoutMode mode) : super(mode);

  /// 根据[fixedSize]和[mode]生成FixedLayoutMode
  factory FixedLayoutMode(Size fixedSize, LayoutMode mode) {
    switch (mode) {
      case NormalLayoutMode():
      case AdaptLayoutMode():
        return FixedLayoutMode._(fixedSize, mode);
      case FixedLayoutMode():
        assert(mode.prevMode != null, 'fixed prevMode must cannot be null');
        return FixedLayoutMode._(fixedSize, mode.prevMode!);
    }
  }

  /// 整体绘制区域固定大小
  final Size fixedSize;

  @override
  Size get mainSize {
    assert(prevMode != null, 'prevMode must cannot be null');
    return prevMode!.mainSize;
  }

  @override
  FixedLayoutMode update(Size size, [bool sync = false]) {
    assert(prevMode != null, 'prevMode must cannot be null');
    return FixedLayoutMode._(size, prevMode!);
  }
}

/// Setting API
abstract interface class ISetting {
  /// Canvas区域大小监听器
  ValueListenable<Rect> get canvasSizeChangeListener;

  /// Config ///

  /// 保存到本地
  void storeFlexiKlineConfig({
    bool storeIndicators = true,
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
abstract interface class IPaintContext implements IStorage, ILogger {
  IFlexiKlineTheme get theme;

  /// 是否是正常布局模式
  // LayoutMode get layoutMode;
  /// 是否允许更新而已高度
  /// 注: 目前仅支持正常模式和适配模式下缓存高度的变化.
  bool get isAllowUpdateLayoutHeight;

  /// 指标图是否已开始缩放
  bool get isStartZoomChart;

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
abstract interface class IDrawContext implements IStorage, ILogger {
  IFlexiKlineTheme get theme;

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
