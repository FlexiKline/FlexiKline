// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kline_spec.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$KlineSpecCWProxy {
  KlineSpec symbol(String symbol);

  KlineSpec interval(ITimeInterval interval);

  KlineSpec limit(int limit);

  KlineSpec precision(int precision);

  KlineSpec from(int? from);

  KlineSpec to(int? to);

  KlineSpec label(String? label);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `KlineSpec(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// KlineSpec(...).copyWith(id: 12, name: "My name")
  /// ```
  KlineSpec call({
    String symbol,
    ITimeInterval interval,
    int limit,
    int precision,
    int? from,
    int? to,
    String? label,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfKlineSpec.copyWith(...)` or call `instanceOfKlineSpec.copyWith.fieldName(value)` for a single field.
class _$KlineSpecCWProxyImpl implements _$KlineSpecCWProxy {
  const _$KlineSpecCWProxyImpl(this._value);

  final KlineSpec _value;

  @override
  KlineSpec symbol(String symbol) => call(symbol: symbol);

  @override
  KlineSpec interval(ITimeInterval interval) => call(interval: interval);

  @override
  KlineSpec limit(int limit) => call(limit: limit);

  @override
  KlineSpec precision(int precision) => call(precision: precision);

  @override
  KlineSpec from(int? from) => call(from: from);

  @override
  KlineSpec to(int? to) => call(to: to);

  @override
  KlineSpec label(String? label) => call(label: label);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `KlineSpec(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// KlineSpec(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  KlineSpec call({
    Object? symbol = const $CopyWithPlaceholder(),
    Object? interval = const $CopyWithPlaceholder(),
    Object? limit = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
    Object? from = const $CopyWithPlaceholder(),
    Object? to = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return KlineSpec(
      symbol: symbol == const $CopyWithPlaceholder() || symbol == null
          ? _value.symbol
          // ignore: cast_nullable_to_non_nullable
          : symbol as String,
      interval: interval == const $CopyWithPlaceholder() || interval == null
          ? _value.interval
          // ignore: cast_nullable_to_non_nullable
          : interval as ITimeInterval,
      limit: limit == const $CopyWithPlaceholder() || limit == null
          ? _value.limit
          // ignore: cast_nullable_to_non_nullable
          : limit as int,
      precision: precision == const $CopyWithPlaceholder() || precision == null
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int,
      from: from == const $CopyWithPlaceholder()
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as int?,
      to: to == const $CopyWithPlaceholder()
          ? _value.to
          // ignore: cast_nullable_to_non_nullable
          : to as int?,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
    );
  }
}

extension $KlineSpecCopyWith on KlineSpec {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfKlineSpec.copyWith(...)` or `instanceOfKlineSpec.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$KlineSpecCWProxy get copyWith => _$KlineSpecCWProxyImpl(this);
}
