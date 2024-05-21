// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tooltip_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TooltipConfig _$TooltipConfigFromJson(Map<String, dynamic> json) =>
    TooltipConfig(
      show: json['show'] as bool? ?? true,
      background: json['background'] == null
          ? const Color(0xFFD6D6D6)
          : const ColorConverter().fromJson(json['background'] as String?),
      margin: json['margin'] == null
          ? const EdgeInsets.only(left: 15, right: 65, top: 4)
          : const EdgeInsetsConverter()
              .fromJson(json['margin'] as Map<String, dynamic>),
      padding: json['padding'] == null
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      radius: json['radius'] == null
          ? const BorderRadius.all(Radius.circular(4))
          : const BorderRadiusConverter()
              .fromJson(json['radius'] as Map<String, dynamic>),
      style: json['style'] == null
          ? const TextStyle(
              fontSize: defaulTextSize,
              color: Colors.black,
              overflow: TextOverflow.ellipsis,
              height: defaultMultiTextHeight)
          : const TextStyleConverter()
              .fromJson(json['style'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TooltipConfigToJson(TooltipConfig instance) {
  final val = <String, dynamic>{
    'show': instance.show,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'background', const ColorConverter().toJson(instance.background));
  val['margin'] = const EdgeInsetsConverter().toJson(instance.margin);
  val['padding'] = const EdgeInsetsConverter().toJson(instance.padding);
  val['radius'] = const BorderRadiusConverter().toJson(instance.radius);
  val['style'] = const TextStyleConverter().toJson(instance.style);
  return val;
}
