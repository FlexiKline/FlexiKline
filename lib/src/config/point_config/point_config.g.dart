// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PointConfigCWProxy {
  PointConfig radius(double radius);

  PointConfig width(double width);

  PointConfig color(Color color);

  PointConfig borderWidth(double? borderWidth);

  PointConfig borderColor(Color? borderColor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PointConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PointConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PointConfig call({
    double? radius,
    double? width,
    Color? color,
    double? borderWidth,
    Color? borderColor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPointConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPointConfig.copyWith.fieldName(...)`
class _$PointConfigCWProxyImpl implements _$PointConfigCWProxy {
  const _$PointConfigCWProxyImpl(this._value);

  final PointConfig _value;

  @override
  PointConfig radius(double radius) => this(radius: radius);

  @override
  PointConfig width(double width) => this(width: width);

  @override
  PointConfig color(Color color) => this(color: color);

  @override
  PointConfig borderWidth(double? borderWidth) =>
      this(borderWidth: borderWidth);

  @override
  PointConfig borderColor(Color? borderColor) => this(borderColor: borderColor);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PointConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PointConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PointConfig call({
    Object? radius = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? borderWidth = const $CopyWithPlaceholder(),
    Object? borderColor = const $CopyWithPlaceholder(),
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
      color: color == const $CopyWithPlaceholder() || color == null
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as Color,
      borderWidth: borderWidth == const $CopyWithPlaceholder()
          ? _value.borderWidth
          // ignore: cast_nullable_to_non_nullable
          : borderWidth as double?,
      borderColor: borderColor == const $CopyWithPlaceholder()
          ? _value.borderColor
          // ignore: cast_nullable_to_non_nullable
          : borderColor as Color?,
    );
  }
}

extension $PointConfigCopyWith on PointConfig {
  /// Returns a callable class that can be used as follows: `instanceOfPointConfig.copyWith(...)` or like so:`instanceOfPointConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PointConfigCWProxy get copyWith => _$PointConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointConfig _$PointConfigFromJson(Map<String, dynamic> json) => PointConfig(
      radius: (json['radius'] as num?)?.toDouble() ?? 2,
      width: (json['width'] as num?)?.toDouble() ?? 2,
      color: json['color'] == null
          ? const Color(0xFF000000)
          : const ColorConverter().fromJson(json['color'] as String),
      borderWidth: (json['borderWidth'] as num?)?.toDouble(),
      borderColor: _$JsonConverterFromJson<String, Color>(
          json['borderColor'], const ColorConverter().fromJson),
    );

Map<String, dynamic> _$PointConfigToJson(PointConfig instance) {
  final val = <String, dynamic>{
    'radius': instance.radius,
    'width': instance.width,
    'color': const ColorConverter().toJson(instance.color),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('borderWidth', instance.borderWidth);
  writeNotNull(
      'borderColor',
      _$JsonConverterToJson<String, Color>(
          instance.borderColor, const ColorConverter().toJson));
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
