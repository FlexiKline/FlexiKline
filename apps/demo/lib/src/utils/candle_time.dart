/// 时间戳对齐到周期边界（毫秒）。
int alignToInterval(int tsMs, int intervalMs) => (tsMs ~/ intervalMs) * intervalMs;
