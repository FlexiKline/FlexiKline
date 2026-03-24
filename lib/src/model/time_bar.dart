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

import 'package:flexi_formatter/date_time.dart';

import '../extension/basic_type_ext.dart';

/// 时间粒度接口
abstract interface class ITimeBar {
  String get bar;

  int get multiplier;

  TimeUnit get unit;
}

extension ITimeBarExt on ITimeBar {
  /// 是否是有效的时间粒度
  bool get isValid {
    return bar.isNotEmpty && multiplier > 0 && unit != TimeUnit.microsecond;
  }

  /// 当前时间粒度对应的毫秒数
  int get milliseconds => unit.microseconds ~/ 1000 * multiplier;

  bool get isUtc {
    return bar.equalsIgnoreCase('utc');
  }

  /// 比较两个时间粒度是否相同
  bool isSameAs(ITimeBar other) {
    return bar == other.bar && milliseconds == other.milliseconds;
  }
}

/// 比较两个时间粒度是否相同
bool compareTimeBar(ITimeBar a, ITimeBar b) {
  return a.bar == b.bar && a.milliseconds == b.milliseconds;
}

/// 自定义时间粒度
final class FlexiTimeBar implements ITimeBar {
  const FlexiTimeBar(
    this.bar,
    this.multiplier,
    this.unit,
  );
  @override
  final String bar;

  @override
  final int multiplier;

  @override
  final TimeUnit unit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ITimeBar &&
        runtimeType == other.runtimeType &&
        bar == other.bar &&
        milliseconds == other.milliseconds;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ bar.hashCode ^ milliseconds.hashCode;

  @override
  String toString() => '$bar:$milliseconds';
}
