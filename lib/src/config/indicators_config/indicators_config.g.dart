// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicators_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IndicatorsConfigCWProxy {
  IndicatorsConfig candle(CandleIndicator candle);

  IndicatorsConfig volume(VolumeIndicator volume);

  IndicatorsConfig ma(MAIndicator ma);

  IndicatorsConfig time(TimeIndicator time);

  IndicatorsConfig mavol(MAVolumeIndicator mavol);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IndicatorsConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IndicatorsConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  IndicatorsConfig call({
    CandleIndicator? candle,
    VolumeIndicator? volume,
    MAIndicator? ma,
    TimeIndicator? time,
    MAVolumeIndicator? mavol,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIndicatorsConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIndicatorsConfig.copyWith.fieldName(...)`
class _$IndicatorsConfigCWProxyImpl implements _$IndicatorsConfigCWProxy {
  const _$IndicatorsConfigCWProxyImpl(this._value);

  final IndicatorsConfig _value;

  @override
  IndicatorsConfig candle(CandleIndicator candle) => this(candle: candle);

  @override
  IndicatorsConfig volume(VolumeIndicator volume) => this(volume: volume);

  @override
  IndicatorsConfig ma(MAIndicator ma) => this(ma: ma);

  @override
  IndicatorsConfig time(TimeIndicator time) => this(time: time);

  @override
  IndicatorsConfig mavol(MAVolumeIndicator mavol) => this(mavol: mavol);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IndicatorsConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IndicatorsConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  IndicatorsConfig call({
    Object? candle = const $CopyWithPlaceholder(),
    Object? volume = const $CopyWithPlaceholder(),
    Object? ma = const $CopyWithPlaceholder(),
    Object? time = const $CopyWithPlaceholder(),
    Object? mavol = const $CopyWithPlaceholder(),
  }) {
    return IndicatorsConfig(
      candle: candle == const $CopyWithPlaceholder() || candle == null
          ? _value.candle
          // ignore: cast_nullable_to_non_nullable
          : candle as CandleIndicator,
      volume: volume == const $CopyWithPlaceholder() || volume == null
          ? _value.volume
          // ignore: cast_nullable_to_non_nullable
          : volume as VolumeIndicator,
      ma: ma == const $CopyWithPlaceholder() || ma == null
          ? _value.ma
          // ignore: cast_nullable_to_non_nullable
          : ma as MAIndicator,
      time: time == const $CopyWithPlaceholder() || time == null
          ? _value.time
          // ignore: cast_nullable_to_non_nullable
          : time as TimeIndicator,
      mavol: mavol == const $CopyWithPlaceholder() || mavol == null
          ? _value.mavol
          // ignore: cast_nullable_to_non_nullable
          : mavol as MAVolumeIndicator,
    );
  }
}

extension $IndicatorsConfigCopyWith on IndicatorsConfig {
  /// Returns a callable class that can be used as follows: `instanceOfIndicatorsConfig.copyWith(...)` or like so:`instanceOfIndicatorsConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IndicatorsConfigCWProxy get copyWith => _$IndicatorsConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndicatorsConfig _$IndicatorsConfigFromJson(Map<String, dynamic> json) =>
    IndicatorsConfig(
      candle: CandleIndicator.fromJson(json['candle'] as Map<String, dynamic>),
      volume: VolumeIndicator.fromJson(json['volume'] as Map<String, dynamic>),
      ma: MAIndicator.fromJson(json['ma'] as Map<String, dynamic>),
      time: TimeIndicator.fromJson(json['time'] as Map<String, dynamic>),
      mavol: MAVolumeIndicator.fromJson(json['mavol'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$IndicatorsConfigToJson(IndicatorsConfig instance) =>
    <String, dynamic>{
      'candle': instance.candle.toJson(),
      'volume': instance.volume.toJson(),
      'ma': instance.ma.toJson(),
      'time': instance.time.toJson(),
      'mavol': instance.mavol.toJson(),
    };
