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

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../extension/export.dart';
import '../framework/export.dart';
import 'binding_base.dart';
import 'interface.dart';

/// 负责Grid图层的绘制
///
/// 绘制底层的网络
mixin GridBinding on KlineBindingBase implements IGrid {
  @override
  void initState() {
    super.initState();
    logd('initState grid');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose grid');
    repaintGridBg.dispose();
  }

  @override
  void markRepaintGrid() => repaintGridBg.value++;
  ValueNotifier<int> repaintGridBg = ValueNotifier(0);

  void paintGridBg(Canvas canvas, Size size) {
    if (gridConfig.show) {
      // 主图图Grid X轴起始值
      final mainLeft = mainRect.left;
      final mainRight = mainRect.right;
      // 主图图Grid Y轴起始值
      final mainTop = mainRect.top;
      final mainBottom = mainRect.bottom;
      // 副图Grid Y轴起始值
      final subTop = subRect.top;
      final subBottom = subRect.bottom;

      /// 绘制horizontal轴 Grid 线
      if (gridConfig.horizontal.show) {
        final horiLineType = gridConfig.horizontal.type;
        final horiPaint = gridConfig.horizontal.paint;
        final horiDashes = gridConfig.horizontal.dashes;

        double dy = mainTop;

        // 绘制Top边框线
        canvas.drawLineType(
          horiLineType,
          Path()
            ..moveTo(mainLeft, dy)
            ..lineTo(mainRight, dy),
          horiPaint,
          dashes: horiDashes,
        );

        // 绘制主图网格横线
        final step = mainBottom / gridConfig.horizontal.count;
        for (int i = 1; i < gridConfig.horizontal.count; i++) {
          dy = i * step;
          canvas.drawLineType(
            horiLineType,
            Path()
              ..moveTo(mainLeft, dy)
              ..lineTo(mainRight, dy),
            horiPaint,
            dashes: horiDashes,
          );
        }

        // 绘制主图mainDrawBottom线
        canvas.drawLineType(
          horiLineType,
          Path()
            ..moveTo(mainLeft, mainBottom)
            ..lineTo(mainRight, mainBottom),
          horiPaint,
          dashes: horiDashes,
        );

        // // 绘制副图区域起始线
        // canvas.drawLineType(
        //   horiLineType,
        //   Path()
        //     ..moveTo(mainLeft, subTop)
        //     ..lineTo(mainRight, subTop),
        //   horiPaint,
        //   dashes: horiDashes,
        // );

        /// 副图区域
        // 绘制每一个副图的底部线
        double height = 0.0;
        for (final indicator in subRectIndicators) {
          height += indicator.height;
          dy = subTop + height;
          canvas.drawLineType(
            horiLineType,
            Path()
              ..moveTo(mainLeft, dy)
              ..lineTo(mainRight, dy),
            horiPaint,
            dashes: horiDashes,
          );
        }
      }

      /// 绘制Vertical轴 Grid 线
      if (gridConfig.vertical.show) {
        final vertLineType = gridConfig.vertical.type;
        final vertPaint = gridConfig.vertical.paint;
        final vertDashes = gridConfig.horizontal.dashes;

        double dx = mainLeft;
        final step = mainRight / gridConfig.vertical.count;

        // 绘制左边框线
        canvas.drawLineType(
          vertLineType,
          Path()
            ..moveTo(dx, mainTop)
            ..lineTo(dx, subBottom),
          vertPaint,
          dashes: vertDashes,
        );

        // 计算排除时间指标后的top和bottom
        double top = subTop;
        double bottom = subBottom;
        final timeIndicator = indicatorsConfig.time;
        if (timeIndicator.position == DrawPosition.bottom) {
          bottom -= timeIndicator.height;
        } else {
          top += timeIndicator.height;
        }

        // 绘制主区/副区的Vertical线
        for (int i = 1; i < gridConfig.vertical.count; i++) {
          dx = i * step;

          /// 绘制主区的Grid竖线
          canvas.drawLineType(
            vertLineType,
            Path()
              ..moveTo(dx, mainTop)
              ..lineTo(dx, mainBottom),
            vertPaint,
            dashes: vertDashes,
          );

          /// 绘制副区Grid竖线
          canvas.drawLineType(
            vertLineType,
            Path()
              ..moveTo(dx, top)
              ..lineTo(dx, bottom),
            vertPaint,
            dashes: vertDashes,
          );
        }

        // 绘制右边框线
        canvas.drawLineType(
          vertLineType,
          Path()
            ..moveTo(mainRight, mainTop)
            ..lineTo(mainRight, subBottom),
          vertPaint,
          dashes: vertDashes,
        );
      }
    }
  }
}
