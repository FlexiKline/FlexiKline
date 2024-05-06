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

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/material.dart';

part 'candle_indicator.g.dart';

@FlexiIndicatorSerializable
class CustomCandleIndicator extends CandleIndicator {
  CustomCandleIndicator({
    required super.height,
    super.latestPriceRectBackgroundColor,
    // this.latestPriceTextStyle,
  });

  // final TextStyle? latestPriceTextStyle;

  @override
  CustomCandlePaintObject createPaintObject(FlexiKlineController controller) {
    return CustomCandlePaintObject(controller: controller, indicator: this);
  }
}

class CustomCandlePaintObject extends CandlePaintObject<CustomCandleIndicator> {
  CustomCandlePaintObject({
    required super.controller,
    required super.indicator,
  });

  @override
  void paintLatestPriceMark(Canvas canvas, Size size) {
    if (!setting.isDrawLatestPriceMark) return;
    final data = klineData;
    final model = data.latest;
    if (model == null) {
      logd('paintLatestPriceMark > on data!');
      return;
    }

    bool showLastPriceUpdateTime = setting.showLatestPriceUpdateTime;
    double dx = chartRect.right;
    double firstCandleDx = startCandleDx;
    double rightMargin = setting.latestPriceRectRightMinMargin;
    double ldx = 0; // 计算最新价刻度线lineTo参数X轴的dx值. 默认0: 代表橫穿整个Canvas.
    double dy;
    if (model.close >= minMax.max) {
      dy = chartRect.top; // 画板顶部展示.
    } else if (model.close <= minMax.min) {
      dy = chartRect.bottom; // 画板底部展示.
    } else {
      dy = clampDyInChart(valueToDy(model.close));
    }
    // 计算最新价在当前画板中的X轴位置.
    if (firstCandleDx < dx) {
      ldx = firstCandleDx;
    } else {
      if (setting.showLatestPriceXAxisLineWhenMoveOffDrawArea) {
        ldx = 0;
        rightMargin += setting.latestPriceRectRightMaxMargin;
        showLastPriceUpdateTime = false;
      } else {
        ldx = dx - rightMargin;
      }
    }

    // 画最新价在画板中的刻度线.
    final path = Path();
    path.moveTo(dx, dy);
    path.lineTo(ldx, dy);
    canvas.drawDashPath(
      path,
      setting.latestPriceMarkLinePaint,
      dashes: setting.latestPriceMarkLineDashes,
    );

    // 画最新价文本区域.
    double textHeight =
        setting.latestPriceRectPadding.vertical + setting.latestPriceFontSize;
    String text = setting.formatPrice(
      model.close,
      instId: klineData.req.instId,
      precision: klineData.req.precision,
      cutInvalidZero: false,
    );
    if (showLastPriceUpdateTime) {
      final nextUpdateDateTime = model.nextUpdateDateTime(klineData.req.bar);
      // logd(
      //   'paintLastPriceMark lastModelTime:${model.dateTime}, nextUpdateDateTime:$nextUpdateDateTime',
      // );
      if (nextUpdateDateTime != null) {
        final timeDiff = formatTimeDiff(nextUpdateDateTime);
        if (timeDiff != null) {
          text += "\n$timeDiff";
          textHeight += setting.latestPriceFontSize;
        }
      }
    }

    canvas.drawText(
      offset: Offset(
        dx - rightMargin,
        dy - textHeight / 2, // 计算最新价文本区域相对于刻度线的位置
      ),
      drawDirection: DrawDirection.rtl,
      drawableRect: drawBounding,
      text: text,
      style: setting.latestPriceTextStyle,
      textAlign: TextAlign.end,
      textWidthBasis: TextWidthBasis.longestLine,
      padding: setting.latestPriceRectPadding,
      backgroundColor: indicator.latestPriceRectBackgroundColor ??
          setting.latestPriceRectBackgroundColor,
      radius: setting.latestPriceRectBorderRadius,
      borderWidth: setting.latestPriceRectBorderWidth,
      borderColor: setting.latestPriceRectBorderColor,
    );
  }
}
