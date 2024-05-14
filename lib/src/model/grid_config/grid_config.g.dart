// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grid_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GridConfig _$GridConfigFromJson(Map<String, dynamic> json) => GridConfig(
      show: json['show'] as bool? ?? true,
      horizontal: json['horizontal'] == null
          ? const GridAxis()
          : GridAxis.fromJson(json['horizontal'] as Map<String, dynamic>),
      vertical: json['vertical'] == null
          ? const GridAxis()
          : GridAxis.fromJson(json['vertical'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GridConfigToJson(GridConfig instance) =>
    <String, dynamic>{
      'show': instance.show,
      'horizontal': instance.horizontal.toJson(),
      'vertical': instance.vertical.toJson(),
    };

GridAxis _$GridAxisFromJson(Map<String, dynamic> json) => GridAxis(
      show: json['show'] as bool? ?? true,
      count: (json['count'] as num?)?.toInt() ?? 5,
      width: (json['width'] as num?)?.toDouble() ?? 0.5,
      color: json['color'] == null
          ? const Color(0xffE9EDF0)
          : const ColorConverter().fromJson(json['color'] as String?),
      type: json['type'] == null
          ? LineType.solid
          : const LineTypeConverter().fromJson(json['type'] as String),
      dashes: (json['dashes'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [2, 2],
    );

Map<String, dynamic> _$GridAxisToJson(GridAxis instance) {
  final val = <String, dynamic>{
    'show': instance.show,
    'count': instance.count,
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
