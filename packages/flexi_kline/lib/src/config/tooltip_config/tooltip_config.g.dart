// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tooltip_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TooltipConfigCWProxy {
  TooltipConfig show(bool show);

  TooltipConfig margin(EdgeInsets margin);

  TooltipConfig padding(EdgeInsets padding);

  TooltipConfig radius(BorderRadius radius);

  TooltipConfig spacing(double spacing);

  TooltipConfig hitTestMargin(double hitTestMargin);

  TooltipConfig style(TextStyle style);

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
    BorderRadius radius,
    double spacing,
    double hitTestMargin,
    TextStyle style,
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
  TooltipConfig radius(BorderRadius radius) => call(radius: radius);

  @override
  TooltipConfig spacing(double spacing) => call(spacing: spacing);

  @override
  TooltipConfig hitTestMargin(double hitTestMargin) =>
      call(hitTestMargin: hitTestMargin);

  @override
  TooltipConfig style(TextStyle style) => call(style: style);

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
    Object? radius = const $CopyWithPlaceholder(),
    Object? spacing = const $CopyWithPlaceholder(),
    Object? hitTestMargin = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
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
      radius: radius == const $CopyWithPlaceholder() || radius == null
          ? _value.radius
          // ignore: cast_nullable_to_non_nullable
          : radius as BorderRadius,
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
      radius: const BorderRadiusConverter().fromJson(
        json['radius'] as Map<String, dynamic>,
      ),
      spacing: (json['spacing'] as num?)?.toDouble() ?? 2,
      hitTestMargin: (json['hitTestMargin'] as num?)?.toDouble() ?? 2,
      style: const TextStyleConverter().fromJson(
        json['style'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$TooltipConfigToJson(TooltipConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'margin': const EdgeInsetsConverter().toJson(instance.margin),
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'radius': const BorderRadiusConverter().toJson(instance.radius),
      'spacing': instance.spacing,
      'hitTestMargin': instance.hitTestMargin,
      'style': const TextStyleConverter().toJson(instance.style),
    };
