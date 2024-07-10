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

import 'package:decimal/decimal.dart';

import '../constant.dart';

extension StringExt on String {
  Decimal? get decimal => Decimal.tryParse(this);
  Decimal get d => Decimal.tryParse(this) ?? Decimal.zero;
}

extension DoubleExt on double {
  Decimal get decimal => d;
  Decimal get d => Decimal.parse(toString());
}

extension IntExt on int {
  Decimal get decimal => d;
  Decimal get d => Decimal.fromInt(this);
}

final Decimal two = Decimal.fromInt(2);
final Decimal three = Decimal.fromInt(3);
final Decimal twentieth = (Decimal.one / Decimal.fromInt(20)).toDecimal();
final Decimal fifty = Decimal.fromInt(50);
final Decimal hundred = Decimal.fromInt(100);

extension FormatDecimal on Decimal {
  Decimal get half => (this / two).toDecimal(
        scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
      );

  Decimal divNum(num num) {
    assert(num != 0, 'divisor cannot be zero');
    if (num is int) return div(Decimal.fromInt(num));
    if (num is double) return div(num.d);
    throw Exception('$num cannot convert to decimal');
  }

  Decimal div(Decimal other) {
    assert(other != Decimal.zero, 'divisor cannot be zero');
    return (this / other).toDecimal(
      scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
    );
  }

  /// Global configuration for xThousand formatting default [thousandSeparator].
  static String thousandSeparator = ',';

  /// Global configuration for thousand formatting default unit [thousandUnitBuilder].
  static String Function(ThousandUnit) thousandUnitBuilder =
      (ThousandUnit unit) => unit.value;

  /// Global configuration for displayed as the minimum boundary value of the exponent.
  static Decimal exponentMinDecimal = Decimal.ten.pow(-15).toDecimal();

  /// Global configuration for displayed as the maximum boundary value of the exponent
  static Decimal exponentMaxDecimal = Decimal.ten.pow(21).toDecimal();

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

  /// use [RoundMode] to handling Decimal
  Decimal toRoundMode(RoundMode mode, {int? scale}) {
    Decimal val = this;
    scale ??= 0;
    switch (mode) {
      case RoundMode.round:
        val = val.round(scale: scale);
        break;
      case RoundMode.floor:
        val = val.floor(scale: scale);
        break;
      case RoundMode.ceil:
        val = val.ceil(scale: scale);
        break;
      case RoundMode.truncate:
        val = val.truncate(scale: scale);
        break;
    }
    return val;
  }

  /// The rational string that correctly represents this number.
  ///
  /// All [Decimal]s in the range `10^-15` (inclusive) to `10^21` (exclusive)
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
    Decimal val = this;
    if (mode != null) val = toRoundMode(mode, scale: precision);
    String result;
    if (val.abs() <= exponentMinDecimal || val.abs() > exponentMaxDecimal) {
      result = val.toStringAsExponential(precision);
      isClean = true;
    } else {
      result = val.toStringAsFixed(precision);
    }
    if (isClean) result = result.cleaned;
    return result;
  }

  /// Parsing [Decimal] to percentage [String].
  String get percentage => '${(this * hundred).toStringAsFixed(2).cleaned}%';

  /// Parsing Decimal to thousands [String].
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
}

extension on Decimal {
  static final trillionDecimal = Decimal.ten.pow(12).toDecimal();
  static final billionDecimal = Decimal.ten.pow(9).toDecimal();
  static final millionDecimal = Decimal.ten.pow(6).toDecimal();
  static final thousandDecimal = Decimal.ten.pow(3).toDecimal();

  (Decimal, ThousandUnit) get toCompact {
    final val = abs();
    if (val >= trillionDecimal) {
      return (
        (this / trillionDecimal).toDecimal(
          scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
        ),
        ThousandUnit.trillion,
      );
    } else if (val >= billionDecimal) {
      return (
        (this / billionDecimal).toDecimal(
          scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
        ),
        ThousandUnit.billion,
      );
    } else if (val >= millionDecimal) {
      return (
        (this / millionDecimal).toDecimal(
          scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
        ),
        ThousandUnit.million,
      );
    } else if (val >= thousandDecimal) {
      return (
        (this / thousandDecimal).toDecimal(
          scaleOnInfinitePrecision: defaultScaleOnInfinitePrecision,
        ),
        ThousandUnit.thousand,
      );
    } else {
      return (this, ThousandUnit.less);
    }
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
}
