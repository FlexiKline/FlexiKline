// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ma.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MAIndicator _$MAIndicatorFromJson(Map<String, dynamic> json) => MAIndicator(
      key: json['key'] == null
          ? maKey
          : const ValueKeyConverter().fromJson(json['key'] as String),
      name: json['name'] as String? ?? 'MA',
      height: (json['height'] as num).toDouble(),
      padding: json['padding'] == null
          ? defaultMainIndicatorPadding
          : const EdgeInsetsConverter()
              .fromJson(json['padding'] as Map<String, dynamic>),
      calcParams: (json['calcParams'] as List<dynamic>)
          .map((e) => MaParam.fromJson(e as Map<String, dynamic>))
          .toList(),
      tipsPadding: const EdgeInsetsConverter()
          .fromJson(json['tipsPadding'] as Map<String, dynamic>),
      lineWidth: (json['lineWidth'] as num).toDouble(),
    );

Map<String, dynamic> _$MAIndicatorToJson(MAIndicator instance) =>
    <String, dynamic>{
      'key': const ValueKeyConverter().toJson(instance.key),
      'name': instance.name,
      'height': instance.height,
      'padding': const EdgeInsetsConverter().toJson(instance.padding),
      'calcParams': instance.calcParams.map((e) => e.toJson()).toList(),
      'tipsPadding': const EdgeInsetsConverter().toJson(instance.tipsPadding),
      'lineWidth': instance.lineWidth,
    };
