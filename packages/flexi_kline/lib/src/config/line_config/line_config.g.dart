// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LineConfigCWProxy {
  LineConfig type(LineType type);

  LineConfig length(double? length);

  LineConfig dashes(List<double> dashes);

  LineConfig paint(PaintConfig paint);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `LineConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LineConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  LineConfig call({
    LineType type,
    double? length,
    List<double> dashes,
    PaintConfig paint,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLineConfig.copyWith(...)` or call `instanceOfLineConfig.copyWith.fieldName(value)` for a single field.
class _$LineConfigCWProxyImpl implements _$LineConfigCWProxy {
  const _$LineConfigCWProxyImpl(this._value);

  final LineConfig _value;

  @override
  LineConfig type(LineType type) => call(type: type);

  @override
  LineConfig length(double? length) => call(length: length);

  @override
  LineConfig dashes(List<double> dashes) => call(dashes: dashes);

  @override
  LineConfig paint(PaintConfig paint) => call(paint: paint);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `LineConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LineConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LineConfig call({
    Object? type = const $CopyWithPlaceholder(),
    Object? length = const $CopyWithPlaceholder(),
    Object? dashes = const $CopyWithPlaceholder(),
    Object? paint = const $CopyWithPlaceholder(),
  }) {
    return LineConfig(
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as LineType,
      length: length == const $CopyWithPlaceholder()
          ? _value.length
          // ignore: cast_nullable_to_non_nullable
          : length as double?,
      dashes: dashes == const $CopyWithPlaceholder() || dashes == null
          ? _value.dashes
          // ignore: cast_nullable_to_non_nullable
          : dashes as List<double>,
      paint: paint == const $CopyWithPlaceholder() || paint == null
          ? _value.paint
          // ignore: cast_nullable_to_non_nullable
          : paint as PaintConfig,
    );
  }
}

extension $LineConfigCopyWith on LineConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLineConfig.copyWith(...)` or `instanceOfLineConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LineConfigCWProxy get copyWith => _$LineConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineConfig _$LineConfigFromJson(Map<String, dynamic> json) => LineConfig(
  type: json['type'] == null
      ? LineType.solid
      : const LineTypeConverter().fromJson(json['type'] as String),
  length: (json['length'] as num?)?.toDouble(),
  dashes:
      (json['dashes'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [3, 3],
  paint: json['paint'] == null
      ? const PaintConfig(strokeWidth: defaultAuxiliaryLineWidth)
      : PaintConfig.fromJson(json['paint'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LineConfigToJson(LineConfig instance) =>
    <String, dynamic>{
      'type': const LineTypeConverter().toJson(instance.type),
      'length': ?instance.length,
      'dashes': instance.dashes,
      'paint': instance.paint.toJson(),
    };
