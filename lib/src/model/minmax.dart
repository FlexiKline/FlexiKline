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

import 'package:decimal/decimal.dart';

import '../extension/collections_ext.dart';
import '../types.dart';
import 'flexi_num.dart';

class MinMax {
  static final MinMax zero = MinMax(max: FlexiNum.zero, min: FlexiNum.zero);

  MinMax({required this.max, required this.min});

  factory MinMax.same(FlexiNum val) => MinMax(max: val, min: val);

  factory MinMax.from(FlexiNum a, FlexiNum b) {
    if (a < b) (a, b) = (b, a);
    return MinMax(max: a, min: b);
  }

  MinMax clone() => MinMax(max: max, min: min);

  /// 两端点转成 [mode] 的**新**区间; 恒复制, 于是调用方不必额外 [clone]。
  MinMax reset(ComputeMode mode) => MinMax(max: max.reset(mode), min: min.reset(mode));

  FlexiNum max;
  FlexiNum min;

  // 外来值一律 reset 到端点自身的模式: [FlexiNum] 的运算恒以左操作数模式为准, 只有赋值绕过
  // 这条规则(`ByNum` / `ByDecimal` 按入参类型硬造 FlexiNum, 同属此列)。

  void updateMinMaxBy(FlexiNum val) {
    if (max < val) max = val.reset(max.mode);
    if (min > val) min = val.reset(min.mode);
  }

  void updateMinMaxByNum(num val) {
    if (max.ltNum(val)) max = FlexiNum.fromNum(val).reset(max.mode);
    if (min.gtNum(val)) min = FlexiNum.fromNum(val).reset(min.mode);
  }

  void updateMinMaxByDecimal(Decimal val) {
    if (max.ltDecimal(val)) max = FlexiNum.fromDecimal(val).reset(max.mode);
    if (min.gtDecimal(val)) min = FlexiNum.fromDecimal(val).reset(min.mode);
  }

  void updateMinMax(MinMax? minmax) {
    if (minmax == null) return;
    if (max < minmax.max) max = minmax.max.reset(max.mode);
    if (min > minmax.min) min = minmax.min.reset(min.mode);
  }

  void expand(num margin) {
    if (margin > 0) {
      max = max.addNum(margin);
      min = min.subNum(margin);
    }
  }

  void expandByRatios(List<double> ratios) {
    if (ratios.isEmpty) return;
    final maxRatio = ratios.firstOrNull;
    final minRatio = ratios.secondOrNull;
    if (maxRatio != null && maxRatio > 0) {
      max = max.mulNum(1 + maxRatio);
    }
    if (minRatio != null && minRatio > 0) {
      min = min.mulNum(1 - minRatio);
    }
  }

  /// 围绕区间中点按 [coeff] 缩放跨度, 中点保持不变。
  ///
  /// [coeff] 大于 1 时跨度变大, 同样的像素高度装进更大的价格跨度, 视觉上内容被压缩;
  /// 小于 1 时相反。
  ///
  /// 乘法本身不会产生 0 跨度, 所以不需要额外的跨度下限; 但极端缩小后 [max] 与 [min] 的
  /// 差可能小于其自身的浮点精度而相等, 此时 [diffDivisor] 回落到 1, 不会除零。
  ///
  /// [coeff] 非有限值或当前跨度为 0 时不做任何改动。
  void scaleAroundCenter(double coeff) {
    if (!coeff.isFinite || isSame) return;
    final center = (max + min).divNum(2);
    // clampScale: 缩放以当前区间为基准, 逐次自乘会让 Decimal 的 scale 无界增长。
    max = (center + (max - center).mulNum(coeff)).clampScale();
    min = (center + (min - center).mulNum(coeff)).clampScale();
  }

  /// 整体平移区间, 跨度保持不变。
  ///
  /// [delta] 非有限值或为 0 时不做任何改动。
  void shift(num delta) {
    if (!delta.isFinite || delta == 0) return;
    max = max.addNum(delta);
    min = min.addNum(delta);
  }

  void minToZero() {
    min = min > FlexiNum.zero ? FlexiNum.zero : min;
  }

  FlexiNum get middle => size / FlexiNum.two;

  FlexiNum get size => max - min;

  /// 最大最小值做为除数
  FlexiNum get diffDivisor => max == min ? FlexiNum.one : max - min;

  bool get isZero => max == FlexiNum.zero && min == FlexiNum.zero;

  bool get isSame => max == min;

  /// 两端点都能换算为有限 double; 否则既映射不出坐标, 也过不了 accurate 模式的 `Decimal.parse`。
  bool get isFinite => max.toDouble().isFinite && min.toDouble().isFinite;

  /// 计算给定集合[list]中的所有[FlexiNum]的最大最小值
  static MinMax? getMinMaxByList(List<FlexiNum?>? list) {
    if (list == null || list.isEmpty) return null;
    MinMax? minmax;
    for (final val in list) {
      if (val != null) {
        minmax ??= MinMax.same(val);
        minmax.updateMinMaxBy(val);
      }
    }
    return minmax;
  }

  /// 线性插值: 从 [a] 到 [b], 按 [t] 比例过渡 (t=0 返回 a, t=1 返回 b)
  ///
  /// 结果经 [FlexiNum.clampScale] 收口: 逐帧自插值会让 Decimal 的 scale 无界增长。
  static MinMax lerp(MinMax a, MinMax b, double t) {
    if (t >= 1 || a == b) return b.clone();
    if (t <= 0) return a.clone();
    final tNum = FlexiNum.fromNum(t);
    final oneMinusT = FlexiNum.fromNum(1 - t);
    return MinMax(
      max: (a.max * oneMinusT + b.max * tNum).clampScale(),
      min: (a.min * oneMinusT + b.min * tNum).clampScale(),
    );
  }

  @override
  String toString() {
    return 'MinMax(max:${max.toString()}, min:${min.toString()})';
  }
}
