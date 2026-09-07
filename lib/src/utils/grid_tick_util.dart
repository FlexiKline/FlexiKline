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

/// 网格线与刻度的取位算法, 全部是纯函数。
///
/// 三种取位方式各占一节: 等分([evenPositions])、固定间距([spacedPositions])、nice-number
/// 取整([computePriceTicks])。前两种只吃长度, 后一种只吃价格区间 —— 都不认识 Rect、canvas
/// 或任何绘制对象, 值到像素的换算留给调用方(`PaintGridTicksMixin`)。
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// 等分
// ---------------------------------------------------------------------------

/// 把 [length] 等分成 [divisions] 段, 产出 `divisions - 1` 个**内部**位置。
///
/// 不含两端: 调用方的两端通常已有边框或分隔线, 再产出一条只是重合。[divisions] 是间隔数,
/// 因此 `1` 与非正值都没有内部位置。长度非正或非有限时返回空。
List<double> evenPositions(int divisions, {required double start, required double length}) {
  if (divisions <= 1) return const [];
  if (!length.isFinite || length <= 0) return const [];
  final step = length / divisions;
  return [for (int i = 1; i < divisions; i++) start + i * step];
}

/// 把 [length] 按**刻度数** [count] 等分, 产出 [count] 个位置, **含两端**。
///
/// 与 [evenPositions] 的端点语义刻意相反: 那里的参数是间隔数且避开两端, 这里的参数是刻度数
/// 且贴住两端 —— 贴顶贴底的两条承载的是区间极值, 是信息而非冗余。[count] 为 1 时取正中,
/// 非正时返回空。
List<double> positionsByCount(int count, {required double start, required double length}) {
  if (count <= 0) return const [];
  if (count == 1) return [start + length / 2];
  final step = length / (count - 1);
  return [for (int i = 0; i < count; i++) start + i * step];
}

// ---------------------------------------------------------------------------
// 固定间距
// ---------------------------------------------------------------------------

/// 按固定间距 [spacing] 切分 [length], 余量平分两端, 产出**内部**位置。
///
/// 间距严格等于 [spacing], 不为了整除而调整它 —— 那会让不同高度的 pane 呈现不同间距, 本
/// 模式随之失去意义。余量平分两端即整体居中; 两端本身通常是边框, 不重复产出, 所以位置数是
/// 完整间隔数减一。装不下一格、[spacing] 非正或非有限、长度非正或非有限时返回空。
List<double> spacedPositions(double spacing, {required double start, required double length}) {
  if (spacing <= 0 || !spacing.isFinite) return const [];
  if (!length.isFinite || length <= 0) return const [];
  final count = (length / spacing).floor(); // 完整间隔数
  if (count <= 0) return const []; // 容不下一格
  final pad = (length - count * spacing) / 2;
  return [for (int i = 1; i < count; i++) start + pad + i * spacing];
}

// ---------------------------------------------------------------------------
// nice-number 取整
// ---------------------------------------------------------------------------

/// 归一化的 nice 步长: step == fraction * 10^exponent。
///
/// [fraction] 与 [exponent] 是为了让换档不必重新解析 [step], 不出本文件的边界。
typedef NiceStep = ({double step, double fraction, int exponent});

/// nice 步长候选: 1 / 2 / 2.5 / 5, 乘以 10 的整数次幂。
///
/// 末尾的 10 是归一化兜底。理想步长恰为 10 的整数次幂时 `log().floor()` 可能少一位指数
/// (如 1000 得到 exponent=2), 此时归一化系数为 10, 靠这一档才能还原出精确的步长。
const _niceFractions = <double>[1, 2, 2.5, 5, 10];

