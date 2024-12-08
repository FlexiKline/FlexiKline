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

part of 'indicator.dart';

/// FlexiKlineController 状态/配置/接口代理
mixin ConfigStateMixin<T extends Indicator> on IndicatorObject<T> {
  /// Config
  SettingConfig get settingConfig => context.settingConfig;
  GridConfig get gridConfig => context.gridConfig;
  CrossConfig get crossConfig => context.crossConfig;

  double get candleActualWidth => context.candleActualWidth;

  double get candleWidthHalf => context.candleWidthHalf;

  KlineData get klineData => context.curKlineData;

  double get paintDxOffset => context.paintDxOffset;

  double get startCandleDx => context.startCandleDx;

  bool get isCrossing => context.isCrossing;

  int? _dataIndex;
  // 注: 如果PaintObject被创建了, 其DataIndex必然有值.
  int get dataIndex => _dataIndex ??= context.getDataIndex(indicator.key)!;
}

/// 绘制对象混入边界计算的通用扩展
mixin PaintObjectBoundingMixin on PaintObject implements IPaintBoundingBox {
  bool get drawInMain => slot == mainIndicatorSlot;
  bool get drawInSub => slot > mainIndicatorSlot;

  int _slot = mainIndicatorSlot;

  /// 当前指标所在位置索引
  /// <0 代表在主图绘制
  /// >=0 代表在副图绘制
  int get slot => _slot;

  Rect? _drawableRect;
  Rect? _chartRect;
  Rect? _topRect;
  Rect? _bottomRect;

  /// 更新布布局参数
  @override
  bool updateLayout({
    double? height,
    EdgeInsets? padding,
    bool reset = false,
  }) {
    bool hasChange = false;
    if (height != null && height > 0 && height != indicator.height) {
      _indicator.height = height;
      hasChange = true;
    }

    if (padding != null && padding != indicator.padding) {
      _indicator.padding = padding;
      hasChange = true;
    }
    if (reset || hasChange) {
      resetPaintBounding();
    }
    return reset || hasChange;
  }

  @nonVirtual
  @override
  void resetPaintBounding({int? slot}) {
    if (slot != null) _slot = slot;
    _drawableRect = null;
    _chartRect = null;
    _topRect = null;
    _bottomRect = null;
  }

  @override
  Rect get drawableRect {
    if (_drawableRect != null) return _drawableRect!;
    if (drawInMain) {
      _drawableRect = context.mainRect;
    } else {
      final top = context.calculateIndicatorTop(slot);
      _drawableRect = Rect.fromLTRB(
        context.subRect.left,
        context.subRect.top + top,
        context.subRect.right,
        context.subRect.top + top + indicator.height,
      );
    }
    return _drawableRect!;
  }

  @override
  Rect get topRect {
    return _topRect ??= Rect.fromLTRB(
      drawableRect.left,
      drawableRect.top,
      drawableRect.right,
      drawableRect.top + padding.top,
    );
  }

  @override
  Rect get bottomRect {
    return _bottomRect ??= Rect.fromLTRB(
      drawableRect.left,
      drawableRect.bottom - padding.bottom,
      drawableRect.right,
      drawableRect.bottom,
    );
  }

  @override
  Rect get chartRect {
    if (_chartRect != null) return _chartRect!;
    final chartBottom = drawableRect.bottom - padding.bottom;
    double chartTop;
    if (indicator.paintMode == PaintMode.alone) {
      chartTop = chartBottom - indicator.height;
    } else {
      chartTop = drawableRect.top + padding.top;
    }
    return _chartRect = Rect.fromLTRB(
      drawableRect.left + padding.left,
      chartTop,
      drawableRect.right - padding.right,
      chartBottom,
    );
  }

  double get chartRectWidthHalf => chartRect.width / 2;

  double clampDxInChart(double dx) => dx.clamp(chartRect.left, chartRect.right);
  double clampDyInChart(double dy) => dy.clamp(chartRect.top, chartRect.bottom);

  // Tips区域向下移动height.
  @override
  Rect shiftNextTipsRect(double height) {
    return drawableRect.shiftYAxis(height);
  }
}

/// 绘制对象混入数据初始化的通用扩展
mixin PaintObjectDataInitMixin on PaintObject implements IPaintDataInit {
  int? _start;
  int? _end;

  MinMax? _minMax;

  @override
  MinMax get minMax => _minMax ?? MinMax.zero;

  @override
  void setMinMax(MinMax val) {
    _minMax = val;
  }

  double? _dyFactor;
  double get dyFactor {
    if (_dyFactor != null) return _dyFactor!;
    if (chartRect.height == 0) return _dyFactor = 1;
    return _dyFactor = chartRect.height / (minMax.diffDivisor).toDouble();
  }

  double valueToDy(BagNum value, {bool correct = true}) {
    if (correct) value = value.clamp(minMax.min, minMax.max);
    return chartRect.bottom - (value - minMax.min).toDouble() * dyFactor;
  }

  BagNum? dyToValue(double dy, {bool check = true}) {
    if (check && !drawableRect.includeDy(dy)) return null;
    return minMax.max - ((dy - chartRect.top) / dyFactor).toBagNum();
  }

  double? indexToDx(num index, {bool check = true}) {
    final indexDx = index * candleActualWidth;
    double dx = chartRect.right + paintDxOffset - indexDx;
    if (!check) return dx;
    return chartRect.includeDx(dx) ? dx : null;
  }

  double dxToIndex(double dx) {
    final dxPaintOffset = chartRect.right + paintDxOffset - dx;
    return dxPaintOffset / candleActualWidth;
  }

  CandleModel? dxToCandle(double dx) {
    final index = dxToIndex(dx).toInt();
    return klineData.getCandle(index);
  }

  CandleModel? offsetToCandle(Offset? offset) {
    if (offset != null) return dxToCandle(offset.dx);
    return null;
  }
}

