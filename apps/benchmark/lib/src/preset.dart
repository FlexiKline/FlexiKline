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

import 'indicators/ma.dart';
import 'indicators/macd.dart';
import 'indicators/vol_ma.dart';
import 'indicators/volume.dart';

/// 指标装配; 名称是场景名的后半段, 入库后不改。
enum BenchPreset {
  /// 只有蜡烛与时间轴。
  base,

  /// 典型页面: 主区 VOL(alone) + MA(combine), 副区 MACD + VOLMA, 全部带计算(VOL 除外)。
  full;

  static BenchPreset parse(String name) => values.firstWhere((s) => s.name == name);

  List<Indicator> mainIndicators() => this == full ? [BenchVolumeIndicator(), BenchMaIndicator()] : const [];

  List<Indicator> subIndicators() => this == full ? [BenchMacdIndicator(), BenchVolMaIndicator()] : const [];
}

/// 按场景打开的交互, 默认全关。
enum BenchFeature {
  /// 开启绘图并注册 flexi_kline_draw_tools 的全部工具。
  draw,

  /// 允许拖动指标分隔线调整高度; 打开后网格会多画可拖拽分隔线。
  resize,

  /// 允许在右侧价格轴上纵向拖动缩放 Y 轴; 打开后落在价格轴上的拖动归 zoom, 不再平移。
  zoom,
}
