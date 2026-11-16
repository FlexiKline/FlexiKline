// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tooltip_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TooltipConfigCWProxy {
  TooltipConfig show(bool show);

  TooltipConfig margin(EdgeInsets margin);

  TooltipConfig padding(EdgeInsets padding);

  TooltipConfig spacing(double spacing);

  TooltipConfig hitTestMargin(double hitTestMargin);

  TooltipConfig style(TextStyle style);

  TooltipConfig backgroundColor(Color? backgroundColor);

  TooltipConfig border(BorderSide? border);

  TooltipConfig borderRadius(BorderRadius? borderRadius);

  TooltipConfig gradient(GradientConfig? gradient);

  TooltipConfig borderGradient(GradientConfig? borderGradient);

  TooltipConfig shadows(List<BoxShadow>? shadows);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TooltipConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TooltipConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  TooltipConfig call({
    bool show,
    EdgeInsets margin,
    EdgeInsets padding,
    double spacing,
    double hitTestMargin,
    TextStyle style,
    Color? backgroundColor,
    BorderSide? border,
    BorderRadius? borderRadius,
    GradientConfig? gradient,
    GradientConfig? borderGradient,
    List<BoxShadow>? shadows,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTooltipConfig.copyWith(...)` or call `instanceOfTooltipConfig.copyWith.fieldName(value)` for a single field.
class _$TooltipConfigCWProxyImpl implements _$TooltipConfigCWProxy {
  const _$TooltipConfigCWProxyImpl(this._value);

  final TooltipConfig _value;

  @override
  TooltipConfig show(bool show) => call(show: show);

  @override
  TooltipConfig margin(EdgeInsets margin) => call(margin: margin);

  @override
  TooltipConfig padding(EdgeInsets padding) => call(padding: padding);

  @override
  TooltipConfig spacing(double spacing) => call(spacing: spacing);

  @override
  TooltipConfig hitTestMargin(double hitTestMargin) =>
      call(hitTestMargin: hitTestMargin);

  @override
  TooltipConfig style(TextStyle style) => call(style: style);

  @override
  TooltipConfig backgroundColor(Color? backgroundColor) =>
      call(backgroundColor: backgroundColor);

  @override
  TooltipConfig border(BorderSide? border) => call(border: border);

  @override
  TooltipConfig borderRadius(BorderRadius? borderRadius) =>
      call(borderRadius: borderRadius);

  @override
  TooltipConfig gradient(GradientConfig? gradient) => call(gradient: gradient);

  @override
  TooltipConfig borderGradient(GradientConfig? borderGradient) =>
      call(borderGradient: borderGradient);

  @override
  TooltipConfig shadows(List<BoxShadow>? shadows) => call(shadows: shadows);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TooltipConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TooltipConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TooltipConfig call({
    Object? show = const $CopyWithPlaceholder(),
    Object? margin = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? hitTestMargin = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
    Object? backgroundColor = const $CopyWithPlaceholder(),
    Object? border = const $CopyWithPlaceholder(),
    Object? borderRadius = const $CopyWithPlaceholder(),
    Object? gradient = const $CopyWithPlaceholder(),
    Object? borderGradient = const $CopyWithPlaceholder(),
    Object? shadows = const $CopyWithPlaceholder(),
  }) {
    return TooltipConfig(
      show: show == const $CopyWithPlaceholder() || show == null
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      margin: margin == const $CopyWithPlaceholder() || margin == null
          ? _value.margin
          // ignore: cast_nullable_to_non_nullable
          : margin as EdgeInsets,
      padding: padding == const $CopyWithPlaceholder() || padding == null
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      spacing: spacing == const $CopyWithPlaceholder() || spacing == null
          ? _value.spacing
          // ignore: cast_nullable_to_non_nullable
          : spacing as double,
      hitTestMargin:
          hitTestMargin == const $CopyWithPlaceholder() || hitTestMargin == null
          ? _value.hitTestMargin
          // ignore: cast_nullable_to_non_nullable
          : hitTestMargin as double,
      style: style == const $CopyWithPlaceholder() || style == null
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as TextStyle,
      backgroundColor: backgroundColor == const $CopyWithPlaceholder()
          ? _value.backgroundColor
          // ignore: cast_nullable_to_non_nullable
          : backgroundColor as Color?,
      border: border == const $CopyWithPlaceholder()
          ? _value.border
          // ignore: cast_nullable_to_non_nullable
          : border as BorderSide?,
      borderRadius: borderRadius == const $CopyWithPlaceholder()
          ? _value.borderRadius
          // ignore: cast_nullable_to_non_nullable
          : borderRadius as BorderRadius?,
      gradient: gradient == const $CopyWithPlaceholder()
          ? _value.gradient
          // ignore: cast_nullable_to_non_nullable
          : gradient as GradientConfig?,
      borderGradient: borderGradient == const $CopyWithPlaceholder()
          ? _value.borderGradient
          // ignore: cast_nullable_to_non_nullable
          : borderGradient as GradientConfig?,
      shadows: shadows == const $CopyWithPlaceholder()
          ? _value.shadows
          // ignore: cast_nullable_to_non_nullable
          : shadows as List<BoxShadow>?,
    );
  }
}

extension $TooltipConfigCopyWith on TooltipConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTooltipConfig.copyWith(...)` or `instanceOfTooltipConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TooltipConfigCWProxy get copyWith => _$TooltipConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TooltipConfig _$TooltipConfigFromJson(Map<String, dynamic> json) =>
    TooltipConfig(
      show: json['show'] as bool? ?? true,
      margin: const EdgeInsetsConverter().fromJson(
        json['margin'] as Map<String, dynamic>,
      ),
      padding: const EdgeInsetsConverter().fromJson(
        json['padding'] as Map<String, dynamic>,
      ),
      spacing: (json['spacing'] as num?)?.toDouble() ?? 2,
      hitTestMargin: (json['hitTestMargin'] as num?)?.toDouble() ?? 2,
      style: const TextStyleConverter().fromJson(
        json['style'] as Map<String, dynamic>,
      ),
      backgroundColor: _$JsonConverterFromJson<String, Color>(
        json['backgroundColor'],
        const ColorConverter().fromJson,
      ),
      border: _$JsonConverterFromJson<Map<String, dynamic>, BorderSide>(
        json['border'],
        const BorderSideConverter().fromJson,
      ),
      borderRadius: _$JsonConverterFromJson<Map<String, dynamic>, BorderRadius>(
        json['borderRadius'],
        const BorderRadiusConverter().fromJson,
      ),
      gradient: json['gradient'] == null
          ? null
          : GradientConfig.fromJson(json['gradient'] as Map<String, dynamic>),
      borderGradient: json['borderGradient'] == null
          ? null
          : GradientConfig.fromJson(
              json['borderGradient'] as Map<String, dynamic>,
            ),
      shadows: (json['shadows'] as List<dynamic>?)
          ?.map(
            (e) =>
                const BoxShadowConverter().fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$TooltipConfigToJson(
  TooltipConfig instance,
) => <String, dynamic>{
  'show': instance.show,
  'margin': const EdgeInsetsConverter().toJson(instance.margin),
  'padding': const EdgeInsetsConverter().toJson(instance.padding),
  'spacing': instance.spacing,
  'hitTestMargin': instance.hitTestMargin,
  'style': const TextStyleConverter().toJson(instance.style),
  'backgroundColor': ?_$JsonConverterToJson<String, Color>(
    instance.backgroundColor,
    const ColorConverter().toJson,
  ),
  'border': ?_$JsonConverterToJson<Map<String, dynamic>, BorderSide>(
    instance.border,
    const BorderSideConverter().toJson,
  ),
  'borderRadius': ?_$JsonConverterToJson<Map<String, dynamic>, BorderRadius>(
    instance.borderRadius,
    const BorderRadiusConverter().toJson,
  ),
  'gradient': ?instance.gradient?.toJson(),
  'borderGradient': ?instance.borderGradient?.toJson(),
  'shadows': ?instance.shadows?.map(const BoxShadowConverter().toJson).toList(),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
