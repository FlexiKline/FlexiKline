// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkConfig _$MarkConfigFromJson(Map<String, dynamic> json) => MarkConfig(
      show: json['show'] as bool? ?? true,
      spacing: (json['spacing'] as num?)?.toDouble() ?? 0,
      line: json['line'] == null
          ? const LineConfig()
          : LineConfig.fromJson(json['line'] as Map<String, dynamic>),
      text: json['text'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.black,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight))
          : TextAreaConfig.fromJson(json['text'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MarkConfigToJson(MarkConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'spacing': instance.spacing,
      'line': instance.line.toJson(),
      'text': instance.text.toJson(),
    };
