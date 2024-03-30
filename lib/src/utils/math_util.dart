import 'dart:math' as math;

/// 对数增长曲线（先快后慢）
double slowGrowth(double x, {double k = 0.1}) {
  return math.log(k * x) - 1;
}

/// 指数增长曲线（先慢后快）
double fastGrowth(double x, {double k = 0.1}) {
  return math.exp(x + 1) / k;
}
