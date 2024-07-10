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

import 'package:flutter/material.dart';

import '../config/sar_param/sar_param.dart';
import '../framework/common.dart';
import '../model/export.dart';
import 'base_data.dart';

/// SAR 指标 是以英文为缩写的技术指标，全名为Parabolic Stop and Reverse，意思即「停止和转向」，
/// 目的是提供市场趋势转向的讯号，包含止盈与停损讯号。
/// 当一段快速的趋势中 (无论上行或下行)，SAR指针分析价格与时间，此指针会形成一条抛物线，所以 SAR指标 又称为「抛物线指标」。
mixin SARData on BaseData {
  @override
  void initData() {
    super.initData();
    logd('init SAR');
  }

  @override
  void dispose() {
    super.dispose();
    logd('dispose SAR');
    for (var model in list) {
      model.cleanSar();
    }
  }

  @override
  void precompute(
    ValueKey key, {
    dynamic calcParam,
    required Range range,
    bool reset = false,
  }) {
    if ((key == sarKey || key == subSarKey) && calcParam is SARParam) {
      calcuAndCacheSar(
        param: calcParam,
        // start: range.start,
        // end: range.end,
        reset: reset,
      );
      return;
    }
    super.precompute(key, calcParam: calcParam, range: range, reset: reset);
  }

  /// SAR 的计算公式:
  /// SAR(今日)：SAR (昨日) + AF (动能趋势指标) x [ (区间极值(波段内最极值) – SAR(昨日)]
  /// 当前SAR依赖于昨日SAR, 以及区间极值和这一阶段的动能趋势AF, 因此, 每次都从头开始算.
  /// 加之极值与动能趋势指标AF在任意位置开始时, 向前追溯算法相对会复杂.
  void calcuAndCacheSar({
    required SARParam param,
    bool reset = false,
  }) {
    final len = list.length;
    const start = 0;
    int end = len;
    if (!checkStartAndEnd(start, end)) return;
    logd('calcuAndCacheSar [len:$len ~ 0] param:$param');

    end = end - 1;

    double af = param.startAf;
    final step = param.step;
    final maxAf = param.maxAf;
    BagNum? ep;
    bool isIncreasing = false;
    BagNum sar = BagNum.zero;
    BagNum minLow;
    BagNum maxHigh;
    CandleModel m;
    int flag = 0;
    for (int i = end; i >= start; i--) {
      m = list[i];
      if (isIncreasing) {
        flag = 1; // 上涨
        if (ep == null || ep < m.high) {
          ep = m.high;
          af = math.min(af + step, maxAf);
        }
        sar = (ep - sar).mulNum(af) + sar;
        minLow = m.low.calcuMin(list[math.min(i + 1, end)].low);
        if (sar > m.low) {
          sar = ep;
          // 重新初始化值
          flag = 0; // 开始上涨.
          af = param.startAf;
          ep = null;
          isIncreasing = !isIncreasing;
        } else if (sar > minLow) {
          sar = minLow;
        }
      } else {
        flag = -1; // 下跌
        if (ep == null || ep > m.low) {
          ep = m.low;
          af = math.min(af + step, maxAf);
        }
        sar = (ep - sar).mulNum(af) + sar;
        maxHigh = m.high.calcuMax(list[math.min(i + 1, end)].high);
        if (sar < m.high) {
          sar = ep;
          // 重新初始化值
          flag = 0; // 开始下跌.
          af = 0;
          ep = null;
          isIncreasing = !isIncreasing;
        } else if (sar < maxHigh) {
          sar = maxHigh;
        }
      }
      m.sarFlag = flag;
      m.sar = sar;
    }
  }

  MinMax? calcuSarMinmax({
    required SARParam param,
    int? start,
    int? end,
  }) {
    start ??= this.start;
    end ??= this.end;
    if (!checkStartAndEnd(start, end)) return null;

    int endIndex = end - 1;
    if (end < start) return null;
    if (!list[endIndex].isValidSarData) {
      calcuAndCacheSar(param: param);
    }

    MinMax? minmax;
    CandleModel m;
    for (int i = endIndex; i >= start; i--) {
      m = list[i];
      if (m.sar != null) {
        minmax ??= MinMax.same(m.sar!);
        minmax.updateMinMaxBy(m.sar!);
      }
    }
    return minmax;
  }
}
