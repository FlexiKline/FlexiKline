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

import '../extension/collections_ext.dart';

class MinMax {
  static final MinMax zero = MinMax(max: 0, min: 0);

  MinMax({required this.max, required this.min});

  factory MinMax.same(double val) => MinMax(max: val, min: val);

  factory MinMax.from(double a, double b) {
    if (a < b) (a, b) = (b, a);
    return MinMax(max: a, min: b);
  }

  MinMax clone() => MinMax(max: max, min: min);

  double max;
  double min;

  void updateMinMaxBy(double val) {
    if (max < val) max = val;
    if (min > val) min = val;
  }

  void updateMinMax(MinMax? minmax) {
    if (minmax == null) return;
    if (max < minmax.max) max = minmax.max;
    if (min > minmax.min) min = minmax.min;
  }

  void expand(num margin) {
    if (margin > 0) {
      max += margin;
      min -= margin;
    }
  }

  void expandByRatios(List<double> ratios) {
    if (ratios.isEmpty) return;
    final maxRatio = ratios.firstOrNull;
    final minRatio = ratios.secondOrNull;
    if (maxRatio != null && maxRatio > 0) {
      max *= 1 + maxRatio;
    }
    if (minRatio != null && minRatio > 0) {
      min *= 1 - minRatio;
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
    final center = (max + min) / 2;
    max = center + (max - center) * coeff;
    min = center + (min - center) * coeff;
  }

  /// 整体平移区间, 跨度保持不变。
  ///
  /// [delta] 非有限值或为 0 时不做任何改动。
  void shift(num delta) {
    if (!delta.isFinite || delta == 0) return;
    max += delta;
    min += delta;
  }

  void minToZero() {
    if (min > 0) min = 0;
  }

  double get middle => size / 2;

  double get size => max - min;

  /// 最大最小值做为除数
  double get diffDivisor => max == min ? 1 : max - min;

  bool get isZero => max == 0 && min == 0;

  bool get isSame => max == min;

  /// 两端点都是有限值; 否则映射不出坐标。
  bool get isFinite => max.isFinite && min.isFinite;

  /// 计算给定集合[list]中所有非 null 值的最大最小值
  static MinMax? getMinMaxByList(List<double?>? list) {
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
  static MinMax lerp(MinMax a, MinMax b, double t) {
    if (t >= 1 || a == b) return b.clone();
    if (t <= 0) return a.clone();
    return MinMax(max: a.max * (1 - t) + b.max * t, min: a.min * (1 - t) + b.min * t);
  }

  @override
  String toString() {
    return 'MinMax(max:$max, min:$min)';
  }
}
