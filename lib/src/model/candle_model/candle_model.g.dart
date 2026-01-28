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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CandleModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CandleModel(...).copyWith(id: 12, name: "My name")
  /// ````
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCandleModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCandleModel.copyWith.fieldName(...)`
class _$CandleModelCWProxyImpl implements _$CandleModelCWProxy {
  const _$CandleModelCWProxyImpl(this._value);

  final CandleModel _value;

  @override
  CandleModel timestamp(int timestamp) => this(timestamp: timestamp);

  @override
  CandleModel open(Object open) => this(open: open);

  @override
  CandleModel high(Object high) => this(high: high);

  @override
  CandleModel low(Object low) => this(low: low);

  @override
  CandleModel close(Object close) => this(close: close);

  @override
  CandleModel volume(Object volume) => this(volume: volume);

  @override
  CandleModel turnover(Object? turnover) => this(turnover: turnover);

  @override
  CandleModel tradeCount(int? tradeCount) => this(tradeCount: tradeCount);

  @override
  CandleModel confirmed(bool confirmed) => this(confirmed: confirmed);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CandleModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CandleModel(...).copyWith(id: 12, name: "My name")
  /// ````
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
      timestamp: timestamp == const $CopyWithPlaceholder()
          ? _value.timestamp
          // ignore: cast_nullable_to_non_nullable
          : timestamp as int,
      open: open == const $CopyWithPlaceholder()
          ? _value.open
          // ignore: cast_nullable_to_non_nullable
          : open as Object,
      high: high == const $CopyWithPlaceholder()
          ? _value.high
          // ignore: cast_nullable_to_non_nullable
          : high as Object,
      low: low == const $CopyWithPlaceholder()
          ? _value.low
          // ignore: cast_nullable_to_non_nullable
          : low as Object,
      close: close == const $CopyWithPlaceholder()
          ? _value.close
          // ignore: cast_nullable_to_non_nullable
          : close as Object,
      volume: volume == const $CopyWithPlaceholder()
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
      confirmed: confirmed == const $CopyWithPlaceholder()
          ? _value.confirmed
          // ignore: cast_nullable_to_non_nullable
          : confirmed as bool,
    );
  }
}

extension $CandleModelCopyWith on CandleModel {
  /// Returns a callable class that can be used as follows: `instanceOfCandleModel.copyWith(...)` or like so:`instanceOfCandleModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CandleModelCWProxy get copyWith => _$CandleModelCWProxyImpl(this);
}
