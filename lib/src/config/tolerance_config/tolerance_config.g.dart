// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tolerance_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToleranceConfigCWProxy {
  ToleranceConfig maxDuration(int maxDuration);

  ToleranceConfig distanceFactor(double distanceFactor);

  ToleranceConfig curvestr(String curvestr);

  ToleranceConfig panSmoothFactor(double panSmoothFactor);

  ToleranceConfig convergenceRatio(double convergenceRatio);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToleranceConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToleranceConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  ToleranceConfig call({
    int maxDuration,
    double distanceFactor,
    String curvestr,
    double panSmoothFactor,
    double convergenceRatio,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfToleranceConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfToleranceConfig.copyWith.fieldName(...)`
class _$ToleranceConfigCWProxyImpl implements _$ToleranceConfigCWProxy {
  const _$ToleranceConfigCWProxyImpl(this._value);

  final ToleranceConfig _value;

  @override
  ToleranceConfig maxDuration(int maxDuration) =>
      this(maxDuration: maxDuration);

  @override
  ToleranceConfig distanceFactor(double distanceFactor) =>
      this(distanceFactor: distanceFactor);

  @override
  ToleranceConfig curvestr(String curvestr) => this(curvestr: curvestr);

  @override
  ToleranceConfig panSmoothFactor(double panSmoothFactor) =>
      this(panSmoothFactor: panSmoothFactor);

  @override
  ToleranceConfig convergenceRatio(double convergenceRatio) =>
      this(convergenceRatio: convergenceRatio);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToleranceConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToleranceConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  ToleranceConfig call({
    Object? maxDuration = const $CopyWithPlaceholder(),
    Object? distanceFactor = const $CopyWithPlaceholder(),
    Object? curvestr = const $CopyWithPlaceholder(),
    Object? panSmoothFactor = const $CopyWithPlaceholder(),
    Object? convergenceRatio = const $CopyWithPlaceholder(),
  }) {
    return ToleranceConfig(
      maxDuration: maxDuration == const $CopyWithPlaceholder()
          ? _value.maxDuration
          // ignore: cast_nullable_to_non_nullable
          : maxDuration as int,
      distanceFactor: distanceFactor == const $CopyWithPlaceholder()
          ? _value.distanceFactor
          // ignore: cast_nullable_to_non_nullable
          : distanceFactor as double,
      curvestr: curvestr == const $CopyWithPlaceholder()
          ? _value.curvestr
          // ignore: cast_nullable_to_non_nullable
          : curvestr as String,
      panSmoothFactor: panSmoothFactor == const $CopyWithPlaceholder()
          ? _value.panSmoothFactor
          // ignore: cast_nullable_to_non_nullable
          : panSmoothFactor as double,
      convergenceRatio: convergenceRatio == const $CopyWithPlaceholder()
          ? _value.convergenceRatio
          // ignore: cast_nullable_to_non_nullable
          : convergenceRatio as double,
    );
  }
}

extension $ToleranceConfigCopyWith on ToleranceConfig {
  /// Returns a callable class that can be used as follows: `instanceOfToleranceConfig.copyWith(...)` or like so:`instanceOfToleranceConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToleranceConfigCWProxy get copyWith => _$ToleranceConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToleranceConfig _$ToleranceConfigFromJson(Map<String, dynamic> json) =>
    ToleranceConfig(
      maxDuration: (json['maxDuration'] as num?)?.toInt() ?? 3000,
      distanceFactor: (json['distanceFactor'] as num?)?.toDouble() ?? 0.8,
      curvestr: json['curvestr'] as String? ?? 'easeOutCubic',
      panSmoothFactor: (json['panSmoothFactor'] as num?)?.toDouble() ?? 0.15,
      convergenceRatio: (json['convergenceRatio'] as num?)?.toDouble() ?? 0.85,
    );

Map<String, dynamic> _$ToleranceConfigToJson(ToleranceConfig instance) =>
    <String, dynamic>{
      'maxDuration': instance.maxDuration,
      'distanceFactor': instance.distanceFactor,
      'curvestr': instance.curvestr,
      'panSmoothFactor': instance.panSmoothFactor,
      'convergenceRatio': instance.convergenceRatio,
    };
