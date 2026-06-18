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

/// 记录 PaintObject 生命周期事件，供生命周期测试断言。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter/painting.dart';

/// 生命周期事件记录器。
class LifecycleLog {
  final List<String> events = <String>[];

  int countOf(String event) => events.where((e) => e == event).length;

  void clear() => events.clear();

  @override
  String toString() => events.toString();
}

/// Spy External 指标：createPaintObject 返回记录生命周期的 PaintObject。
class SpyExternalIndicator extends ExternalIndicator {
  SpyExternalIndicator({
    required super.key,
    required this.log,
    super.height = 80,
  }) : super(padding: EdgeInsets.zero);

  final LifecycleLog log;

  @override
  ExternalPaintObject<ExternalIndicator> createPaintObject() => SpyExternalPaintObject();
}

class SpyExternalPaintObject extends ExternalPaintObject<SpyExternalIndicator> {
  String get _id => indicator.key.id;
  LifecycleLog get _log => indicator.log;

  @override
  void initState() {
    super.initState();
    _log.events.add('initState:$_id');
  }

  @override
  void didAttach() => _log.events.add('didAttach:$_id');

  @override
  void didDetach() => _log.events.add('didDetach:$_id');

  @override
  void didChangeDependencies(KlineSpec oldSpec) => _log.events.add('didChangeDependencies:$_id');

  @override
  void didUpdateIndicator(covariant SpyExternalIndicator oldIndicator) {
    super.didUpdateIndicator(oldIndicator);
    _log.events.add('didUpdateIndicator:$_id');
  }

  @override
  void dispose() {
    if (isDisposed) return;
    _log.events.add('dispose:$_id');
    super.dispose();
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTooltip(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
}

/// Spy Computed 指标：默认 keepAlive=false；可传 keepAlive=true 验证用户复写。
class SpyComputedIndicator extends ComputedIndicator {
  SpyComputedIndicator({
    required super.key,
    required this.log,
    this.keepAlive = false,
    super.height = 100,
  }) : super(padding: EdgeInsets.zero);

  final LifecycleLog log;
  final bool keepAlive;

  @override
  ComputedPaintObject<ComputedIndicator> createPaintObject() => SpyComputedPaintObject();
}

class SpyComputedPaintObject extends ComputedPaintObject<SpyComputedIndicator> {
  String get _id => indicator.key.id;
  LifecycleLog get _log => indicator.log;

  @override
  bool get keepAlive => indicator.keepAlive;

  @override
  void initState() {
    super.initState();
    _log.events.add('initState:$_id');
  }

  @override
  void didAttach() => _log.events.add('didAttach:$_id');

  @override
  void didDetach() => _log.events.add('didDetach:$_id');

  @override
  void dispose() {
    if (isDisposed) return;
    _log.events.add('dispose:$_id');
    super.dispose();
  }

  @override
  MinMax? computeVisibleMinMax(int start, int end) => null;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  Size? paintTooltip(Canvas canvas, {FlexiCandleModel? model, Offset? offset, Rect? tipsRect}) => null;
  @override
  bool shouldRecompute(covariant SpyComputedIndicator oldIndicator) => false;
  @override
  void compute(Range range, {bool reset = false}) {}
}
