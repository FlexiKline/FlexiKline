// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoadingConfig _$LoadingConfigFromJson(Map<String, dynamic> json) =>
    LoadingConfig(
      size: (json['size'] as num?)?.toDouble() ?? 24,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 4,
      background: json['background'] == null
          ? const Color(0xFFECECEC)
          : const ColorConverter().fromJson(json['background'] as String?),
      valueColor: json['valueColor'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['valueColor'] as String?),
    );

Map<String, dynamic> _$LoadingConfigToJson(LoadingConfig instance) {
  final val = <String, dynamic>{
    'size': instance.size,
    'strokeWidth': instance.strokeWidth,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'background', const ColorConverter().toJson(instance.background));
  writeNotNull(
      'valueColor', const ColorConverter().toJson(instance.valueColor));
  return val;
}
