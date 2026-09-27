// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_area_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TextAreaConfigCWProxy {
  TextAreaConfig style(TextStyle style);

  TextAreaConfig textAlign(TextAlign textAlign);

  TextAreaConfig strutStyle(StrutStyle? strutStyle);

  TextAreaConfig textWidth(double? textWidth);

  TextAreaConfig minWidth(double? minWidth);

  TextAreaConfig maxWidth(double? maxWidth);

  TextAreaConfig maxLines(int? maxLines);

  TextAreaConfig backgroundColor(Color? backgroundColor);

  TextAreaConfig padding(EdgeInsets? padding);

  TextAreaConfig border(BorderSide? border);

  TextAreaConfig borderRadius(BorderRadius? borderRadius);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TextAreaConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TextAreaConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  TextAreaConfig call({
    TextStyle style,
    TextAlign textAlign,
    StrutStyle? strutStyle,
    double? textWidth,
    double? minWidth,
    double? maxWidth,
    int? maxLines,
    Color? backgroundColor,
    EdgeInsets? padding,
    BorderSide? border,
    BorderRadius? borderRadius,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTextAreaConfig.copyWith(...)` or call `instanceOfTextAreaConfig.copyWith.fieldName(value)` for a single field.
class _$TextAreaConfigCWProxyImpl implements _$TextAreaConfigCWProxy {
  const _$TextAreaConfigCWProxyImpl(this._value);

  final TextAreaConfig _value;

  @override
  TextAreaConfig style(TextStyle style) => call(style: style);

  @override
  TextAreaConfig textAlign(TextAlign textAlign) => call(textAlign: textAlign);

  @override
  TextAreaConfig strutStyle(StrutStyle? strutStyle) =>
      call(strutStyle: strutStyle);

  @override
  TextAreaConfig textWidth(double? textWidth) => call(textWidth: textWidth);

  @override
  TextAreaConfig minWidth(double? minWidth) => call(minWidth: minWidth);

  @override
  TextAreaConfig maxWidth(double? maxWidth) => call(maxWidth: maxWidth);

  @override
  TextAreaConfig maxLines(int? maxLines) => call(maxLines: maxLines);

  @override
  TextAreaConfig backgroundColor(Color? backgroundColor) =>
      call(backgroundColor: backgroundColor);

  @override
  TextAreaConfig padding(EdgeInsets? padding) => call(padding: padding);

  @override
  TextAreaConfig border(BorderSide? border) => call(border: border);

  @override
  TextAreaConfig borderRadius(BorderRadius? borderRadius) =>
      call(borderRadius: borderRadius);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TextAreaConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TextAreaConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TextAreaConfig call({
    Object? style = const $CopyWithPlaceholder(),
    Object? textAlign = const $CopyWithPlaceholder(),
    Object? strutStyle = const $CopyWithPlaceholder(),
    Object? textWidth = const $CopyWithPlaceholder(),
    Object? minWidth = const $CopyWithPlaceholder(),
    Object? maxWidth = const $CopyWithPlaceholder(),
    Object? maxLines = const $CopyWithPlaceholder(),
    Object? backgroundColor = const $CopyWithPlaceholder(),
    Object? padding = const $CopyWithPlaceholder(),
    Object? border = const $CopyWithPlaceholder(),
    Object? borderRadius = const $CopyWithPlaceholder(),
  }) {
    return TextAreaConfig(
      style: style == const $CopyWithPlaceholder() || style == null
          ? _value.style
          // ignore: cast_nullable_to_non_nullable
          : style as TextStyle,
      textAlign: textAlign == const $CopyWithPlaceholder() || textAlign == null
          ? _value.textAlign
          // ignore: cast_nullable_to_non_nullable
          : textAlign as TextAlign,
      strutStyle: strutStyle == const $CopyWithPlaceholder()
          ? _value.strutStyle
          // ignore: cast_nullable_to_non_nullable
          : strutStyle as StrutStyle?,
      textWidth: textWidth == const $CopyWithPlaceholder()
          ? _value.textWidth
          // ignore: cast_nullable_to_non_nullable
          : textWidth as double?,
      minWidth: minWidth == const $CopyWithPlaceholder()
          ? _value.minWidth
          // ignore: cast_nullable_to_non_nullable
          : minWidth as double?,
      maxWidth: maxWidth == const $CopyWithPlaceholder()
          ? _value.maxWidth
          // ignore: cast_nullable_to_non_nullable
          : maxWidth as double?,
      maxLines: maxLines == const $CopyWithPlaceholder()
          ? _value.maxLines
          // ignore: cast_nullable_to_non_nullable
          : maxLines as int?,
      backgroundColor: backgroundColor == const $CopyWithPlaceholder()
          ? _value.backgroundColor
          // ignore: cast_nullable_to_non_nullable
          : backgroundColor as Color?,
      padding: padding == const $CopyWithPlaceholder()
          ? _value.padding
          // ignore: cast_nullable_to_non_nullable
          : padding as EdgeInsets?,
      border: border == const $CopyWithPlaceholder()
          ? _value.border
          // ignore: cast_nullable_to_non_nullable
          : border as BorderSide?,
      borderRadius: borderRadius == const $CopyWithPlaceholder()
          ? _value.borderRadius
          // ignore: cast_nullable_to_non_nullable
          : borderRadius as BorderRadius?,
    );
  }
}

extension $TextAreaConfigCopyWith on TextAreaConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTextAreaConfig.copyWith(...)` or `instanceOfTextAreaConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TextAreaConfigCWProxy get copyWith => _$TextAreaConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextAreaConfig _$TextAreaConfigFromJson(Map<String, dynamic> json) =>
    TextAreaConfig(
      style: json['style'] == null
          ? const TextStyle(
              fontSize: defaultTextSize,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight,
            )
          : const TextStyleConverter().fromJson(
              json['style'] as Map<String, dynamic>,
            ),
      textAlign: json['textAlign'] == null
          ? TextAlign.start
          : const TextAlignConvert().fromJson(json['textAlign'] as String),
      strutStyle: _$JsonConverterFromJson<Map<String, dynamic>, StrutStyle>(
        json['strutStyle'],
        const StrutStyleConverter().fromJson,
      ),
      textWidth: (json['textWidth'] as num?)?.toDouble(),
      minWidth: (json['minWidth'] as num?)?.toDouble(),
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      maxLines: (json['maxLines'] as num?)?.toInt(),
      backgroundColor: _$JsonConverterFromJson<String, Color>(
        json['backgroundColor'],
        const ColorConverter().fromJson,
      ),
      padding: _$JsonConverterFromJson<Map<String, dynamic>, EdgeInsets>(
        json['padding'],
        const EdgeInsetsConverter().fromJson,
      ),
      border: _$JsonConverterFromJson<Map<String, dynamic>, BorderSide>(
        json['border'],
        const BorderSideConvert().fromJson,
      ),
      borderRadius: _$JsonConverterFromJson<Map<String, dynamic>, BorderRadius>(
        json['borderRadius'],
        const BorderRadiusConverter().fromJson,
      ),
    );

Map<String, dynamic> _$TextAreaConfigToJson(
  TextAreaConfig instance,
) => <String, dynamic>{
  'style': const TextStyleConverter().toJson(instance.style),
  'textAlign': const TextAlignConvert().toJson(instance.textAlign),
  'strutStyle': ?_$JsonConverterToJson<Map<String, dynamic>, StrutStyle>(
    instance.strutStyle,
    const StrutStyleConverter().toJson,
  ),
  'textWidth': ?instance.textWidth,
  'minWidth': ?instance.minWidth,
  'maxWidth': ?instance.maxWidth,
  'maxLines': ?instance.maxLines,
  'backgroundColor': ?_$JsonConverterToJson<String, Color>(
    instance.backgroundColor,
    const ColorConverter().toJson,
  ),
  'padding': ?_$JsonConverterToJson<Map<String, dynamic>, EdgeInsets>(
    instance.padding,
    const EdgeInsetsConverter().toJson,
  ),
  'border': ?_$JsonConverterToJson<Map<String, dynamic>, BorderSide>(
    instance.border,
    const BorderSideConvert().toJson,
  ),
  'borderRadius': ?_$JsonConverterToJson<Map<String, dynamic>, BorderRadius>(
    instance.borderRadius,
    const BorderRadiusConverter().toJson,
  ),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