/// 绘制当前图表在Y轴上的刻度值
mixin PaintYAxisTicksMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// 为副区的指标图绘制Y轴上的刻度信息
  @protected
  void paintYAxisTicks(
    Canvas canvas,
    Size size, {
    required int tickCount, // 刻度数量.
    required int precision,
  }) {
    if (minMax.isZero) return;
    if (tickCount <= 0) return;

    double dyStep = 0;
    double drawTop;
    if (tickCount == 1) {
      drawTop = chartRect.top + chartRect.height / 2;
    } else {
      drawTop = chartRect.top;
      dyStep = chartRect.height / (tickCount - 1);
    }

    final dx = chartRect.right;
    double dy = 0.0;
    for (int i = 0; i < tickCount; i++) {
      dy = drawTop + i * dyStep;
      final value = dyToValue(dy);
      if (value == null) continue;

      final text = fromatTicksValue(value, precision: precision);

      final ticksText = settingConfig.ticksText;

      canvas.drawTextArea(
        offset: Offset(
          dx,
          dy - ticksText.areaHeight, // 绘制在刻度线之上
        ),
        drawDirection: DrawDirection.rtl,
        drawableRect: drawableRect,
        text: text,
        textConfig: ticksText,
      );
    }
  }

  /// 如果要定制格式化刻度值. 在PaintObject中覆写此方法.
  @protected
  String fromatTicksValue(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

/// 当Cross事件发生时, 在Y轴上的绘制crossing相应的刻度值
mixin PaintYAxisTicksOnCrossMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  /// onCross时, 绘制Y轴上的刻度值
  @protected
  void paintYAxisTicksOnCross(
    Canvas canvas,
    Offset offset, {
    required int precision,
  }) {
    final value = dyToValue(offset.dy);
    if (value == null) return;

    final text = formatTicksValueOnCross(value, precision: precision);

    final ticksText = crossConfig.ticksText;

    canvas.drawTextArea(
      offset: Offset(
        chartRect.right - crossConfig.spacing,
        offset.dy - ticksText.areaHeight / 2,
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawableRect,
      text: text,
      textConfig: ticksText,
    );
  }

  @protected
  String formatTicksValueOnCross(BagNum value, {required int precision}) {
    return formatNumber(
      value.toDecimal(),
      precision: precision,
      defIfZero: '0.00',
      showCompact: true,
    );
  }
}

/// 绘制简易蜡烛图
/// 主要用于SubBoll图和SubSar图中
mixin PaintSimpleCandleMixin<T extends SinglePaintObjectIndicator>
    on SinglePaintObjectBox<T> {
  void paintSimpleCandleChart(
    Canvas canvas,
    Size size, {
    double? lineWidth, // 简易蜡烛线宽.
  }) {
    if (!klineData.canPaintChart) return;
    final list = klineData.list;
    int start = klineData.start;
    int end = klineData.end;

    final offset = startCandleDx - candleWidthHalf;

    CandleModel m;
    for (var i = start; i < end; i++) {
      m = list[i];
      final dx = offset - (i - start) * candleActualWidth;
      final isLong = m.close >= m.open;

      final linePaint = isLong
          ? settingConfig.defLongLinePaint
          : settingConfig.defShortLinePaint;

      if (lineWidth != null) linePaint.strokeWidth = lineWidth;

      final highOff = Offset(dx, valueToDy(m.high));
      final lowOff = Offset(dx, valueToDy(m.low));

      canvas.drawLine(
        highOff,
        lowOff,
        linePaint,
      );

      final openDy = valueToDy(m.open);
      canvas.drawLine(
        Offset(dx - candleWidthHalf, openDy),
        Offset(dx, openDy),
        linePaint,
      );

      final closeDy = valueToDy(m.close);
      canvas.drawLine(
        Offset(dx, closeDy),
        Offset(dx + candleWidthHalf, closeDy),
        linePaint,
      );
    }
  }
}

extension PaintObjectExt on PaintObject {
  /// 获取当前指标计算参数
  Map<IIndicatorKey, dynamic> getCalcParams() {
    if (calcParams != null) {
      return {key: calcParams};
    }
    return const <IIndicatorKey, dynamic>{};
  }
}

extension MultiPaintObjectBoxExt on MultiPaintObjectBox {
  /// 收集[MultiPaintObjectBox]中子指标的计算参数
  Map<IIndicatorKey, dynamic> getCalcParams() {
    final params = <IIndicatorKey, dynamic>{};
    for (var object in children) {
      if (object.calcParams != null) {
        params[object.key] = object.calcParams;
      }
    }
    return params;
  }
}
