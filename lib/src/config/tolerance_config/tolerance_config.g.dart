// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tolerance_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToleranceConfigCWProxy {
  ToleranceConfig maxDuration(int maxDuration);

  ToleranceConfig distanceFactor(double distanceFactor);

  ToleranceConfig curvestr(String curvestr);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToleranceConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToleranceConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  ToleranceConfig call({
    int? maxDuration,
    double? distanceFactor,
    String? curvestr,
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
  }) {
    return ToleranceConfig(
      maxDuration:
          maxDuration == const $CopyWithPlaceholder() || maxDuration == null
              ? _value.maxDuration
              // ignore: cast_nullable_to_non_nullable
              : maxDuration as int,
      distanceFactor: distanceFactor == const $CopyWithPlaceholder() ||
              distanceFactor == null
          ? _value.distanceFactor
          // ignore: cast_nullable_to_non_nullable
          : distanceFactor as double,
      curvestr: curvestr == const $CopyWithPlaceholder() || curvestr == null
          ? _value.curvestr
          // ignore: cast_nullable_to_non_nullable
          : curvestr as String,
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
      maxDuration: (json['maxDuration'] as num?)?.toInt() ?? 1000,
      distanceFactor: (json['distanceFactor'] as num?)?.toDouble() ?? 0.3,
      curvestr: json['curvestr'] as String? ?? 'decelerate',
    );

Map<String, dynamic> _$ToleranceConfigToJson(ToleranceConfig instance) =>
    <String, dynamic>{
      'maxDuration': instance.maxDuration,
      'distanceFactor': instance.distanceFactor,
      'curvestr': instance.curvestr,
    };
