// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CrossConfigCWProxy {
  CrossConfig enable(bool enable);

  CrossConfig crosshair(LineConfig crosshair);

  CrossConfig point(CrossPointConfig point);

  CrossConfig tickText(TextAreaConfig tickText);

  CrossConfig spacing(double spacing);

  CrossConfig showLatestTipsInBlank(bool showLatestTipsInBlank);

  CrossConfig moveByCandleInBlank(bool moveByCandleInBlank);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CrossConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CrossConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  CrossConfig call({
    bool? enable,
    LineConfig? crosshair,
    CrossPointConfig? point,
    TextAreaConfig? tickText,
    double? spacing,
    bool? showLatestTipsInBlank,
    bool? moveByCandleInBlank,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCrossConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCrossConfig.copyWith.fieldName(...)`
class _$CrossConfigCWProxyImpl implements _$CrossConfigCWProxy {
  const _$CrossConfigCWProxyImpl(this._value);

  final CrossConfig _value;

  @override
  CrossConfig enable(bool enable) => this(enable: enable);

  @override
  CrossConfig crosshair(LineConfig crosshair) => this(crosshair: crosshair);

  @override
  CrossConfig point(CrossPointConfig point) => this(point: point);

  @override
  CrossConfig tickText(TextAreaConfig tickText) => this(tickText: tickText);

  @override
  CrossConfig spacing(double spacing) => this(spacing: spacing);

  @override
  CrossConfig showLatestTipsInBlank(bool showLatestTipsInBlank) =>
      this(showLatestTipsInBlank: showLatestTipsInBlank);

  @override
  CrossConfig moveByCandleInBlank(bool moveByCandleInBlank) =>
      this(moveByCandleInBlank: moveByCandleInBlank);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CrossConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CrossConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  CrossConfig call({
    Object? enable = const $CopyWithPlaceholder(),
    Object? crosshair = const $CopyWithPlaceholder(),
    Object? point = const $CopyWithPlaceholder(),
    Object? tickText = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? showLatestTipsInBlank = const $CopyWithPlaceholder(),
    Object? moveByCandleInBlank = const $CopyWithPlaceholder(),
  }) {
    return CrossConfig(
      enable: enable == const $CopyWithPlaceholder() || enable == null
          ? _value.enable
          // ignore: cast_nullable_to_non_nullable
          : enable as bool,
      crosshair: crosshair == const $CopyWithPlaceholder() || crosshair == null
          ? _value.crosshair
          // ignore: cast_nullable_to_non_nullable
          : crosshair as LineConfig,
      point: point == const $CopyWithPlaceholder() || point == null
          ? _value.point
          // ignore: cast_nullable_to_non_nullable
          : point as CrossPointConfig,
      tickText: tickText == const $CopyWithPlaceholder() || tickText == null
          ? _value.tickText
          // ignore: cast_nullable_to_non_nullable
          : tickText as TextAreaConfig,
      spacing: spacing == const $CopyWithPlaceholder() || spacing == null
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      showLatestTipsInBlank:
          showLatestTipsInBlank == const $CopyWithPlaceholder() ||
                  showLatestTipsInBlank == null
              ? _value.showLatestTipsInBlank
              // ignore: cast_nullable_to_non_nullable
              : showLatestTipsInBlank as bool,
      moveByCandleInBlank:
          moveByCandleInBlank == const $CopyWithPlaceholder() ||
                  moveByCandleInBlank == null
              ? _value.moveByCandleInBlank
              // ignore: cast_nullable_to_non_nullable
              : moveByCandleInBlank as bool,
    );
  }
}

extension $CrossConfigCopyWith on CrossConfig {
  /// Returns a callable class that can be used as follows: `instanceOfCrossConfig.copyWith(...)` or like so:`instanceOfCrossConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CrossConfigCWProxy get copyWith => _$CrossConfigCWProxyImpl(this);
}

abstract class _$CrossPointConfigCWProxy {
  CrossPointConfig radius(double radius);

  CrossPointConfig width(double width);

  CrossPointConfig color(Color color);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CrossPointConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CrossPointConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  CrossPointConfig call({
    double? radius,
    double? width,
    Color? color,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCrossPointConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCrossPointConfig.copyWith.fieldName(...)`
class _$CrossPointConfigCWProxyImpl implements _$CrossPointConfigCWProxy {
  const _$CrossPointConfigCWProxyImpl(this._value);

  final CrossPointConfig _value;

  @override
  CrossPointConfig radius(double radius) => this(radius: radius);

  @override
  CrossPointConfig width(double width) => this(width: width);

  @override
  CrossPointConfig color(Color color) => this(color: color);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CrossPointConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CrossPointConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  CrossPointConfig call({
    Object? radius = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
  }) {
    return CrossPointConfig(
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

extension $CrossPointConfigCopyWith on CrossPointConfig {
  /// Returns a callable class that can be used as follows: `instanceOfCrossPointConfig.copyWith(...)` or like so:`instanceOfCrossPointConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CrossPointConfigCWProxy get copyWith => _$CrossPointConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrossConfig _$CrossConfigFromJson(Map<String, dynamic> json) => CrossConfig(
      enable: json['enable'] as bool? ?? true,
      crosshair: LineConfig.fromJson(json['crosshair'] as Map<String, dynamic>),
      point: CrossPointConfig.fromJson(json['point'] as Map<String, dynamic>),
      tickText:
          TextAreaConfig.fromJson(json['tickText'] as Map<String, dynamic>),
      spacing: (json['spacing'] as num).toDouble(),
      showLatestTipsInBlank: json['showLatestTipsInBlank'] as bool? ?? true,
      moveByCandleInBlank: json['moveByCandleInBlank'] as bool? ?? false,
    );

Map<String, dynamic> _$CrossConfigToJson(CrossConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'crosshair': instance.crosshair.toJson(),
      'point': instance.point.toJson(),
      'tickText': instance.tickText.toJson(),
      'spacing': instance.spacing,
      'showLatestTipsInBlank': instance.showLatestTipsInBlank,
      'moveByCandleInBlank': instance.moveByCandleInBlank,
    };

CrossPointConfig _$CrossPointConfigFromJson(Map<String, dynamic> json) =>
    CrossPointConfig(
      radius: (json['radius'] as num?)?.toDouble() ?? 2,
      width: (json['width'] as num?)?.toDouble() ?? 6,
      color: json['color'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['color'] as String),
    );

Map<String, dynamic> _$CrossPointConfigToJson(CrossPointConfig instance) =>
    <String, dynamic>{
      'radius': instance.radius,
      'width': instance.width,
      'color': const ColorConverter().toJson(instance.color),
    };
