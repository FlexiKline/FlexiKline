// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PointConfigCWProxy {
  PointConfig radius(double radius);

  PointConfig width(double width);

  PointConfig color(Color color);

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
      width: (json['width'] as num?)?.toDouble() ?? 6,
      color: json['color'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['color'] as String),
    );

Map<String, dynamic> _$PointConfigToJson(PointConfig instance) =>
    <String, dynamic>{
      'radius': instance.radius,
      'width': instance.width,
      'color': const ColorConverter().toJson(instance.color),
    };
