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

  TooltipConfig style(TextStyle style);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TooltipConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TooltipConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  TooltipConfig call({
    bool show,
    EdgeInsets margin,
    EdgeInsets padding,
    BorderRadius radius,
    TextStyle style,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTooltipConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTooltipConfig.copyWith.fieldName(...)`
class _$TooltipConfigCWProxyImpl implements _$TooltipConfigCWProxy {
  const _$TooltipConfigCWProxyImpl(this._value);

  final TooltipConfig _value;

  @override
  TooltipConfig show(bool show) => this(show: show);

  @override
  TooltipConfig margin(EdgeInsets margin) => this(margin: margin);

  @override
  TooltipConfig padding(EdgeInsets padding) => this(padding: padding);

  @override
  TooltipConfig radius(BorderRadius radius) => this(radius: radius);

  @override
  TooltipConfig style(TextStyle style) => this(style: style);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TooltipConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TooltipConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  TooltipConfig call({
    Object? show = const $CopyWithPlaceholder(),
    Object? margin = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? radius = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
  }) {
    return TooltipConfig(
      show: show == const $CopyWithPlaceholder()
          ? _value.show
          // ignore: cast_nullable_to_non_nullable
          : show as bool,
      margin: margin == const $CopyWithPlaceholder()
          ? _value.margin
          // ignore: cast_nullable_to_non_nullable
          : margin as EdgeInsets,
      padding: padding == const $CopyWithPlaceholder()
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets,
      radius: radius == const $CopyWithPlaceholder()
          ? _value.radius
          // ignore: cast_nullable_to_non_nullable
          : radius as BorderRadius,
      style: style == const $CopyWithPlaceholder()
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as TextStyle,
    );
  }
}

extension $TooltipConfigCopyWith on TooltipConfig {
  /// Returns a callable class that can be used as follows: `instanceOfTooltipConfig.copyWith(...)` or like so:`instanceOfTooltipConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TooltipConfigCWProxy get copyWith => _$TooltipConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TooltipConfig _$TooltipConfigFromJson(Map<String, dynamic> json) =>
    TooltipConfig(
      show: json['show'] as bool? ?? true,
      margin: const EdgeInsetsConverter()
          .fromJson(json['margin'] as Map<String, dynamic>),
      padding: const EdgeInsetsConverter()
          .fromJson(json['padding'] as Map<String, dynamic>),
      radius: const BorderRadiusConverter()
          .fromJson(json['radius'] as Map<String, dynamic>),
      style: const TextStyleConverter()
          .fromJson(json['style'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TooltipConfigToJson(TooltipConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'margin': const EdgeInsetsConverter().toJson(instance.margin),
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'radius': const BorderRadiusConverter().toJson(instance.radius),
      'style': const TextStyleConverter().toJson(instance.style),
    };
