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

/// 绘图层场景。
library;

import 'package:flexi_kline_benchmark/src/preset.dart';
import 'package:flexi_kline_draw_tools/flexi_kline_draw_tools.dart' as tools;
import 'package:flutter_test/flutter_test.dart';

import '../scenario.dart';
import 'interaction.dart' show pan;

final drawScenarios = <String, Scenario>{
  'draw/base': const Scenario(BenchPreset.base, pan, features: {BenchFeature.draw}, prepare: _fillDrawings),
};

/// draw 场景铺的绘图对象数量。
const _drawings = 30;

/// 在主图上半部铺 [_drawings] 个绘图对象(趋势线、射线、矩形、斐波那契回撤轮换), 只铺一次。
///
/// 只占主图上 45%: 拖动走在主图中线上, 起点不能落在绘图对象上, 否则手势会变成选中或移动对象。
Future<void> _fillDrawings(ScenarioContext ctx) async {
  final controller = ctx.controller;
  if (controller.hasDrawOverlay) return;
  const types = [tools.trendLine, tools.rayLine, tools.rectangle, tools.fibRetracement];
  final main = controller.mainRect;
  var created = 0;
  for (var i = 0; i < _drawings; i++) {
    final from = Offset(
      main.left + main.width * (0.05 + (i ~/ 6) * 0.18),
      main.top + main.height * (0.05 + (i % 6) * 0.05),
    );
    final to = from + Offset(main.width * 0.12, main.height * 0.04);
    controller.startDraw(types[i % types.length], isInitPointer: false);
    controller.onDrawConfirm(from);
    controller.onDrawUpdate(to);
    controller.onDrawConfirm(to);
    if (controller.drawState.object != null) created++;
    // 停在 Editing 时同类型再 startDraw 是收起语义, 退回 Prepared。
    controller.prepareDraw(force: true);
    // Overlay.id 取创建时刻的毫秒时间戳, 同一毫秒内同类型会撞号。
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  controller.exitDraw();
  await ctx.nextFrame();
  expect(created, _drawings, reason: '前置：$_drawings 个绘图对象都要落成');
  expect(controller.hasDrawOverlay, isTrue, reason: '前置：退出绘制后对象仍要显示');
}
