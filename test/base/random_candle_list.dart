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

import 'package:flexi_kline/flexi_kline.dart';

/// 随机生成CandleModel列表
/// [count] : 返回列表数量
/// [inital] : 初始收盘价
/// [range] : 开/收/高/低价的随机波动范围
/// [initalVol] : 初始交易量
/// [rangeVol] : 交易量的随机波动范围
/// [bar] : 时间间隔
/// [dateTime] : 初始时间
/// [isHistory] : 是否生成历史数据
Future<List<CandleModel>> genRandomCandleList({
  int count = 5,
  double inital = 1000,
  double range = 100,
  double initalVol = 100,
  double rangeVol = 50,
  TimeBar bar = TimeBar.D1,
  DateTime? dateTime,
  bool isHistory = true,
}) async {
  List<CandleModel> list = [];
  dateTime ??= DateTime.now();
  final random = math.Random();
  CandleModel? m;
  double h, l, o, c = inital, v = initalVol;

  double genVal(double m, double k, {bool? isUp}) {
    double val;
    double r = random.nextDouble();
    if (isUp != null) {
      r = r * r;
    }
    isUp ??= random.nextBool();
    if (isUp) {
      val = m + r * k;
    } else {
      val = m - r * k;
    }
    return val;
  }

  int flag = isHistory ? -1 : 1;

  for (int i = 0; i < count; i++) {
    o = c;
    c = genVal(o, range);
    h = genVal(math.max(o, c), range, isUp: true);
    l = genVal(math.min(o, c), range, isUp: false);
    if (h < l) [h, l] = [l, h];
    v = genVal(v, rangeVol);
    m = CandleModel(
      ts: dateTime
          .add(Duration(milliseconds: flag * i * bar.milliseconds))
          .millisecondsSinceEpoch,
      h: h.d,
      o: o.d,
      c: c.d,
      l: l.d,
      v: v.d,
    );
    if (isHistory) {
      list.add(m);
    } else {
      list.insert(0, m);
    }
  }

  return list;
}
