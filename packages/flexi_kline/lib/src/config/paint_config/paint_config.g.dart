// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paint_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaintConfigCWProxy {
  PaintConfig color(Color? color);

  PaintConfig strokeWidth(double strokeWidth);

  PaintConfig style(PaintingStyle style);

  PaintConfig blendMode(BlendMode blendMode);

  PaintConfig isAntiAlias(bool isAntiAlias);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PaintConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaintConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  PaintConfig call({
    Color? color,
    double strokeWidth,
    PaintingStyle style,
    BlendMode blendMode,
    bool isAntiAlias,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaintConfig.copyWith(...)` or call `instanceOfPaintConfig.copyWith.fieldName(value)` for a single field.
class _$PaintConfigCWProxyImpl implements _$PaintConfigCWProxy {
  const _$PaintConfigCWProxyImpl(this._value);

  final PaintConfig _value;

  @override
  PaintConfig color(Color? color) => call(color: color);

  @override
  PaintConfig strokeWidth(double strokeWidth) => call(strokeWidth: strokeWidth);

  @override
  PaintConfig style(PaintingStyle style) => call(style: style);

  @override
  PaintConfig blendMode(BlendMode blendMode) => call(blendMode: blendMode);

  @override
  PaintConfig isAntiAlias(bool isAntiAlias) => call(isAntiAlias: isAntiAlias);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PaintConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaintConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaintConfig call({
    Object? color = const $CopyWithPlaceholder(),
    Object? strokeWidth = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
    Object? blendMode = const $CopyWithPlaceholder(),
    Object? isAntiAlias = const $CopyWithPlaceholder(),
  }) {
    return PaintConfig(
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as Color?,
      strokeWidth:
          strokeWidth == const $CopyWithPlaceholder() || strokeWidth == null
          ? _value.strokeWidth
          // ignore: cast_nullable_to_non_nullable
          : strokeWidth as double,
      style: style == const $CopyWithPlaceholder() || style == null
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as PaintingStyle,
      blendMode: blendMode == const $CopyWithPlaceholder() || blendMode == null
          ? _value.blendMode
          // ignore: cast_nullable_to_non_nullable
          : blendMode as BlendMode,
      isAntiAlias:
          isAntiAlias == const $CopyWithPlaceholder() || isAntiAlias == null
          ? _value.isAntiAlias
          // ignore: cast_nullable_to_non_nullable
          : isAntiAlias as bool,
    );
  }
}

extension $PaintConfigCopyWith on PaintConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaintConfig.copyWith(...)` or `instanceOfPaintConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaintConfigCWProxy get copyWith => _$PaintConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaintConfig _$PaintConfigFromJson(Map<String, dynamic> json) => PaintConfig(
  color: _$JsonConverterFromJson<String, Color>(
    json['color'],
    const ColorConverter().fromJson,
  ),
  strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0,
  style: json['style'] == null
      ? PaintingStyle.stroke
      : const PaintingStyleConverter().fromJson(json['style'] as String),
  blendMode: json['blendMode'] == null
      ? BlendMode.srcOver
      : const BlendModeConverter().fromJson(json['blendMode'] as String),
  isAntiAlias: json['isAntiAlias'] as bool? ?? true,
);

Map<String, dynamic> _$PaintConfigToJson(PaintConfig instance) =>
    <String, dynamic>{
      'color': ?_$JsonConverterToJson<String, Color>(
        instance.color,
        const ColorConverter().toJson,
      ),
      'strokeWidth': instance.strokeWidth,
      'style': const PaintingStyleConverter().toJson(instance.style),
      'blendMode': const BlendModeConverter().toJson(instance.blendMode),
      'isAntiAlias': instance.isAntiAlias,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
