// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reveal_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RevealConfigCWProxy {
  RevealConfig enabled(bool enabled);

  RevealConfig trigger(RevealTrigger trigger);

  RevealConfig duration(int duration);

  RevealConfig curve(String curve);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `RevealConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevealConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  RevealConfig call({
    bool enabled,
    RevealTrigger trigger,
    int duration,
    String curve,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRevealConfig.copyWith(...)` or call `instanceOfRevealConfig.copyWith.fieldName(value)` for a single field.
class _$RevealConfigCWProxyImpl implements _$RevealConfigCWProxy {
  const _$RevealConfigCWProxyImpl(this._value);

  final RevealConfig _value;

  @override
  RevealConfig enabled(bool enabled) => call(enabled: enabled);

  @override
  RevealConfig trigger(RevealTrigger trigger) => call(trigger: trigger);

  @override
  RevealConfig duration(int duration) => call(duration: duration);

  @override
  RevealConfig curve(String curve) => call(curve: curve);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `RevealConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RevealConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RevealConfig call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? trigger = const $CopyWithPlaceholder(),
    Object? duration = const $CopyWithPlaceholder(),
    Object? curve = const $CopyWithPlaceholder(),
  }) {
    return RevealConfig(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      trigger: trigger == const $CopyWithPlaceholder() || trigger == null
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as RevealTrigger,
      duration: duration == const $CopyWithPlaceholder() || duration == null
          ? _value.duration
          // ignore: cast_nullable_to_non_nullable
          : duration as int,
      curve: curve == const $CopyWithPlaceholder() || curve == null
          ? _value.curve
          // ignore: cast_nullable_to_non_nullable
          : curve as String,
    );
  }
}

extension $RevealConfigCopyWith on RevealConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRevealConfig.copyWith(...)` or `instanceOfRevealConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RevealConfigCWProxy get copyWith => _$RevealConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevealConfig _$RevealConfigFromJson(Map<String, dynamic> json) => RevealConfig(
  enabled: json['enabled'] as bool? ?? false,
  trigger:
      $enumDecodeNullable(_$RevealTriggerEnumMap, json['trigger']) ??
      RevealTrigger.controllerFirst,
  duration: (json['duration'] as num?)?.toInt() ?? 600,
  curve: json['curve'] as String? ?? 'easeInOut',
);

Map<String, dynamic> _$RevealConfigToJson(RevealConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'trigger': _$RevealTriggerEnumMap[instance.trigger]!,
      'duration': instance.duration,
      'curve': instance.curve,
    };

const _$RevealTriggerEnumMap = {
  RevealTrigger.controllerFirst: 'controllerFirst',
  RevealTrigger.specFirstLoad: 'specFirstLoad',
};