/// 在 [bottom], [top] 之间生成 nice 价格刻度。
///
/// [targetCount] 是目标**间隔数**, 实测实际刻度数落在 3~7。[precision] 是显示侧的最小可辨
/// 精度, 只作为 step 的选档约束进来 —— 本函数不产出任何格式化参数, 刻度文本由调用方的
/// `formatPrice` 决定。
///
/// 跨度非正、非有限或 [targetCount] 非正时返回空列表。
({double step, List<double> values}) computePriceTicks({
  required double bottom,
  required double top,
  required int targetCount,
  required int precision,
}) {
  final range = top - bottom;
  if (!range.isFinite || range <= 0 || targetCount <= 0) {
    return (step: 0, values: const []);
  }

  var ns = _fitPrecision(niceStep(range / targetCount), precision);
  var values = _buildTicks(bottom, top, ns.step, targetCount);

  // targetCount <= 2 时最接近取档可能给出 step > range, 区间内一个整数倍都没有。空刻度会让
  // 滑竿宽度归零、zoom 手势失效, 所以降一档重试一次(仍要过一遍 precision 约束)。
  if (values.isEmpty) {
    ns = _fitPrecision(_previousStep(ns), precision);
    values = _buildTicks(bottom, top, ns.step, targetCount);
  }
  return (step: ns.step, values: values);
}

/// 列出 [bottom], [top] 之间所有 [step] 的整数倍。
List<double> _buildTicks(double bottom, double top, double step, int targetCount) {
  if (step <= 0) return const [];
  final values = <double>[];
  // 减一个容差: bottom 恰为 step 整数倍时, 浮点除法可能给出 5.000000000000001 而 ceil 到 6,
  // 白丢最边缘一条刻度。
  var i = (bottom / step - 1e-9).ceil();
  // 用 v = (++i) * step 递推而非 v += step: 累加的浮点误差随项数增长(0.1 起步第 8 项得到
  // 0.7999999999999999), 乘法的误差恒定不累积。
  for (var v = i * step; v <= top; v = (++i) * step) {
    values.add(v);
    if (values.length > targetCount * 4) break; // 防御: step 异常时不无限循环
  }
  return values;
}

/// 把理想步长 [rough] 归整到最接近的 nice 档位。[rough] 须为正的有限值。
///
/// 取「最接近」而非「不小于」: 后者实测在 21 个价格 × 缩放组合中有 8 次给出不足 3 条刻度。
NiceStep niceStep(double rough) {
  final exponent = (math.log(rough) / math.ln10).floor();
  final base = math.pow(10, exponent).toDouble();
  final f = rough / base;
  for (int i = 0; i < _niceFractions.length - 1; i++) {
    final lo = _niceFractions[i];
    final hi = _niceFractions[i + 1];
    if (f <= hi) {
      final fraction = f - lo < hi - f ? lo : hi;
      return (step: fraction * base, fraction: fraction, exponent: exponent);
    }
  }
  return (step: 10 * base, fraction: 10, exponent: exponent);
}

/// 把 [ns] 调整为满足「是最小可辨单位 u = 10^-[precision] 的整数倍」的档位。
///
/// 这一条约束封住两种失败模式: step 小于 u 会让刻度文本重复; step 大于 u 却不是整数倍
/// 会让等距的刻度线在格式化之后显示成不等差的数字(如 5.43 | 5.45 | 5.48 | 5.50)。
NiceStep _fitPrecision(NiceStep ns, int precision) {
  final u = math.pow(10, -precision).toDouble();
  if (ns.step < u) {
    return (step: u, fraction: 1, exponent: -precision);
  }

  // 非整数倍的商恒为 2.5(exponent 恰为 -precision 的那一档), 提升到同量级的 5 而不是降到
  // 2: 降档会让 step 更逼近 u, 方向相反。
  final quotient = ns.step / u;
  final rounded = quotient.roundToDouble();
  // 相对容差而非相等比较: 商在 double 下会带尾数(如 2.4999999999999996 与
  // 25.000000000000004), 相等比较会把合法档位误判成非整数倍。step >= u 保证 rounded >= 1,
  // 容差不会退化为 0。
  if ((quotient - rounded).abs() > rounded * 1e-6) {
    final base = math.pow(10, ns.exponent).toDouble();
    return (step: 5 * base, fraction: 5, exponent: ns.exponent);
  }
  return ns;
}

/// 降一档。1 档的下一档是上一量级的 5, 其余档在同量级内下移。
NiceStep _previousStep(NiceStep ns) {
  final index = _niceFractions.lastIndexWhere((f) => f < ns.fraction);
  final exponent = index < 0 ? ns.exponent - 1 : ns.exponent;
  final fraction = index < 0 ? 5.0 : _niceFractions[index];
  return (step: fraction * math.pow(10, exponent).toDouble(), fraction: fraction, exponent: exponent);
}
