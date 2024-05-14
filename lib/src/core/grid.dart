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
import '../model/export.dart';
import 'binding_base.dart';
import 'interface.dart';
import 'setting.dart';

mixin GridBinding
    on KlineBindingBase, SettingBinding
    implements IGrid, IConfig {
  @override
  void init() {
    super.init();
    initGridConfig(gridConfig);
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
    storeGridConfig(grid);
  }

  late Grid _grid;

  @override
  Grid get grid => _grid;

  void initGridConfig(Map<String, dynamic> config) {
    // 从配置中恢复
    _grid = Grid.fromJson(config);
  }

  @override
  void markRepaintGrid() => repaintGridBg.value++;
  ValueNotifier<int> repaintGridBg = ValueNotifier(0);

  void paintGridBg(Canvas canvas, Size size) {
    if (grid.show) {
      // 主图图Grid X轴起始值
      const mainLeft = 0.0;
      final mainRight = mainRectWidth;
      // 主图图Grid Y轴起始值
      const mainTop = 0.0;
      final mainBottom = mainDrawBottom;
      // 副图Grid Y轴起始值
      final subTop = subRect.top;
      final subBottom = subRect.bottom;

      // 绘制horizontal轴 Grid 线
      if (grid.horizontal.show) {
        double dy = mainTop;

        // 绘制主图顶部起始线
        canvas.drawLineType(
          grid.horizontal.type,
          Path()
            ..moveTo(mainLeft, dy)
            ..lineTo(mainRight, dy),
          grid.horizontal.paint,
        );

        // 绘制主图网格线
        final step = mainBottom / grid.horizontal.count;
        for (int i = 1; i < grid.horizontal.count; i++) {
          dy = i * step;
          canvas.drawLineType(
            grid.horizontal.type,
            Path()
              ..moveTo(mainLeft, dy)
              ..lineTo(mainRight, dy),
            grid.horizontal.paint,
          );
        }

        // 绘制主图mainDrawBottom线
        canvas.drawLineType(
          grid.horizontal.type,
          Path()
            ..moveTo(mainLeft, mainBottom)
            ..lineTo(mainRight, mainBottom),
          grid.horizontal.paint,
        );

        // 绘制副图区域起始线
        canvas.drawLineType(
          grid.horizontal.type,
          Path()
            ..moveTo(mainLeft, subTop)
            ..lineTo(mainRight, subTop),
          grid.horizontal.paint,
        );

        // 绘制每一个副图的底部线
        final list = subIndicatorHeightList;
        double height = 0.0;
        for (int i = 0; i < list.length; i++) {
          height += list[i];
          dy = subTop + height;
          canvas.drawLineType(
            grid.horizontal.type,
            Path()
              ..moveTo(mainLeft, dy)
              ..lineTo(mainRight, dy),
            grid.horizontal.paint,
          );
        }
      }

      // 绘制Vertical轴 Grid 线
      if (grid.vertical.show) {
        double dx = mainLeft;
        final step = mainRight / grid.vertical.count;

        for (int i = 1; i < grid.vertical.count; i++) {
          dx = i * step;
          canvas.drawLineType(
            grid.horizontal.type,
            Path()
              ..moveTo(dx, mainTop)
              ..lineTo(dx, mainBottom),
            grid.horizontal.paint,
          );

          canvas.drawLineType(
            grid.horizontal.type,
            Path()
              ..moveTo(dx, subTop)
              ..lineTo(dx, subBottom),
            grid.horizontal.paint,
          );
        }
      }
    }
  }
}
