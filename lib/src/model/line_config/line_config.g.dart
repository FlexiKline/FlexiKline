// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineConfig _$LineConfigFromJson(Map<String, dynamic> json) => LineConfig(
      type: json['type'] == null
          ? LineType.solid
          : const LineTypeConverter().fromJson(json['type'] as String),
      color: json['color'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['color'] as String?),
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 0.5,
      dashes: (json['dashes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [3, 3],
    );

Map<String, dynamic> _$LineConfigToJson(LineConfig instance) {
  final val = <String, dynamic>{
    'type': const LineTypeConverter().toJson(instance.type),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('color', const ColorConverter().toJson(instance.color));
  writeNotNull('length', instance.length);
  val['width'] = instance.width;
  val['dashes'] = instance.dashes;
  return val;
}
