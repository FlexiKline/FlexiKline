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

/// 自定义 matcher：断言即规格。
library;

import 'package:flexi_kline/flexi_kline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../doubles/lifecycle_spy.dart';

/// 断言 key 已在主区激活
Matcher isActivatedInMain(IndicatorPaintObjectManager m) =>
    _ActivatedMatcher(m, main: true);

/// 断言 key 已在副区激活
Matcher isActivatedInSub(IndicatorPaintObjectManager m) =>
    _ActivatedMatcher(m, main: false);

/// 断言 ComputedIndicatorKey 已分配 slot
Matcher hasComputedSlot(IndicatorPaintObjectManager m) =>
    _HasSlotMatcher(m, expectSlot: true);

/// 断言 key 未分配 slot
Matcher hasNoComputedSlot(IndicatorPaintObjectManager m) =>
    _HasSlotMatcher(m, expectSlot: false);

/// 断言生命周期事件按给定顺序出现（允许其间插入其它事件）
Matcher emitsLifecycle(List<String> ordered) => _EmitsLifecycleMatcher(ordered);

// ---------------------------------------------------------------------------
// 实现
// ---------------------------------------------------------------------------

class _ActivatedMatcher extends Matcher {
  _ActivatedMatcher(this._m, {required this.main});
  final IndicatorPaintObjectManager _m;
  final bool main;

  @override
  bool matches(Object? item, Map matchState) {
    final keys = main ? _m.mainIndicatorKeys : _m.subIndicatorKeys;
    return keys.contains(item);
  }

  @override
  Description describe(Description d) =>
      d.add('activated in ${main ? "main" : "sub"}');

  @override
  Description describeMismatch(
      Object? item, Description d, Map matchState, bool verbose) {
    final keys = main ? _m.mainIndicatorKeys : _m.subIndicatorKeys;
    return d.add('$item not found in ${keys.toList()}');
  }
}

class _HasSlotMatcher extends Matcher {
  _HasSlotMatcher(this._m, {required this.expectSlot});
  final IndicatorPaintObjectManager _m;
  final bool expectSlot;

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! ComputedIndicatorKey) return !expectSlot;
    final slot = _m.getComputedDataIndex(item);
    return expectSlot ? slot != null : slot == null;
  }

  @override
  Description describe(Description d) =>
      d.add('${expectSlot ? "has" : "has no"} computed slot');
}

class _EmitsLifecycleMatcher extends Matcher {
  _EmitsLifecycleMatcher(this._ordered);
  final List<String> _ordered;

  @override
  bool matches(Object? item, Map matchState) {
    final List<String> events;
    if (item is List<String>) {
      events = item;
    } else if (item is LifecycleLog) {
      events = item.events;
    } else {
      return false;
    }
    int i = 0;
    for (final e in events) {
      if (i < _ordered.length && e == _ordered[i]) i++;
    }
    return i == _ordered.length;
  }

  @override
  Description describe(Description d) =>
      d.add('emits lifecycle in order $_ordered');

  @override
  Description describeMismatch(
      Object? item, Description d, Map matchState, bool verbose) {
    final events = item is LifecycleLog ? item.events : item;
    return d.add('actual events: $events');
  }
}
