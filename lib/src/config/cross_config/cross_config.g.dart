// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CrossConfigCWProxy {
  CrossConfig enable(bool enable);

  CrossConfig crosshair(LineConfig crosshair);

  CrossConfig crosspoint(PointConfig crosspoint);

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
    PointConfig? crosspoint,
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
  CrossConfig crosspoint(PointConfig crosspoint) =>
      this(crosspoint: crosspoint);

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
    Object? crosspoint = const $CopyWithPlaceholder(),
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
      crosspoint:
          crosspoint == const $CopyWithPlaceholder() || crosspoint == null
              ? _value.crosspoint
              // ignore: cast_nullable_to_non_nullable
              : crosspoint as PointConfig,
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

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrossConfig _$CrossConfigFromJson(Map<String, dynamic> json) => CrossConfig(
      enable: json['enable'] as bool? ?? true,
      crosshair: LineConfig.fromJson(json['crosshair'] as Map<String, dynamic>),
      crosspoint:
          PointConfig.fromJson(json['crosspoint'] as Map<String, dynamic>),
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
      'crosspoint': instance.crosspoint.toJson(),
      'tickText': instance.tickText.toJson(),
      'spacing': instance.spacing,
      'showLatestTipsInBlank': instance.showLatestTipsInBlank,
      'moveByCandleInBlank': instance.moveByCandleInBlank,
    };
