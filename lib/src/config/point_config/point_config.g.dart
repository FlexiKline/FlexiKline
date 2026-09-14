// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PointConfigCWProxy {
  PointConfig radius(double radius);

  PointConfig width(double width);

  PointConfig color(Color? color);

  PointConfig useThemeColor(bool useThemeColor);

  PointConfig borderWidth(double? borderWidth);

  PointConfig borderColor(Color? borderColor);

  PointConfig borderOpacity(double borderOpacity);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PointConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PointConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  PointConfig call({
    double radius,
    double width,
    Color? color,
    bool useThemeColor,
    double? borderWidth,
    Color? borderColor,
    double borderOpacity,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPointConfig.copyWith(...)` or call `instanceOfPointConfig.copyWith.fieldName(value)` for a single field.
class _$PointConfigCWProxyImpl implements _$PointConfigCWProxy {
  const _$PointConfigCWProxyImpl(this._value);

  final PointConfig _value;

  @override
  PointConfig radius(double radius) => call(radius: radius);

  @override
  PointConfig width(double width) => call(width: width);

  @override
  PointConfig color(Color? color) => call(color: color);

  @override
  PointConfig useThemeColor(bool useThemeColor) =>
      call(useThemeColor: useThemeColor);

  @override
  PointConfig borderWidth(double? borderWidth) =>
      call(borderWidth: borderWidth);

  @override
  PointConfig borderColor(Color? borderColor) => call(borderColor: borderColor);

  @override
  PointConfig borderOpacity(double borderOpacity) =>
      call(borderOpacity: borderOpacity);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `PointConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PointConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PointConfig call({
    Object? radius = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? useThemeColor = const $CopyWithPlaceholder(),
    Object? borderWidth = const $CopyWithPlaceholder(),
    Object? borderColor = const $CopyWithPlaceholder(),
    Object? borderOpacity = const $CopyWithPlaceholder(),
  }) {
    return PointConfig(
      radius: radius == const $CopyWithPlaceholder() || radius == null
          ? _value.radius
          // ignore: cast_nullable_to_non_nullable
          : radius as double,
      width: width == const $CopyWithPlaceholder() || width == null
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as double,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as Color?,
      useThemeColor:
          useThemeColor == const $CopyWithPlaceholder() || useThemeColor == null
          ? _value.useThemeColor
          // ignore: cast_nullable_to_non_nullable
          : useThemeColor as bool,
      borderWidth: borderWidth == const $CopyWithPlaceholder()
          ? _value.borderWidth
          // ignore: cast_nullable_to_non_nullable
          : borderWidth as double?,
      borderColor: borderColor == const $CopyWithPlaceholder()
          ? _value.borderColor
          // ignore: cast_nullable_to_non_nullable
          : borderColor as Color?,
      borderOpacity:
          borderOpacity == const $CopyWithPlaceholder() || borderOpacity == null
          ? _value.borderOpacity
          // ignore: cast_nullable_to_non_nullable
          : borderOpacity as double,
    );
  }
}

extension $PointConfigCopyWith on PointConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPointConfig.copyWith(...)` or `instanceOfPointConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PointConfigCWProxy get copyWith => _$PointConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointConfig _$PointConfigFromJson(Map<String, dynamic> json) => PointConfig(
  radius: (json['radius'] as num?)?.toDouble() ?? 2,
  width: (json['width'] as num?)?.toDouble() ?? 2,
  color: _$JsonConverterFromJson<String, Color>(
    json['color'],
    const ColorConverter().fromJson,
  ),
  useThemeColor: json['useThemeColor'] as bool? ?? true,
  borderWidth: (json['borderWidth'] as num?)?.toDouble(),
  borderColor: _$JsonConverterFromJson<String, Color>(
    json['borderColor'],
    const ColorConverter().fromJson,
  ),
  borderOpacity: (json['borderOpacity'] as num?)?.toDouble() ?? 1,
);

Map<String, dynamic> _$PointConfigToJson(PointConfig instance) =>
    <String, dynamic>{
      'radius': instance.radius,
      'width': instance.width,
      'color': ?_$JsonConverterToJson<String, Color>(
        instance.color,
        const ColorConverter().toJson,
      ),
      'useThemeColor': instance.useThemeColor,
      'borderWidth': ?instance.borderWidth,
      'borderColor': ?_$JsonConverterToJson<String, Color>(
        instance.borderColor,
        const ColorConverter().toJson,
      ),
      'borderOpacity': instance.borderOpacity,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
