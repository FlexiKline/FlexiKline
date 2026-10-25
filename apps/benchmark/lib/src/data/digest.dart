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

/// 场景口径的版本: 场景常量(根数、种子、手势参数、窗口)变化时加 1。
///
/// 两侧版本号与 [dataDigest] 都相等, 才说明两次采集喂的是同一份负载; 它取代比对基准代码的树哈希,
/// 因为跨数据方向对比时两侧各用自己版本的基准代码。
const scenarioVersion = 1;

/// 蜡烛内容的指纹: 按时间戳排序后对 (ts, o, h, l, c, v) 取 FNV-1a 64 位哈希, 与列表方向无关。
String dataDigest(List<CandleModel> candles) {
  final sorted = [...candles]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  var hash = 0xcbf29ce484222325;
  for (final c in sorted) {
    for (final unit in '${c.timestamp},${c.open},${c.high},${c.low},${c.close},${c.volume};'.codeUnits) {
      hash = (hash ^ unit) * 0x100000001b3;
    }
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}
