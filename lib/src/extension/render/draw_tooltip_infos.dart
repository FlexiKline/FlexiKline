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

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../model/tooltip_info/tooltip_info.dart';
import 'types.dart';

extension FlexiDrawTooltipInfosExt on Canvas {
  /// 将 [tooltipInfos] 绘制为左右两列的 Tooltip 卡片。
  ///
  /// label 在内容区左对齐，value 在内容区右对齐。
  /// 返回包含 padding 的卡片实际尺寸。
  Size drawTooltipInfos({
    required Offset offset,
    required List<TooltipInfo> tooltipInfos,
    DrawDirection drawDirection = DrawDirection.ltr,
    Rect? drawableRect,
    TextStyle? defaultStyle,
    StrutStyle? strutStyle,
    TextDirection textDirection = TextDirection.ltr,
    int? maxLines,
    TextScaler textScaler = TextScaler.noScaling,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    double spacing = 0,
    double maxWidth = double.infinity,
    YAxisAlign yAxisAlign = YAxisAlign.center,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BorderSide? borderSide,
    EdgeInsets padding = EdgeInsets.zero,
    void Function(
      Rect bounds,
      List<Rect> itemBounds,
    )? onLayout,
  }) {
    assert(spacing >= 0);
    assert(maxWidth >= 0);

    if (tooltipInfos.isEmpty) {
      return Size.zero;
    }

    TextPainter createPainter(
      String text,
      TextStyle? itemStyle,
      TextAlign textAlign,
    ) {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: itemStyle ?? defaultStyle,
        ),
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        textScaler: textScaler,
        textWidthBasis: textWidthBasis,
      );
    }

    final labelPainters = <TextPainter>[];
    final valuePainters = <TextPainter>[];

    try {
      double maxLabelWidth = 0;
      double maxValueWidth = 0;

      for (final info in tooltipInfos) {
        final labelPainter = createPainter(
          info.label,
          info.labelStyle,
          TextAlign.start,
        )..layout();
        final valuePainter = createPainter(
          info.value,
          info.valueStyle,
          TextAlign.end,
        )..layout();

        labelPainters.add(labelPainter);
        valuePainters.add(valuePainter);
        maxLabelWidth = math.max(maxLabelWidth, labelPainter.width);
        maxValueWidth = math.max(maxValueWidth, valuePainter.width);
      }

      final columnSpacing = math.max(0.0, spacing);
      final naturalContentWidth = maxLabelWidth + columnSpacing + maxValueWidth;

      double contentWidth = naturalContentWidth;
      if (maxWidth.isFinite && naturalContentWidth > maxWidth && maxWidth > maxLabelWidth + columnSpacing) {
        contentWidth = maxWidth;
        final valueMaxWidth = maxWidth - maxLabelWidth - columnSpacing;

        for (final painter in valuePainters) {
          painter.layout(maxWidth: valueMaxWidth);
        }
      }

      final rowHeights = <double>[];
      double contentHeight = 0;
      for (int index = 0; index < tooltipInfos.length; index++) {
        final rowHeight = math.max(
          labelPainters[index].height,
          valuePainters[index].height,
        );
        rowHeights.add(rowHeight);
        contentHeight += rowHeight;
      }

      final size = Size(
        contentWidth + padding.horizontal,
        contentHeight + padding.vertical,
      );

      double dx = switch (drawDirection) {
        DrawDirection.ltr => offset.dx,
        DrawDirection.center => offset.dx - size.width / 2,
        DrawDirection.rtl => offset.dx - size.width,
      };
      double dy = offset.dy;

      if (drawableRect != null) {
        dx = math.max(
          drawableRect.left,
          math.min(dx, drawableRect.right - size.width),
        );
        dy = math.max(
          drawableRect.top,
          math.min(dy, drawableRect.bottom),
        );
      }

      final bounds = Offset(dx, dy) & size;
      final rrect = borderRadius?.toRRect(bounds) ??
          RRect.fromRectAndRadius(
            bounds,
            Radius.zero,
          );

      if (backgroundColor != null && backgroundColor.a != 0) {
        drawRRect(
          rrect,
          Paint()
            ..color = backgroundColor
            ..style = PaintingStyle.fill,
        );
      }

      if (borderSide != null && borderSide.color.a != 0 && borderSide.width > 0) {
        drawRRect(
          rrect,
          Paint()
            ..color = borderSide.color
            ..strokeWidth = borderSide.width
            ..style = PaintingStyle.stroke,
        );
      }

      double rowTop = bounds.top + padding.top;
      final itemBounds = onLayout == null ? null : <Rect>[];

      for (int index = 0; index < tooltipInfos.length; index++) {
        final labelPainter = labelPainters[index];
        final valuePainter = valuePainters[index];
        final rowHeight = rowHeights[index];
        final rowBottom = rowTop + rowHeight;

        double alignedY(TextPainter painter) {
          if (rowHeight <= painter.height) {
            return rowTop;
          }
          return yAxisAlign.distributeOffset(
            rowTop,
            rowBottom,
            painter.height,
          );
        }

        labelPainter.paint(
          this,
          Offset(
            bounds.left + padding.left,
            alignedY(labelPainter),
          ),
        );
        valuePainter.paint(
          this,
          Offset(
            bounds.right - padding.right - valuePainter.width,
            alignedY(valuePainter),
          ),
        );

        itemBounds?.add(
          Rect.fromLTRB(
            bounds.left,
            rowTop,
            bounds.right,
            rowBottom,
          ),
        );
        rowTop = rowBottom;
      }

      if (itemBounds != null) {
        onLayout!(
          bounds,
          List<Rect>.unmodifiable(itemBounds),
        );
      }

      return size;
    } finally {
      for (final painter in labelPainters) {
        painter.dispose();
      }
      for (final painter in valuePainters) {
        painter.dispose();
      }
    }
  }
}
