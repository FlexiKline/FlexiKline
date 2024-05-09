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

import '../model/export.dart';

/// Base数据
abstract class BaseResult {
  final int ts;
  final bool dirty;

  BaseResult({required this.ts, required this.dirty});
}

/// MA, WMA, EMA计算结果
class MaResult extends BaseResult {
  final int count;
  final BagNum val;

  MaResult({
    required this.count,
    required super.ts,
    required this.val,
    super.dirty = false,
  });

  @override
  String toString() {
    return 'MaResult(ts:$ts, count:$count => val:${val.toString()})';
  }
}

/// MACD 计算结果
class MacdResult extends BaseResult {
  final BagNum emaShort;
  final BagNum emaLong;
  final BagNum dif;
  final BagNum dea;
  final BagNum macd;

  MacdResult({
    required super.ts,
    super.dirty = true,
    required this.dif,
    required this.dea,
    required this.macd,
    required this.emaShort,
    required this.emaLong,
  });

  MinMax get minmax {
    BagNum max = dif.compareTo(dea) > 0 ? dif : dea;
    max = max.compareTo(macd) > 0 ? max : macd;
    BagNum min = dif.compareTo(dea) < 0 ? dif : dea;
    min = min.compareTo(macd) < 0 ? min : macd;
    return MinMax(max: max, min: min);
  }

  @override
  String toString() {
    return 'MacdResult(ts:$ts, dif:${dif.toString()}, dea:${dea.toString()}, macd:${macd.toString()})';
  }
}

/// KDJ指标计算结果
class KdjReset extends BaseResult {
  final BagNum k;
  final BagNum d;
  final BagNum j;

  KdjReset({
    required super.ts,
    super.dirty = false,
    required this.k,
    required this.d,
    required this.j,
  });

  MinMax get minmax {
    BagNum max = k > d ? k : d;
    max = max > j ? max : j;
    BagNum min = k < d ? k : d;
    min = min < j ? min : j;
    return MinMax(max: max, min: min);
  }

  @override
  String toString() {
    return 'KdjReset(ts:$ts, k:${k.toString()}, d:${d.toString()}, j:${j.toString()})';
  }
}

class BollResult extends BaseResult {
  final BagNum mb;
  final BagNum up;
  final BagNum dn;

  BollResult({
    required super.ts,
    super.dirty = false,
    required this.mb,
    required this.up,
    required this.dn,
  });

  @override
  String toString() {
    return 'BollResult(ts:$ts, mb:${mb.toString()}, up:${up.toString()}, dn:${dn.toString()})';
  }
}
