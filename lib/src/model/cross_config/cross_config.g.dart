// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrossConfig _$CrossConfigFromJson(Map<String, dynamic> json) => CrossConfig(
      enable: json['enable'] as bool? ?? true,
      crosshair: json['crosshair'] == null
          ? const Crosshair()
          : Crosshair.fromJson(json['crosshair'] as Map<String, dynamic>),
      point: json['point'] == null
          ? const CrossPoint()
          : CrossPoint.fromJson(json['point'] as Map<String, dynamic>),
      tickText: json['tickText'] == null
          ? const CrossTickText()
          : CrossTickText.fromJson(json['tickText'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CrossConfigToJson(CrossConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'crosshair': instance.crosshair.toJson(),
      'point': instance.point.toJson(),
      'tickText': instance.tickText.toJson(),
    };

Crosshair _$CrosshairFromJson(Map<String, dynamic> json) => Crosshair(
      width: (json['width'] as num?)?.toDouble() ?? 0.5,
      color: json['color'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['color'] as String?),
      type: json['type'] == null
          ? LineType.dashed
          : const LineTypeConverter().fromJson(json['type'] as String),
      dashes: (json['dashes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [3, 3],
    );

Map<String, dynamic> _$CrosshairToJson(Crosshair instance) {
  final val = <String, dynamic>{
    'width': instance.width,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('color', const ColorConverter().toJson(instance.color));
  val['type'] = const LineTypeConverter().toJson(instance.type);
  val['dashes'] = instance.dashes;
  return val;
}

CrossPoint _$CrossPointFromJson(Map<String, dynamic> json) => CrossPoint(
      radius: (json['radius'] as num?)?.toDouble() ?? 2,
      width: (json['width'] as num?)?.toDouble() ?? 6,
      color: json['color'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['color'] as String?),
    );

Map<String, dynamic> _$CrossPointToJson(CrossPoint instance) {
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

CrossTickText _$CrossTickTextFromJson(Map<String, dynamic> json) =>
    CrossTickText(
      style: json['style'] == null
          ? const TextStyle(
              fontSize: defaulTextSize,
              color: Colors.white,
              overflow: TextOverflow.ellipsis,
              height: defaultTextHeight)
          : const TextStyleConverter()
              .fromJson(json['style'] as Map<String, dynamic>),
      background: json['background'] == null
          ? Colors.black
          : const ColorConverter().fromJson(json['background'] as String?),
      padding: json['padding'] == null
          ? const EdgeInsets.all(2)
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      border: json['border'] == null
          ? BorderSide.none
          : const BorderSideConvert()
              .fromJson(json['border'] as Map<String, dynamic>),
      borderRadius: json['borderRadius'] == null
          ? const BorderRadius.all(Radius.circular(2))
          : const BorderRadiusConverter()
              .fromJson(json['borderRadius'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CrossTickTextToJson(CrossTickText instance) {
  final val = <String, dynamic>{
    'style': const TextStyleConverter().toJson(instance.style),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'background', const ColorConverter().toJson(instance.background));
  val['padding'] = const EdgeInsetsConverter().toJson(instance.padding);
  val['border'] = const BorderSideConvert().toJson(instance.border);
  val['borderRadius'] =
      const BorderRadiusConverter().toJson(instance.borderRadius);
  return val;
}
