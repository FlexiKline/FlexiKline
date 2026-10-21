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

import 'package:flexi_formatter/date_time.dart' show TimeUnit;
import 'package:flexi_kline/flexi_kline.dart';

const benchSpec = KlineSpec(symbol: 'DEVICE-BENCH', interval: FlexiTimeInterval(1, TimeUnit.minute));

/// 切换场景的另一个品种: 与 [benchSpec] 来回切换, 模拟切币对。
const benchAltSpec = KlineSpec(symbol: 'DEVICE-BENCH-ALT', interval: FlexiTimeInterval(1, TimeUnit.minute));

const _intervalMs = 60000;
const _latestTs = 1760000000000;

/// 固定种子的随机游走蜡烛, 按时间倒序(最新在前), 与 `replaceKlineData` / `appendHistoryKlineData` 的约定一致。
///
/// [offset] 为距最新一根的根数: 加载历史时取紧接已有数据的更早一段; 种子随 [offset] 变, 每段可复现。
List<CandleModel> benchCandles({int count = 2000, int offset = 0}) {
  final random = math.Random(20261020 + offset);
  var close = 1000.0;
  final candles = <CandleModel>[];
  for (var i = 0; i < count; i++) {
    final open = close + (random.nextDouble() - 0.5) * 8;
    final high = math.max(open, close) + random.nextDouble() * 6;
    final low = math.min(open, close) - random.nextDouble() * 6;
    candles.add(
      CandleModel(
        timestamp: _latestTs - (offset + i) * _intervalMs,
        open: _round(open),
        high: _round(high),
        low: _round(low),
        close: _round(close),
        volume: _round(500 + random.nextDouble() * 1500),
      ),
    );
    // 倒序生成: 下一根(更早)的收盘价围绕本根开盘价游走。
    close = open + (random.nextDouble() - 0.5) * 4;
  }
  return candles;
}

/// 实时场景的第 [tick] 次推送: 每 10 次收盘并开一根新蜡烛, 价格小幅摆动。
CandleModel benchTick(FlexiCandleModel latest, int tick) {
  final ts = tick % 10 == 9 ? latest.ts + _intervalMs : latest.ts;
  final close = latest.close.toDouble() + ((tick % 7) - 3) * 0.5;
  final open = ts == latest.ts ? latest.open.toDouble() : latest.close.toDouble();
  return CandleModel(
    timestamp: ts,
    open: open,
    high: math.max(open, close) + 1,
    low: math.min(open, close) - 1,
    close: _round(close),
    volume: 100,
  );
}

double _round(double v) => (v * 100).roundToDouble() / 100;
