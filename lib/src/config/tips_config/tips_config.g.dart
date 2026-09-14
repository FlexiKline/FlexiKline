// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tips_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TipsConfigCWProxy {
  TipsConfig label(String label);

  TipsConfig precision(int? precision);

  TipsConfig isShow(bool isShow);

  TipsConfig lineWidth(double? lineWidth);

  TipsConfig style(TextStyle style);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TipsConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TipsConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  TipsConfig call({
    String label,
    int? precision,
    bool isShow,
    double? lineWidth,
    TextStyle style,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTipsConfig.copyWith(...)` or call `instanceOfTipsConfig.copyWith.fieldName(value)` for a single field.
class _$TipsConfigCWProxyImpl implements _$TipsConfigCWProxy {
  const _$TipsConfigCWProxyImpl(this._value);

  final TipsConfig _value;

  @override
  TipsConfig label(String label) => call(label: label);

  @override
  TipsConfig precision(int? precision) => call(precision: precision);

  @override
  TipsConfig isShow(bool isShow) => call(isShow: isShow);

  @override
  TipsConfig lineWidth(double? lineWidth) => call(lineWidth: lineWidth);

  @override
  TipsConfig style(TextStyle style) => call(style: style);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TipsConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TipsConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TipsConfig call({
    Object? label = const $CopyWithPlaceholder(),
    Object? precision = const $CopyWithPlaceholder(),
    Object? isShow = const $CopyWithPlaceholder(),
    Object? lineWidth = const $CopyWithPlaceholder(),
    Object? style = const $CopyWithPlaceholder(),
  }) {
    return TipsConfig(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      precision: precision == const $CopyWithPlaceholder()
          ? _value.precision
          // ignore: cast_nullable_to_non_nullable
          : precision as int?,
      isShow: isShow == const $CopyWithPlaceholder() || isShow == null
          ? _value.isShow
          // ignore: cast_nullable_to_non_nullable
          : isShow as bool,
      lineWidth: lineWidth == const $CopyWithPlaceholder()
          ? _value.lineWidth
          // ignore: cast_nullable_to_non_nullable
          : lineWidth as double?,
      style: style == const $CopyWithPlaceholder() || style == null
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as TextStyle,
    );
  }
}

extension $TipsConfigCopyWith on TipsConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTipsConfig.copyWith(...)` or `instanceOfTipsConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TipsConfigCWProxy get copyWith => _$TipsConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TipsConfig _$TipsConfigFromJson(Map<String, dynamic> json) => TipsConfig(
  label: json['label'] as String? ?? '',
  precision: (json['precision'] as num?)?.toInt(),
  isShow: json['isShow'] as bool? ?? true,
  lineWidth: (json['lineWidth'] as num?)?.toDouble(),
  style: json['style'] == null
      ? const TextStyle(
          fontSize: defaultTextSize,
          overflow: TextOverflow.ellipsis,
          height: defaultTipsTextHeight,
        )
      : const TextStyleConverter().fromJson(
          json['style'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$TipsConfigToJson(TipsConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      'precision': ?instance.precision,
      'isShow': instance.isShow,
      'lineWidth': ?instance.lineWidth,
      'style': const TextStyleConverter().toJson(instance.style),
    };
