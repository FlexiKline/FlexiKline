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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `KlineSpec(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// KlineSpec(...).copyWith(id: 12, name: "My name")
  /// ````
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfKlineSpec.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfKlineSpec.copyWith.fieldName(...)`
class _$KlineSpecCWProxyImpl implements _$KlineSpecCWProxy {
  const _$KlineSpecCWProxyImpl(this._value);

  final KlineSpec _value;

  @override
  KlineSpec symbol(String symbol) => this(symbol: symbol);

  @override
  KlineSpec interval(ITimeInterval interval) => this(interval: interval);

  @override
  KlineSpec limit(int limit) => this(limit: limit);

  @override
  KlineSpec precision(int precision) => this(precision: precision);

  @override
  KlineSpec from(int? from) => this(from: from);

  @override
  KlineSpec to(int? to) => this(to: to);

  @override
  KlineSpec label(String? label) => this(label: label);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `KlineSpec(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// KlineSpec(...).copyWith(id: 12, name: "My name")
  /// ````
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
      symbol: symbol == const $CopyWithPlaceholder()
          ? _value.symbol
          // ignore: cast_nullable_to_non_nullable
          : symbol as String,
      interval: interval == const $CopyWithPlaceholder()
          ? _value.interval
          // ignore: cast_nullable_to_non_nullable
          : interval as ITimeInterval,
      limit: limit == const $CopyWithPlaceholder()
          ? _value.limit
          // ignore: cast_nullable_to_non_nullable
          : limit as int,
      precision: precision == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfKlineSpec.copyWith(...)` or like so:`instanceOfKlineSpec.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$KlineSpecCWProxy get copyWith => _$KlineSpecCWProxyImpl(this);
}
