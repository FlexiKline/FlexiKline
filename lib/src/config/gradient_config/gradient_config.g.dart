// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradient_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GradientConfigCWProxy {
  GradientConfig begin(Alignment begin);

  GradientConfig end(Alignment end);

  GradientConfig stops(List<double>? stops);

  GradientConfig tileMode(TileMode tileMode);

  GradientConfig startAlpha(double startAlpha);

  GradientConfig endAlpha(double endAlpha);

  GradientConfig colors(List<Color>? colors);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GradientConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GradientConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  GradientConfig call({
    Alignment begin,
    Alignment end,
    List<double>? stops,
    TileMode tileMode,
    double startAlpha,
    double endAlpha,
    List<Color>? colors,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGradientConfig.copyWith(...)` or call `instanceOfGradientConfig.copyWith.fieldName(value)` for a single field.
class _$GradientConfigCWProxyImpl implements _$GradientConfigCWProxy {
  const _$GradientConfigCWProxyImpl(this._value);

  final GradientConfig _value;

  @override
  GradientConfig begin(Alignment begin) => call(begin: begin);

  @override
  GradientConfig end(Alignment end) => call(end: end);

  @override
  GradientConfig stops(List<double>? stops) => call(stops: stops);

  @override
  GradientConfig tileMode(TileMode tileMode) => call(tileMode: tileMode);

  @override
  GradientConfig startAlpha(double startAlpha) => call(startAlpha: startAlpha);

  @override
  GradientConfig endAlpha(double endAlpha) => call(endAlpha: endAlpha);

  @override
  GradientConfig colors(List<Color>? colors) => call(colors: colors);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `GradientConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GradientConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GradientConfig call({
    Object? begin = const $CopyWithPlaceholder(),
    Object? end = const $CopyWithPlaceholder(),
    Object? stops = const $CopyWithPlaceholder(),
    Object? tileMode = const $CopyWithPlaceholder(),
    Object? startAlpha = const $CopyWithPlaceholder(),
    Object? endAlpha = const $CopyWithPlaceholder(),
    Object? colors = const $CopyWithPlaceholder(),
  }) {
    return GradientConfig(
      begin: begin == const $CopyWithPlaceholder() || begin == null
          ? _value.begin
          // ignore: cast_nullable_to_non_nullable
          : begin as Alignment,
      end: end == const $CopyWithPlaceholder() || end == null
          ? _value.end
          // ignore: cast_nullable_to_non_nullable
          : end as Alignment,
      stops: stops == const $CopyWithPlaceholder()
          ? _value.stops
          // ignore: cast_nullable_to_non_nullable
          : stops as List<double>?,
      tileMode: tileMode == const $CopyWithPlaceholder() || tileMode == null
          ? _value.tileMode
          // ignore: cast_nullable_to_non_nullable
          : tileMode as TileMode,
      startAlpha:
          startAlpha == const $CopyWithPlaceholder() || startAlpha == null
          ? _value.startAlpha
          // ignore: cast_nullable_to_non_nullable
          : startAlpha as double,
      endAlpha: endAlpha == const $CopyWithPlaceholder() || endAlpha == null
          ? _value.endAlpha
          // ignore: cast_nullable_to_non_nullable
          : endAlpha as double,
      colors: colors == const $CopyWithPlaceholder()
          ? _value.colors
          // ignore: cast_nullable_to_non_nullable
          : colors as List<Color>?,
    );
  }
}

extension $GradientConfigCopyWith on GradientConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGradientConfig.copyWith(...)` or `instanceOfGradientConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GradientConfigCWProxy get copyWith => _$GradientConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradientConfig _$GradientConfigFromJson(Map<String, dynamic> json) =>
    GradientConfig(
      begin: json['begin'] == null
          ? Alignment.topCenter
          : const AlignmentConverter().fromJson(
              json['begin'] as Map<String, dynamic>,
            ),
      end: json['end'] == null
          ? Alignment.bottomCenter
          : const AlignmentConverter().fromJson(
              json['end'] as Map<String, dynamic>,
            ),
      stops: (json['stops'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      tileMode: json['tileMode'] == null
          ? TileMode.decal
          : const TileModeConverter().fromJson(json['tileMode'] as String),
      startAlpha: (json['startAlpha'] as num?)?.toDouble() ?? 0.5,
      endAlpha: (json['endAlpha'] as num?)?.toDouble() ?? 0.0,
      colors: (json['colors'] as List<dynamic>?)
          ?.map((e) => const ColorConverter().fromJson(e as String))
          .toList(),
    );

Map<String, dynamic> _$GradientConfigToJson(GradientConfig instance) =>
    <String, dynamic>{
      'begin': const AlignmentConverter().toJson(instance.begin),
      'end': const AlignmentConverter().toJson(instance.end),
      'stops': ?instance.stops,
      'tileMode': const TileModeConverter().toJson(instance.tileMode),
      'startAlpha': instance.startAlpha,
      'endAlpha': instance.endAlpha,
      'colors': ?instance.colors?.map(const ColorConverter().toJson).toList(),
    };
