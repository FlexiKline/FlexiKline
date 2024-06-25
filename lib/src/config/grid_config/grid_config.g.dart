// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GridConfigCWProxy {
  GridConfig show(bool show);

  GridConfig horizontal(GridAxis horizontal);

  GridConfig vertical(GridAxis vertical);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GridConfig call({
    bool? show,
    GridAxis? horizontal,
    GridAxis? vertical,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGridConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGridConfig.copyWith.fieldName(...)`
class _$GridConfigCWProxyImpl implements _$GridConfigCWProxy {
  const _$GridConfigCWProxyImpl(this._value);

  final GridConfig _value;

  @override
  GridConfig show(bool show) => this(show: show);

  @override
  GridConfig horizontal(GridAxis horizontal) => this(horizontal: horizontal);

  @override
  GridConfig vertical(GridAxis vertical) => this(vertical: vertical);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  GridConfig call({
    Object? show = const $CopyWithPlaceholder(),
    Object? horizontal = const $CopyWithPlaceholder(),
    Object? vertical = const $CopyWithPlaceholder(),
  }) {
    return GridConfig(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      horizontal:
          horizontal == const $CopyWithPlaceholder() || horizontal == null
              ? _value.horizontal
              // ignore: cast_nullable_to_non_nullable
              : horizontal as GridAxis,
      vertical: vertical == const $CopyWithPlaceholder() || vertical == null
          ? _value.vertical
          // ignore: cast_nullable_to_non_nullable
          : vertical as GridAxis,
    );
  }
}

extension $GridConfigCopyWith on GridConfig {
  /// Returns a callable class that can be used as follows: `instanceOfGridConfig.copyWith(...)` or like so:`instanceOfGridConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GridConfigCWProxy get copyWith => _$GridConfigCWProxyImpl(this);
}

abstract class _$GridAxisCWProxy {
  GridAxis show(bool show);

  GridAxis count(int count);

  GridAxis width(double width);

  GridAxis color(Color color);

  GridAxis type(LineType type);

  GridAxis dashes(List<double> dashes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridAxis(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridAxis(...).copyWith(id: 12, name: "My name")
  /// ````
  GridAxis call({
    bool? show,
    int? count,
    double? width,
    Color? color,
    LineType? type,
    List<double>? dashes,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGridAxis.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfGridAxis.copyWith.fieldName(...)`
class _$GridAxisCWProxyImpl implements _$GridAxisCWProxy {
  const _$GridAxisCWProxyImpl(this._value);

  final GridAxis _value;

  @override
  GridAxis show(bool show) => this(show: show);

  @override
  GridAxis count(int count) => this(count: count);

  @override
  GridAxis width(double width) => this(width: width);

  @override
  GridAxis color(Color color) => this(color: color);

  @override
  GridAxis type(LineType type) => this(type: type);

  @override
  GridAxis dashes(List<double> dashes) => this(dashes: dashes);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `GridAxis(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// GridAxis(...).copyWith(id: 12, name: "My name")
  /// ````
  GridAxis call({
    Object? show = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? dashes = const $CopyWithPlaceholder(),
  }) {
    return GridAxis(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      width: width == const $CopyWithPlaceholder() || width == null
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as double,
      color: color == const $CopyWithPlaceholder() || color == null
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as Color,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as LineType,
      dashes: dashes == const $CopyWithPlaceholder() || dashes == null
          ? _value.dashes
          // ignore: cast_nullable_to_non_nullable
          : dashes as List<double>,
    );
  }
}

extension $GridAxisCopyWith on GridAxis {
  /// Returns a callable class that can be used as follows: `instanceOfGridAxis.copyWith(...)` or like so:`instanceOfGridAxis.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GridAxisCWProxy get copyWith => _$GridAxisCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GridConfig _$GridConfigFromJson(Map<String, dynamic> json) => GridConfig(
      show: json['show'] as bool? ?? true,
      horizontal: json['horizontal'] == null
          ? const GridAxis()
          : GridAxis.fromJson(json['horizontal'] as Map<String, dynamic>),
      vertical: json['vertical'] == null
          ? const GridAxis()
          : GridAxis.fromJson(json['vertical'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GridConfigToJson(GridConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'horizontal': instance.horizontal.toJson(),
      'vertical': instance.vertical.toJson(),
    };

GridAxis _$GridAxisFromJson(Map<String, dynamic> json) => GridAxis(
      show: json['show'] as bool? ?? true,
      count: (json['count'] as num?)?.toInt() ?? 5,
      width: (json['width'] as num?)?.toDouble() ?? 0.5,
      color: json['color'] == null
          ? const Color(0xffE9EDF0)
          : const ColorConverter().fromJson(json['color'] as String),
      type: json['type'] == null
          ? LineType.solid
          : const LineTypeConverter().fromJson(json['type'] as String),
      dashes: (json['dashes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [2, 2],
    );

Map<String, dynamic> _$GridAxisToJson(GridAxis instance) => <String, dynamic>{
      'show': instance.show,
      'count': instance.count,
      'width': instance.width,
      'color': const ColorConverter().toJson(instance.color),
      'type': const LineTypeConverter().toJson(instance.type),
      'dashes': instance.dashes,
    };
