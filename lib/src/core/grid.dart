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

import '../config/export.dart';
import '../extension/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin GridBinding
    on KlineBindingBase, SettingBinding
    implements IGrid, IConfig {
  @override
  void init() {
    super.init();
    logd('init grid');
    _gridConfig = GridConfig.fromJson(gridConfigData);
  }

  @override
  void initState() {
    super.initState();
    logd('initState grid');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose grid');
  }

  @override
  void storeState() {
    super.storeState();
    logd("storeState grid");
    storeGridConfig(gridConfig);
  }

  @override
  void loadConfig(Map<String, dynamic> configData) {
    super.loadConfig(configData);
    logd("loadConfig grid");
    _gridConfig = GridConfig.fromJson(configData);
  }

  late GridConfig _gridConfig;

  @override
  GridConfig get gridConfig => _gridConfig;

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

        // 绘制主图顶部起始线
        canvas.drawLineType(
          horiLineType,
          Path()
            ..moveTo(mainLeft, dy)
            ..lineTo(mainRight, dy),
          horiPaint,
          dashes: horiDashes,
        );

        // 绘制主图网格线
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

        // 绘制每一个副图的底部线
        final list = subIndicatorHeightList;
        double height = 0.0;
        for (int i = 0; i < list.length; i++) {
          height += list[i];
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

        // 绘制左边线
        canvas.drawLineType(
          vertLineType,
          Path()
            ..moveTo(dx, mainTop)
            ..lineTo(dx, subBottom),
          vertPaint,
          dashes: vertDashes,
        );

        // 绘制主区/副区的Vertical线
        for (int i = 1; i < gridConfig.vertical.count; i++) {
          dx = i * step;
          canvas.drawLineType(
            vertLineType,
            Path()
              ..moveTo(dx, mainTop)
              ..lineTo(dx, mainBottom),
            vertPaint,
            dashes: vertDashes,
          );

          canvas.drawLineType(
            vertLineType,
            Path()
              ..moveTo(dx, subTop)
              ..lineTo(dx, subBottom),
            vertPaint,
            dashes: vertDashes,
          );
        }

        // 绘制右边线
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
