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

/// K 线数据工厂：随机生成 + 调试打印工具。
library;

import 'dart:math' as math;

import 'package:flexi_formatter/flexi_formatter.dart';
import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// 随机 K 线生成
// ---------------------------------------------------------------------------

/// 随机生成 [CandleModel] 列表
Future<List<CandleModel>> genRandomCandleList({
  int count = 5,
  double inital = 1000,
  double range = 100,
  double initalVol = 100,
  double rangeVol = 50,
  ITimeInterval interval = const FlexiTimeInterval(1, TimeUnit.day),
  DateTime? dateTime,
  bool isHistory = true,
}) async {
  final List<CandleModel> list = [];
  dateTime ??= DateTime.now();
  final random = math.Random();
  double h, l, o, c = inital, v = initalVol;

  double genVal(double m, double k, {bool? isUp}) {
    double r = random.nextDouble();
    if (isUp != null) r = r * r;
    isUp ??= random.nextBool();
    return isUp ? m + r * k : m - r * k;
  }

  final int flag = isHistory ? -1 : 1;

  for (int i = 0; i < count; i++) {
    o = c;
    c = genVal(o, range);
    h = genVal(math.max(o, c), range, isUp: true);
    l = genVal(math.min(o, c), range, isUp: false);
    if (h < l) [h, l] = [l, h];
    v = genVal(v, rangeVol);
    final m = CandleModel(
      timestamp: dateTime.add(Duration(milliseconds: flag * i * interval.milliseconds)).millisecondsSinceEpoch,
      high: h.d,
      open: o.d,
      close: c.d,
      low: l.d,
      volume: v.d,
    );
    if (isHistory) {
      list.add(m);
    } else {
      list.insert(0, m);
    }
  }
  return list;
}

// ---------------------------------------------------------------------------
// 调试打印工具
// ---------------------------------------------------------------------------

/// 逐行打印可迭代集合
void printIterable<T>(Iterable<T> list, {String? tag}) {
  for (final val in list) {
    debugPrint('${tag ?? ''}>${val.toString()}');
  }
}

/// 逐行打印 Map
void printMap<K, V>(Map<K, V> map, {String? tag}) {
  map.forEach((key, val) {
    debugPrint('${tag ?? ''}> key:$key \t val:${val.toString()}');
  });
}

/// 简易日志打印
void logMsg(dynamic msg) {
  debugPrint(msg.toString());
}

// ---------------------------------------------------------------------------
// 确定性 K 线生成（手势与视口用例专用）
// ---------------------------------------------------------------------------

/// 生成 [count] 根价量恒定的蜡烛，时间戳自 [latestTimestamp] 按 [intervalMs] 向历史递减。
///
/// 手势与视口用例只需要「蜡烛够多，`paintDxOffset` 双向都有可平移的余量」，不关心行情形态。
/// 价量恒定让断言只受手势影响，不受随机数据影响；[genRandomCandleList] 那种随机序列会让
/// 缩放锚点、Y 轴 minMax 一类断言变得不可复现。
List<CandleModel> genFlatCandleList({
  int count = 200,
  int latestTimestamp = 12000000,
  int intervalMs = 60000,
}) {
  return List.generate(
    count,
    (index) => CandleModel(
      timestamp: latestTimestamp - index * intervalMs,
      open: 100,
      high: 110,
      low: 90,
      close: 105,
      volume: 1000,
    ),
  );
}
