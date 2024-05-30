// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vol_ma.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VolMaIndicator _$VolMaIndicatorFromJson(Map<String, dynamic> json) =>
    VolMaIndicator(
      key: json['key'] == null
          ? volMaKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'VOLMA',
      height: (json['height'] as num?)?.toDouble() ?? defaultSubIndicatorHeight,
      padding: json['padding'] == null
          ? defaultSubIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>)
          .map((e) => MaParam.fromJson(e as Map<String, dynamic>))
          .toList(),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      lineWidth: (json['lineWidth'] as num).toDouble(),
      precision: (json['precision'] as num).toInt(),
    );

Map<String, dynamic> _$VolMaIndicatorToJson(VolMaIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'lineWidth': instance.lineWidth,
      'precision': instance.precision,
    };
