// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CandleModelCWProxy {
  CandleModel timestamp(int timestamp);

  CandleModel open(Object open);

  CandleModel high(Object high);

  CandleModel low(Object low);

  CandleModel close(Object close);

  CandleModel volume(Object volume);

  CandleModel turnover(Object? turnover);

  CandleModel tradeCount(int? tradeCount);

  CandleModel confirmed(bool confirmed);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CandleModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CandleModel(...).copyWith(id: 12, name: "My name")
  /// ```
  CandleModel call({
    int timestamp,
    Object open,
    Object high,
    Object low,
    Object close,
    Object volume,
    Object? turnover,
    int? tradeCount,
    bool confirmed,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCandleModel.copyWith(...)` or call `instanceOfCandleModel.copyWith.fieldName(value)` for a single field.
class _$CandleModelCWProxyImpl implements _$CandleModelCWProxy {
  const _$CandleModelCWProxyImpl(this._value);

  final CandleModel _value;

  @override
  CandleModel timestamp(int timestamp) => call(timestamp: timestamp);

  @override
  CandleModel open(Object open) => call(open: open);

  @override
  CandleModel high(Object high) => call(high: high);

  @override
  CandleModel low(Object low) => call(low: low);

  @override
  CandleModel close(Object close) => call(close: close);

  @override
  CandleModel volume(Object volume) => call(volume: volume);

  @override
  CandleModel turnover(Object? turnover) => call(turnover: turnover);

  @override
  CandleModel tradeCount(int? tradeCount) => call(tradeCount: tradeCount);

  @override
  CandleModel confirmed(bool confirmed) => call(confirmed: confirmed);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CandleModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CandleModel(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CandleModel call({
    Object? timestamp = const $CopyWithPlaceholder(),
    Object? open = const $CopyWithPlaceholder(),
    Object? high = const $CopyWithPlaceholder(),
    Object? low = const $CopyWithPlaceholder(),
    Object? close = const $CopyWithPlaceholder(),
    Object? volume = const $CopyWithPlaceholder(),
    Object? turnover = const $CopyWithPlaceholder(),
    Object? tradeCount = const $CopyWithPlaceholder(),
    Object? confirmed = const $CopyWithPlaceholder(),
  }) {
    return CandleModel(
      timestamp: timestamp == const $CopyWithPlaceholder() || timestamp == null
          ? _value.timestamp
          // ignore: cast_nullable_to_non_nullable
          : timestamp as int,
      open: open == const $CopyWithPlaceholder() || open == null
          ? _value.open
          // ignore: cast_nullable_to_non_nullable
          : open as Object,
      high: high == const $CopyWithPlaceholder() || high == null
          ? _value.high
          // ignore: cast_nullable_to_non_nullable
          : high as Object,
      low: low == const $CopyWithPlaceholder() || low == null
          ? _value.low
          // ignore: cast_nullable_to_non_nullable
          : low as Object,
      close: close == const $CopyWithPlaceholder() || close == null
          ? _value.close
          // ignore: cast_nullable_to_non_nullable
          : close as Object,
      volume: volume == const $CopyWithPlaceholder() || volume == null
          ? _value.volume
          // ignore: cast_nullable_to_non_nullable
          : volume as Object,
      turnover: turnover == const $CopyWithPlaceholder()
          ? _value.turnover
          // ignore: cast_nullable_to_non_nullable
          : turnover as Object?,
      tradeCount: tradeCount == const $CopyWithPlaceholder()
          ? _value.tradeCount
          // ignore: cast_nullable_to_non_nullable
          : tradeCount as int?,
      confirmed: confirmed == const $CopyWithPlaceholder() || confirmed == null
          ? _value.confirmed
          // ignore: cast_nullable_to_non_nullable
          : confirmed as bool,
    );
  }
}

extension $CandleModelCopyWith on CandleModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCandleModel.copyWith(...)` or `instanceOfCandleModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CandleModelCWProxy get copyWith => _$CandleModelCWProxyImpl(this);
}
