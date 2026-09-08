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
/// 三种取位方式: 等分([dividedPositions])、固定间距([spacedPositions])、nice-number
/// 取整([computeNiceTicks])。都不认识 Rect 或 canvas, 值到像素的换算留给调用方。
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// 等分
// ---------------------------------------------------------------------------

/// 把 [length] 等分成 [divisions] 段, 产出 `divisions + 1` 个位置, **含两端**。
///
/// [divisions] 非正时返回空; 长度非正或非有限时返回空。
List<double> dividedPositions(int divisions, {required double start, required double length}) {
  if (divisions <= 0) return const [];
  if (!length.isFinite || length <= 0) return const [];
  final step = length / divisions;
  return [for (int i = 0; i <= divisions; i++) start + i * step];
}

/// 按**刻度数** [count] 等分产出位置, **含两端**。
///
/// `tickPositions(N)` 等价于 `dividedPositions(N - 1)`: 副区用刻度数描述(3 = 高/中/低),
/// 本函数做一次减法让调用方不必关心。
List<double> tickPositions(int count, {required double start, required double length}) {
  return dividedPositions(count - 1, start: start, length: length);
}

// ---------------------------------------------------------------------------
// 固定间距
// ---------------------------------------------------------------------------

/// 按固定间距 [spacing] 切分 [length], 余量平分两端, 产出**内部**位置。
///
/// 间距严格等于 [spacing], 不为整除而调整。装不下一格或参数无效时返回空。
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
typedef NiceStep = ({double step, double fraction, int exponent});

/// nice 步长候选: 1 / 2 / 2.5 / 5, 乘以 10 的整数次幂。
///
/// 末尾的 10 是归一化兜底。理想步长恰为 10 的整数次幂时 `log().floor()` 可能少一位指数
/// (如 1000 得到 exponent=2), 此时归一化系数为 10, 靠这一档才能还原出精确的步长。
const _niceFractions = <double>[1, 2, 2.5, 5, 10];

/// 在 [bottom], [top] 之间生成 nice 价格刻度。
///
/// [targetCount] 是目标间隔数, 实测刻度数落在 3~7。[precision] 是显示精度, 作为 step
/// 的选档约束。跨度非正或 [targetCount] 非正时返回空。
({double step, List<double> values}) computeNiceTicks({
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

/// 把理想步长 [rough] 归整到最接近的 nice 档位。
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

/// 降一档。
NiceStep _previousStep(NiceStep ns) {
  final index = _niceFractions.lastIndexWhere((f) => f < ns.fraction);
  final exponent = index < 0 ? ns.exponent - 1 : ns.exponent;
  final fraction = index < 0 ? 5.0 : _niceFractions[index];
  return (step: fraction * math.pow(10, exponent).toDouble(), fraction: fraction, exponent: exponent);
}
