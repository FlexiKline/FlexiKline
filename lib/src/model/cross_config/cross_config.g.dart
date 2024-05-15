// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrossConfig _$CrossConfigFromJson(Map<String, dynamic> json) => CrossConfig(
      enable: json['enable'] as bool? ?? true,
      crosshair: json['crosshair'] == null
          ? const LineConfig(
              type: LineType.dashed,
              color: Colors.black,
              width: 0.5,
              dashes: [3, 3])
          : LineConfig.fromJson(json['crosshair'] as Map<String, dynamic>),
      point: json['point'] == null
          ? const CrossPointConfig()
          : CrossPointConfig.fromJson(json['point'] as Map<String, dynamic>),
      tickText: json['tickText'] == null
          ? const TextAreaConfig(
              style: TextStyle(
                  fontSize: defaulTextSize,
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                  height: defaultTextHeight),
              background: Colors.black,
              padding: EdgeInsets.all(2),
              border: BorderSide.none,
              borderRadius: BorderRadius.all(Radius.circular(2)))
          : TextAreaConfig.fromJson(json['tickText'] as Map<String, dynamic>),
      spacing: (json['spacing'] as num?)?.toDouble() ?? 1,
    );

Map<String, dynamic> _$CrossConfigToJson(CrossConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'crosshair': instance.crosshair.toJson(),
      'point': instance.point.toJson(),
      'tickText': instance.tickText.toJson(),
      'spacing': instance.spacing,
    };

CrossPointConfig _$CrossPointConfigFromJson(Map<String, dynamic> json) =>
    CrossPointConfig(
      radius: (json['radius'] as num?)?.toDouble() ?? 2,
      width: (json['width'] as num?)?.toDouble() ?? 6,
      color: json['color'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['color'] as String?),
    );

Map<String, dynamic> _$CrossPointConfigToJson(CrossPointConfig instance) {
  final val = <String, dynamic>{
    'radius': instance.radius,
    'width': instance.width,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('color', const ColorConverter().toJson(instance.color));
  return val;
}
