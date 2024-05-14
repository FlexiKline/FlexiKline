// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tips_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TipsConfig _$TipsConfigFromJson(Map<String, dynamic> json) => TipsConfig(
      label: json['label'] as String? ?? '',
      precision: (json['precision'] as num?)?.toInt(),
      style: json['style'] == null
          ? const TextStyle(
              fontSize: defaulTextSize,
              color: Colors.black,
              overflow: TextOverflow.ellipsis,
              height: defaultTipsTextHeight)
          : const TextStyleConverter()
              .fromJson(json['style'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TipsConfigToJson(TipsConfig instance) {
  final val = <String, dynamic>{
    'label': instance.label,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('precision', instance.precision);
  val['style'] = const TextStyleConverter().toJson(instance.style);
  return val;
}
