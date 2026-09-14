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

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ToleranceConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToleranceConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  ToleranceConfig call({
    int maxDuration,
    double distanceFactor,
    String curvestr,
    double panSmoothFactor,
    double convergenceRatio,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToleranceConfig.copyWith(...)` or call `instanceOfToleranceConfig.copyWith.fieldName(value)` for a single field.
class _$ToleranceConfigCWProxyImpl implements _$ToleranceConfigCWProxy {
  const _$ToleranceConfigCWProxyImpl(this._value);

  final ToleranceConfig _value;

  @override
  ToleranceConfig maxDuration(int maxDuration) =>
      call(maxDuration: maxDuration);

  @override
  ToleranceConfig distanceFactor(double distanceFactor) =>
      call(distanceFactor: distanceFactor);

  @override
  ToleranceConfig curvestr(String curvestr) => call(curvestr: curvestr);

  @override
  ToleranceConfig panSmoothFactor(double panSmoothFactor) =>
      call(panSmoothFactor: panSmoothFactor);

  @override
  ToleranceConfig convergenceRatio(double convergenceRatio) =>
      call(convergenceRatio: convergenceRatio);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ToleranceConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToleranceConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToleranceConfig call({
    Object? maxDuration = const $CopyWithPlaceholder(),
    Object? distanceFactor = const $CopyWithPlaceholder(),
    Object? curvestr = const $CopyWithPlaceholder(),
    Object? panSmoothFactor = const $CopyWithPlaceholder(),
    Object? convergenceRatio = const $CopyWithPlaceholder(),
  }) {
    return ToleranceConfig(
      maxDuration:
          maxDuration == const $CopyWithPlaceholder() || maxDuration == null
          ? _value.maxDuration
          // ignore: cast_nullable_to_non_nullable
          : maxDuration as int,
      distanceFactor:
          distanceFactor == const $CopyWithPlaceholder() ||
              distanceFactor == null
          ? _value.distanceFactor
          // ignore: cast_nullable_to_non_nullable
          : distanceFactor as double,
      curvestr: curvestr == const $CopyWithPlaceholder() || curvestr == null
          ? _value.curvestr
          // ignore: cast_nullable_to_non_nullable
          : curvestr as String,
      panSmoothFactor:
          panSmoothFactor == const $CopyWithPlaceholder() ||
              panSmoothFactor == null
          ? _value.panSmoothFactor
          // ignore: cast_nullable_to_non_nullable
          : panSmoothFactor as double,
      convergenceRatio:
          convergenceRatio == const $CopyWithPlaceholder() ||
              convergenceRatio == null
          ? _value.convergenceRatio
          // ignore: cast_nullable_to_non_nullable
          : convergenceRatio as double,
    );
  }
}

extension $ToleranceConfigCopyWith on ToleranceConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToleranceConfig.copyWith(...)` or `instanceOfToleranceConfig.copyWith.fieldName(...)`.
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
