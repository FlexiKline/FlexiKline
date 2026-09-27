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

/// 绘图工具分组 ID：线系列
const String drawGroupLines = 'lines';

/// 绘图工具分组 ID：投影系列
const String drawGroupProjection = 'projection';

/// 绘图工具分组 ID：斐波那契系列
const String drawGroupFibonacci = 'fibonacci';

/// 绘图工具分组 ID：形态系列
const String drawGroupPatterns = 'patterns';

// ---------------------------------------------------------------------------
// 线系列: lines
// ---------------------------------------------------------------------------

/// 趋势线（2 点）
const trendLine = FlexiDrawType('trendLine', 2, groupId: drawGroupLines);

/// 箭头线（2 点）
const arrowLine = FlexiDrawType('arrowLine', 2, groupId: drawGroupLines);

/// 延长趋势线（2 点）
const extendedTrendLine = FlexiDrawType(
  'extendedTrendLine',
  2,
  groupId: drawGroupLines,
);

/// 趋势线角度（2 点）
const trendAngle = FlexiDrawType('trendAngle', 2, groupId: drawGroupLines);

/// 射线（2 点）
const rayLine = FlexiDrawType('rayLine', 2, groupId: drawGroupLines);

/// 水平趋势线（2 点）
const horizontalTrendLine = FlexiDrawType(
  'horizontalTrendLine',
  2,
  groupId: drawGroupLines,
);

/// 水平射线（2 点）
const horizontalRayLine = FlexiDrawType(
  'horizontalRayLine',
  2,
  groupId: drawGroupLines,
);

/// 水平线（1 点）
const horizontalLine = FlexiDrawType(
  'horizontalLine',
  1,
  groupId: drawGroupLines,
);

/// 垂直线（1 点）
const verticalLine = FlexiDrawType(
  'verticalLine',
  1,
  groupId: drawGroupLines,
);

/// 十字线（1 点）
const crossLine = FlexiDrawType(
  'crossLine',
  1,
  groupId: drawGroupLines,
);

/// 价格线（1 点）
const priceLine = FlexiDrawType(
  'priceLine',
  1,
  groupId: drawGroupLines,
);

// ---------------------------------------------------------------------------
// 投影系列: projection
// ---------------------------------------------------------------------------

/// 矩形（2 点）
const rectangle = FlexiDrawType(
  'rectangle',
  2,
  groupId: drawGroupProjection,
);

/// 平行通道（3 点）
const parallelChannel = FlexiDrawType(
  'parallelChannel',
  3,
  groupId: drawGroupProjection,
);

/// 平行四边形（3 点，第 4 点自动推算）
const parallelogram = FlexiDrawType(
  'parallelogram',
  3,
  groupId: drawGroupProjection,
);

// ---------------------------------------------------------------------------
// 斐波那契系列: fibonacci
// ---------------------------------------------------------------------------

/// 斐波那契回撤（2 点）
const fibRetracement = FlexiDrawType(
  'fibRetracement',
  2,
  groupId: drawGroupFibonacci,
);

/// 斐波那契扩展（3 点）
const fibExpansion = FlexiDrawType(
  'fibExpansion',
  3,
  groupId: drawGroupFibonacci,
);

/// 斐波那契扇形（2 点）
const fibFans = FlexiDrawType(
  'fibFans',
  2,
  groupId: drawGroupFibonacci,
);

// ---------------------------------------------------------------------------
// 形态系列: patterns
// ---------------------------------------------------------------------------

/// 三浪（4 点），由 [ElliottImpulseWaveDrawObject] 实现
const tripleWaves = FlexiDrawType(
  'tripleWaves',
  4,
  groupId: drawGroupPatterns,
);

/// 五浪（6 点），由 [ElliottImpulseWaveDrawObject] 实现
const pentaWaves = FlexiDrawType(
  'pentaWaves',
  6,
  groupId: drawGroupPatterns,
);
