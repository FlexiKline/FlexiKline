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

import 'dart:math' as math;

import '../constant.dart';

extension FormatNum<T extends num> on T {
  /// Global configuration for xThousand formatting default [thousandSeparator].
  static String thousandSeparator = ',';

  /// Global configuration for thousand formatting default unit [thousandUnitBuilder].
  static String Function(ThousandUnit) thousandUnitBuilder =
      (ThousandUnit unit) => unit.value;

  /// Global configuration for displayed as the minimum boundary value of the exponent.
  static num exponentMinDecimal = math.pow(10, -15);

  /// Global configuration for displayed as the maximum boundary value of the exponent
  static num exponentMaxDecimal = math.pow(10, 21);

  /// Format this number with thousands separators
  /// If [precision] is not specified, it defaults to 3.
  String compact({
    int precision = 3,
    bool isClean = true,
    String Function(ThousandUnit)? builder,
  }) {
    final (value, unit) = toCompact;
    String result = value.toStringAsFixed(precision);
    if (isClean) result = result.cleaned;
    final suffix = (builder ?? thousandUnitBuilder)(unit);

    return '$result$suffix';
  }

  /// use [RoundMode] to handling [T]
  /// 注: 在超过有效位数后会精度丢失.
  num toRoundMode(RoundMode mode, {int? precision}) {
    num val = this;
    precision ??= 0;
    if (precision > 0) val = val * math.pow(10, precision);
    switch (mode) {
      case RoundMode.round:
        val = val.round();
        break;
      case RoundMode.floor:
        val = val.floor();
        break;
      case RoundMode.ceil:
        val = val.ceil();
        break;
      case RoundMode.truncate:
        val = val.truncate();
        break;
    }
    if (precision > 0) val = val / math.pow(10, precision);
    return val;
  }

  /// The rational string that correctly represents this number.
  ///
  /// All [double]s in the range `10^-15` (inclusive) to `10^21` (exclusive)
  /// are converted to their decimal representation with at least one digit
  /// afer the decimal point. For all other decimal, this method returns an
  /// exponential representation (see [toStringAsExponential]).
  ///
  /// [precision] stands for fractionDigits
  String formatAsString(
    int precision, {
    RoundMode? mode,
    bool isClean = true,
  }) {
    num val = this;
    if (mode != null) val = toRoundMode(mode, precision: precision);
    String result;
    if (val.abs() <= exponentMinDecimal || val.abs() > exponentMaxDecimal) {
      result = val.toStringAsExponential(math.min(precision, 17));
      isClean = true;
    } else {
      precision = precision.clamp(0, 20);
      result = val.toStringAsFixed(precision);
    }
    if (isClean) result = result.cleaned;
    return result;
  }

  /// Parsing [T] to percentage [String].
  String get percentage => '${(this * 100).toStringAsFixed(2).cleaned}%';

  /// Parsing [T] to thousands [String].
  String thousands(
    int precision, {
    RoundMode? mode,
    bool isClean = true,
    String? separator,
  }) {
    String result = formatAsString(
      precision,
      mode: mode,
      isClean: isClean,
    ).thousands(
      separator ?? thousandSeparator,
    );
    return result;
  }

  /// Parsing [T] to ten thousands [String].
  String tenThousands(int precision, {RoundMode? mode, bool isClean = true}) =>
      xThousands(
        precision: precision,
        count: 4,
        isClean: isClean,
      );

  /// Parsing [T] to [count] strings separated by [separator].
  String xThousands({
    required int precision,
    required int count,
    RoundMode? mode,
    bool isClean = true,
    String? separator,
  }) {
    String result = formatAsString(
      precision,
      mode: mode,
      isClean: isClean,
    ).xThousands(
      count,
      separator ?? thousandSeparator,
    );
    return result;
  }
}

extension<T extends num> on T {
  (num, ThousandUnit) get toCompact {
    return switch (abs()) {
      >= 1000000000000 => (this / 1000000000000, ThousandUnit.trillion),
      >= 1000000000 => (this / 1000000000, ThousandUnit.billion),
      >= 1000000 => (this / 1000000, ThousandUnit.million),
      >= 1000 => (this / 1000, ThousandUnit.thousand),
      _ => (this, ThousandUnit.less),
    };
  }
}

extension on String {
  String get cleaned {
    return switch (this) {
      String value when value.endsWith('.') =>
        value.substring(0, value.length - 1),
      String value when value.endsWith('0') && contains('.') =>
        value.substring(0, value.length - 1).cleaned,
      String value when value.contains('e') =>
        value.replaceAll(RegExp(r'(?<=\.\d*?)0+(?!\d)'), ''),
      _ => this,
    };
  }

  String thousands(String separator) {
    final regex = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    final parts = split('.');
    return parts[0].replaceAllMapped(
          regex,
          (Match match) => '${match[1]}$separator',
        ) +
        (parts.length > 1 ? '.${parts[1]}' : '');
  }

  String xThousands(int count, String separator) {
    count = math.max(1, count);
    final regex = RegExp('''(\\d)(?=(\\d{$count})+(?!\\d))''');
    final parts = split('.');
    return parts[0].replaceAllMapped(
          regex,
          (Match match) => '${match[1]}$separator',
        ) +
        (parts.length > 1 ? '.${parts[1]}' : '');
  }
}
