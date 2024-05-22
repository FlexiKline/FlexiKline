// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_area_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextAreaConfig _$TextAreaConfigFromJson(Map<String, dynamic> json) =>
    TextAreaConfig(
      style: json['style'] == null
          ? const TextStyle(
              fontSize: defaulTextSize,
              color: Colors.black,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight)
          : const TextStyleConverter()
              .fromJson(json['style'] as Map<String, dynamic>),
      textAlign: json['textAlign'] == null
          ? TextAlign.start
          : const TextAlignConvert().fromJson(json['textAlign'] as String),
      strutStyle: _$JsonConverterFromJson<Map<String, dynamic>, StrutStyle>(
          json['strutStyle'], const StrutStyleConverter().fromJson),
      textWidth: (json['textWidth'] as num?)?.toDouble(),
      minWidth: (json['minWidth'] as num?)?.toDouble(),
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      maxLines: (json['maxLines'] as num?)?.toInt(),
      background:
          const ColorConverter().fromJson(json['background'] as String?),
      padding: _$JsonConverterFromJson<Map<String, dynamic>, EdgeInsets>(
          json['padding'], const EdgeInsetsConverter().fromJson),
      border: _$JsonConverterFromJson<Map<String, dynamic>, BorderSide>(
          json['border'], const BorderSideConvert().fromJson),
      borderRadius: _$JsonConverterFromJson<Map<String, dynamic>, BorderRadius>(
          json['borderRadius'], const BorderRadiusConverter().fromJson),
    );

Map<String, dynamic> _$TextAreaConfigToJson(TextAreaConfig instance) {
  final val = <String, dynamic>{
    'style': const TextStyleConverter().toJson(instance.style),
    'textAlign': const TextAlignConvert().toJson(instance.textAlign),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'strutStyle',
      _$JsonConverterToJson<Map<String, dynamic>, StrutStyle>(
          instance.strutStyle, const StrutStyleConverter().toJson));
  writeNotNull('textWidth', instance.textWidth);
  writeNotNull('minWidth', instance.minWidth);
  writeNotNull('maxWidth', instance.maxWidth);
  writeNotNull('maxLines', instance.maxLines);
  writeNotNull(
      'background',
      _$JsonConverterToJson<String?, Color>(
          instance.background, const ColorConverter().toJson));
  writeNotNull(
      'padding',
      _$JsonConverterToJson<Map<String, dynamic>, EdgeInsets>(
          instance.padding, const EdgeInsetsConverter().toJson));
  writeNotNull(
      'border',
      _$JsonConverterToJson<Map<String, dynamic>, BorderSide>(
          instance.border, const BorderSideConvert().toJson));
  writeNotNull(
      'borderRadius',
      _$JsonConverterToJson<Map<String, dynamic>, BorderRadius>(
          instance.borderRadius, const BorderRadiusConverter().toJson));
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
