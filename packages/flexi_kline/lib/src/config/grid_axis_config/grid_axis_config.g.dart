// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_axis_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GridAxisConfigCWProxy {
  GridAxisConfig mode(GridTickMode mode);

  GridAxisConfig line(LineConfig? line);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GridAxisConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GridAxisConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  GridAxisConfig call({GridTickMode mode, LineConfig? line});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGridAxisConfig.copyWith(...)` or call `instanceOfGridAxisConfig.copyWith.fieldName(value)` for a single field.
class _$GridAxisConfigCWProxyImpl implements _$GridAxisConfigCWProxy {
  const _$GridAxisConfigCWProxyImpl(this._value);

  final GridAxisConfig _value;

  @override
  GridAxisConfig mode(GridTickMode mode) => call(mode: mode);

  @override
  GridAxisConfig line(LineConfig? line) => call(line: line);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GridAxisConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GridAxisConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GridAxisConfig call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? line = const $CopyWithPlaceholder(),
  }) {
    return GridAxisConfig(
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as GridTickMode,
      line: line == const $CopyWithPlaceholder()
          ? _value.line
          // ignore: cast_nullable_to_non_nullable
          : line as LineConfig?,
    );
  }
}

extension $GridAxisConfigCopyWith on GridAxisConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGridAxisConfig.copyWith(...)` or `instanceOfGridAxisConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GridAxisConfigCWProxy get copyWith => _$GridAxisConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GridAxisConfig _$GridAxisConfigFromJson(Map<String, dynamic> json) =>
    GridAxisConfig(
      mode: json['mode'] == null
          ? GridTickMode.fallback
          : const GridTickModeConverter().fromJson(
              json['mode'] as Map<String, dynamic>,
            ),
      line: json['line'] == null
          ? null
          : LineConfig.fromJson(json['line'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GridAxisConfigToJson(GridAxisConfig instance) =>
    <String, dynamic>{
      'mode': const GridTickModeConverter().toJson(instance.mode),
      'line': ?instance.line?.toJson(),
    };
