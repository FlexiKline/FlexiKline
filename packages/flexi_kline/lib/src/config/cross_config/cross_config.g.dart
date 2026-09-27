// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CrossConfigCWProxy {
  CrossConfig enable(bool enable);

  CrossConfig crosshair(LineConfig crosshair);

  CrossConfig crosspoint(PointConfig crosspoint);

  CrossConfig ticksText(TextAreaConfig ticksText);

  CrossConfig spacing(double spacing);

  CrossConfig showLatestTipsInBlank(bool showLatestTipsInBlank);

  CrossConfig moveByCandleInBlank(bool moveByCandleInBlank);

  CrossConfig tooltipConfig(TooltipConfig tooltipConfig);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CrossConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CrossConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  CrossConfig call({
    bool enable,
    LineConfig crosshair,
    PointConfig crosspoint,
    TextAreaConfig ticksText,
    double spacing,
    bool showLatestTipsInBlank,
    bool moveByCandleInBlank,
    TooltipConfig tooltipConfig,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCrossConfig.copyWith(...)` or call `instanceOfCrossConfig.copyWith.fieldName(value)` for a single field.
class _$CrossConfigCWProxyImpl implements _$CrossConfigCWProxy {
  const _$CrossConfigCWProxyImpl(this._value);

  final CrossConfig _value;

  @override
  CrossConfig enable(bool enable) => call(enable: enable);

  @override
  CrossConfig crosshair(LineConfig crosshair) => call(crosshair: crosshair);

  @override
  CrossConfig crosspoint(PointConfig crosspoint) =>
      call(crosspoint: crosspoint);

  @override
  CrossConfig ticksText(TextAreaConfig ticksText) => call(ticksText: ticksText);

  @override
  CrossConfig spacing(double spacing) => call(spacing: spacing);

  @override
  CrossConfig showLatestTipsInBlank(bool showLatestTipsInBlank) =>
      call(showLatestTipsInBlank: showLatestTipsInBlank);

  @override
  CrossConfig moveByCandleInBlank(bool moveByCandleInBlank) =>
      call(moveByCandleInBlank: moveByCandleInBlank);

  @override
  CrossConfig tooltipConfig(TooltipConfig tooltipConfig) =>
      call(tooltipConfig: tooltipConfig);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CrossConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CrossConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CrossConfig call({
    Object? enable = const $CopyWithPlaceholder(),
    Object? crosshair = const $CopyWithPlaceholder(),
    Object? crosspoint = const $CopyWithPlaceholder(),
    Object? ticksText = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? showLatestTipsInBlank = const $CopyWithPlaceholder(),
    Object? moveByCandleInBlank = const $CopyWithPlaceholder(),
    Object? tooltipConfig = const $CopyWithPlaceholder(),
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
      ticksText: ticksText == const $CopyWithPlaceholder() || ticksText == null
          ? _value.ticksText
          // ignore: cast_nullable_to_non_nullable
          : ticksText as TextAreaConfig,
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
      tooltipConfig:
          tooltipConfig == const $CopyWithPlaceholder() || tooltipConfig == null
          ? _value.tooltipConfig
          // ignore: cast_nullable_to_non_nullable
          : tooltipConfig as TooltipConfig,
    );
  }
}

extension $CrossConfigCopyWith on CrossConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCrossConfig.copyWith(...)` or `instanceOfCrossConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CrossConfigCWProxy get copyWith => _$CrossConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrossConfig _$CrossConfigFromJson(Map<String, dynamic> json) => CrossConfig(
  enable: json['enable'] as bool? ?? true,
  crosshair: json['crosshair'] == null
      ? const LineConfig(
          paint: PaintConfig(strokeWidth: defaultAuxiliaryLineWidth),
          type: LineType.dashed,
          dashes: [3, 3],
        )
      : LineConfig.fromJson(json['crosshair'] as Map<String, dynamic>),
  crosspoint: json['crosspoint'] == null
      ? const PointConfig(
          radius: 2,
          width: 0,
          borderWidth: 3,
          borderOpacity: 0.2,
        )
      : PointConfig.fromJson(json['crosspoint'] as Map<String, dynamic>),
  ticksText: json['ticksText'] == null
      ? const TextAreaConfig(
          style: TextStyle(
            fontSize: defaultTextSize,
            fontWeight: FontWeight.normal,
            height: defaultTipsTextHeight,
          ),
          padding: EdgeInsets.all(2),
          border: defaultBorderSide,
          borderRadius: BorderRadius.all(Radius.circular(2)),
          textAlign: TextAlign.end,
        )
      : TextAreaConfig.fromJson(json['ticksText'] as Map<String, dynamic>),
  spacing: (json['spacing'] as num?)?.toDouble() ?? 1,
  showLatestTipsInBlank: json['showLatestTipsInBlank'] as bool? ?? true,
  moveByCandleInBlank: json['moveByCandleInBlank'] as bool? ?? false,
  tooltipConfig: json['tooltipConfig'] == null
      ? const TooltipConfig(
          show: true,
          margin: EdgeInsets.only(left: 15, right: 65, top: 10),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          radius: BorderRadius.all(Radius.circular(6)),
          style: TextStyle(
            fontSize: defaultTextSize,
            overflow: TextOverflow.ellipsis,
            height: defaultMultiTextHeight,
          ),
        )
      : TooltipConfig.fromJson(json['tooltipConfig'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CrossConfigToJson(CrossConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'crosshair': instance.crosshair.toJson(),
      'crosspoint': instance.crosspoint.toJson(),
      'ticksText': instance.ticksText.toJson(),
      'tooltipConfig': instance.tooltipConfig.toJson(),
      'spacing': instance.spacing,
      'showLatestTipsInBlank': instance.showLatestTipsInBlank,
      'moveByCandleInBlank': instance.moveByCandleInBlank,
    };
