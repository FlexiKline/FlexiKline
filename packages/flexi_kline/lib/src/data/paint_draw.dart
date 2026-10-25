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

part of 'kline_data.dart';

mixin PaintDrawData on BaseData {
  /// 以最新根右侧移出视区的根数 [barsBack] 与可见根数 [count] 设置绘制区间 `[start, end)`。
  void ensurePaintRange({required int barsBack, required int count}) {
    end = length - barsBack;
    start = end - count;
  }

  Range get computableRange => Range(0, length);

  Range get paintIndexRange => Range(start, end);

  /// [ts]对应的连续下标: 整数位是蜡烛中心, 相邻蜡烛间按 ts 线性插值, 两端外按周期外推.
  double? timestampToIndex(int ts) {
    if (isEmpty || !spec.interval.isValid) return null;
    final span = spec.interval.milliseconds;
    final first = _list.first.ts, last = _list.last.ts;
    if (ts <= first) return (ts - first) / span;
    if (ts >= last) return length - 1 + (ts - last) / span;
    final i = _lowerBound(ts); // _list[i-1].ts < ts <= _list[i].ts
    final hi = _list[i].ts;
    if (hi == ts) return i.toDouble();
    final lo = _list[i - 1].ts;
    return i - 1 + (ts - lo) / (hi - lo);
  }

  /// [timestampToIndex]的逆; [index] 非有限值时返回 null。
  int? indexToTimestamp(double index) {
    if (isEmpty || !spec.interval.isValid || !index.isFinite) return null;
    final span = spec.interval.milliseconds;
    final last = length - 1;
    if (index <= 0) return _list.first.ts + (index * span).round();
    if (index >= last) return _list.last.ts + ((index - last) * span).round();
    final i = index.floor();
    final lo = _list[i].ts;
    return lo + ((index - i) * (_list[i + 1].ts - lo)).round();
  }
}
