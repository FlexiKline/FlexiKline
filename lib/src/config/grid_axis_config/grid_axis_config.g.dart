// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_axis_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GridAxisConfigCWProxy {
  GridAxisConfig mode(GridTickMode mode);

  GridAxisConfig line(LineConfig? line);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridAxisConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridAxisConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GridAxisConfig call({
    GridTickMode mode,
    LineConfig? line,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGridAxisConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGridAxisConfig.copyWith.fieldName(...)`
class _$GridAxisConfigCWProxyImpl implements _$GridAxisConfigCWProxy {
  const _$GridAxisConfigCWProxyImpl(this._value);

  final GridAxisConfig _value;

  @override
  GridAxisConfig mode(GridTickMode mode) => this(mode: mode);

  @override
  GridAxisConfig line(LineConfig? line) => this(line: line);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridAxisConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridAxisConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GridAxisConfig call({
    Object? mode = const $CopyWithPlaceholder(),
    Object? line = const $CopyWithPlaceholder(),
  }) {
    return GridAxisConfig(
      mode: mode == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfGridAxisConfig.copyWith(...)` or like so:`instanceOfGridAxisConfig.copyWith.fieldName(...)`.
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
          : const GridTickModeConverter()
              .fromJson(json['mode'] as Map<String, dynamic>),
      line: json['line'] == null
          ? null
          : LineConfig.fromJson(json['line'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GridAxisConfigToJson(GridAxisConfig instance) =>
    <String, dynamic>{
      'mode': const GridTickModeConverter().toJson(instance.mode),
      if (instance.line?.toJson() case final value?) 'line': value,
    };
